import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Add this import
import 'package:trunriproject/events/tickets/book_tickets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trunriproject/widgets/helper.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const EventDetailsScreen({
    super.key,
    required this.eventData,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  List? photoUrl;
  String? eventName;
  String? eventTime;
  String? eventDate;
  String? location;
  String? price;
  String? description;
  String? category;
  String? contactInfo;
  String? eventType;
  String? eventPosterName;

  late Map<String, dynamic> data;

  @override
  void initState() {
    super.initState();
    data = widget.eventData;

    photoUrl = data['photo'] != null && data['photo'].isNotEmpty
        ? data['photo']
        : 'https://via.placeholder.com/400';
    eventName = data['eventName'];
    eventDate = data['eventDate'];
    eventTime = data['eventTime'];
    location = data['location'];
    price = data['ticketPrice'];
    description = data['description'];
    category = data['category'][0];
    contactInfo = data['contactInformation'];
    eventType = data['eventType'][0];
    eventPosterName = data['eventPosterName'];
  }

  bool isFavorite = false;
  final PageController _pageController = PageController();
  int currentPageIndex = 0;

  // Gradient for buttons
  static const LinearGradient _buttonGradient = LinearGradient(
    colors: [Colors.deepOrangeAccent, Colors.orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Event Details",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0), // Global Padding
          child: Column(
            children: [
              if (photoUrl != null && photoUrl!.isNotEmpty) ...[
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: photoUrl!.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentPageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: photoUrl![index],
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.deepOrangeAccent,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading image...',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Image not available',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: photoUrl!.length,
                    effect: ExpandingDotsEffect(
                      dotColor: Colors.grey.shade400,
                      activeDotColor: Colors.deepOrangeAccent, // Updated color
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 2,
                    ),
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    "assets/images/singing.jpeg",
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Title
                      Text(
                        eventName ?? 'Event Name',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle / Category
                      Text(
                        category ?? 'Organizer / Category',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date and Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.deepOrangeAccent,
                            size: 22,
                          ), // Updated color
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "${eventDate ?? 'Date'} at ${eventTime ?? 'Time'}",
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Location (Multi-line)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.deepOrangeAccent,
                            size: 22,
                          ), // Updated color
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              location ?? 'Location not specified',
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // About Section
                      Text(
                        "About",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description ?? "Description not added for this event.",
                        style: GoogleFonts.urbanist(
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Bottom Buttons with Gradient
              Row(
                children: [
                  // Buy Ticket - Gradient Button
                  Expanded(
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: _buttonGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrangeAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          double price1 = 0;
                          if (price!.isEmpty) {
                            price1 = 0;
                          } else {
                            price1 = price!.toNum.toDouble();
                          }
                          Get.to(
                            () => BuyTicketScreen(
                              eventName: eventName!,
                              ticketPrice: price1,
                              eventPosterName: eventPosterName ?? 'No Name',
                              eventDetails: {
                                'eventName': eventName!,
                                'eventDate': eventDate,
                                'eventTime': eventTime,
                                'address': location,
                              },
                            ),
                          );
                        },
                        child: const Text(
                          "Buy Ticket",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share - Outlined Button with Gradient Border Effect
                  Expanded(
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: _buttonGradient,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrangeAccent.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        margin:
                            const EdgeInsets.all(2), // Creates border effect
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            Share.share(
                                "Check out this event: $eventName at $eventTime on $eventDate");
                          },
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                _buttonGradient.createShader(bounds),
                            child: const Text(
                              "Share",
                              style: TextStyle(
                                color: Colors
                                    .white, // This will be masked by the gradient
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
