import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserTiles extends StatelessWidget {
  const UserTiles({
    super.key,
    required this.userName,
    this.onSendFriendRequest,
    this.onOpenChat,
    this.onAcceptRequest,
    this.onDeclineRequest,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.chatType,
    this.imageUrl,
    required this.status,
  });
  final String userName;
  final String lastMessage;
  final String lastMessageTime;
  final void Function()? onSendFriendRequest;
  final void Function()? onOpenChat;
  final void Function()? onAcceptRequest;
  final void Function()? onDeclineRequest;

  final String chatType;
  final String? imageUrl;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: onOpenChat,
        child: Container(
          padding:
              const EdgeInsets.only(left: 15, right: 15, top: 11, bottom: 11),
          decoration: BoxDecoration(
            color: Colors.white,
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
              (imageUrl != null && imageUrl!.isNotEmpty)
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
                      userName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    (status == 'friend')
                        ? Text(
                            lastMessage.isNotEmpty
                                ? lastMessage
                                : 'No messages yet',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : (status == 'received')
                            ? const Text(
                                'Wants to be friends',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              )
                            : const SizedBox.shrink(),
                  ],
                ),
              ),
              (status == 'friend')
                  ? Text(
                      lastMessageTime.isNotEmpty ? lastMessageTime : '',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : status == 'sent'
                      ? const Text(
                          'Request Sent',
                          style: TextStyle(color: Colors.grey),
                        )
                      : (status == 'received')
                          ? Row(
                              children: [
                                IconButton(
                                  onPressed: onAcceptRequest,
                                  //fillColor: Colors.orangeAccent.shade100,
                                  // padding: const EdgeInsets.symmetric(
                                  //     horizontal: 8, vertical: 8),
                                  // constraints: const BoxConstraints(
                                  //   minWidth: 10,
                                  //   minHeight: 10,
                                  // ), // allows smaller size
                                  //shape: RoundedRectangleBorder(
                                  //borderRadius: BorderRadius.circular(10),
                                  //),
                                  //materialTapTargetSize: MaterialTapTargetSize
                                  //.shrinkWrap, // removes extra padding
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                ),
                                // const SizedBox(width: 10),
                                IconButton(
                                  onPressed: onDeclineRequest,
                                  // fillColor: Colors.orangeAccent.shade100,
                                  // padding: const EdgeInsets.symmetric(
                                  //     horizontal: 8, vertical: 8),
                                  // constraints: const BoxConstraints(
                                  //   minWidth: 10,
                                  //   minHeight: 10,
                                  // ), // allows smaller size
                                  // shape: RoundedRectangleBorder(
                                  //   borderRadius: BorderRadius.circular(10),
                                  // ),
                                  // materialTapTargetSize: MaterialTapTargetSize
                                  //     .shrinkWrap, // removes extra padding
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            )
                          : RawMaterialButton(
                              onPressed: onSendFriendRequest,
                              fillColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              constraints: const BoxConstraints(
                                minWidth: 10,
                                minHeight: 10,
                              ), // allows smaller size
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              materialTapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // removes extra padding
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
            ],
          ),
        ),
      ),
    );
  }
}
