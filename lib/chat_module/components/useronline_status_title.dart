import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

class UserOnlineStatusTitle extends StatelessWidget {
  final String userId;
  final String userName;

  const UserOnlineStatusTitle({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName,
          style: const TextStyle(fontSize: 22),
        ),
        getOnlineOfflineStream()
      ],
    );
  }

  Widget getOnlineOfflineStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }

        if (snapshot.hasError) {
          return Container();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container();
        }

        final doc = snapshot.data!.docs.first;
        final rawData = doc.data();

        if (rawData is! Map<String, dynamic>) {
          return Container();
        }

        final data = rawData;

        final bool isOnline = data['isOnline'] ?? false;
        final Timestamp? lastSeenTimestamp = data['lastSeen'];
        final lastSeen = lastSeenTimestamp?.toDate();

        return Row(
          children: [
            (isOnline)
                ? const Text(
                    '🟢',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                    ),
                  )
                : Container(),
            (isOnline) ? const SizedBox(width: 5) : Container(),
            Text(
              isOnline ? 'Online' : getLastSeenText(lastSeen),
              style: TextStyle(
                fontSize: 12,
                color: isOnline ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  String getLastSeenText(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastSeenDate = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);

    if (lastSeenDate == today) {
      return 'Last seen ${DateFormat('hh:mm a').format(lastSeen)}';
    } else if (lastSeenDate == yesterday) {
      return 'Last seen Yesterday';
    } else {
      return 'Last seen ${DateFormat('d MMM yyyy').format(lastSeen)}';
    }
  }
}
