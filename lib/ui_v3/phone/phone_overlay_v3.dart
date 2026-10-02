import 'package:flutter/material.dart';

import 'phone_controller_v3.dart';

Future<void> showPhoneOverlayV3(
  BuildContext context, {
  PhoneControllerV3 controller = const PhoneControllerV3(),
}) => showDialog<void>(
  context: context,
  builder: (context) => PhoneOverlayV3(controller: controller),
);

class PhoneOverlayV3 extends StatelessWidget {
  const PhoneOverlayV3({super.key, required this.controller});

  final PhoneControllerV3 controller;

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('phone_overlay_v3'),
    title: Text(controller.title),
    content: Text(controller.developmentMessage),
    actions: [
      TextButton(
        key: const ValueKey('phone_overlay_close_v3'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Fechar'),
      ),
    ],
  );
}
