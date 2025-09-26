import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AddEventIdButton extends StatelessWidget {
  const AddEventIdButton({super.key});

  Future<void> addEventIds() async {
    final firestore = FirebaseFirestore.instance;
    // const uuid = Uuid();

    try {
      final querySnapshot = await firestore.collection("User").get();

      for (var doc in querySnapshot.docs) {
        // final newEventId = uuid.v4(); // Generate unique id

        await firestore.collection("User").doc(doc.id).update({
          "blockedUsers": [],
        });
      }

      log("✅ All users updated with blockedUsers field.");
    } catch (e) {
      log("❌ Error updating users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text("Add Unique Event IDs"),
      onPressed: () async {
        await addEventIds();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unique Event IDs added successfully!")),
        );
      },
    );
  }
}
