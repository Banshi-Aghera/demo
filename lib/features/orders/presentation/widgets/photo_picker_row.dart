import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/services_providers.dart';
import '../../../../core/theme/app_spacing.dart';

/// Thumbnails of picked photos plus an "Add photo" tile.
class PhotoPickerRow extends ConsumerWidget {
  const PhotoPickerRow({
    super.key,
    required this.photos,
    required this.max,
    required this.onChanged,
  });

  final List<XFile> photos;
  final int max;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    Future<void> add() async {
      final file = await ref.read(storageServiceProvider).pickImage();
      if (file != null) {
        photos.add(file);
        onChanged();
      }
    }

    return Wrap(
      spacing: Gap.s,
      runSpacing: Gap.s,
      children: [
        for (final p in photos)
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 72,
                  child: FutureBuilder<Uint8List>(
                    future: p.readAsBytes(),
                    builder: (context, snap) => snap.hasData
                        ? Image.memory(snap.data!, fit: BoxFit.cover)
                        : Container(color: scheme.surfaceContainerHighest),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                top: -8,
                child: IconButton.filledTonal(
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  tooltip: AppStrings.remove,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    photos.remove(p);
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        if (photos.length < max)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: add,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: scheme.primary),
                  const SizedBox(height: 2),
                  Text(AppStrings.addPhoto,
                      style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
