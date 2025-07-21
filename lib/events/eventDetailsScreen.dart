import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trunriproject/widgets/helper.dart';

class EventDetailsScreen extends StatefulWidget {
  final List? photoUrl;
  final String? eventName;
  final String? eventDate;
  final String? eventTime;
  final String? location;
  final String? price;
  final String? description;
  final String? category;
  final String? contactInfo;
  final String? eventType;

  const EventDetailsScreen({
    super.key,
    this.eventDate,
    this.eventName,
    this.eventTime,
    this.location,
    this.photoUrl,
    this.price,
    this.description,
    this.category,
    this.contactInfo,
    this.eventType,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool isFavorite = false;
  final PageController _pageController = PageController();
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Event Details"),
        backgroundColor: Colors.grey.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.photoUrl!.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.photoUrl![index],
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.photoUrl!.length,
                  effect: ExpandingDotsEffect(
                    dotColor: Colors.grey.shade400,
                    activeDotColor: Colors.orange,
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
            Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(widget.eventName ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    leading:
                        const Icon(Icons.calendar_today, color: Colors.grey),
                    title: Text("${widget.eventDate} at ${widget.eventTime}",
                        style: GoogleFonts.urbanist(
                            fontSize: 16, color: Colors.grey[800])),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.grey),
                    title: Text(widget.location ?? '',
                        style: GoogleFonts.urbanist(
                            fontSize: 16, color: Colors.blue.shade700)),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.grey),
                    title: Text(
                        (widget.price!.contains("0"))
                            ? "Price: ${widget.price}"
                            : "Price: Free",
                        style: GoogleFonts.urbanist(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
                // const SizedBox(height: 10),
                const SizedBox(height: 10),
                if (widget.category != null && widget.category!.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.category, color: Colors.grey),
                      title: Text("Category: ${widget.category!}",
                          style: GoogleFonts.urbanist(
                              fontSize: 16, color: Colors.black87)),
                    ),
                  ),
                const SizedBox(height: 10),
                if (widget.contactInfo != null &&
                    widget.contactInfo!.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      leading:
                          const Icon(Icons.contact_phone, color: Colors.grey),
                      title: Text("Contact: ${widget.contactInfo!}",
                          style: GoogleFonts.urbanist(
                              fontSize: 16, color: Colors.black87)),
                    ),
                  ),
                const SizedBox(height: 10),
                if (widget.eventType != null && widget.eventType!.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.grey),
                      title: Text("Type: ${widget.eventType!}",
                          style: GoogleFonts.urbanist(
                              fontSize: 16, color: Colors.black87)),
                    ),
                  ),
                if (widget.description != null &&
                    widget.description!.isNotEmpty)
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            top: 8,
                            right: 8,
                            bottom: 5,
                          ),
                          child: Text(
                            'Event Description: ',
                            style: GoogleFonts.urbanist(
                              fontSize: 19,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.description, color: Colors.grey),
                          title: Text(widget.description!,
                              style: GoogleFonts.urbanist(
                                  fontSize: 16, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite,
                      color: isFavorite ? Colors.red : Colors.grey, size: 30),
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                    showSnackBar(
                        context,
                        isFavorite
                            ? 'Added to Favorites'
                            : 'Removed from Favorites');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.orange, size: 30),
                  onPressed: () {
                    Share.share(
                        "Check out this event: ${widget.eventName} at ${widget.eventTime} on ${widget.eventDate}");
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.map, color: Colors.green, size: 30),
                  onPressed: () async {
                    final Uri uri = Uri.parse(widget.location.toString());
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      showSnackBar(context, 'Could not open the map.');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: () {
                  showSnackBar(context, 'Ticket purchasing not implemented');
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      "Buy Ticket",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
