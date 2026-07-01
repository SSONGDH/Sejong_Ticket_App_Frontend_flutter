import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'package:logger/logger.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:passtime/services/mobile_ads_service.dart';
import 'package:passtime/services/donate_purchase_service.dart';

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
  // notification 페이로드가 있으면 Android가 FCM 알림을 자동 표시하므로
  // 로컬 알림을 추가로 띄우면 동일 알림이 2개 보입니다.
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

  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  if (kakaoKey != null && kakaoKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoKey);
  }

  runApp(const MyApp());

  unawaited(_bootstrapServices());
}

Future<void> _bootstrapServices() async {
  await _initLocalNotifications();

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  final kakaoJsKey = dotenv.env['KAKAO_MAP_JS_KEY'] ??
      dotenv.env['KAKAO_JAVASCRIPT_KEY'] ??
      dotenv.env['KAKAO_NATIVE_APP_KEY'];

  if (kakaoKey != null && kakaoKey.isNotEmpty) {
    logger.i("[KakaoSDK] 🔑 KAKAO_NATIVE_APP_KEY: $kakaoKey");
    try {
      await KakaoMapsFlutter.init(kakaoKey);
      logger.i("[KakaoMap] ✅ 초기화 완료");
    } catch (e) {
      logger.e("[KakaoMap] ❌ 초기화 실패: $e");
    }
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

  try {
    await MobileAdsService.ensureInitialized();
    await DonatePurchaseService.instance.initialize();
  } catch (e) {
    logger.e("[Monetization] ❌ 초기화 실패: $e");
  }

  final NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  logger.i("🔐 알림 권한 상태: ${settings.authorizationStatus}");

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

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

  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null && message.notification != null) {
      logger.i("📩 앱 종료 상태에서 알림 클릭됨");
      logger.i("Title: ${message.notification!.title}");
      logger.i("Body: ${message.notification!.body}");
      logger.i("click_action: ${message.data["click_action"]}");
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
    if (message != null && message.notification != null) {
      logger.i("📩 백그라운드 상태에서 알림 클릭됨");
      logger.i("Title: ${message.notification!.title}");
      logger.i("Body: ${message.notification!.body}");
      logger.i("click_action: ${message.data["click_action"]}");
    }
  });
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
