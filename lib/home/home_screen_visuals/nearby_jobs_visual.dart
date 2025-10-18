import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/job/jobDetailsScreen.dart';

class NearbyJobsVisual extends StatelessWidget {
  const NearbyJobsVisual({super.key, required this.isInAustralia});
  final bool isInAustralia;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return SizedBox(
      // height: (isInAustralia) ? height * .37 : height * .35,
      height: height * .32,
      width: width,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoJobsWidget();
          }

          final jobList = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where((job) => job['isApproved'] == true)
              .toList();

          if (jobList.isEmpty) {
            return _buildNoJobsWidget();
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: jobList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              Map<String, dynamic> data = jobList[index];

              return Container(
                width: 265,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['positionName'] ?? 'No Position Mentioned',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    buildInfoRow(
                      icon: Icons.business,
                      value: data['companyName'] ?? 'No company name',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    buildInfoRow(
                      icon: Icons.location_on_outlined,
                      value: data['city'] ?? 'No city',
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    buildInfoRow(
                      icon: Icons.badge,
                      value: data['experience'] ?? 'No experience',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    buildInfoRow(
                      icon: Icons.school,
                      value: data['eduction'] ?? 'No education',
                      color: Colors.purple,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.to(JobDetailsScreen(data: data));
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.deepOrangeAccent, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrangeAccent,
                            fontSize: 15,
                          ),
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

  Widget _buildNoJobsWidget() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        Container(
          width: 200,
          margin: const EdgeInsets.symmetric(horizontal: 80),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepOrange.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_center,
                size: 46,
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

  Widget buildInfoRow({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
