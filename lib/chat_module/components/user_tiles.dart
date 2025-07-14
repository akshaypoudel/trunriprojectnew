import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserTiles extends StatelessWidget {
  const UserTiles({
    super.key,
    required this.text,
    required this.onTap,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.chatType,
    this.imageUrl,
  });
  final String text;
  final String lastMessage;
  final String lastMessageTime;
  final void Function() onTap;
  final String chatType;
  final String? imageUrl;

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
                color: Colors.orange.withValues(alpha: 0.04),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
            border: const Border.symmetric(
              vertical: BorderSide(color: Colors.black),
              horizontal: BorderSide(color: Colors.black),
            ),
          ),
          child: Row(
            children: [
              (imageUrl != null)
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 23,
                        backgroundImage: imageProvider,
                      ),
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )
                  : CircleAvatar(
                      radius: 23,
                      backgroundColor: const Color.fromARGB(222, 177, 177, 177),
                      foregroundColor: Colors.white,
                      child: (chatType == 'user')
                          ? const Icon(
                              Icons.person,
                              size: 41,
                            )
                          : const Icon(
                              Icons.group,
                              size: 41,
                            ),
                    ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                lastMessageTime.isNotEmpty ? lastMessageTime : '',
                style: const TextStyle(
                  fontSize: 10,
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
