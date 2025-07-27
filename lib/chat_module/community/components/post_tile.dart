import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostTile extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const PostTile({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final username = post['username'] ?? 'Unknown';
    final message = post['content'] ?? '';
    final tags = List<String>.from(post['tags'] ?? []);
    final timestamp = post['timestamp'] as Timestamp?;
    final profileUrl = post['profileUrl'];
    final isEdited = post['isEdited'] ?? false;

    final timeAgo =
        timestamp != null ? _timeAgo(timestamp.toDate()) : 'Just now';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.shade100,
                    backgroundImage:
                        (profileUrl != null && profileUrl.isNotEmpty)
                            ? NetworkImage(profileUrl)
                            : null,
                    child: (profileUrl == null || profileUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.orange)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          (isEdited)
                              ? const Text(
                                  '  · Edited',
                                  style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _layoutShortText(message, context),
              const SizedBox(height: 8),
              if (tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: -8,
                  children: tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: const TextStyle(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layoutShortText(String message, BuildContext context) {
    const textStyle = TextStyle(fontSize: 16);
    const maxLines = 6;
    final textSpan = TextSpan(text: message, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width - 64,
    );

    final didOverflow = textPainter.didExceedMaxLines;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
        if (didOverflow)
          const SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '......',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
