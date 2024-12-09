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
      : uploadService = UploadService(flutterLocalNotificationsPlugin) {
    _initializeNotifications();
  }

  File? get selectedFile => _selectedFile;
  double get uploadProgress => _uploadProgress;
  VideoPlayerController? get videoController => _videoController;

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification taps if needed
      },
    );

    // Create the notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'upload_channel_id', // Unique ID for this channel
      'File Upload', // Channel name
      description: 'Shows progress of file uploads', // Channel description
      importance: Importance.low,
    );

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<void> _showProgressNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'upload_channel_id',
      'File Upload',
      channelDescription: 'Shows progress of file uploads',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      ongoing: true,
      enableVibration:
          false, // Optional: Disable vibration for ongoing notifications
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      1, // Notification ID
      'Uploading File',
      'Progress: ${(uploadProgress * 100).toStringAsFixed(0)}%',
      platformChannelSpecifics,
      payload: 'upload', // Optional: Add custom payload
    );
  }

  Future<void> _updateProgressNotification() async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'upload_channel_id',
      'File Upload',
      channelDescription: 'Shows progress of file uploads',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: (uploadProgress * 100).toInt(),
      ongoing: true,
      enableVibration:
          false, // Optional: Disable vibration for ongoing notifications
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      1, // Notification ID
      'Uploading File',
      'Progress: ${(uploadProgress * 100).toStringAsFixed(0)}%',
      platformChannelSpecifics,
    );
  }

  Future<void> _cancelProgressNotification() async {
    await flutterLocalNotificationsPlugin.cancel(1);
  }

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
      for (int progress = 0; progress <= 100; progress++) {
        _uploadProgress = progress / 100;
        notifyListeners();
        await _updateProgressNotification();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _cancelProgressNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload Completed")),
      );
    } catch (e) {
      await _cancelProgressNotification();
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
