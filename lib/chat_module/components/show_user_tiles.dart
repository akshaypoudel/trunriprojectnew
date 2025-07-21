import 'package:flutter/material.dart';

class ShowUserTiles extends StatelessWidget {
  const ShowUserTiles({
    super.key,
    required this.onTap,
    required this.userName,
  });

  final void Function() onTap;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(18, 255, 153, 0)
                    .withValues(alpha: 0.04),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
            border: Border.symmetric(
              vertical: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
              horizontal:
                  BorderSide(color: Colors.black.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color.fromARGB(222, 177, 177, 177),
                foregroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 30,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
