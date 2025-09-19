import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserTiles extends StatelessWidget {
  const UserTiles(
      {super.key,
      required this.userName,
      required this.lastMessage,
      required this.lastMessageTime,
      required this.chatType,
      required this.status,
      required this.shortBio,
      this.imageUrl,
      this.onSendFriendRequest,
      this.onOpenChat,
      this.onAcceptRequest,
      this.onDeclineRequest});

  final String userName;
  final String lastMessage;
  final String lastMessageTime;
  final String chatType;
  final String status;
  final String shortBio;
  final String? imageUrl;
  final void Function()? onSendFriendRequest;
  final void Function()? onOpenChat;
  final void Function()? onAcceptRequest;
  final void Function()? onDeclineRequest;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (chatType == 'group') ? onOpenChat : () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              _buildAvatar(),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    (chatType == 'group')
                        ? Text(
                            lastMessage.isNotEmpty
                                ? lastMessage
                                : "No messages yet",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            shortBio,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),

              // Action Button
              _buildActionWidgets(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? "",
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 60,
            height: 60,
            color: Colors.grey[100],
            child: const Icon(Icons.person, size: 30, color: Colors.grey),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 60,
            height: 60,
            color: Colors.grey[100],
            child: Icon(
              chatType == "user" ? Icons.person : Icons.group,
              size: 30,
              color: Colors.grey,
            ),
          ),
          fadeInDuration: const Duration(milliseconds: 150),
        ),
      ),
    );
  }

  Widget _buildActionWidgets() {
    switch (status) {
      case "group":
        return Text(
          lastMessageTime,
          style: const TextStyle(fontSize: 12),
        );
      case "friend":
        return SizedBox(
          width: 80,
          child: ElevatedButton(
            onPressed: onOpenChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Say Hello',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        );

      case "sent":
        return Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Sent',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );

      case "received":
        return Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 30,
              ),
              onPressed: onAcceptRequest,
              splashRadius: 30,
            ),
            IconButton(
              icon: const Icon(
                Icons.cancel,
                color: Colors.redAccent,
                size: 30,
              ),
              onPressed: onDeclineRequest,
              splashRadius: 30,
            ),
          ],
        );

      default:
        return SizedBox(
          width: 80,
          child: ElevatedButton(
            onPressed: onSendFriendRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Add',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        );
    }
  }
}
