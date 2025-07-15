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
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  controller.text,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.edit_location_alt_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
