import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/chat_module/context_chats/screens/context_chat_screen.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/job/uploadResumeScreen.dart';

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const JobDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final companyName = data['companyName'];
    Timestamp jobPostDate = data['postDate'];
    final postId = data['postID'];
    final posterName = data['posterName'];
    final postTitle = data['positionName'];
    final postCity = data['city'];
    final postState = data['state'];
    final posterID = data['uid'];
    final seekerID = AuthServices().getCurrentUser()!.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(data['positionName'] ?? 'Job Details'),
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Position Title
                  Text(
                    data['companyName'] ?? 'Company Name',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Company and Address
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${data['city']}, ${data['state']}' ??
                              'No Address Available',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.orange),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          jobPostDate.toDate().toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Details Section
                  _infoCard(
                    icon: Icons.badge_outlined,
                    title: "Position",
                    value: data['positionName'] ?? 'No Position Available',
                  ),
                  _infoCard(
                    icon: Icons.category_outlined,
                    title: "Category",
                    value: data['category'] ?? 'No Category Available',
                  ),
                  _infoCard(
                    icon: Icons.work_outline,
                    title: "Experience",
                    value: data['experience'] ?? '',
                  ),
                  _infoCard(
                    icon: Icons.monetization_on_outlined,
                    title: "Salary",
                    value: data['salary'] ?? '',
                  ),
                  _infoCard(
                    icon: Icons.brush_outlined,
                    title: "Key Skills",
                    value: data['keySkills'] ?? 'No Skills Mentioned',
                  ),
                  _infoCard(
                    icon: Icons.business_center_sharp,
                    title: "Openings",
                    value: data['openings'] ?? '',
                  ),
                  _infoCard(
                    icon: Icons.apartment_outlined,
                    title: "Industry Type",
                    value: data['industryType'] ?? '',
                  ),
                  _infoCard(
                    icon: Icons.business_center_outlined,
                    title: "Employment Type",
                    value: data['employmentType'] ?? '',
                  ),
                  _infoCard(
                    icon: Icons.account_tree_outlined,
                    title: "Department",
                    value: data['department'] ?? '',
                  ),

                  const SizedBox(height: 20),

                  // Job Description
                  const Text(
                    "Job Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      data['jobDescription'] ?? '',
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),

                  const SizedBox(height: 20),

                  //company description

                  Text(
                    "About ${companyName ?? 'Company'}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      data['aboutCompany'] ??
                          'No Description Available for ${companyName ?? 'Company'}',
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          (posterID != AuthServices().getCurrentUser()!.uid)
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.to(
                              () => ContextChatScreen(
                                postId: postId,
                                postType: 'job',
                                posterId: posterID,
                                seekerId: seekerID,
                                postTitle: postTitle,
                                city: postCity,
                                state: postState,
                                posterName: posterName,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.question_answer_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Inquire Now",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // space between buttons
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.to(() => const UploadResumeScreen());
                          },
                          icon: const Icon(
                            Icons.upload_file_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Apply Now",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.to(() => const MyBottomNavBar(index: 2));
                      },
                      icon: const Icon(
                        Icons.upload_file_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "See Who Inquired",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(width: 10),
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
