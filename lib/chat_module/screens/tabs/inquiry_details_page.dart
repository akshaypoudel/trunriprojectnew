// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:trunriproject/chat_module/context_chats/screens/context_chat_screen.dart';

// class InquiryDetailsPage extends StatelessWidget {
//   const InquiryDetailsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;

//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('contextChats')
//           .where('seekerId', isEqualTo: currentUser!.uid)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final docs = snapshot.data?.docs ?? [];

//         if (docs.isEmpty) {
//           return const Center(child: Text('No previous inquiries yet.'));
//         }

//         return ListView.builder(
//           itemCount: docs.length,
//           itemBuilder: (context, index) {
//             final data = docs[index].data() as Map<String, dynamic>;
//             final listingTitle = data['postTitle'] ?? 'Listing';
//             final listingType = data['postType'] ?? 'accommodation';
//             final String address = '${data['city']},${data['state']}';

//             return Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.orange.withValues(alpha: 0.04),
//                       blurRadius: 5,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                   borderRadius: BorderRadius.circular(12),
//                   border: const Border.symmetric(
//                     vertical: BorderSide(color: Colors.black),
//                     horizontal: BorderSide(color: Colors.black),
//                   ),
//                 ),
//                 child: ListTile(
//                   leading: Icon(
//                     listingType == 'job'
//                         ? Icons.work_outline
//                         : Icons.home_outlined,
//                     color: Colors.orange,
//                   ),
//                   title: Text(listingTitle),
//                   subtitle: Text(
//                     address,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   trailing: Text(
//                     listingType,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   onTap: () {
//                     Get.to(
//                       () => ContextChatScreen(
//                         postId: data['postId'],
//                         postType: data['postType'],
//                         posterId: data['posterId'],
//                         seekerId: data['seekerId'],
//                         postTitle: data['postTitle'],
//                         city: data['city'],
//                         state: data['state'],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/chat_module/context_chats/screens/context_chat_screen.dart';

class InquiryDetailsPage extends StatelessWidget {
  const InquiryDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contextChats')
          .where(
            Filter.or(
              Filter('seekerId', isEqualTo: currentUser!.uid),
              Filter('posterId', isEqualTo: currentUser.uid),
            ),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];

        if (allDocs.isEmpty) {
          return const Center(child: Text('No inquiries yet.'));
        }

        final sentInquiries = allDocs
            .where((doc) => (doc['seekerId'] ?? '') == currentUser.uid)
            .toList();

        final receivedInquiries = allDocs
            .where((doc) => (doc['posterId'] ?? '') == currentUser.uid)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            if (sentInquiries.isNotEmpty) ...[
              const Text(
                'Inquiries I Sent',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...sentInquiries
                  .map((doc) => _buildInquiryTile(doc, currentUser.uid)),
              const SizedBox(height: 16),
            ],
            if (receivedInquiries.isNotEmpty) ...[
              const Text(
                'Inquiries I Received',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...receivedInquiries
                  .map((doc) => _buildInquiryTile(doc, currentUser.uid)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInquiryTile(QueryDocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    final listingTitle = data['postTitle'] ?? 'Listing';
    final listingType = data['postType'] ?? 'accommodation';
    final String address = '${data['city'] ?? ''}, ${data['state'] ?? ''}';
    final String city = data['city'];
    bool isPoster = currentUserId == data['posterId'];
    final seekerName = data['seekerName'];
    final posterName = data['posterName'];

    return (isPoster)
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
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
                border: Border.all(color: Colors.black),
              ),
              child: ListTile(
                leading: Icon(
                  listingType == 'job'
                      ? Icons.work_outline
                      : Icons.home_outlined,
                  color: Colors.orange,
                ),
                title: Text(seekerName),
                subtitle: Text(
                  '$listingTitle, $city',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  listingType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Get.to(
                    () => ContextChatScreen(
                      postId: data['postId'],
                      postType: data['postType'],
                      posterId: data['posterId'],
                      seekerId: data['seekerId'],
                      postTitle: data['postTitle'],
                      city: data['city'],
                      state: data['state'],
                      posterName: data['posterName'],
                    ),
                  );
                },
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.04),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black),
              ),
              child: ListTile(
                leading: Icon(
                  listingType == 'job'
                      ? Icons.work_outline
                      : Icons.home_outlined,
                  color: Colors.orange,
                ),
                title: (listingType == 'job')
                    ? Text(listingTitle)
                    : Text('$listingTitle, $city'),
                subtitle: Text(
                  'Posted by: $posterName, $city',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  listingType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Get.to(
                    () => ContextChatScreen(
                      postId: data['postId'],
                      postType: data['postType'],
                      posterId: data['posterId'],
                      seekerId: data['seekerId'],
                      postTitle: data['postTitle'],
                      city: data['city'],
                      state: data['state'],
                      posterName: data['posterName'],
                    ),
                  );
                },
              ),
            ),
          );
  }
}
