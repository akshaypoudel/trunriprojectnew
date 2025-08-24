import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trunriproject/accommodation/accomodationDetailsScreen.dart';
import 'package:trunriproject/ads/ads_details_screen.dart';
import 'package:trunriproject/ads/create_ad_screen.dart';
import 'package:trunriproject/events/eventDetailsScreen.dart';
import 'package:trunriproject/events/postEventScreen.dart';
import 'package:trunriproject/job/addJobScreen.dart';
import 'package:trunriproject/accommodation/whichYouListScreen.dart';
import 'package:trunriproject/job/jobDetailsScreen.dart';
import 'package:trunriproject/model/subscription_alert_dialog_box.dart';
import 'package:trunriproject/subscription/subscription_data.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  int selectedIndex = 0;

  final List<String> tabs = ["Events", "Jobs", "Housing", "Ads"];

  final LinearGradient gradient = const LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionData>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Listings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected ? gradient : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepOrangeAccent,
                          width: isSelected ? 0 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.deepOrangeAccent,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                _MyEventsTab(
                  provider: provider,
                  gradient: gradient,
                  currentUserId: currentUserId,
                ),
                _MyJobsTab(
                  gradient: gradient,
                  currentUserId: currentUserId,
                ),
                _MyAccommodationsTab(
                  gradient: gradient,
                  currentUserId: currentUserId,
                ),
                _MyAdsTab(
                  provider: provider,
                  gradient: gradient,
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Event Tab with beautiful listing
class _MyEventsTab extends StatelessWidget {
  final SubscriptionData provider;
  final LinearGradient gradient;
  final String currentUserId;

  const _MyEventsTab(
      {required this.provider,
      required this.gradient,
      required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('MakeEvent')
          .where('uid', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrangeAccent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyStateWidget(
            icon: Icons.event_note_rounded,
            label: "You haven't posted any events.",
            actionLabel: "Create Event",
            gradient: gradient,
            onAction: () {
              if (provider.isUserSubscribed) {
                Get.to(() => const PostEventScreen());
              } else {
                SubscriptionAlertDialogBox.showSubscriptionAlertDialogForEvents(
                    context);
              }
            },
          );
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final doc = events[index];
            final data = doc.data() as Map<String, dynamic>;

            return _EnhancedListingCard(
              title: data['eventName'] ?? 'Untitled Event',
              subtitle: data['location'] ?? 'No location',
              description: data['description'] ?? '',
              imageUrls:
                  (data['photo'] as List<dynamic>?)?.cast<String>() ?? [],
              publishedDate: data['timestamp'] as Timestamp?,
              gradient: gradient,
              type: 'Event',
              onTap: () {
                // Navigate to Event Details Screen
                Get.to(
                  () => EventDetailsScreen(
                    eventData: data,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Enhanced Jobs Tab
class _MyJobsTab extends StatelessWidget {
  final LinearGradient gradient;
  final String currentUserId;

  const _MyJobsTab({required this.gradient, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('uid', isEqualTo: currentUserId)
          .orderBy('postDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrangeAccent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyStateWidget(
            icon: Icons.work_outline_rounded,
            label: "You haven't posted any jobs.",
            actionLabel: "Post a Job",
            gradient: gradient,
            onAction: () {
              Get.to(() => const AddJobScreen());
            },
          );
        }

        final jobs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final doc = jobs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _EnhancedListingCard(
              title: data['positionName'] ?? 'Untitled Job',
              subtitle: data['companyName'] ?? 'Company not specified',
              description: data['jobDescription'] ?? '',
              imageUrls: const [],
              publishedDate: data['postDate'] as Timestamp?,
              gradient: gradient,
              type: 'job',
              onTap: () {
                // Navigate to Job Details Screen
                Get.to(() => JobDetailsScreen(data: data));
              },
            );
          },
        );
      },
    );
  }
}

// Enhanced Accommodation Tab
class _MyAccommodationsTab extends StatelessWidget {
  final LinearGradient gradient;
  final String currentUserId;

  const _MyAccommodationsTab(
      {required this.gradient, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('accommodation')
          .where('uid', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrangeAccent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyStateWidget(
            icon: Icons.hotel_rounded,
            label: "You haven't posted any accommodations.",
            actionLabel: "Add Accommodation",
            gradient: gradient,
            onAction: () {
              Get.to(() => const WhichYouListScreen());
            },
          );
        }

        final accommodations = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: accommodations.length,
          itemBuilder: (context, index) {
            final doc = accommodations[index];
            final data = doc.data() as Map<String, dynamic>;

            return _EnhancedListingCard(
              title: data['title'] ?? 'Accommodation',
              subtitle: data['fullAddress'] ?? 'Address not specified',
              description: data['description'] ?? '',
              imageUrls:
                  (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
              publishedDate: data['timestamp'] as Timestamp?,
              gradient: gradient,
              type: 'Accommodation',
              onTap: () {
                // Navigate to Accommodation Details Screen
                Get.to(
                  () => AccommodationDetailsScreen(
                    accommodation: data,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MyAdsTab extends StatelessWidget {
  final SubscriptionData provider;
  final LinearGradient gradient;
  final String currentUserId;

  const _MyAdsTab(
      {required this.provider,
      required this.gradient,
      required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Advertisements')
          .where('ownerId', isEqualTo: currentUserId)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrangeAccent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyStateWidget(
            icon: Icons.event_note_rounded,
            label: "You haven't posted any Ads.",
            actionLabel: "Create Ads",
            gradient: gradient,
            onAction: () {
              if (provider.isUserSubscribed) {
                Get.to(() => const CreateAdvertisementScreen());
              } else {
                SubscriptionAlertDialogBox.showSubscriptionAlertDialogForAds(
                  context,
                );
              }
            },
          );
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final doc = events[index];
            final data = doc.data() as Map<String, dynamic>;

            return _EnhancedListingCard(
              title: data['title'] ?? 'Untitled Advertisement',
              subtitle: data['location']['address'] ?? 'No location',
              description: data['description'] ?? '',
              imageUrls:
                  (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
              publishedDate: data['createdAt'] as Timestamp?,
              gradient: gradient,
              type: 'Ads',
              onTap: () {
                // Navigate to Event Details Screen
                Get.to(
                  () => AdvertisementDetailScreen(
                    adData: data,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Enhanced Beautiful Listing Card
class _EnhancedListingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final List<String> imageUrls;
  final Timestamp? publishedDate;
  final LinearGradient gradient;
  final String type;
  final VoidCallback onTap;

  const _EnhancedListingCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrls,
    required this.publishedDate,
    required this.gradient,
    required this.type,
    required this.onTap,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      _buildImageWidget(),
                      // Type badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Date badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(publishedDate),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle with icon
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (type == 'job') {
      return const SizedBox.shrink();
    }
    if (imageUrls.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[200]!,
              Colors.grey,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getTypeIcon(),
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrls.first,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 180,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.deepOrangeAccent,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[300]!,
              Colors.grey,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 48,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 8),
            Text(
              'Image Error',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (type.toLowerCase()) {
      case 'event':
        return Icons.event_rounded;
      case 'job':
        return Icons.work_rounded;
      case 'accommodation':
        return Icons.hotel_rounded;
      default:
        return Icons.image_rounded;
    }
  }
}

// Enhanced Empty State Widget (unchanged functionality, improved design)
class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onAction;
  final LinearGradient gradient;

  const _EmptyStateWidget({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onAction,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.deepOrangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrangeAccent.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.deepOrangeAccent,
                size: 50,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                ),
                onPressed: onAction,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
