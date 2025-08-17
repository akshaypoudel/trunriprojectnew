import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming you're using GetX for navigation

class PostTile extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  final Function(String)? onReply; // Callback for when user submits a reply
  final VoidCallback? onShowMoreReplies; // Callback for showing more replies
  final VoidCallback? onLike; // Callback for when user likes the post
  final TextEditingController replyController;
  final FocusNode replyFocusNode;

  const PostTile({
    super.key,
    required this.post,
    required this.onTap,
    required this.replyController,
    required this.replyFocusNode,
    this.onReply,
    this.onShowMoreReplies,
    this.onLike,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> with TickerProviderStateMixin {
  bool _isReplyFieldVisible = false;
  // late AnimationController _likeAnimationController;
  // late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    // _likeAnimationController = AnimationController(
    //   duration: const Duration(milliseconds: 200),
    //   vsync: this,
    // );
    // _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
    //   CurvedAnimation(
    //       parent: _likeAnimationController, curve: Curves.elasticOut),
    // );
  }

  @override
  void dispose() {
    // _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.post['username'] ?? 'Unknown';
    final message = widget.post['content'] ?? '';
    final tags = List<String>.from(widget.post['tags'] ?? []);
    final timestamp = widget.post['timestamp'] as Timestamp?;
    final profileUrl = widget.post['profileUrl'];
    final isEdited = widget.post['isEdited'] ?? false;
    final postId = widget.post['id'] ?? '';
    final isLiked = widget.post['isLiked'] ?? false;
    final likeCount = widget.post['likeCount'] ?? 0;
    final replyCount = widget.post['replyCount'];

    final List<Map<String, dynamic>> replies = widget.post['replies'] ?? [];

    final timeAgo =
        timestamp != null ? _timeAgo(timestamp.toDate()) : 'Just now';

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with profile and user info
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        // backgroundImage:
                        //     (profileUrl != null && profileUrl.isNotEmpty)
                        //         ? NetworkImage(profileUrl)
                        //         : null,
                        child: (profileUrl == null || profileUrl.isEmpty)
                            ? Icon(
                                Icons.person_rounded,
                                color: Colors.orange.shade400,
                                size: 24,
                              )
                            : ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: profileUrl,
                                  width: 44,
                                  height: 44,
                                  placeholder: (context, url) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.deepOrange,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.person_rounded,
                                    color: Colors.orange.shade400,
                                    size: 24,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isEdited) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'EDITED',
                                    style: TextStyle(
                                      color: Colors.orange.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Message content
                _buildMessageContent(message, context),

                // Tags section
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTagsSection(tags),
                ],

                //extra space section
                const SizedBox(height: 10),
                const Divider(
                  thickness: .5,
                ),

                const SizedBox(height: 10),

                //total Replies Text
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade50,
                          Colors.orange.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.comment_rounded,
                          size: 13,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$replyCount Replies',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Single reply preview (if replies exist)
                if (replies.isNotEmpty) ...[
                  _buildSingleReplyPreview(replies[0]),
                  const SizedBox(height: 12),
                  _buildShowMoreRepliesButton(replyCount, postId),
                  const SizedBox(height: 12),
                ],

                // Like and Reply buttons row
                _buildActionButtonsRow(isLiked, likeCount, replyCount),

                // Reply text field (shown when reply button is tapped)
                if (_isReplyFieldVisible) ...[
                  const SizedBox(height: 12),
                  _buildReplyField(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow(bool isLiked, int likeCount, int replyCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Reply button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isReplyFieldVisible = !_isReplyFieldVisible;
                  if (_isReplyFieldVisible) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      widget.replyFocusNode.requestFocus();
                    });
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _isReplyFieldVisible
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isReplyFieldVisible
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isReplyFieldVisible ? Icons.close : Icons.reply_rounded,
                      size: 18,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isReplyFieldVisible ? 'Cancel' : 'Reply',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleReplyPreview(Map<String, dynamic> reply) {
    final replyUsername = reply['userName'] ?? 'Unknown';
    final replyContent = reply['reply'] ?? '';
    final replyProfileUrl = reply['userImage'];
    final replyTimestamp = reply['timestamp'] as Timestamp?;
    final replyTimeAgo =
        replyTimestamp != null ? _timeAgo(replyTimestamp.toDate()) : 'Just now';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            backgroundImage:
                (replyProfileUrl != null && replyProfileUrl.isNotEmpty)
                    ? NetworkImage(replyProfileUrl)
                    : null,
            child: (replyProfileUrl == null || replyProfileUrl.isEmpty)
                ? Icon(
                    Icons.person_rounded,
                    color: Colors.orange.shade400,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      replyUsername,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      replyTimeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  replyContent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowMoreRepliesButton(int totalReplies, String postId) {
    if (totalReplies <= 1) return const SizedBox.shrink();

    final remainingReplies = totalReplies - 1;

    return GestureDetector(
      onTap: () {
        // Navigate to ReadPostScreen
        if (widget.onShowMoreReplies != null) {
          widget.onShowMoreReplies!();
        } else {
          // Default navigation - replace with your actual screen
          // Get.to(() => ReadPostScreen(postId: postId));
          widget.onTap();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'Show $remainingReplies more ${remainingReplies == 1 ? 'reply' : 'replies'}',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: widget.replyController,
            focusNode: widget.replyFocusNode,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a reply...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isReplyFieldVisible = false;
                    widget.replyController.clear();
                  });
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (widget.replyController.text.trim().isNotEmpty) {
                    if (widget.onReply != null) {
                      widget.onReply!(widget.replyController.text.trim());
                    }
                    setState(() {
                      _isReplyFieldVisible = false;
                      widget.replyController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Reply',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String message, BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: Colors.black87,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
    );
    const maxLines = 8;

    final textSpan = TextSpan(text: message, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width - 112,
    );

    final didOverflow = textPainter.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
        if (didOverflow) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Read more',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  size: 16,
                  color: Colors.orange.shade600,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              'Tags',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.orange.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    tag,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
