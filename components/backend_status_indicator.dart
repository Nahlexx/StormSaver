import 'package:flutter/material.dart';
import '../data/services/expense_service.dart';

class BackendStatusIndicator extends StatefulWidget {
  const BackendStatusIndicator({Key? key}) : super(key: key);

  @override
  State<BackendStatusIndicator> createState() => _BackendStatusIndicatorState();
}

class _BackendStatusIndicatorState extends State<BackendStatusIndicator> {
  bool? _isConnected;
  String? _details;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final service = ExpenseService();
    try {
      final result = await service.testConnection();
      setState(() {
        _isConnected = true;
        _details = "Host: "+(result['details']?['host']?.toString() ?? "?")+"\nDB: "+(result['details']?['name']?.toString() ?? "?");
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _details = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    if (_isConnected == null) {
      color = Colors.grey;
      text = "Checking backend...";
    } else if (_isConnected == true) {
      color = Colors.green;
      text = "Backend Connected";
    } else {
      color = Colors.red;
      text = "Backend Not Connected";
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color)),
        if (_details != null && _isConnected == true)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(_details!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
      ],
    );
  }
} 