import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 本地 HTTP 服务器，用于接收 passport OIDC 回调 (Authorization Code 回跳)
///
/// 标准桌面 OIDC 客户端的 Local Redirect URI 模式 (RFC 8252)：
/// 在 127.0.0.1 上监听固定端口，passport 授权完成后浏览器重定向到
/// http://127.0.0.1:<port>/callback?code=...&state=...，本地服务器捕获 code。
class LocalSsoCallbackServer {
  HttpServer? _server;
  Completer<Map<String, String>>? _resultCompleter;
  final int port;

  LocalSsoCallbackServer(this.port);

  String get callbackUrl => 'http://127.0.0.1:$port/callback';

  bool get _isRunning => _server != null;

  /// 启动本地回调服务器
  Future<void> start() async {
    if (_isRunning) return;
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
    _server!.listen(_onRequest);
  }

  /// 等待浏览器回跳并解析 code + state (超时后关闭)
  Future<Map<String, String>> waitForCallback({
    Duration timeout = const Duration(seconds: 120),
  }) async {
    if (!_isRunning) {
      throw StateError('Callback server not started');
    }

    _resultCompleter = Completer<Map<String, String>>();

    try {
      await _resultCompleter!.future.timeout(timeout);
    } on TimeoutException {
      if (!_resultCompleter!.isCompleted) {
        _resultCompleter!.complete({'error': 'timeout'});
      }
    }

    final result = await _resultCompleter!.future;
    await _server?.close(force: true);
    _server = null;
    return result;
  }

  void _onRequest(HttpRequest request) {
    final uri = request.uri;
    if (uri.path != '/callback') {
      request.response
        ..statusCode = 404
        ..write('Not Found');
      request.response.close();
      return;
    }

    final query = uri.queryParameters;
    final code = query['code'];
    final state = query['state'];
    final error = query['error'];

    Map<String, String> result;
    if (error != null) {
      result = {'error': error};
    } else if (code != null) {
      result = {'code': code, 'state': state ?? ''};
    } else {
      result = {'error': 'missing_code'};
    }

    if (!_resultCompleter!.isCompleted) {
      _resultCompleter!.complete(result);
    }

    final body = error != null
        ? '''<!DOCTYPE html><html><body style="font-family:sans-serif;text-align:center;padding:40px;background:#F2F2F7;">
<h2 style="color:#FF3B30">Login Failed</h2>
<p style="color:#6E6E73">$error - you can close this window</p>
</body></html>'''
        : '''<!DOCTYPE html><html><body style="font-family:sans-serif;text-align:center;padding:60px;background:#F2F2F7;">
<div style="width:64px;height:64px;background:#007AFF;border-radius:16px;margin:0 auto 20px;display:flex;align-items:center;justify-content:center;">
<svg width="32" height="32" fill="none" stroke="white" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
</div>
<h2 style="color:#1D1D1F">Login Successful</h2>
<p style="color:#6E6E73">You can close this window and return to LitchiViewer.</p>
<script>window.close()</script>
</body></html>''';

    request.response
      ..headers.contentType = ContentType.html
      ..write(body);
    request.response.close();
  }
}