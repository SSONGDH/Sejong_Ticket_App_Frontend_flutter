import 'package:cookie_jar/cookie_jar.dart';

class CookieJarSingleton {
  // 싱글톤 인스턴스를 생성
  static final CookieJarSingleton _instance = CookieJarSingleton._internal();

  // 내부에 CookieJar 인스턴스를 보유
  final CookieJar _cookieJar = CookieJar();

  // SSO 토큰을 저장할 변수
  String? _ssoToken;

  // factory constructor로 싱글톤 인스턴스 반환
  factory CookieJarSingleton() {
    return _instance;
  }

  // 내부 생성자
  CookieJarSingleton._internal();

  // CookieJar 객체 반환
  CookieJar get cookieJar => _cookieJar;

  // SSO 토큰 저장
  Future<void> saveSsoToken(String ssoToken) async {
    _ssoToken = ssoToken;
  }

  // SSO 토큰 가져오기
  String? get ssoToken => _ssoToken;
}
