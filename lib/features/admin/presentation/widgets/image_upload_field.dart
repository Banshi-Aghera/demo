import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/providers/services_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Picks images, uploads them to Storage and reports back the URLs.
/// Uploading immediately keeps the form simple: by save time the URLs exist.
class ImageUploadField extends ConsumerStatefulWidget {
  const ImageUploadField({
    super.key,
    required this.urls,
    required this.onChanged,
    required this.folder,
    this.max = 5,
    this.label = AppStrings.images,
  });

  final List<String> urls;
  final ValueChanged<List<String>> onChanged;
  final String folder;
  final int max;
  final String label;

  @override
  ConsumerState<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends ConsumerState<ImageUploadField> {
  bool _busy = false;

  Future<void> _add() async {
    final storage = ref.read(storageServiceProvider);
    final file = await storage.pickImage();
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final url = await storage.upload(widget.folder, file);
      widget.onChanged([...widget.urls, url]);
    } catch (e) {
      final msg = ErrorMapper.message(e);
      if (mounted && msg != null) showErrorSnackBar(context, msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: Gap.s),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (final url in widget.urls)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppNetworkImage(url: url, width: 84, height: 84),
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: IconButton.filledTonal(
                      iconSize: 16,
                      visualDensity: VisualDensity.compact,
                      tooltip: AppStrings.remove,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => widget.onChanged(
                          widget.urls.where((u) => u != url).toList()),
                    ),
                  ),
                ],
              ),
            if (widget.urls.length < widget.max)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _busy ? null : _add,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: _busy
                      ? const Center(
                          child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: scheme.primary),
                            const SizedBox(height: 2),
                            Text(AppStrings.addImage,
                                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                          ],
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
