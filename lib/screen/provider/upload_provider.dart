import 'dart:async';
import 'dart:io';
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
  bool _isConnected = true;
  Timer? _connectivityTimer;

  bool get isNetworkAvailable => _isNetworkAvailable;

  UploadProvider(this.flutterLocalNotificationsPlugin)
      : uploadService = UploadService(flutterLocalNotificationsPlugin) {
    _updateProgressNotification();
    _startConnectivityChecks();
  }

  File? get selectedFile => _selectedFile;
  double get uploadProgress => _uploadProgress;
  VideoPlayerController? get videoController => _videoController;
  bool get isConnected => _isConnected;

//
//this blcok shows the uploading status on the notification bar section of phone
//

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
      enableVibration: false,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      1,
      'Marinode',
      'Uploading file: ${(uploadProgress * 100).toStringAsFixed(0)}%',
      platformChannelSpecifics,
    );
  }

  Future<void> _cancelProgressNotification() async {
    await flutterLocalNotificationsPlugin.cancel(1);
  }

//
// choose file from divice, the formate of the file should be listed below, also it must be above 100 MB in size
//

  Future<void> pickFile(BuildContext context) async {
    await checkConnectivity();
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No internet connection."),
          backgroundColor: Appcolors.red.withOpacity(0.5),
        ),
      );
      return;
    }

    File? file = await uploadService.pickFile();

    if (file != null) {
      String extension = file.path.split('.').last.toLowerCase();

      List<String> allowedVideoExtensions = [
        'mp4',
        'mkv',
        'avi',
        'mov',
        'flv',
        'webm',
        'wmv',
        'mpeg',
        'mpg',
        '3gp'
      ];

      if (!allowedVideoExtensions.contains(extension) &&
          extension != 'pdf' &&
          extension != 'doc' &&
          extension != 'docx') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Only upload video or doc/pdf."),
            backgroundColor: Appcolors.red.withOpacity(0.5),
          ),
        );
        return;
      }

      if (file.lengthSync() < 100 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("File size must be at least 100MB."),
            backgroundColor: Appcolors.red.withOpacity(0.5),
          ),
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

//
//check the internet connection
//
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

//
//upload file to the firebase
//

  Future<void> _uploadFile(File file, BuildContext context) async {
    await checkConnectivity();

    final storage = FirebaseStorage.instance;

    try {
      final storageRef =
          storage.ref().child('uploads/${file.uri.pathSegments.last}');

      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
        _updateProgressNotification();
      });

      await uploadTask.whenComplete(() async {
        final downloadUrl = await storageRef.getDownloadURL();
        _uploadProgress = 1.0;
        notifyListeners();

        await _cancelProgressNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Upload Completed"),
              backgroundColor: Appcolors.green.withOpacity(0.5)),
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
    _connectivityTimer?.cancel();

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
