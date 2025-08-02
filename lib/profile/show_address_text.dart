import 'package:flutter/material.dart';

class ShowAddressText extends StatelessWidget {
  const ShowAddressText({
    super.key,
    required this.onTap,
    required this.controller,
  });
  final TextEditingController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.text,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.location_on,
              size: 18,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
