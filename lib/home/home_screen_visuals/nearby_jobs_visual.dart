import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:trunriproject/job/jobDetailsScreen.dart';

class NearbyJobsVisual extends StatelessWidget {
  const NearbyJobsVisual({super.key, required this.isInAustralia});
  final bool isInAustralia;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: (isInAustralia) ? height * .32 : height * .26,
      width: width,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 100),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.business_center,
                        size: 48,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (isInAustralia) ? 'No Jobs Nearby' : 'No Jobs Found',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isInAustralia
                            ? 'Try expanding your radius or check another suburb'
                            : 'Select a different suburb in Australia to find Jobs',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    buildInfoRow(
                      icon: Icons.business,
                      label: "Company:",
                      value: data['companyName'] ?? 'No company name',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    buildInfoRow(
                      icon: Icons.badge,
                      label: "Position:",
                      value: data['positionName'] ?? 'No Position Mentioned',
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    buildInfoRow(
                      icon: Icons.school,
                      label: "Education:",
                      value: data['eduction'] ?? 'No education',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    buildInfoRow(
                      icon: Icons.work_outline,
                      label: "Employment Type:",
                      value: data['employmentType'] ?? 'No employment type',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(JobDetailsScreen(data: data));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          elevation: 15,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            maxLines: 1,
            text: TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
