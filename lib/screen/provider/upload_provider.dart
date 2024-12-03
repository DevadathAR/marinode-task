// upload_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:marinode/screen/service/service.dart';
import 'package:video_player/video_player.dart';

class UploadProvider extends ChangeNotifier {
  File? _selectedFile;
  double _uploadProgress = 0.0;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final UploadService uploadService;
  VideoPlayerController? _videoController;

  UploadProvider(this.flutterLocalNotificationsPlugin)
      : uploadService = UploadService(flutterLocalNotificationsPlugin);

  File? get selectedFile => _selectedFile;
  double get uploadProgress => _uploadProgress;
  VideoPlayerController? get videoController => _videoController;

  Future<void> pickFile(BuildContext context) async {
    File? file = await uploadService.pickFile();

    if (file != null) {
      if (file.lengthSync() < 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File size must be at least 100MB.")),
        );
        return;
      }

      _selectedFile = file;
      notifyListeners();

      if (uploadService.isVideo(file.path)) {
        _initializeVideoPreview(file);
      }

      await _uploadFile(file, context);
    }
  }

  void _initializeVideoPreview(File file) {
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        notifyListeners();
      });
  }

  Future<void> _uploadFile(File file, BuildContext context) async {
    try {
      await uploadService.uploadFile(file, (progress) {
        _uploadProgress = progress;
        uploadService.showUploadNotification(progress);
        notifyListeners();
      });

      uploadService.cancelUploadNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload Completed")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void toggleVideoPlayback() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController?.pause();
    } else {
      _videoController?.play();
    }
    notifyListeners();
  }
}
