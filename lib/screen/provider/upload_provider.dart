import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:marinode/screen/service/service.dart';
import 'package:marinode/screen/utilities/color.dart';
import 'package:video_player/video_player.dart';

class UploadProvider extends ChangeNotifier {
  File? _selectedFile;
  double _uploadProgress = 0.0;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final UploadService uploadService;
  VideoPlayerController? _videoController;
  bool _isNetworkAvailable = true;
  bool _isConnected = true; // Track connectivity status
  Timer? _connectivityTimer; // Timer for periodic connectivity checks

  bool get isNetworkAvailable => _isNetworkAvailable;

  UploadProvider(this.flutterLocalNotificationsPlugin)
      : uploadService = UploadService(flutterLocalNotificationsPlugin) {
    _initializeNotifications();
    _startConnectivityChecks();
  }

  File? get selectedFile => _selectedFile;
  double get uploadProgress => _uploadProgress;
  VideoPlayerController? get videoController => _videoController;
  bool get isConnected => _isConnected; // Expose connectivity status

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
  // Check connectivity status
  await checkConnectivity();
  if (!_isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text("No internet connection."),backgroundColor: Appcolors.red.withOpacity(0.5)),
    );
    return;
  }

  // Proceed with file selection
  File? file = await uploadService.pickFile();

  if (file != null) {
    // Validate file size
    if (file.lengthSync() < 100 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("File size must be at least 100MB."),backgroundColor: Appcolors.red.withOpacity(0.5)),
      );
      return;
    }

    _selectedFile = file;
    notifyListeners();

    // Check if the file is a video and initialize preview
    if (uploadService.isVideo(file.path)) {
      _initializeVideoPreview(file);
    }

    // Attempt to upload the file
    await _uploadFile(file, context);
  }
}


  void _initializeVideoPreview(File file) {
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        notifyListeners();
      });
  }

  Future<void> checkConnectivity() async {
    
    try {
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _isConnected = false;
    }
    notifyListeners();
  }

  void _startConnectivityChecks() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        await checkConnectivity();
      },
    );
  }

  Future<void> _uploadFile(File file, BuildContext context) async {
    await checkConnectivity();

    final storage = FirebaseStorage.instance;

    try {
      // Reference to the file on Firebase
      final storageRef =
          storage.ref().child('uploads/${file.uri.pathSegments.last}');

      // Start the upload task
      final uploadTask = storageRef.putFile(file);

      // Listen for progress updates
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
        _updateProgressNotification();
      });

      // Wait for the upload to complete
      await uploadTask.whenComplete(() async {
        final downloadUrl = await storageRef.getDownloadURL();
        _uploadProgress = 1.0;
        notifyListeners();

        await _cancelProgressNotification();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Upload Completed"),backgroundColor: Appcolors.green.withOpacity(0.5)),
        );

      });
    } catch (e) {
      await _cancelProgressNotification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  void dispose() {
    _connectivityTimer
        ?.cancel(); // Stop the timer when the provider is disposed

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
