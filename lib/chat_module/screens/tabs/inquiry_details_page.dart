import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:trunriproject/chat_module/context_chats/screens/context_chat_screen.dart';

class InquiryDetailsPage extends StatefulWidget {
  const InquiryDetailsPage({super.key});

  @override
  State<InquiryDetailsPage> createState() => _InquiryDetailsPageState();
}

class _InquiryDetailsPageState extends State<InquiryDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepOrangeAccent,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.deepOrangeAccent,
              indicatorWeight: 1,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  text: "Sent",
                  icon: Icon(
                    FontAwesomeIcons.paperPlane,
                    size: 21,
                  ),
                ),
                Tab(
                  text: "Received",
                  icon: Icon(
                    FontAwesomeIcons.inbox,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contextChats')
                  .where(
                    Filter.or(
                      Filter('seekerId', isEqualTo: currentUser!.uid),
                      Filter('posterId', isEqualTo: currentUser.uid),
                    ),
                  )
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepOrange,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading inquiries',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                final sentInquiries = allDocs
                    .where((doc) => (doc['seekerId'] ?? '') == currentUser.uid)
                    .toList();

                final receivedInquiries = allDocs
                    .where((doc) => (doc['posterId'] ?? '') == currentUser.uid)
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInquiryList(sentInquiries, currentUser.uid, "sent"),
                    _buildInquiryList(
                        receivedInquiries, currentUser.uid, "received"),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryList(List<QueryDocumentSnapshot> inquiries,
      String currentUserId, String type) {
    if (inquiries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      type == "sent"
                          ? FontAwesomeIcons.paperPlane
                          : FontAwesomeIcons.inbox,
                      size: 64,
                      color: Colors.deepOrange.shade300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    type == "sent"
                        ? "No inquiries sent yet"
                        : "No inquiries received yet",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type == "sent"
                        ? "Start exploring and connect with hosts!"
                        : "Share your listings to get inquiries!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.deepOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inquiries.length,
        itemBuilder: (context, index) {
          return _buildModernInquiryTile(inquiries[index], currentUserId);
        },
      ),
    );
  }

  Widget _buildModernInquiryTile(
      QueryDocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    final listingTitle = data['postTitle'] ?? 'Listing';
    final listingType = data['postType'] ?? 'accommodation';
    final city = data['city'] ?? '';
    final state = data['state'] ?? '';
    final seekerName = data['seekerName'] ?? 'Unknown';
    final posterName = data['posterName'] ?? 'Unknown';

    bool isPoster = currentUserId == data['posterId'];

    final timestamp =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeAgo = _getTimeAgo(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.to(() => ContextChatScreen(
                postId: data['postId'],
                postType: data['postType'],
                posterId: data['posterId'],
                seekerId: data['seekerId'],
                postTitle: data['postTitle'],
                city: city,
                state: state,
                posterName: posterName,
              ));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.orange.shade50,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(
                      listingType == 'job'
                          ? Icons.work_outline
                          : Icons.home_outlined,
                      color: Colors.deepOrange,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPoster ? seekerName : listingTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPoster
                              ? "Inquiry about: $listingTitle"
                              : "Posted by: $posterName",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.deepOrange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          listingType.toUpperCase(),
                          style: TextStyle(
                            color: Colors.deepOrange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      city.isNotEmpty && state.isNotEmpty
                          ? "$city, $state"
                          : city.isNotEmpty
                              ? city
                              : "Location not specified",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return "${(difference.inDays / 7).floor()}w ago";
    } else if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}
