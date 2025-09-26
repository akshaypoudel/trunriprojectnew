import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trunriproject/home/favourites/favourite_model.dart';
import 'package:trunriproject/home/favourites/favourite_provider.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this for opening Google Maps
import 'package:trunriproject/events/tickets/book_tickets.dart';
import 'package:trunriproject/home/constants.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final List<Map<String, dynamic>>? nearbyEvents;

  const EventDetailsScreen({
    super.key,
    required this.eventData,
    this.nearbyEvents,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  List? photoUrl;
  String? eventId;
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
  double? latitude;
  double? longitude;

  late Map<String, dynamic> data;

  // Optimized map controller management
  Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> markers = <Marker>{};
  bool _isMapReady = false;
  CameraPosition? _initialPosition;
  double _currentZoom = 15.0; // Track current zoom level

  @override
  void initState() {
    super.initState();
    data = widget.eventData;

    photoUrl = data['photo'] != null && data['photo'].isNotEmpty
        ? data['photo']
        : [Constants.PLACEHOLDER_IMAGE];
    eventName = data['eventName'];
    eventId = data['eventId'];
    eventDate = data['eventDate'];
    eventTime = data['eventTime'];
    location = data['location'];
    price = data['ticketPrice'];
    description = data['description'];
    category = data['category'] != null && data['category'].isNotEmpty
        ? data['category'][0]
        : 'Event';
    contactInfo = data['contactInformation'];
    eventType = data['eventType'] != null && data['eventType'].isNotEmpty
        ? data['eventType'][0]
        : 'Event';
    eventPosterName = data['eventPosterName'];

    // Get latitude and longitude from Firestore
    latitude = data['latitude']?.toDouble();
    longitude = data['longitude']?.toDouble();

    log('lat and long = $latitude, $longitude');

    // Pre-configure camera position and markers
    if (latitude != null && longitude != null) {
      _initialPosition = CameraPosition(
        target: LatLng(latitude!, longitude!),
        zoom: _currentZoom,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('event_location'),
          position: LatLng(latitude!, longitude!),
          infoWindow: InfoWindow(
            title: eventName ?? 'Event Location',
            snippet: location ?? 'Event venue',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController = Completer();
    super.dispose();
  }

  // NEW: Zoom in function
  void _zoomIn() async {
    final GoogleMapController controller = await _mapController.future;
    _currentZoom = (_currentZoom + 1).clamp(1.0, 20.0);
    controller.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  // NEW: Zoom out function
  void _zoomOut() async {
    final GoogleMapController controller = await _mapController.future;
    _currentZoom = (_currentZoom - 1).clamp(1.0, 20.0);
    controller.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  // NEW: Open in Google Maps function
  void _openInGoogleMaps() async {
    if (latitude != null && longitude != null) {
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      final String appleMapsUrl =
          'https://maps.apple.com/?q=$latitude,$longitude';

      try {
        // Try to open Google Maps app first
        final Uri googleMapsUri =
            Uri.parse('comgooglemaps://?q=$latitude,$longitude');
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri);
        } else {
          // Fallback to web version
          final Uri webUri = Uri.parse(googleMapsUrl);
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        log('Error opening maps: $e');
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool isFavorite = false;
  bool isBookmarked = false;
  final PageController _pageController = PageController();
  int currentPageIndex = 0;

  // Generate random attendee data
  List<String> generateAttendeeAvatars() {
    return List.generate(
        55,
        (index) =>
            'https://ui-avatars.com/api/?name=User${index + 1}&background=random');
  }

  @override
  Widget build(BuildContext context) {
    final attendeeAvatars = generateAttendeeAvatars();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Background
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    Share.share(
                        "Check out this event: $eventName at $eventTime on $eventDate");
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Consumer<FavouritesProvider>(
                  builder: (context, favProvider, child) {
                    // Remove FutureBuilder - just use local state directly
                    final isFavorited = favProvider.isFavouriteLocal(
                      eventId!,
                      FavouriteType.events,
                    );

                    return IconButton(
                      icon: Icon(
                        isFavorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        if (isFavorited) {
                          final success =
                              await favProvider.removeFromFavourites(
                            eventId!,
                            FavouriteType.events,
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from favorites'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          final success = await favProvider.addToFavourites(
                            eventId!,
                            FavouriteType.events,
                          );
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to favorites'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: photoUrl != null && photoUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: photoUrl!.length,
                          onPageChanged: (index) {
                            setState(() {
                              currentPageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: photoUrl![index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            );
                          },
                        ),
                        // Gradient overlay
                        Container(
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
                        // Page indicator
                        if (photoUrl!.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: photoUrl!.length,
                                effect: const WormEffect(
                                  dotColor: Colors.white54,
                                  activeDotColor: Colors.white,
                                  dotHeight: 8,
                                  dotWidth: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.event,
                          size: 100, color: Colors.grey),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventName ?? 'Event Name',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Category with rating
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text(
                                category ?? 'Public group',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                ...List.generate(
                                    4,
                                    (index) => const Icon(
                                          Icons.star,
                                          color: Colors.orange,
                                          size: 16,
                                        )),
                                const Icon(
                                  Icons.star_half,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '4.3',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Date and Time with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatEventDate(eventDate ?? ''),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${eventTime ?? 'Time'} AEST',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Location with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location?.split(',').first ?? 'Venue Name',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    location ?? 'Location not specified',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Like and Reply buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? Colors.red
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Like',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.reply,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Reply',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description ??
                              "One of our favourite venues, this location is available at late notice for all of our group to come and take over. Whilst this venue is relatively new on the scene, it is quickly becoming a favorite spot for events like this.",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            // Show more text
                          },
                          child: Text(
                            'Read more',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Hosting and Going sections
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hosting (2)',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        NetworkImage(attendeeAvatars[0]),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        NetworkImage(attendeeAvatars[1]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Going (55)',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ...List.generate(
                                      4,
                                      (index) => Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundImage: NetworkImage(
                                                  attendeeAvatars[index + 2]),
                                            ),
                                          )),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+51',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Who will be there section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.groups,
                              color: Colors.orange.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Who will be there',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.people_alt,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '21 members attending for the first time',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Learn more about who will be there',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ENHANCED: Location section with Google Maps, zoom controls, and directions button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          location?.split(',').first ?? 'Venue Name',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          location ?? 'Address not specified',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Exact meeting location provided after you join',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ENHANCED: Google Maps Widget with zoom controls and open in maps button
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: latitude != null &&
                                    longitude != null &&
                                    _initialPosition != null
                                ? Stack(
                                    children: [
                                      // Google Map
                                      GoogleMap(
                                        initialCameraPosition:
                                            _initialPosition!,
                                        markers: markers,
                                        onMapCreated: (GoogleMapController
                                            controller) async {
                                          if (!_mapController.isCompleted) {
                                            _mapController.complete(controller);

                                            await Future.delayed(const Duration(
                                                milliseconds: 100));
                                            if (mounted) {
                                              setState(() {
                                                _isMapReady = true;
                                              });
                                            }
                                          }
                                        },
                                        onCameraMove:
                                            (CameraPosition position) {
                                          _currentZoom = position.zoom;
                                        },
                                        mapType: MapType.normal,
                                        myLocationEnabled: false,
                                        myLocationButtonEnabled: false,
                                        zoomControlsEnabled: false,
                                        mapToolbarEnabled: false,
                                        compassEnabled: false,
                                        rotateGesturesEnabled: true,
                                        scrollGesturesEnabled: true,
                                        tiltGesturesEnabled: false,
                                        zoomGesturesEnabled: true,
                                        indoorViewEnabled: false,
                                        trafficEnabled: false,
                                        buildingsEnabled: true,
                                        liteModeEnabled: false,
                                      ),

                                      // NEW: Zoom Controls (Bottom Left)
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        child: Column(
                                          children: [
                                            // Zoom In Button
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  topRight: Radius.circular(4),
                                                ),
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade300),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: InkWell(
                                                onTap: _zoomIn,
                                                child: const Icon(
                                                  Icons.add,
                                                  color: Colors.black87,
                                                  size: 20,
                                                ),
                                              ),
                                            ),

                                            // Divider line
                                            Container(
                                              width: 40,
                                              height: 1,
                                              color: Colors.grey.shade300,
                                            ),

                                            // Zoom Out Button
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(4),
                                                  bottomRight:
                                                      Radius.circular(4),
                                                ),
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade300),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: InkWell(
                                                onTap: _zoomOut,
                                                child: const Icon(
                                                  Icons.remove,
                                                  color: Colors.black87,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // NEW: Open in Google Maps Button (Top Right)
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: InkWell(
                                            onTap: _openInGoogleMaps,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.directions,
                                                    color:
                                                        Colors.orange.shade600,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Directions',
                                                    style: TextStyle(
                                                      color: Colors
                                                          .orange.shade600,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_off,
                                            size: 40,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Location not available',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nearby Events Section
                  // if (widget.nearbyEvents != null &&
                  //     widget.nearbyEvents!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Similar events nearby',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to all nearby events
                              },
                              child: Text(
                                'See all',
                                style: TextStyle(
                                  color: Colors.orange.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Horizontal ListView of nearby events
                        SizedBox(
                          height: 280,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.nearbyEvents!.length,
                            itemBuilder: (context, index) {
                              final event = widget.nearbyEvents![index];
                              return _buildNearbyEventCard(event);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom button
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price == null || price!.isEmpty ? 'Free' : '\$$price',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '0 spots left',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
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
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          double price1 = 0;
                          if (price == null || price!.isEmpty) {
                            price1 = 0;
                          } else {
                            price1 = double.tryParse(price!) ?? 0;
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
                          'Join and RSVP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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

  // Build nearby event card widget
  Widget _buildNearbyEventCard(Map<String, dynamic> event) {
    final eventName = event['eventName'] ?? 'Event Name';
    final eventDate = event['eventDate'] ?? '';
    final eventTime = event['eventTime'] ?? '';
    final location = event['location'] ?? 'Location';
    final photoUrl = event['photo'] != null && event['photo'].isNotEmpty
        ? (event['photo'] is List ? event['photo'][0] : event['photo'])
        : Constants.PLACEHOLDER_IMAGE;
    final price = event['ticketPrice'] ?? '';

    return GestureDetector(
      onTap: () {
        Get.to(() => EventDetailsScreen(
              eventData: event,
              nearbyEvents: widget.nearbyEvents,
            ));
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.event, color: Colors.grey, size: 30),
                  ),
                ),
              ),
            ),

            // Event Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Time
                    Text(
                      '${_formatNearbyEventDate(eventDate)} • $eventTime',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Event Name
                    Text(
                      eventName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price and spots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price.isEmpty ? 'Free' : '\$$price',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Join',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNearbyEventDate(String date) {
    try {
      if (date.contains(' ')) {
        final parts = date.split(' ');
        final datePart = parts[1];
        final dateTime = DateTime.parse(datePart);
        final weekday = _getShortWeekday(dateTime.weekday);
        final day = dateTime.day;
        final month = _getShortMonth(dateTime.month);
        return '$weekday, $day $month';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  String _getShortWeekday(int weekday) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[(weekday - 1) % 7];
  }

  String _getShortMonth(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[(month - 1) % 12];
  }

  String _formatEventDate(String date) {
    try {
      if (date.contains(' ')) {
        final parts = date.split(' ');
        final datePart = parts[1];
        final dateTime = DateTime.parse(datePart);
        final weekday = _getWeekday(dateTime.weekday);
        final day = dateTime.day;
        final month = _getMonth(dateTime.month);
        final year = dateTime.year;
        return '$weekday, $day $month $year';
      }
      return date;
    } catch (e) {
      log('format error: $e');
      return date;
    }
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[(weekday - 1) % 7];
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[(month - 1) % 12];
  }
}
