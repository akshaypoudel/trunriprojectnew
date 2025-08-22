import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:trunriproject/ads/ads_details_screen.dart';
// Import your advertisement detail screen

class GetBannersVisual extends StatelessWidget {
  const GetBannersVisual({super.key, required this.onPageChanged});
  final Function(int, CarouselPageChangedReason) onPageChanged;

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Changed from 'banners' to 'advertisements' collection
      stream: FirebaseFirestore.instance
          .collection('Advertisements')
          .where('isActive', isEqualTo: true) // Only show active ads
          .where('isApproved', isEqualTo: true) // Only show approved ads
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'No Ads Available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        // Convert documents to advertisement data maps
        List<Map<String, dynamic>> advertisements =
            snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id; // Add document ID for reference
          return data;
        }).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CarouselSlider.builder(
            itemCount: advertisements.length,
            itemBuilder: (context, index, realIndex) {
              final advertisement = advertisements[index];
              final images = advertisement['images'] as List<dynamic>?;
              final imageUrl = (images != null && images.isNotEmpty)
                  ? images[0].toString()
                  : '';

              return GestureDetector(
                onTap: () {
                  // Navigate to Advertisement Detail Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdvertisementDetailScreen(
                        adData: advertisement,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Image
                      imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported,
                                          color: Colors.grey, size: 40),
                                      SizedBox(height: 8),
                                      Text('Image not available',
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 180,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image,
                                        color: Colors.grey, size: 40),
                                    SizedBox(height: 8),
                                    Text('No image available',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),

                      // Price badge (top right)
                      if (advertisement['price'] != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${advertisement['currency'] ?? 'INR'} ${advertisement['price']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      // Type badge (top left)
                      if (advertisement['type'] != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              advertisement['type'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),

                      // Gradient + Text overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                advertisement['title'] ?? 'Advertisement',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (advertisement['description'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  advertisement['description'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              // Location info
                              if (advertisement['location'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${advertisement['location']['city'] ?? ''}, ${advertisement['location']['state'] ?? ''}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Tap to view indicator
                      Positioned(
                        top: 8,
                        right: 8,
                        left: 8,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 14,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to view details',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 180, // Fixed height for consistency
              viewportFraction: 1.0,
              enlargeCenterPage: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayCurve: Curves.easeInOut,
              onPageChanged: onPageChanged,
            ),
          ),
        );
      },
    );
  }
}

class BannerWithDotsWidget extends StatelessWidget {
  const BannerWithDotsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final RxInt sliderIndex = 0.obs;

    return Column(
      children: [
        // Your existing GetBannersVisual widget
        GetBannersVisual(
          onPageChanged: (index, reason) {
            sliderIndex.value = index;
          },
        ),

        const SizedBox(height: 16),

        // Dots Indicator with dynamic count
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Advertisements')
              .where('isActive', isEqualTo: true)
              .where('isApproved', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final advertisementsCount = snapshot.data!.docs.length;

            return Obx(() => DotsIndicator(
                  dotsCount: advertisementsCount,
                  position: sliderIndex.value.toInt(),
                  decorator: DotsDecorator(
                    activeColor: Colors.orange,
                    size: const Size.square(8.0),
                    activeSize: const Size(18.0, 8.0),
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    color: Colors.grey.shade300,
                    spacing: const EdgeInsets.symmetric(horizontal: 4.0),
                  ),
                ));
          },
        ),
      ],
    );
  }
}
