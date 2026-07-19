import 'package:logger/logger.dart';

class _BufferOutput extends LogOutput {
  final List<String> buffer;
  _BufferOutput(this.buffer);

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      buffer.add(line);
      if (buffer.length > 200) {
        buffer.removeRange(0, buffer.length - 200);
      }
    }
  }
}

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<String> _buffer = [];
  late final Logger _logger = Logger(
    filter: _ProductionFilter(),
    output: _BufferOutput(_buffer),
    printer: SimplePrinter(printTime: true),
  );

  void debug(String message) => _logger.d(message);
  void info(String message) => _logger.i(message);
  void warning(String message) => _logger.w(message);
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
    _logger.e(message, error: error, stackTrace: stackTrace);

  List<String> get buffer => List.unmodifiable(_buffer);

  String evict() => _buffer.join('\n');
}

class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (event.level.index >= Level.warning.index) return true;
    return false;
  }
}
