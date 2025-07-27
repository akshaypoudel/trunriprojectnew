import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:trunriproject/accommodation/subscribed_user/message_owner_for_non_subscribed.dart';
import 'package:trunriproject/chat_module/context_chats/screens/context_chat_screen.dart';

class AccommodationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> accommodation;

  const AccommodationDetailsScreen({super.key, required this.accommodation});

  @override
  State<AccommodationDetailsScreen> createState() =>
      _AccommodationDetailsScreenState();
}

class _AccommodationDetailsScreenState
    extends State<AccommodationDetailsScreen> {
  final PageController _pageController = PageController();
  int currentPageIndex = 0;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final data = widget.accommodation;
    final List<dynamic> images = data['images'] ?? [];

    final String postId = data['formID'] as String;
    const String postType = 'accommodation';
    final String posterId = data['uid'] as String; // host’s user ID
    final String seekerId = _firebaseAuth.currentUser!.uid;
    final String postTitle = data['Give your listing a title'] as String;

    Widget buildInfoCard(String label, String value, {IconData? icon}) {
      return Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: icon != null ? Icon(icon, color: Colors.orange) : null,
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "$label - ",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildBoolInfo(String label, bool value) {
      return buildInfoCard(label, value ? "Yes" : "No",
          icon: Icons.check_circle_outline);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: const Text("Accommodation Details"),
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🖼 Image slider
                  if (images.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (index) =>
                                setState(() => currentPageIndex = index),
                            itemBuilder: (_, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(images[index],
                                  fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: images.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Colors.orange,
                            dotColor: Colors.grey.shade400,
                            dotHeight: 8,
                            dotWidth: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // 🏠 Details
                  buildInfoCard(
                      "Title", data['Give your listing a title'] ?? 'No Title'),
                  buildInfoCard("Description",
                      data['Add a description'] ?? 'No Description'),
                  buildInfoCard("Address", data['fullAddress'] ?? ''),
                  buildInfoCard("City", data['city'] ?? ''),
                  buildInfoCard("State", data['state'] ?? ''),
                  buildInfoCard("Room Type", data['roomType'] ?? ''),
                  buildInfoCard("Price Range",
                      "${data['currentRangeValues']?['start'] ?? 0} - ${data['currentRangeValues']?['end'] ?? 0}"),

                  // Room Info
                  buildInfoCard("Bathrooms", "${data['bathrooms'] ?? 0}"),
                  buildInfoCard("Toilets", "${data['toilets'] ?? 0}"),
                  buildInfoCard(
                      "Single Bed Rooms", "${data['singleBadRoom'] ?? 0}"),
                  buildInfoCard(
                      "Double Bed Rooms", "${data['doubleBadRoom'] ?? 0}"),

                  // Preferences
                  buildBoolInfo("For Couples", data['isCouples'] ?? false),
                  buildBoolInfo("For Students", data['isStudents'] ?? false),
                  buildBoolInfo("For Employees", data['isEmployees'] ?? false),
                  buildBoolInfo("For Families", data['isFamilies'] ?? false),
                  buildBoolInfo(
                      "For Individuals", data['isIndividuals'] ?? false),

                  // Services
                  buildBoolInfo(
                      "Cleaning Service", data['cleaningService'] ?? false),
                  buildBoolInfo(
                      "Lift Available", data['isLiftAvailable'] ?? false),
                  buildBoolInfo("Gym", data['gym'] ?? false),
                  buildBoolInfo("Pool", data['poolAccess'] ?? false),
                  buildBoolInfo("Lawn Care", data['lawnCare'] ?? false),
                  buildBoolInfo(
                      "Maintenance", data['maintenanceService'] ?? false),

                  // Availability
                  if (data['selectedAvailabilityDate'] != null)
                    buildInfoCard("Available From",
                        data['selectedAvailabilityDate'].toDate().toString()),
                  buildInfoCard("Minimum Stay", data['selectedMinStay'] ?? '-'),
                  buildInfoCard("Maximum Stay", data['selectedMaxStay'] ?? '-'),

                  // Amenities
                  if (data['roomAmenities'] != null)
                    buildInfoCard("Room Amenities",
                        (data['roomAmenities'] as List).join(", ")),
                  if (data['propertyAmenities'] != null)
                    buildInfoCard("Property Amenities",
                        (data['propertyAmenities'] as List).join(", ")),

                  // Rules
                  if (data['homeRules'] != null)
                    buildInfoCard(
                        "Home Rules", (data['homeRules'] as List).join(", ")),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 📩 Message Owner Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // Get.to(()=>MessageOwnerScreen(ownerId: , ownerName: ownerName, propertyTitle: data['Give your listing a title'],),);
                  Get.to(
                    () => ContextChatScreen(
                      postId: postId,
                      postType: postType,
                      posterId: posterId,
                      seekerId: seekerId,
                      postTitle: postTitle,
                    ),
                  );
                },
                icon: const Icon(Icons.message_outlined),
                label: const Text(
                  "Message the Property Owner",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
