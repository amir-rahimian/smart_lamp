enum WifiState {
  idle,
  trying,
  connected,
}

class Wifi {
  final String ssid;
  final int waveLevel;
  final String securityType;
  WifiState wifiState = WifiState.idle;

  Wifi({required this.ssid, required this.waveLevel, required this.securityType});

  factory Wifi.fromMap(Map<dynamic, dynamic> map) {
    return Wifi(
      ssid: map['ssid'] ?? '',
      waveLevel: map['waveLevel'] ?? 0,
      securityType: map['securityType'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Wifi && ssid == other.ssid);

  @override
  int get hashCode => ssid.hashCode;

  @override
  String toString() => 'Wifi(ssid: $ssid, waveLevel: $waveLevel, securityType: $securityType)';
}
