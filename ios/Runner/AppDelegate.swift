import Flutter
import UIKit
import KakaoMapsSDK // 카카오맵 SDK import 추가

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ [수정된 부분] Info.plist에서 지도 API 키를 가져와 초기화합니다.
    // 키 이름을 'KAKAO_APP_KEY'로 변경하여 지도 SDK 설정과 일치시켰습니다.
    if let appKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String {
        // Kakao Maps SDK 초기화
        SDKInitializer.InitSDK(appKey: appKey)
        print("✅ [Debug] Kakao Maps SDK가 성공적으로 초기화되었습니다. App Key: \(appKey)")
    } else {
        print("❌ [Debug] Info.plist에서 'KAKAO_APP_KEY'를 찾을 수 없습니다.")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}