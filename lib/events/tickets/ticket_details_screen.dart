import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketDetailsScreen extends StatelessWidget {
  const TicketDetailsScreen({super.key, required this.eventDetails});
  final Map<String, dynamic> eventDetails;

  @override
  Widget build(BuildContext context) {
    log('eventdetail = $eventDetails');
    const accent = Colors.orange;
    final eventName = eventDetails['eventName'];
    final eventDate = eventDetails['eventDate'];
    final eventTime = eventDetails['eventTime'];
    final eventLocation = eventDetails['address'];
    final ticketId = eventDetails['ticketID'];
    final ticketHolder = eventDetails['ticketHolder'];
    final numTickets = eventDetails['numberOfTickets'].toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Your Ticket'),
        leading: const BackButton(color: Colors.black),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stylized event icon
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 22),
              // Event Name
              Text(
                eventName,
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Event date/time row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    eventDate,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    eventTime,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Venue
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on,
                      size: 18, color: Colors.black54),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      eventLocation,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 10,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1.1),
              // Ticket details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TicketInfoRow(label: 'Holder', value: ticketHolder),
                  // _TicketInfoRow(label: 'Ticket No', value: ticketId),
                  _TicketInfoRow(label: 'Qty', value: numTickets),
                ],
              ),
              const SizedBox(height: 24),
              // Barcode area (mocked)
              Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: QrImageView(
                  data: 'Ticket ID: ${eventDetails['ticketID']}',
                  version: QrVersions.auto,
                  errorStateBuilder: (context, error) {
                    return const Center(
                      child: Text(
                        'Uh oh! Something went wrong...',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                  size: 140,
                ),
              ),
              const SizedBox(height: 18),
              // Download Ticket Button (optional)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Add your download/share PDF/image logic here
                  },
                  child: const Text(
                    "Thanks For Booking this Event Ticket",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _TicketInfoRow({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
      ],
    );
  }
}
