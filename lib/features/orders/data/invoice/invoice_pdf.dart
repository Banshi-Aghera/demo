import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/constants/app_strings.dart';
import '../models/app_order.dart';
import 'amount_in_words.dart';

/// Builds a GST tax invoice from the order. All amounts come from the server
/// (taxable value and tax per line are stored on the order), so the invoice
/// always matches what was charged.
class InvoicePdf {
  InvoicePdf._();

  static Future<Uint8List> build(AppOrder order) async {
    // Noto Sans has the ₹ glyph; fall back to "Rs." if the font can't load.
    pw.Font? regular;
    pw.Font? bold;
    try {
      regular = await PdfGoogleFonts.notoSansRegular();
      bold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {}
    final rupee = regular == null ? 'Rs. ' : '₹';
    final money = NumberFormat.currency(locale: 'en_IN', symbol: rupee, decimalDigits: 2);
    final num2 = NumberFormat('#,##,##0.00', 'en_IN');

    final seller = order.seller;
    final intra = order.taxType == 'intra';
    final date = order.createdAt ?? DateTime.now();
    final dateFmt = DateFormat('d MMM yyyy');
    const teal = PdfColor.fromInt(0xFF0F766E);
    const grey = PdfColor.fromInt(0xFF6B7280);

    final small = pw.TextStyle(fontSize: 8.5, color: grey);
    final label = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

    // ---------- Table rows ----------
    final headers = <String>[
      '#',
      AppStrings.invItem,
      AppStrings.invQty,
      AppStrings.invTaxable,
      AppStrings.invGstRate,
      if (intra) AppStrings.invCgst,
      if (intra) AppStrings.invSgst,
      if (!intra) AppStrings.invIgst,
      AppStrings.invTotal,
    ];

    List<String> taxCells(double tax) => intra
        ? [num2.format(tax / 2), num2.format(tax / 2)]
        : [num2.format(tax)];

    final rows = <List<String>>[];
    var i = 1;
    for (final l in order.items) {
      rows.add([
        '${i++}',
        l.variantLabel == null ? l.name : '${l.name} (${l.variantLabel})',
        '${l.quantity}',
        num2.format(l.taxableValue),
        '${l.gstRate.toStringAsFixed(l.gstRate % 1 == 0 ? 0 : 1)}%',
        ...taxCells(l.taxAmount),
        num2.format(l.netAmount),
      ]);
    }
    final p = order.pricing;
    if (p.deliveryFee > 0) {
      rows.add([
        '${i++}',
        AppStrings.invDeliveryCharges,
        '1',
        num2.format(p.deliveryTaxable),
        '18%',
        ...taxCells(p.deliveryTax),
        num2.format(p.deliveryFee),
      ]);
    }

    final totalTaxable =
        order.items.fold<double>(0, (a, l) => a + l.taxableValue) + p.deliveryTaxable;
    final totalTax = p.gstIncluded + p.deliveryTax;

    final doc = pw.Document(
      title: '${AppStrings.taxInvoice} ${order.invoiceNumber}',
      author: seller?.legalName ?? AppStrings.appName,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: regular == null
            ? pw.ThemeData.base()
            : pw.ThemeData.withFont(base: regular, bold: bold),
        build: (context) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppStrings.appName,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: teal)),
                    pw.SizedBox(height: 4),
                    pw.Text(AppStrings.taxInvoice,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _kv('${AppStrings.invoiceNo}: ', order.invoiceNumber, label),
                  _kv('${AppStrings.invoiceDate}: ', dateFmt.format(date), label),
                  _kv('${AppStrings.orderNo}: ', order.orderNumber, label),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),

          // Seller and buyer
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppStrings.soldBy, style: label),
                    pw.SizedBox(height: 3),
                    if (seller == null || seller.legalName.isEmpty)
                      pw.Text(AppStrings.sellerNotConfigured, style: small)
                    else ...[
                      pw.Text(seller.legalName),
                      pw.Text(seller.addressLine, style: small),
                      pw.Text('${seller.city}, ${seller.state} ${seller.pincode}', style: small),
                      pw.SizedBox(height: 3),
                      pw.Text('${AppStrings.gstin}: ${seller.gstin}', style: label),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppStrings.billTo, style: label),
                    pw.SizedBox(height: 3),
                    pw.Text(order.address.fullName),
                    pw.Text(order.address.formatted, style: small),
                    pw.Text(order.address.phone, style: small),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${AppStrings.placeOfSupply}: ${order.address.state}'
                      '${order.address.stateCode.isEmpty ? '' : ' (${order.address.stateCode})'}',
                      style: label,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Items
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: teal),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.centerRight,
            cellAlignments: {0: pw.Alignment.center, 1: pw.Alignment.centerLeft},
            columnWidths: {1: const pw.FlexColumnWidth(3.2)},
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF6F7F9)),
          ),
          pw.SizedBox(height: 10),

          // Totals
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (p.couponDiscount > 0)
                      pw.Text(
                        '${AppStrings.invCouponNote} (${p.couponCode}: -${money.format(p.couponDiscount)})',
                        style: small,
                      ),
                    pw.SizedBox(height: 6),
                    pw.Text(AppStrings.amountInWords, style: label),
                    pw.Text(amountInWords(p.grandTotal), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Container(
                width: 210,
                child: pw.Column(
                  children: [
                    _total(AppStrings.invTaxable, money.format(totalTaxable)),
                    if (intra) ...[
                      _total(AppStrings.invCgst, money.format(totalTax / 2)),
                      _total(AppStrings.invSgst, money.format(totalTax / 2)),
                    ] else
                      _total(AppStrings.invIgst, money.format(totalTax)),
                    pw.Divider(color: PdfColors.grey400),
                    _total(AppStrings.grandTotal, money.format(p.grandTotal), bold: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Text(AppStrings.invFooter, style: small),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _kv(String k, String v, pw.TextStyle labelStyle) => pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: k, style: labelStyle),
          pw.TextSpan(text: v, style: const pw.TextStyle(fontSize: 9)),
        ]),
      );

  static pw.Widget _total(String k, String v, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 11 : 9.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.Expanded(child: pw.Text(k, style: style)),
        pw.Text(v, style: style),
      ]),
    );
  }

  /// Opens the system share/save sheet (downloads the file on web).
  static Future<void> share(AppOrder order) async {
    final bytes = await build(order);
    final safeName = order.invoiceNumber.replaceAll('/', '-');
    await Printing.sharePdf(bytes: bytes, filename: 'Invoice-$safeName.pdf');
  }
}
