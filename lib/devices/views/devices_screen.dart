import 'package:care_watch/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(title: "Devices"),
      body: Center(
        child: Text(
          "Devices Screen",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}