import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_lamp/models/lamp.dart';
import 'package:smart_lamp/widgets/toast.dart';
import 'package:smart_lamp/wifi/wifi_service.dart';

import 'lamp_control.dart';
import 'models/wifi.dart';

void main() {
  runApp(const SmartLamp());
}

class SmartLamp extends StatelessWidget {
  const SmartLamp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Vazir',
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.white,
        ),
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fa'),
        ],
        locale: const Locale('fa'),
        home: const MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final WifiService wifiService = WifiService();
  final List<Wifi> showingWifi = [];
  bool isLoading = false;
  Wifi? selectedWifi;
  Lamp? lamp;

  @override
  void initState() {
    super.initState();
    _initializeWifiScanning();
  }

  Future<void> _initializeWifiScanning() async {
    await wifiService.initialize((eventType, {success}) {
      switch (eventType) {
        case WifiEventType.wifiScanResults:
          _refreshWifiList();
          break;
        case WifiEventType.networkJoinResult:
          _updateWifiState(success!);
          break;
        case WifiEventType.requestWifiTurnOn:
          _requestWifiOn();
          break;
        case WifiEventType.wifiGone:
          _showToast('اتصال با دستگاه از بین رفت !');
          _disconnectLamp();
          break;
      }
    });
    await _refreshWifiList();
  }

  void _updateWifiState(bool connected) {
    _showToast(connected ? 'متصل شدید' : 'مشکل در اتصال وجود دارد');
    selectedWifi!.wifiState = connected ? WifiState.connected : WifiState.idle;
    if (connected) lamp = Lamp(wifi: selectedWifi!);
    setState(() {});
  }

  void _requestWifiOn() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "شبکه در دسترس نیست !",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("لطفا شبکه WiFi خود را فعال کنید"),
          actions: [
            TextButton(
              child: const Text("بستن اپلیکیشن"),
              onPressed: () {
                Navigator.of(context).popUntil(
                  (route) => true,
                ); // dismiss dialog
              },
            ),
            TextButton(
              child: const Text("باز کردن تنظیمات"),
              onPressed: () {
                wifiService.wifiSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshWifiList() async {
    setState(() => isLoading = true);
    final wifiList = await wifiService.getWifiList();
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      showingWifi
        ..clear()
        ..addAll(wifiList);
      isLoading = false;
    });
  }

  Future<void> _clickedLampWifi(Wifi wifi) async {
    setState(() {
      selectedWifi = wifi;
      selectedWifi!.wifiState = WifiState.trying;
    });
    await wifiService.tryConnectToWifi(wifi.ssid, '12345678');
  }

  void _showToast(String message) => Toast.showToast(context: context, message: message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("لامپ هوشمند", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildWifiList(),
          if (lamp != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2),
                ),
              ),
            ),
          if (lamp != null)
            Positioned(
              bottom: 16,
              left: 10,
              right: 10,
              child: LampControl(lamp: lamp!, onDisconnect: _disconnectLamp),
            ),
        ],
      ),
    );
  }

  Widget _buildWifiList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        showingWifi.isEmpty ? const Center(child: Text("لامپی در شبکه پیدا نشد!")) : _buildWifiCards(),
        if (showingWifi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'از دستگاه های پیدا شده یکی را برای اتصال انتخاب کنید.\nسپس منتظر باشید تا در پایین صفحه کنترل دستگاه ظاهر شود',
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(height: 1.6),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("لامپ های شما"),
          IconButton(
            onPressed: _refreshWifiList,
            icon: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: showingWifi.where((ap) => ap.ssid.startsWith('Lamp')).map((ap) {
          final id = ap.ssid.substring(4);
          return GestureDetector(
            onTap: () {
              if (selectedWifi == ap) {
                _showToast('این دستگاه متصل است!');
                setState(() {
                  selectedWifi!.wifiState = WifiState.connected;
                  lamp = Lamp(wifi: selectedWifi!);
                });
                return;
              }
              _clickedLampWifi(ap);
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                side: BorderSide(
                  color: (selectedWifi == ap) ? Colors.blue : Colors.grey,
                  width: (selectedWifi == ap && ap.wifiState == WifiState.connected) ? 0.3 : 0.6,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: ap.wifiState == WifiState.trying ? 0.5 : 1,
                          child: const Icon(Icons.lightbulb),
                        ),
                        if (ap.wifiState == WifiState.trying)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24, child: VerticalDivider(width: 16, thickness: 1)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("لامپ", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(id, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _disconnectLamp() {
    wifiService.disconnect();
    setState(() {
      lamp = null;
      selectedWifi = null;
    });
  }
}
