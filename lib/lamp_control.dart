import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_lamp/widgets/delay_picker.dart';
import 'package:smart_lamp/wifi/socket/socketer.dart';
import 'package:vibration/vibration.dart';

import 'models/lamp.dart';

class LampControl extends StatefulWidget {
  final Lamp lamp;
  final VoidCallback onDisconnect;

  const LampControl({
    super.key,
    required this.lamp,
    required this.onDisconnect,
  });

  @override
  _LampControlState createState() => _LampControlState();
}

class _LampControlState extends State<LampControl> {
  late bool _lampState;
  late bool _alert;
  late PirMode _pirMode;
  late int _pirDelay;
  StreamSubscription<String>? _udpSubscription;
  Timer? _alertTimer;

  late FixedExtentScrollController delayController;

  @override
  void initState() {
    super.initState();
    _initializeLampState();
    delayController = FixedExtentScrollController(initialItem: _pirDelay);
    UdpManager().initializeSocket();
    _startListeningToUdpMessages();
  }

  void _initializeLampState() {
    _lampState = widget.lamp.state;
    _alert = false;
    _pirMode = widget.lamp.pirMode;
    _pirDelay = widget.lamp.pirDelay;
  }

  void _startListeningToUdpMessages() {
    _udpSubscription = UdpManager().onMessage.listen(_handleUdpMessage);
  }

  void _requestLampState() {
    UdpManager().sendMessage('LST');
  }

  void _handleUdpMessage(String message) {
    if (message == '*') {
      _requestLampState();
    } else if (message.startsWith('L') && message.endsWith('T')) {
      _updateLampStateFromMessage(message);
    } else if (message == 'ALERT') {
      _startAlertVibration();
    }
  }

  void _updateLampStateFromMessage(String message) {
    message = message.substring(1, message.length - 1);
    if (message.contains('P') && message.length == 6) {
      _updateLampAndPirState(message);
    } else if (message.length == 1) {
      _updateLampState(message[0] == '1');
    }
  }

  void _updateLampAndPirState(String message) {
    final state = message[0] == '1';
    final pMode = PirMode.fromInt(int.parse(message[2]));
    final pDelay = int.parse(message.substring(4));
    _safeSetState(() {
      _lampState = state;
      _pirMode = pMode;
      _pirDelay = pDelay;
      delayController.animateToItem(
        _pirDelay,
        duration: const Duration(milliseconds: 400),
        curve: Curves.decelerate,
      );
      // delayController.jumpToItem(_pirDelay);
    });
  }

  void _updateLampState(bool state) {
    _safeSetState(() => _lampState = state);
  }

  void _startAlertVibration() {
    if (!mounted) return;

    _safeSetState(() => _alert = true);
    const Duration vibrationInterval = Duration(seconds: 1);
    final Duration alertDuration = Duration(seconds: _pirDelay);

    _alertTimer?.cancel();
    _alertTimer = Timer.periodic(vibrationInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      Vibration.vibrate(duration: 500, amplitude: 255);
      _safeSetState(() => _alert = !_alert);

      if (timer.tick >= alertDuration.inSeconds) {
        timer.cancel();
        _safeSetState(() => _alert = false);
      }
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    _udpSubscription?.cancel();
    _alertTimer?.cancel();
    UdpManager().stopListening();
    super.dispose();
  }

  void _toggleLampState() {
    _safeSetState(() {
      _lampState = !_lampState;
    });
    UdpManager().sendMessage("L${_lampState ? '1' : '0'}T");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(26),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLampTitle(context),
              const SizedBox(height: 8),
              _buildLampControls(context),
              const SizedBox(height: 8),
              _buildDisconnectButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLampTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        "لامپ ${widget.lamp.wifi.ssid}",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLampControls(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLampToggle(),
        Expanded(flex: 2, child: _buildPirControls(context)),
      ],
    );
  }

  Widget _buildLampToggle() {
    return Expanded(
      child: GestureDetector(
        onTap: _toggleLampState,
        child: Container(
          height: 80.0,
          width: 80.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _alert ? Colors.white : Colors.white30),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Icon(
            Icons.lightbulb,
            size: 50.0,
            color: _alert
                ? Colors.yellowAccent
                : _lampState
                    ? Colors.white
                    : Colors.white30,
          ),
        ),
      ),
    );
  }

  Widget _buildPirControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPirModeTitle(context),
        const SizedBox(height: 4),
        _buildPirModeSegmentedButton(),
        const SizedBox(height: 8.0),
        _buildPirModeDescription(),
        const SizedBox(height: 8.0),
        _buildPirDelayPicker(),
      ],
    );
  }

  Widget _buildPirModeTitle(BuildContext context) {
    return Text(
      'عملکرد سنسور تشخیص حرکت',
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildPirModeSegmentedButton() {
    return SegmentedButton<PirMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: PirMode.off,
          icon: Icon(Icons.sensors_off),
        ),
        ButtonSegment(
          value: PirMode.alert,
          icon: Icon(Icons.notifications),
        ),
        ButtonSegment(
          value: PirMode.onFor,
          icon: Icon(Icons.lightbulb),
        ),
        ButtonSegment(
          value: PirMode.offAfter,
          icon: Icon(Icons.lightbulb_outline),
        ),
      ],
      selected: <PirMode>{_pirMode},
      onSelectionChanged: (newValue) {
        _safeSetState(() {
          _pirMode = newValue.single;
        });
        UdpManager().sendMessage(_makePirPacket());
      },
    );
  }

  Widget _buildPirModeDescription() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      child: Text(
        _getPirModeDescription(),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  String _getPirModeDescription() {
    switch (_pirMode) {
      case PirMode.off:
        return "عملکرد سنسور تشخیص حرکت غیر فعال";
      case PirMode.alert:
        return "با تشخیص حرکت به مدت زمان زیر اخطار داده میشود";
      case PirMode.onFor:
        return "زمانی که حرکت تشخیص داده شود به مدت زمانی که پایین وارد میکنید چراغ روشن میماند";
      case PirMode.offAfter:
        return "بلافاصله با تشخیص حرکت لامپ روشن میشود و با پایان حرکت به مدت زمان وارد شده صبر میکند و سپس چراغ را خاموش میکند";
    }
  }

  Widget _buildPirDelayPicker() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      child: _pirMode != PirMode.off
          ? Column(
              children: [
                const Divider(),
                const Text("مدت زمان تاخیر برای انجام ( ثانیه )"),
                const SizedBox(height: 8.0),
                SizedBox(
                  height: 80,
                  child: DelayPicker(
                    scrollController: delayController,
                    onValueChanged: (value) {
                      _safeSetState(() {
                        _pirDelay = value;
                      });
                      UdpManager().sendMessage(_makePirPacket());
                    },
                  ),
                ),
              ],
            )
          : const SizedBox(),
    );
  }

  Widget _buildDisconnectButton() {
    return OutlinedButton(
      onPressed: () {
        UdpManager().stopListening();
        widget.onDisconnect();
      },
      child: const Text('قطع اتصال'),
    );
  }

  String _makePirPacket() {
    return _pirMode == PirMode.off ? "P0R" : "P${_pirMode.toInt()}|${_pirDelay.toString().padLeft(2, '0')}R";
  }
}
