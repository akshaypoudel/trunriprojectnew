import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:trunriproject/chat_module/services/auth_service.dart';
import 'package:trunriproject/events/tickets/ticket_purchased_screen.dart';
import 'package:trunriproject/widgets/helper.dart';
import 'package:uuid/uuid.dart';

class BuyTicketScreen extends StatefulWidget {
  final String eventName;
  final String eventPosterName;
  final double ticketPrice;
  final Map<String, dynamic> eventDetails;

  const BuyTicketScreen({
    super.key,
    required this.eventName,
    required this.eventPosterName,
    required this.ticketPrice,
    required this.eventDetails,
  });

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  int numberOfTickets = 1;

  @override
  Widget build(BuildContext context) {
    double total = numberOfTickets * widget.ticketPrice;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Buy Ticket" Heading
            const Text(
              "Buy Ticket",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 28),
            // Event title and subtitle
            Text(
              widget.eventName,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 3),
            Text(
              widget.eventPosterName,
              style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF979797),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            // 'Number of tickets'
            const Text(
              "Number of tickets",
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Counter row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Minus button
                CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: IconButton(
                    icon: const Icon(Icons.remove, size: 26),
                    onPressed: numberOfTickets > 1
                        ? () {
                            setState(() {
                              numberOfTickets -= 1;
                            });
                          }
                        : null,
                    color: Colors.orange,
                  ),
                ),
                // Current ticket count
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    numberOfTickets.toString(),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Plus button
                CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 26),
                    onPressed: () {
                      setState(() {
                        if (numberOfTickets >= 10) {
                          showSnackBar(
                            context,
                            "Only 10 tickets at a time is allowed",
                          );
                        } else {
                          numberOfTickets += 1;
                        }
                      });
                    },
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            // Total price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                Text(
                  "\$${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFFA7A10), width: 1.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Uuid uid = const Uuid();
                        String ticketID = uid.v4();
                        Map<String, dynamic> newEntries = {
                          'ticketHolder':
                              AuthServices().getCurrentUserDisplayName(),
                          'numberOfTickets': numberOfTickets,
                          'ticketID': 'EVT-$ticketID',
                        };
                        Map<String, dynamic> updatedEventDetails = {
                          ...widget.eventDetails,
                          ...newEntries,
                        };
                        Get.to(
                          () => TicketPurchasedScreen(
                            eventDetails: updatedEventDetails,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFA7A10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w500),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text("Continue"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
