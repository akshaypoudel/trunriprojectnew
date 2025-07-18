import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/job/addJobScreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'jobDetailsScreen.dart';
import 'jobFilterOption.dart';

class JobHomePageScreen extends StatefulWidget {
  const JobHomePageScreen({super.key});

  @override
  State<JobHomePageScreen> createState() => _JobHomePageScreenState();
}

class _JobHomePageScreenState extends State<JobHomePageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const JobFilterOptionScreen(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Jobs'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 Search for jobs...',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() {
                  _searchQuery = value.toLowerCase().trim();
                }),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Expanded(
                  //   child: ElevatedButton.icon(
                  //     onPressed: _showFilterBottomSheet,
                  //     icon: const Icon(Icons.filter_list),
                  //     label: const Text('Filter'),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.blueGrey.shade50,
                  //       foregroundColor: Colors.deepOrange,
                  //       elevation: 0,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(width: 10),
                  (provider.isUserSubscribed)
                      ? Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.to(const AddJobScreen()),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(
                              'Post a Job',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                              foregroundColor: Colors.deepOrangeAccent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 10),
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('jobs').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator(
                        color: Colors.orange);
                  }

                  var jobs = snapshot.data!.docs;

                  var filtered = _searchQuery.isEmpty
                      ? jobs
                      : jobs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          var position =
                              data['positionName']?.toString().toLowerCase() ??
                                  '';
                          return position.contains(_searchQuery);
                        }).toList();

                  // 🟠 Show message if no jobs match
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          '😕 No matching jobs found.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  // var filtered1 = snapshot.data!.docs.where((doc) {
                  //   var data = doc.data() as Map<String, dynamic>;
                  //   var position =
                  //       data['positionName']?.toString().toLowerCase() ?? '';
                  //   var desc =
                  //       data['jobDescription']?.toString().toLowerCase() ?? '';
                  //   return position.contains(_searchQuery) ||
                  //       desc.contains(_searchQuery);
                  // }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      var data = filtered[index].data() as Map<String, dynamic>;
                      final postDate = data['postDate']?.toDate();
                      final timeAgo = postDate != null
                          ? _getTimeAgo(postDate)
                          : 'Date unknown';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['positionName'] ?? 'Position',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.bookmark_border,
                                      color: Colors.deepOrange),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.business_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data['companyName'] ?? 'Company',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data['companyAddress'] ?? 'Location',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Experience & Salary
                              Row(
                                children: [
                                  const Icon(Icons.badge_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    data['experience'] ?? '-',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.monetization_on_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    data['salary'] ?? '-',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                data['jobDescription'] ?? '-',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),

                              // Footer Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    timeAgo,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    onPressed: () =>
                                        Get.to(JobDetailsScreen(data: data)),
                                    child: const Text("View Details"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime postDate) {
    final now = DateTime.now();
    final diff = now.difference(postDate);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }
}
