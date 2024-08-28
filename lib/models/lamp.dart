import 'package:smart_lamp/models/wifi.dart';

enum PirMode {
  off,
  alert,
  onFor,
  offAfter;

  static PirMode fromInt(int value) => PirMode.values[value];

  int toInt() => index;
}

class Lamp {
  final Wifi wifi;
  bool state;
  PirMode pirMode;
  int pirDelay;

  Lamp({
    required this.wifi,
    this.state = false,
    this.pirMode = PirMode.onFor,
    this.pirDelay = 5,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Lamp && wifi == other.wifi);

  @override
  int get hashCode => wifi.ssid.hashCode;

  @override
  String toString() => 'Lamp(wifi: $wifi, state: $state, pirMode: $pirMode)';
}
