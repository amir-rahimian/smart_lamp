import 'dart:async';
import 'dart:convert';
import 'dart:io';

class UdpManager {
  static const String _targetIp = '192.168.4.1';
  static const int _port = 8888;

  static final UdpManager _instance = UdpManager._internal();

  factory UdpManager() => _instance;

  RawDatagramSocket? _socket;
  late StreamSubscription<RawSocketEvent> _subscription;

  final _messageController = StreamController<String>.broadcast();

  Stream<String> get onMessage => _messageController.stream;

  UdpManager._internal();

  Future<void> initializeSocket() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
      print('Socket initialized for listening on port ${_socket?.port}}');

      _subscription = _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data).trim();
            print('Received ${datagram.address.address} : [${message.length}] $message ');
            _messageController.add(message);
          }
        } else if (event == RawSocketEvent.closed) {
          print('Socket closed');
          _messageController.add('SOCKET_CLOSED');
        } else if (event == RawSocketEvent.write) {
          print('Socket ready to write');
          _messageController.add('*');
        } else if (event == RawSocketEvent.readClosed) {
          print('Socket read closed');
        }
      });
    } on SocketException catch (e) {
      print('Failed to initialize socket: $e');
      _messageController.addError('Socket initialization failed');
    } on Exception catch (e) {
      print('Unexpected error: $e');
      _messageController.addError('Unexpected error');
    }
  }

  Future<void> sendMessage(String message) async {
    if (_socket == null) {
      await initializeSocket();
    }
    try {
      final bytes = utf8.encode(message);
      final ip = InternetAddress(_targetIp);
      print('Sending: $message to ${ip.address.toString()}');
      _socket!.send(bytes, ip, _port);
    } on SocketException catch (e) {
      print('Failed to send message: $e');
      _messageController.addError('Failed to send message');
    } on Exception catch (e) {
      print('Unexpected error while sending: $e');
      _messageController.addError('Unexpected error while sending');
    }
  }

  void stopListening() {
    _subscription.cancel();
    _socket?.close();
    _socket = null;
    print('Stopped listening');
  }
}