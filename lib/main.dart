import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:logger/logger.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

final logger = Logger();

// ✅ 백그라운드 메시지 핸들러: 앱이 종료 상태일 때 호출됨
@pragma('vm:entry-point') // 개선 제안: 어노테이션 추가
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

  // ✅ .env 로드 (Firebase보다 먼저 로드해서 키를 사용할 수 있도록 함)
  await dotenv.load(fileName: ".env");

  // ✅ Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ (가장 중요) 카카오 SDK 네이티브 앱 키 초기화 (수정됨)
  // AuthRepository.initialize() 대신 KakaoSdk.init()을 사용해야 합니다.
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'],
  );

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

  // 🔔 [Foreground] 포그라운드 메시지 핸들러
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.i("🔔 [Foreground] 메시지 수신");
    logger.i("Title: ${message.notification?.title}");
    logger.i("Body: ${message.notification?.body}");
    logger.i("Data: ${message.data}");
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
  // ... (이하 동일)
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
