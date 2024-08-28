import 'package:flutter/services.dart';
import 'package:smart_lamp/models/wifi.dart';

enum WifiEventType {
  wifiScanResults,
  networkJoinResult,
  requestWifiTurnOn,
  wifiGone,
}

typedef WifiEventCallback = void Function(WifiEventType eventType, {bool? success});

class WifiService {
  static const MethodChannel _channel = MethodChannel('com.rahimian.smartlamp/wifi');

  WifiEventCallback? onEvent;

  WifiService() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  Future<void> initialize(WifiEventCallback eventCallback) async {
    onEvent = eventCallback;
    await initializeWifiScanning();
  }

  Future<void> initializeWifiScanning() async {
    try {
      await _channel.invokeMethod('initializeWifiScanning');
    } on PlatformException catch (e) {
      print("Failed to start scanning: '${e.message}'.");
    }
  }

  Future<void> tryConnectToWifi(String ssid, String pass) async {
    try {
      await _channel.invokeMethod('tryConnectToWifi', {"ssid": ssid, "pass": pass});
    } on PlatformException catch (e) {
      print("Failed to connect: '${e.message}'.");
    }
  }

  Future<List<Wifi>> getWifiList() async {
    try {
      final wifiList = await _channel.invokeMethod('getWifiList');
      if (wifiList is List) {
        return wifiList.map((wifi) => Wifi.fromMap(wifi)).toList();
      }
      return [];
    } on PlatformException catch (e) {
      print("Failed to get Wifi list: '${e.message}'.");
      return [];
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      print("Failed to disconnect: '${e.message}'.");
    }
  }

  Future<void> wifiSettings() async {
    try {
      await _channel.invokeMethod('openWifi');
    } on PlatformException catch (e) {
      print("Failed to open Wifi: '${e.message}'.");
    }
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onWifiScanResults':
        final bool success = call.arguments as bool;
        onEvent?.call(WifiEventType.wifiScanResults, success: success);
        break;
      case 'onNetworkJoinResult':
        final bool success = call.arguments as bool;
        onEvent?.call(WifiEventType.networkJoinResult, success: success);
        break;
      case 'requestWifiTurnOn':
        onEvent?.call(WifiEventType.requestWifiTurnOn);
        break;
      case 'onWifiGone':
        onEvent?.call(WifiEventType.wifiGone);
        break;
      default:
        print('Unknown method: ${call.method}');
    }
  }
}
