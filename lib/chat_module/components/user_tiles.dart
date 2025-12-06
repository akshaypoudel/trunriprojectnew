import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserTiles extends StatelessWidget {
  const UserTiles({
    super.key,
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
    this.onDeclineRequest,
    this.onUnfriend,
    this.onBlock,
    this.onDeleteRequest,
    this.onCancelRequest,
  });

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
  final void Function()? onUnfriend;
  final void Function()? onBlock;
  final void Function()? onDeleteRequest;
  final void Function()? onCancelRequest;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (chatType == 'group') ? onOpenChat : () {},
      onLongPress: () => _showActionBottomSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
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

  void _showActionBottomSheet(BuildContext context) {
    List<Widget> actions = [];

    switch (status) {
      case 'friend':
        actions = [
          _buildActionTile(
            context,
            icon: Icons.message,
            title: 'Send Message',
            subtitle: 'Start a conversation',
            onTap: () {
              Navigator.pop(context);
              onOpenChat?.call();
            },
          ),
          _buildActionTile(
            context,
            icon: Icons.person_remove,
            title: 'Unfriend',
            subtitle: 'Remove from friends list',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              _showConfirmationDialog(
                context,
                'Unfriend $userName?',
                'This person will be removed from your friends list.',
                onUnfriend,
              );
            },
          ),
          _buildActionTile(
            context,
            icon: Icons.block,
            title: 'Block',
            subtitle: 'Block this person',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showConfirmationDialog(
                context,
                'Block $userName?',
                'This person will no longer be able to send you messages or friend requests.',
                onBlock,
              );
            },
          ),
        ];
        break;

      case 'sent':
        actions = [
          _buildActionTile(
            context,
            icon: Icons.cancel_outlined,
            title: 'Cancel Request',
            subtitle: 'Cancel friend request',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              _showConfirmationDialog(
                context,
                'Cancel friend request?',
                'Your friend request to $userName will be cancelled.',
                onCancelRequest,
              );
            },
          ),
          _buildActionTile(
            context,
            icon: Icons.block,
            title: 'Block',
            subtitle: 'Block this person',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showConfirmationDialog(
                context,
                'Block $userName?',
                'This person will no longer be able to send you messages or friend requests.',
                onBlock,
              );
            },
          ),
        ];
        break;

      case 'received':
        actions = [
          _buildActionTile(
            context,
            icon: Icons.check_circle,
            title: 'Accept Request',
            subtitle: 'Accept friend request',
            color: Colors.green,
            onTap: () {
              Navigator.pop(context);
              onAcceptRequest?.call();
            },
          ),
          _buildActionTile(
            context,
            icon: Icons.delete_outline,
            title: 'Delete Request',
            subtitle: 'Delete friend request',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              _showConfirmationDialog(
                context,
                'Delete friend request?',
                'The friend request from $userName will be deleted.',
                onDeleteRequest,
              );
            },
          ),
          _buildActionTile(
            context,
            icon: Icons.block,
            title: 'Block',
            subtitle: 'Block this person',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showConfirmationDialog(
                context,
                'Block $userName?',
                'This person will no longer be able to send you messages or friend requests.',
                onBlock,
              );
            },
          ),
        ];
        break;

      case 'group':
        actions = [
          _buildActionTile(
            context,
            icon: Icons.message,
            color: Colors.deepOrangeAccent,
            title: 'Send Message',
            subtitle: 'Start a conversation',
            onTap: () {
              Navigator.pop(context);
              onOpenChat?.call();
            },
          ),
        ];
        break;

      default: // 'none' status
        actions = [
          _buildActionTile(
            context,
            icon: Icons.person_add,
            title: 'Send Friend Request',
            subtitle: 'Add as friend',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              onSendFriendRequest?.call();
            },
          ),
          _buildActionTile(
            context,
            icon: Icons.block,
            title: 'Block',
            subtitle: 'Block this person',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showConfirmationDialog(
                context,
                'Block $userName?',
                'This person will no longer be able to send you messages or friend requests.',
                onBlock,
              );
            },
          ),
        ];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // User info header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          shortBio,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Action buttons
            ...actions,

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final actionColor = color ?? Colors.grey[700];

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: actionColor!.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: actionColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: actionColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback? onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Rest of your existing methods (_buildAvatar, _buildActionWidgets) remain the same
  Widget _buildAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
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
