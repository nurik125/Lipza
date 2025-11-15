import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  late WebSocketChannel _channel;
  late StreamController<String> _predictionController;
  late StreamController<bool> _connectionController;
  late Timer _pingTimer;
  
  bool _isConnected = false;
  final String _serverUrl;

  WebSocketService({String serverUrl = 'ws://localhost:8000/ws'})
      : _serverUrl = serverUrl {
    _predictionController = StreamController<String>.broadcast();
    _connectionController = StreamController<bool>.broadcast();
  }

  /// Get stream of predictions
  Stream<String> get predictionStream => _predictionController.stream;

  /// Get stream of connection status
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));

      await _channel.ready;
      _isConnected = true;
      _connectionController.add(true);

      print('Connected to WebSocket server');

      // Start ping timer for keep-alive
      _startPingTimer();

      // Listen to incoming messages
      _channel.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _connectionController.add(false);
          _isConnected = false;
          _reconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _connectionController.add(false);
          _isConnected = false;
          _stopPingTimer();
          _reconnect();
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      _connectionController.add(false);
      _reconnect();
    }
  }

  /// Send camera frame to server
  void sendFrame(Uint8List frameBytes) {
    if (!_isConnected) {
      print('WebSocket not connected');
      return;
    }

    try {
      // Encode frame to base64
      final base64Frame = base64Encode(frameBytes);

      // Create message
      final message = jsonEncode({
        'type': 'frame',
        'data': base64Frame,
      });

      // Send message
      _channel.sink.add(message);
    } catch (e) {
      print('Error sending frame: $e');
    }
  }

  /// Handle incoming messages from server
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);
        final type = data['type'];

        if (type == 'prediction') {
          final text = data['text'] ?? '';
          final confidence = data['confidence'] ?? 0.0;
          final processingTime = data['processing_time'] ?? 0.0;

          print(
            'Prediction: $text (confidence: $confidence, time: ${processingTime.toStringAsFixed(2)}s)',
          );

          // Add to prediction stream
          _predictionController.add(text);
        } else if (type == 'error') {
          final errorMessage = data['message'] ?? 'Unknown error';
          print('Server error: $errorMessage');
        } else if (type == 'pong') {
          print('Pong received');
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  /// Start keep-alive ping timer
  void _startPingTimer() {
    _pingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_isConnected) {
        try {
          final message = jsonEncode({'type': 'ping'});
          _channel.sink.add(message);
        } catch (e) {
          print('Error sending ping: $e');
        }
      }
    });
  }

  /// Stop ping timer
  void _stopPingTimer() {
    _pingTimer.cancel();
  }

  /// Reconnect to server
  void _reconnect() {
    Future.delayed(Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect...');
        connect();
      }
    });
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    _stopPingTimer();
    if (_isConnected) {
      await _channel.sink.close(status.goingAway);
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// Close all resources
  void dispose() {
    _stopPingTimer();
    _predictionController.close();
    _connectionController.close();
    if (_isConnected) {
      _channel.sink.close(status.goingAway);
    }
  }
}
