import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Contract for media and image picking service.
abstract class IImagePickerService {
  /// Picks a single image from device gallery with optional quality compression.
  Future<XFile?> pickImageFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  });

  /// Captures a single image from device camera.
  Future<XFile?> pickImageFromCamera({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  });

  /// Picks multiple images from device gallery.
  Future<List<XFile>> pickMultiImage({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  });

  /// Picks a single video from device gallery.
  Future<XFile?> pickVideoFromGallery({
    Duration? maxDuration,
  });
}

/// Implementation using official image_picker plugin.
class ImagePickerServiceImpl implements IImagePickerService {
  final ImagePicker _picker;

  ImagePickerServiceImpl([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  @override
  Future<XFile?> pickImageFromGallery({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return image;
    } catch (e, st) {
      debugPrint('[ImagePickerService] Error picking image from gallery: $e\n$st');
      return null;
    }
  }

  @override
  Future<XFile?> pickImageFromCamera({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return image;
    } catch (e, st) {
      debugPrint('[ImagePickerService] Error capturing image from camera: $e\n$st');
      return null;
    }
  }

  @override
  Future<List<XFile>> pickMultiImage({
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return images;
    } catch (e, st) {
      debugPrint('[ImagePickerService] Error picking multiple images: $e\n$st');
      return const [];
    }
  }

  @override
  Future<XFile?> pickVideoFromGallery({
    Duration? maxDuration,
  }) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration,
      );
      return video;
    } catch (e, st) {
      debugPrint('[ImagePickerService] Error picking video from gallery: $e\n$st');
      return null;
    }
  }
}

/// Riverpod provider for [IImagePickerService]
final imagePickerServiceProvider = Provider<IImagePickerService>((ref) {
  return ImagePickerServiceImpl();
});
