import 'package:flutter/material.dart';
import 'nonna_chat_dialog.dart';

class MacinnaFAB extends StatelessWidget {
  const MacinnaFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(context: context, builder: (_) => const NonnaChatDialog());
      },
      backgroundColor: Colors.red[300],
      child: const CircleAvatar(
        radius: 28,
        backgroundImage: AssetImage('assets/images/nonna_dog.jpg'),
      ),
    );
  }
}
