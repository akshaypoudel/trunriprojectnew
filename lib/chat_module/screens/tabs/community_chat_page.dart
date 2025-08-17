import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/community/components/chat_provider.dart';
import 'package:trunriproject/chat_module/community/components/post_tile.dart';
import 'package:trunriproject/chat_module/community/new_post_screen.dart';
import 'package:trunriproject/chat_module/community/read_post_screen.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/widgets/helper.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  final TextEditingController replyController = TextEditingController();
  final FocusNode replyFocusNode = FocusNode();

  @override
  void dispose() {
    replyController.dispose();
    replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          InkWell(
            onTap: () {
              Get.to(() => const NewPostScreen());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.orange.shade100,
                    backgroundImage: (provider.getProfileImage.isNotEmpty)
                        ? NetworkImage(provider.getProfileImage)
                        : null,
                    child: (provider.getProfileImage.isEmpty)
                        ? const Icon(Icons.person, color: Colors.orange)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      Get.to(() => const NewPostScreen());
                    },
                    child: Text(
                      "What's on your mind?",
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          const Divider(height: 0),

          // Post Feed
          Expanded(
            child: RefreshIndicator(
              key: _refreshKey,
              backgroundColor: Colors.white,
              color: Colors.deepOrange,
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 100));
              },
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!.docs;

                  if (posts.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            "No posts yet",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final postDoc = posts[index];
                      final post = postDoc.data() as Map<String, dynamic>;

                      // Add post ID to the post data for easier access
                      post['id'] = postDoc.id;

                      // Nested StreamBuilder to fetch replies for each post
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('community_posts')
                            .doc(postDoc.id)
                            .collection('replies')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, repliesSnapshot) {
                          List<Map<String, dynamic>> repliesList = [];

                          if (repliesSnapshot.hasData) {
                            repliesList = repliesSnapshot.data!.docs.map((doc) {
                              final replyData =
                                  doc.data() as Map<String, dynamic>;
                              replyData['id'] =
                                  doc.id; // Add reply ID if needed
                              return replyData;
                            }).toList();
                          }

                          // Add replies to post data
                          post['replies'] = repliesList;
                          post['replyCount'] = repliesList.length;

                          return PostTile(
                            replyController: replyController,
                            replyFocusNode: replyFocusNode,
                            post: post,
                            onTap: () {
                              Get.to(
                                () => ReadPostScreen(
                                  post: post,
                                  postId: postDoc.id,
                                ),
                              );
                            },
                            onReply: (replyText) async {
                              try {
                                final replyData = {
                                  'reply':
                                      replyText, // Changed from 'reply' to 'content' to match PostTile expectations
                                  'userName': provider
                                      .getUserName, // Changed from 'userName' to 'username'
                                  'userImage': provider.getProfileImage ??
                                      '', // Changed from 'userImage' to 'profileUrl'
                                  'timestamp': FieldValue.serverTimestamp(),
                                };

                                await FirebaseFirestore.instance
                                    .collection('community_posts')
                                    .doc(postDoc.id)
                                    .collection('replies')
                                    .add(replyData);

                                // Show success message
                                showSnackBar(
                                    context, 'Reply added successfully!');
                              } catch (e) {
                                // Show error message
                                showSnackBar(context, 'Reply Can\'t be added');
                              }
                            },
                            onShowMoreReplies: () {
                              Get.to(
                                () => ReadPostScreen(
                                  post: post,
                                  postId: postDoc.id,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
