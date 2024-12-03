// upload_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:marinode/screen/provider/upload_provider.dart';
import 'package:marinode/screen/utilities/color.dart';
import 'package:marinode/screen/utilities/string.dart';
import 'package:marinode/screen/utilities/text_style.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class UploadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UploadProvider(FlutterLocalNotificationsPlugin()),
      child: Scaffold(
        backgroundColor: Appcolors.bgColor,
        appBar: AppBar(
          title: Center(
            child: Text(
              title,
              style: AppTextStyle.boldText(size: 26, color: Appcolors.white),
            ),
          ),
          backgroundColor: Appcolors.blue,
        ),
        body: Consumer<UploadProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //select files button will view only when no file is selcted , after completion of upload button will disply again
                    if (provider.selectedFile == null ||
                        provider.uploadProgress >= 1.0) 
                      _selectionButton(provider, context),  
                   //files name will view only when  file is selcted , 
                
                    if (provider.selectedFile != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        "File: ${provider.selectedFile!.uri.pathSegments.last}",
                        style: AppTextStyle.semiboldText(
                            size: 20, color: Appcolors.black),
                      ),
                      const SizedBox(height: 20),
                
                      // Display selected file initialy disply a thumbainl
                      if (provider.uploadService
                          .isVideo(provider.selectedFile!.path)) ...[
                        _thumbnailAndVideoSection(provider),
                        const SizedBox(height: 8),
                        //paly button
                        _playPauseButton(provider),
                      ],
                      const SizedBox(height: 20),
                      if (provider.uploadProgress != 1)
                        LinearProgressIndicator(
                          value: provider.uploadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.blueAccent),
                        ),
                      const SizedBox(height: 10),
                      if (provider.uploadProgress != 1)
                        Text(textAlign: TextAlign.center,
                          "Uploading: ${(provider.uploadProgress * 100).toStringAsFixed(0)}%",
                          style: AppTextStyle.regularText(
                              size: 20, color: Appcolors.black),
                        ),
                    
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //play pause button

 Widget _playPauseButton(UploadProvider provider) {
  return ElevatedButton(
    onPressed: provider.toggleVideoPlayback,
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.all(8),
      minimumSize: Size(50, 50), // Sets a small size for the button
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      backgroundColor: Appcolors.blue
      ,
    ),
    child: Icon(
      provider.videoController?.value.isPlaying == true
          ? Icons.pause
          : Icons.play_arrow,
      size: 24,
      color: Appcolors.white,
    ),
  );
}


  //show thubnail and play video 

  Widget _thumbnailAndVideoSection(UploadProvider provider) {
    return SizedBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: provider.videoController!.value.aspectRatio,
          child: VideoPlayer(provider.videoController!),
        ),
      ),
    );
  }

  ElevatedButton _selectionButton(
      UploadProvider provider, BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTextStyle.semiboldText(size: 20, color: Appcolors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Appcolors.blue,
      ),
      onPressed: () => provider.pickFile(context),
      child: Text(
        addfile,
        style: AppTextStyle.mediumText(size: 18, color: Appcolors.white),
      ),
    );
  }
}
