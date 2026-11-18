import 'package:flutter_test/flutter_test.dart';
import 'package:nex/core/api_client.dart';
import 'package:nex/features/auth/auth_provider.dart';

/// 可控的 ApiClient 替身：按"授权窗口"脚本依次返回 init / poll 结果。
///
/// 每调用一次 [ssoDesktopInit] 视为开启一个新的授权窗口；该窗口内
/// [ssoDesktopPoll] 按顺序消费 [pollScript] 中对应窗口的响应，用尽后重复最后一条。
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super.test(null);

  int initCalls = 0;
  int pollCalls = 0;

  /// init 返回的 auth_url 序列，用尽后复用最后一个。
  final List<String> authUrls = [];

  /// 每个授权窗口的 poll 响应脚本。
  final List<List<Map<String, dynamic>>> pollScript = [];

  /// 指定窗口首次 poll 时抛出的异常（用于模拟 404 session 过期）。
  final Map<int, ApiException> throwOnceByWindow = {};

  final List<int> _cursor = [];

  @override
  Future<Map<String, dynamic>> ssoDesktopInit() async {
    final index = initCalls < authUrls.length ? initCalls : authUrls.length - 1;
    _cursor.add(0);
    initCalls++;
    return {
      'auth_url': authUrls[index],
      'session_id': 'session-$initCalls',
    };
  }

  @override
  Future<Map<String, dynamic>> ssoDesktopPoll(String sessionId) async {
    pollCalls++;
    final window = _cursor.isEmpty ? 0 : _cursor.length - 1;

    final thrown = throwOnceByWindow[window];
    if (thrown != null && _cursor[window] == 0) {
      _cursor[window] = 1;
      throw thrown;
    }

    final script = pollScript[window.clamp(0, pollScript.length - 1)];
    var index = _cursor[window];
    if (index >= script.length) index = script.length - 1;
    _cursor[window] = index + 1;
    return script[index];
  }

  @override
  Future<void> saveSsoToken(String token, String? refresh) async {}

  @override
  Future<Map<String, dynamic>> get(String path) async => {
        'id': 1,
        'email': 'u@example.com',
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthProvider.startSSOLogin', () {
    test('超时后重新获取 auth_url 并重开浏览器', () async {
      final api = _FakeApiClient()
        ..authUrls.addAll([
          'https://passport.example/oidc/authorize?state=first',
          'https://passport.example/oidc/authorize?state=second',
        ])
        ..pollScript.addAll([
          // 窗口 1：一直 pending → 超时
          [
            {'status': 'pending'},
          ],
          // 窗口 2：登录完成
          [
            {'status': 'complete', 'access_token': 'token', 'refresh_token': 'r'},
          ],
        ]);

      final opened = <String>[];
      final provider = AuthProvider(
        api: api,
        launchBrowser: (uri) async {
          opened.add(uri.toString());
          return true;
        },
        pollInterval: Duration.zero,
        pollAttemptsPerWindow: 1,
        maxRefresh: 2,
      );

      final ok = await provider.startSSOLogin();

      expect(ok, isTrue);
      expect(api.initCalls, 2, reason: '超时应重新调用 init 获取新授权地址');
      expect(opened.length, 2, reason: '超时应重新打开浏览器');
      expect(opened.first, contains('state=first'));
      expect(opened.last, contains('state=second'));
      expect(provider.ssoHint, isNull, reason: '登录成功后应清除刷新提示');
      expect(provider.isLoggedIn, isTrue);
    });

    test('窗口全部超时后返回失败并保留错误信息', () async {
      final api = _FakeApiClient()
        ..authUrls.add('https://passport.example/oidc/authorize?state=x')
        ..pollScript.add([
          {'status': 'pending'},
        ]);

      final provider = AuthProvider(
        api: api,
        launchBrowser: (_) async => true,
        pollInterval: Duration.zero,
        pollAttemptsPerWindow: 1,
        maxRefresh: 1,
      );

      final ok = await provider.startSSOLogin();

      expect(ok, isFalse);
      expect(api.initCalls, 2, reason: '1 次初始 + 1 次刷新');
      expect(provider.ssoInProgress, isFalse);
      expect(provider.lastError, isNotNull);
      expect(provider.ssoHint, isNull);
    });

    test('服务端 404 视为过期并刷新授权地址', () async {
      final api = _FakeApiClient()
        ..authUrls.addAll([
          'https://passport.example/oidc/authorize?state=a',
          'https://passport.example/oidc/authorize?state=b',
        ])
        ..throwOnceByWindow[0] = ApiException(404, 'session not found')
        ..pollScript.add([
          {'status': 'complete', 'access_token': 'token'},
        ]);

      final provider = AuthProvider(
        api: api,
        launchBrowser: (_) async => true,
        pollInterval: Duration.zero,
        pollAttemptsPerWindow: 1,
        maxRefresh: 1,
      );

      final ok = await provider.startSSOLogin();

      expect(ok, isTrue);
      expect(api.initCalls, 2);
    });

    test('服务端 error 不重试', () async {
      final api = _FakeApiClient()
        ..authUrls.add('https://passport.example/oidc/authorize?state=a')
        ..pollScript.add([
          {'status': 'error', 'error': 'invalid_grant'},
        ]);

      final provider = AuthProvider(
        api: api,
        launchBrowser: (_) async => true,
        pollInterval: Duration.zero,
        pollAttemptsPerWindow: 1,
        maxRefresh: 3,
      );

      final ok = await provider.startSSOLogin();

      expect(ok, isFalse);
      expect(api.initCalls, 1, reason: '明确错误不应触发刷新');
      expect(provider.lastError, 'invalid_grant');
    });

    test('maxRefresh 为 0 时保持原有单次行为', () async {
      final api = _FakeApiClient()
        ..authUrls.add('https://passport.example/oidc/authorize?state=a')
        ..pollScript.add([
          {'status': 'pending'},
        ]);

      final provider = AuthProvider(
        api: api,
        launchBrowser: (_) async => true,
        pollInterval: Duration.zero,
        pollAttemptsPerWindow: 1,
        maxRefresh: 0,
      );

      final ok = await provider.startSSOLogin();

      expect(ok, isFalse);
      expect(api.initCalls, 1, reason: '不刷新时只调用一次 init');
      expect(provider.lastError, isNotNull);
    });
  });
}