import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TicketDetailsScreen extends StatelessWidget {
  const TicketDetailsScreen({super.key, required this.eventDetails});
  final Map<String, dynamic> eventDetails;

  static const LinearGradient _buttonGradient = LinearGradient(
    colors: [Colors.deepOrangeAccent, Colors.orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    log('eventdetail = $eventDetails');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Your Ticket'),
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ticketUI(),
            const SizedBox(height: 25),
            // Download Ticket Button (optional)

            SizedBox(
              width: 250,
              height: 60,
              child: TextButton(
                onPressed: () async {
                  final pdf = pw.Document();

                  pdf.addPage(
                    pw.Page(
                      pageFormat: PdfPageFormat.a4,
                      build: (context) => buildPdfTicket(eventDetails),
                    ),
                  );

                  await Printing.layoutPdf(
                    onLayout: (format) async => pdf.save(),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, // Important for full coverage
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF9800),
                        Color(0xFFFF5722)
                      ], // Orange gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    child: const Text(
                      "Download Ticket",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  pw.Widget buildPdfTicket(Map<String, dynamic> event) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: 20),
          pw.Text(event['eventName'] ?? '',
              style:
                  pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('${event['eventDate']}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(width: 20),
              pw.Text('${event['eventTime']}',
                  style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('${event['address']}',
                  style: const pw.TextStyle(
                      fontSize: 13, color: PdfColors.grey800)),
            ],
          ),
          pw.Divider(thickness: 1.2),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Holder:',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    event['ticketHolder'] ?? '',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Qty:',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey600)),
                  pw.Text('${event['numberOfTickets']}',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: 'Ticket ID: ${event['ticketID']}',
              width: 120,
              height: 120,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Thanks for buying Ticket from TruNri.',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget ticketUI() {
    const accent = Colors.orange;
    final eventName = eventDetails['eventName'];
    final eventDate = eventDetails['eventDate'];
    final eventTime = eventDetails['eventTime'];
    final eventLocation = eventDetails['address'];
    final ticketId = eventDetails['ticketID'];
    final ticketHolder = eventDetails['ticketHolder'];
    final numTickets = eventDetails['numberOfTickets'].toString();
    return Center(
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
                // color: accent,
                gradient: _buttonGradient,
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
                const Icon(Icons.location_on, size: 18, color: Colors.black54),
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
          ],
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
