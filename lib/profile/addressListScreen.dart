import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body:
                Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('User not logged in')),
          );
        }

        final user = snapshot.data!;
        return AddressListBody(user: user);
      },
    );
  }
}

class AddressListBody extends StatefulWidget {
  final User user;

  const AddressListBody({super.key, required this.user});

  @override
  State<AddressListBody> createState() => _AddressListBodyState();
}

class _AddressListBodyState extends State<AddressListBody> {
  List<DocumentSnapshot> restaurants = [];

  Future<void> _fetchUserRestaurants() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('nativeAddress')
        .where('userId', isEqualTo: widget.user.uid)
        .get();

    setState(() {
      restaurants = querySnapshot.docs;
    });
  }

  @override
  void initState() {
    super.initState();
    log('InitState: Authenticated user UID: ${widget.user.uid}');
    _fetchUserRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 5,
        backgroundColor: Colors.white,
        title: const Text('Address List'),
        leading: GestureDetector(
          onTap: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back_ios,
            size: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 15, top: 10),
              child: Text(
                'Native Address',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
            ),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('nativeAddress')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.orange));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Native address not found'));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                return buildAddressCard(userData);
              },
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.only(left: 15, top: 10),
              child: Text(
                'Current Address',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
            ),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('currentLocation')
                  .doc(userId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.orange));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Current address not found'));
                }

                var userData = snapshot.data!.data() as Map<String, dynamic>;
                return buildAddressCard(userData);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAddressCard(Map<String, dynamic> userData) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: Get.width,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.grey.shade100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Street: ${userData['Street']}'),
                Text('City: ${userData['city']}'),
                Text('Town: ${userData['town']}'),
                Text('State: ${userData['state']}'),
                Text('Zipcode: ${userData['zipcode']}'),
                Text('Country: ${userData['country']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
