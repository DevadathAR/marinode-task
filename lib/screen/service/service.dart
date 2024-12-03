// service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:video_player/video_player.dart';

class UploadService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  UploadService(this.flutterLocalNotificationsPlugin);

  Future<File?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  bool isVideo(String filePath) {
    final videoExtensions = ['mp4', 'avi', 'mov', 'mkv'];
    final extension = filePath.split('.').last.toLowerCase();
    return videoExtensions.contains(extension);
  }

  Future<void> uploadFile(File file, Function(double) onProgress) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;

      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      Reference storageRef = storage.ref().child('uploads/$fileName');

      UploadTask uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred / snapshot.totalBytes);
        onProgress(progress);
      });

      await uploadTask.whenComplete(() async {
        String downloadUrl = await storageRef.getDownloadURL();
        // You can return the download URL if needed
      });
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

}
