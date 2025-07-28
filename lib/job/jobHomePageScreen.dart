import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
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
  bool showOnlyMyJobs = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextField(
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
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
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showOnlyMyJobs = !showOnlyMyJobs;
                    });
                  },
                  icon: const Icon(Icons.list_alt),
                  label: Text(
                    showOnlyMyJobs ? 'Show All Jobs' : 'Jobs I Have Posted',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
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
                  if (showOnlyMyJobs) {
                    filtered = filtered.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['uid'] ==
                          AuthServices().getCurrentUser()!.uid;
                    }).toList();
                  }
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
                                  const Icon(
                                    Icons.bookmark_border,
                                    color: Colors.deepOrange,
                                  ),
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
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => Get.to(
                                      () => JobDetailsScreen(
                                        data: data,
                                      ),
                                    ),
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
