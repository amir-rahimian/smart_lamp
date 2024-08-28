import 'dart:async';
import 'package:flutter/cupertino.dart';

class DelayPicker extends StatefulWidget {
  final Function(int) onValueChanged;
  final FixedExtentScrollController? scrollController;

  const DelayPicker({
    super.key,
    required this.onValueChanged,
    this.scrollController,
  });

  @override
  _DelayPickerState createState() => _DelayPickerState();
}

class _DelayPickerState extends State<DelayPicker> {
  late FixedExtentScrollController _scrollController;
  late int _selectedValue;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? FixedExtentScrollController();
    _selectedValue = _scrollController.hasClients ? _scrollController.selectedItem : 0;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSelectedItemChanged(int value) {
    setState(() {
      _selectedValue = value;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        widget.onValueChanged(_selectedValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      looping: true,
      useMagnifier: true,
      scrollController: _scrollController,
      itemExtent: 40,
      onSelectedItemChanged: _onSelectedItemChanged,
      children: List<Widget>.generate(60, (int index) {
        return Center(
          child: Text(
            '$index',
            style: const TextStyle(fontSize: 20),
          ),
        );
      }),
    );
  }
}
