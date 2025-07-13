import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  const ChatInputField({
    super.key,
    required this.onSend,
    required this.controller,
    required this.focusNode,
  });

  final VoidCallback onSend;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Colors.orange,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          RawMaterialButton(
            onPressed: onSend,
            shape: const CircleBorder(),
            fillColor: Colors.orange.shade300,
            elevation: 10,
            constraints: const BoxConstraints.tightFor(
              width: 52,
              height: 52,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class GroupNameInputField extends StatelessWidget {
  const GroupNameInputField({
    super.key,
    required this.controller,
    required this.onTap,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onTap: onTap,
              decoration: InputDecoration(
                hintText: "Enter Group Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Colors.orange,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
