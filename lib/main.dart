import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:logger/logger.dart';

final logger = Logger();

Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  logger.i("📩 백그라운드 메시지 수신:");
  logger.i("Title: ${message.notification?.title}");
  logger.i("Body: ${message.notification?.body}");
  logger.i("Data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");

  // ✅ iOS: 알림 권한 요청
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  logger.i("🔐 알림 권한 상태: ${settings.authorizationStatus}");

  // ✅ iOS: 포그라운드 알림 표시 옵션 설정
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  // ✅ 알림 클릭 시 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
    if (message != null && message.notification != null) {
      logger.e("🔔 알림 클릭됨");
      logger.e("Title: ${message.notification!.title}");
      logger.e("Body: ${message.notification!.body}");
      logger.e("click_action: ${message.data["click_action"]}");
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}



// 지정된 학번이 아니면 관리자가 아닙니다 라는 문구가 뜰 수 있도록 O

// 행사 수정하고나서 화면이동 O

// 입장권 상세화면에서 취소/환불 요청하면 페이지 이동 OX

// 모든 화면 이동시 새로고침 해야함

// 시계 ui 바꿔야함 씨발임

// 납부내역 상세화면 사진 크기 조정

// 행사 제작 후 디버깅 중지
