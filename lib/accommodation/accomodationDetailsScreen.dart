import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:trunriproject/chat_module/context_chats/screens/context_chat_screen.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/home/bottom_bar.dart';
import 'package:trunriproject/imageviewer/full_screen_image_viewer.dart';
import 'package:trunriproject/widgets/helper.dart';

class AccommodationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> accommodation;

  const AccommodationDetailsScreen({super.key, required this.accommodation});

  @override
  State<AccommodationDetailsScreen> createState() =>
      _AccommodationDetailsScreenState();
}

class _AccommodationDetailsScreenState extends State<AccommodationDetailsScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int currentPageIndex = 0;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize PageController properly
    _pageController = PageController(initialPage: 0);

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.accommodation;
    final List<dynamic> images = data['images'] ?? [];

    final String postId = data['formID'] as String;
    const String postType = 'accommodation';
    final String posterId = data['uid'] as String;
    final String seekerId = _firebaseAuth.currentUser!.uid;
    final String postTitle = data['title'] as String;
    final String postCity = data['city'];
    final String postState = data['state'];
    final String posterName = data['posterName'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with gradient
          SliverAppBar(
            expandedHeight: 320.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageSlider(images, postTitle),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // actions: [
            //   Container(
            //     margin: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: Colors.white.withOpacity(0.9),
            //       borderRadius: BorderRadius.circular(12),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black.withOpacity(0.1),
            //           blurRadius: 8,
            //           offset: const Offset(0, 2),
            //         ),
            //       ],
            //     ),
            //     child: IconButton(
            //       icon:
            //           const Icon(Icons.favorite_border, color: Colors.black87),
            //       onPressed: () {
            //         // Add to favorites functionality
            //         Get.snackbar(
            //           'Favorites',
            //           'Added to favorites!',
            //           backgroundColor: Colors.deepOrange,
            //           colorText: Colors.white,
            //         );
            //       },
            //     ),
            //   ),
            // ],
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Title Section
                  _buildTitleSection(data),

                  // Quick Info Cards
                  _buildQuickInfoSection(data),

                  // Description Section
                  _buildDescriptionSection(data),

                  // Room Details Section
                  _buildRoomDetailsSection(data),

                  // Amenities Section
                  _buildAmenitiesSection(data),

                  // Preferences Section
                  _buildPreferencesSection(data),

                  // Services Section
                  _buildServicesSection(data),

                  // Availability Section
                  _buildAvailabilitySection(data),

                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(postId, postType, posterId,
          seekerId, postTitle, postCity, postState, posterName),
    );
  }

  Widget _buildImageSlider(List<dynamic> images, String title) {
    if (images.isEmpty) {
      return Container(
        height: 320,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF8A65), Color(0xFFFFAB40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_rounded, size: 80, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'No Images Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => currentPageIndex = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Get.to(
                    () => FullScreenImageViewer(
                      imageUrl: images[index],
                      title: title,
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepOrange),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),

          // Gradient overlay - IMPORTANT: Use IgnorePointer to not block gestures
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Page indicator - IMPORTANT: Use IgnorePointer
          if (images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: images.length,
                      effect: const WormEffect(
                        activeDotColor: Colors.white,
                        dotColor: Colors.white54,
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'No Title',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.deepOrange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${data['city'] ?? ''}, ${data['state'] ?? ''}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFFFAB40)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['roomType'] ?? 'Room',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoSection(Map<String, dynamic> data) {
    final priceRange = data['currentRangeValues'];
    final startPrice = priceRange?['start'] ?? 0;
    final endPrice = priceRange?['end'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickInfoCard(
              'Price Range',
              '₹$startPrice - ₹$endPrice',
              Icons.currency_rupee,
              const Color(0xFFFF8A65),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickInfoCard(
              'Bathrooms',
              '${data['bathrooms'] ?? 0}',
              Icons.bathtub,
              const Color(0xFFFFAB40),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickInfoCard(
              'Bedrooms',
              '${(data['singleBadRoom'] ?? 0) + (data['doubleBadRoom'] ?? 0)}',
              Icons.bed,
              const Color(0xFFFF7043),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> data) {
    return _buildSection(
      'Description',
      Icons.description,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['description'] ?? 'No description available',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetailsSection(Map<String, dynamic> data) {
    return _buildSection(
      'Room Details',
      Icons.home,
      Column(
        children: [
          _buildDetailRow('Single Bed Rooms', '${data['singleBadRoom'] ?? 0}',
              Icons.single_bed),
          _buildDetailRow('Double Bed Rooms', '${data['doubleBadRoom'] ?? 0}',
              Icons.king_bed),
          _buildDetailRow(
              'Bathrooms', '${data['bathrooms'] ?? 0}', Icons.bathtub),
          _buildDetailRow('Toilets', '${data['toilets'] ?? 0}', Icons.wc),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(Map<String, dynamic> data) {
    final roomAmenities =
        (data['roomAmenities'] as List?)?.cast<String>() ?? [];
    final propertyAmenities =
        (data['propertyAmenities'] as List?)?.cast<String>() ?? [];

    if (roomAmenities.isEmpty && propertyAmenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      'Amenities',
      Icons.star,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (roomAmenities.isNotEmpty) ...[
            Text(
              'Room Amenities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roomAmenities
                  .map((amenity) => _buildAmenityChip(amenity))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (propertyAmenities.isNotEmpty) ...[
            Text(
              'Property Amenities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: propertyAmenities
                  .map((amenity) => _buildAmenityChip(amenity))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(Map<String, dynamic> data) {
    final preferences = [
      if (data['isCouples'] == true) 'Couples',
      if (data['isStudents'] == true) 'Students',
      if (data['isEmployees'] == true) 'Employees',
      if (data['isFamilies'] == true) 'Families',
      if (data['isIndividuals'] == true) 'Individuals',
    ];

    if (preferences.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      'Perfect For',
      Icons.people,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            preferences.map((pref) => _buildPreferenceChip(pref)).toList(),
      ),
    );
  }

  Widget _buildServicesSection(Map<String, dynamic> data) {
    final services = [
      if (data['cleaningService'] == true) 'Cleaning Service',
      if (data['isLiftAvailable'] == true) 'Lift Available',
      if (data['gym'] == true) 'Gym',
      if (data['poolAccess'] == true) 'Pool Access',
      if (data['lawnCare'] == true) 'Lawn Care',
      if (data['maintenanceService'] == true) 'Maintenance',
    ];

    if (services.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      'Services',
      Icons.room_service,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            services.map((service) => _buildServiceChip(service)).toList(),
      ),
    );
  }

  Widget _buildAvailabilitySection(Map<String, dynamic> data) {
    return _buildSection(
      'Availability',
      Icons.calendar_today,
      Column(
        children: [
          if (data['selectedAvailabilityDate'] != null)
            _buildDetailRow(
              'Available From',
              (() {
                final value = data['selectedAvailabilityDate'];
                if (value is Timestamp) {
                  // Firestore Timestamp
                  return value.toDate().toString().split(' ')[0];
                } else if (value is String) {
                  // Already a string
                  return value.split(' ')[0];
                } else {
                  // Fallback in case it's null or unexpected type
                  return 'N/A';
                }
              })(),
              Icons.date_range,
            ),
          _buildDetailRow('Minimum Stay',
              data['selectedMinStay'] ?? 'Not specified', Icons.schedule),
          _buildDetailRow('Maximum Stay',
              data['selectedMaxStay'] ?? 'Not specified', Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.deepOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(String amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        amenity,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPreferenceChip(String preference) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        preference,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.green[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildServiceChip(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Text(
        service,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.purple[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
      String postId,
      String postType,
      String posterId,
      String seekerId,
      String postTitle,
      String postCity,
      String postState,
      String posterName) {
    final bool isOwner = posterId == AuthServices().getCurrentUser()!.uid;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A65), Color.fromARGB(255, 255, 168, 55)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                if (isOwner) {
                  Get.to(() => const MyBottomNavBar(index: 2, indexForChat: 0));
                } else {
                  Get.to(
                    () => ContextChatScreen(
                      postId: postId,
                      postType: postType,
                      posterId: posterId,
                      seekerId: seekerId,
                      postTitle: postTitle,
                      city: postCity,
                      state: postState,
                      posterName: posterName,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_rounded,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      isOwner ? 'See Who Inquired' : 'Inquire Now',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
