import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

/// Grid of photo thumbnails plus an "Add" tile.
///
/// The submit screen owns the [photos] list; this widget just renders it,
/// invokes the system picker via [ImagePicker], and reports edits back. We
/// cap at [maxPhotos] to keep upload payloads predictable.
class PhotoPickerGrid extends StatelessWidget {
  const PhotoPickerGrid({
    required this.photos,
    required this.onChanged,
    required this.enabled,
    this.maxPhotos = 6,
    super.key,
  });

  final List<XFile> photos;
  final ValueChanged<List<XFile>> onChanged;
  final bool enabled;
  final int maxPhotos;

  Future<void> _pick(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      // Aggressive client-side compression keeps Storage costs sane and
      // landlord/contractor downloads quick over cellular. Plenty of
      // headroom for AI analysis to read the image too.
      final List<XFile> picked = await picker.pickMultiImage(
        imageQuality: 60,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked.isEmpty) return;
      final List<XFile> next = <XFile>[...photos];
      for (final XFile file in picked) {
        if (next.length >= maxPhotos) break;
        next.add(file);
      }
      onChanged(next);
      if (picked.length + photos.length > maxPhotos) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo limit is $maxPhotos.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the photo picker.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _remove(int index) {
    final List<XFile> next = <XFile>[...photos]..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final bool canAdd = enabled && photos.length < maxPhotos;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Photos',
              style: text.labelLarge?.copyWith(
                color: AppColors.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${photos.length} / $maxPhotos',
              style: text.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (int i = 0; i < photos.length; i++)
              _PhotoTile(
                file: photos[i],
                onRemove: enabled ? () => _remove(i) : null,
              ),
            if (canAdd) _AddTile(onTap: () => _pick(context)),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.lightGray,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_rounded,
                  color: AppColors.mutedText),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DottedBorder(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.add_a_photo_outlined, color: AppColors.navy),
                const SizedBox(height: 4),
                Text(
                  'Add',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal dashed border container (avoids pulling in another package for a
/// single decorative tile).
class DottedBorder extends StatelessWidget {
  const DottedBorder({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: child,
    );
  }
}
