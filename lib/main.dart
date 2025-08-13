import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:logger/logger.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

final logger = Logger();

// ✅ 백그라운드 메시지 핸들러: 앱이 종료 상태일 때 호출됨
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  logger.i("📩 [Background] 메시지 수신:");
  logger.i("Title: ${message.notification?.title}");
  logger.i("Body: ${message.notification?.body}");
  logger.i("Data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ .env 로드
  await dotenv.load(fileName: ".env");

  // ✅ 카카오맵 JavaScript 키 초기화
  AuthRepository.initialize(appKey: dotenv.env['KAKAO_MAP_JS_KEY']!);

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

  // 🔔 [Foreground] 포그라운드 메시지 핸들러: 앱이 실행 중일 때 호출됨
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.i("🔔 [Foreground] 메시지 수신");
    logger.i("Title: ${message.notification?.title}");
    logger.i("Body: ${message.notification?.body}");
    logger.i("Data: ${message.data}");

    // 포그라운드에서는 기본적으로 알림이 표시되지 않습니다.
    // 만약 표시하려면, flutter_local_notifications 패키지를 사용해
    // 직접 알림을 띄우는 로직을 여기에 추가해야 합니다.
  });

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
    final Color lightBlackColor = Colors.black.withOpacity(0.6);
    final Color veryLightBlackColor = Colors.black.withOpacity(0.2);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          secondary: Colors.grey[800],
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: lightBlackColor,
          selectionColor: veryLightBlackColor,
          selectionHandleColor: lightBlackColor,
        ),
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryColor: lightBlackColor,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
