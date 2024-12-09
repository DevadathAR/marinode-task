import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:marinode/screen/provider/upload_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // Import the provider package
import 'package:marinode/screen/view/presenting/upload_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UploadProvider(FlutterLocalNotificationsPlugin()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Media Upload App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: UploadPage(),
      ),
    );
  }
}