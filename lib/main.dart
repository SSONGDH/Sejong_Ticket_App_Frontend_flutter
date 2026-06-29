import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:logger/logger.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final logger = Logger();

// FlutterLocalNotificationsPlugin 초기화
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  logger.i("📩 [Background] 메시지 수신:");
  logger.i("Title: ${message.notification?.title}");
  logger.i("Body: ${message.notification?.body}");
  logger.i("Data: ${message.data}");

  // Android 알림 표시 (백그라운드/종료 시 시스템 알림)
  if (message.notification != null && message.notification!.android != null) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      platformDetails,
    );
  }
}

// FlutterLocalNotifications 초기화
Future<void> _initLocalNotifications() async {
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _initLocalNotifications();

  // Kakao SDK & Kakao Maps 초기화
  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  final kakaoJsKey = dotenv.env['KAKAO_MAP_JS_KEY'] ??
      dotenv.env['KAKAO_JAVASCRIPT_KEY'] ??
      dotenv.env['KAKAO_NATIVE_APP_KEY'];
  if (kakaoKey != null && kakaoKey.isNotEmpty) {
    logger.i("[KakaoSDK] 🔑 KAKAO_NATIVE_APP_KEY: $kakaoKey");
    KakaoSdk.init(nativeAppKey: kakaoKey);
    await KakaoMapsFlutter.init(kakaoKey);
    logger.i("[KakaoMap] ✅ 초기화 완료");
  } else {
    logger.e("[KakaoSDK] ❌ KAKAO_NATIVE_APP_KEY가 비어있습니다!");
  }

  if (kakaoJsKey != null && kakaoJsKey.isNotEmpty) {
    AuthRepository.initialize(
      appKey: kakaoJsKey,
      baseUrl: 'https://dapi.kakao.com',
    );
    logger.i("[KakaoMapPlugin] ✅ JavaScript 키 초기화 완료");
  }

  // iOS: 알림 권한 요청
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  logger.i("🔐 알림 권한 상태: ${settings.authorizationStatus}");

  // 포그라운드 알림 표시 옵션
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Foreground 메시지 핸들러
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    logger.i("🔔 [Foreground] 메시지 수신");
    logger.i("Title: ${message.notification?.title}");
    logger.i("Body: ${message.notification?.body}");
    logger.i("Data: ${message.data}");

    if (message.notification != null && message.notification!.android != null) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        platformDetails,
      );
    }
  });

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  // 앱 종료 상태에서 알림 클릭 처리
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null && message.notification != null) {
      logger.i("📩 앱 종료 상태에서 알림 클릭됨");
      logger.i("Title: ${message.notification!.title}");
      logger.i("Body: ${message.notification!.body}");
      logger.i("click_action: ${message.data["click_action"]}");
    }
  });

  // 백그라운드 상태에서 알림 클릭 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
    if (message != null && message.notification != null) {
      logger.i("📩 백그라운드 상태에서 알림 클릭됨");
      logger.i("Title: ${message.notification!.title}");
      logger.i("Body: ${message.notification!.body}");
      logger.i("click_action: ${message.data["click_action"]}");
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
