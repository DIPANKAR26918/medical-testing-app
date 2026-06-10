import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception wrapper for storage service failures.
class StorageServiceException implements Exception {
  final String message;
  final String? code;

  StorageServiceException(this.message, [this.code]);

  @override
  String toString() =>
      'StorageServiceException: $message${code != null ? ' ($code)' : ''}';
}

/// Service for Supabase Storage operations
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String bucketName;

  StorageService({this.bucketName = 'prescriptions'});

  /// Upload prescription image to Supabase Storage.
  Future<String> uploadPrescription(File imageFile, String userId) async {
    try {
      final extension = _getFileExtension(imageFile.path);
      final filePath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _supabase.storage
          .from(bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return filePath;
    } on StorageException catch (e) {
      throw StorageServiceException(
        'Failed to upload prescription.',
        e.message,
      );
    } catch (e) {
      throw StorageServiceException(
        'Failed to upload prescription.',
        e.toString(),
      );
    }
  }

  /// Upload file to Supabase Storage with custom path.
  Future<String> uploadFile(File file, String path) async {
    try {
      await _supabase.storage
          .from(bucketName)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return path;
    } on StorageException catch (e) {
      throw StorageServiceException('Failed to upload file.', e.message);
    } catch (e) {
      throw StorageServiceException('Failed to upload file.', e.toString());
    }
  }

  /// Download file as bytes.
  Future<Uint8List> downloadFile(String filePath) async {
    try {
      final data = await _supabase.storage.from(bucketName).download(filePath);
      return data;
    } on StorageException catch (e) {
      throw StorageServiceException('Failed to download file.', e.message);
    } catch (e) {
      throw StorageServiceException('Failed to download file.', e.toString());
    }
  }

  /// Get a signed URL for a file path.
  Future<String> createSignedUrl(
    String filePath, {
    int expiresInSeconds = 3600,
  }) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucketName)
          .createSignedUrl(filePath, expiresInSeconds);

      return signedUrl;
    } on StorageException catch (e) {
      throw StorageServiceException('Failed to create signed URL.', e.message);
    } catch (e) {
      throw StorageServiceException(
        'Failed to create signed URL.',
        e.toString(),
      );
    }
  }

  /// Get public URL.
  String getPublicUrl(String filePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }

  /// Delete file from storage (accepts URL or path).
  Future<void> deleteImage(String fileUrlOrPath) async {
    try {
      final filePath = fileUrlOrPath.startsWith('http')
          ? _extractFilePath(fileUrlOrPath)
          : fileUrlOrPath;

      if (filePath == null || filePath.isEmpty) {
        throw StorageServiceException(
          'Invalid storage path for delete operation.',
        );
      }

      await _supabase.storage.from(bucketName).remove([filePath]);
    } on StorageException catch (e) {
      throw StorageServiceException('Failed to delete image.', e.message);
    } catch (e) {
      if (e is StorageServiceException) rethrow;

      throw StorageServiceException('Failed to delete image.', e.toString());
    }
  }

  /// Get file extension safely.
  String _getFileExtension(String filePath) {
    final extension = p.extension(filePath).replaceFirst('.', '').toLowerCase();
    return extension.isEmpty ? 'jpg' : extension;
  }

  /// Extract storage path from Supabase URL.
  String? _extractFilePath(String fileUrl) {
    final uri = Uri.tryParse(fileUrl);
    if (uri == null) return null;

    const publicSegment = '/storage/v1/object/public/';
    const objectSegment = '/storage/v1/object/';

    if (uri.path.contains(publicSegment)) {
      return uri.path.split(publicSegment).last;
    }

    if (uri.path.contains(objectSegment)) {
      return uri.path.split(objectSegment).last;
    }

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf(bucketName);

    if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
      return segments.sublist(bucketIndex + 1).join('/');
    }

    return null;
  }
}
