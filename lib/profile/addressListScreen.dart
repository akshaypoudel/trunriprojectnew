import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/home/provider/location_data.dart';
import 'package:trunriproject/widgets/helper.dart';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }
        if (!authSnap.hasData || authSnap.data == null) {
          return const Scaffold(
            body: Center(child: Text('User not logged in')),
          );
        }
        return const AddressListBody();
      },
    );
  }
}

class AddressListBody extends StatelessWidget {
  const AddressListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationData>();
    final isInAus = provider.isUserInAustralia;

    final addrMap = isInAus
        ? {
            'Street': provider.getUsersAddress.split(',')[0],
            'city': provider.getNativeCity,
            'town': provider.getNativeSuburb,
            'state': provider.getNativeState,
            'zipcode': provider.getNativeZipcode,
            'country': 'Australia',
            'fullAddress': provider.getUsersAddress,
          }
        : {
            'Street': provider.getUsersAddress.split(',')[0],
            'city': provider.getNativeCity,
            'town': provider.getNativeSuburb,
            'state': provider.getNativeState,
            'zipcode': provider.getNativeZipcode,
            'country': 'Australia',
            'fullAddress': provider.getUsersAddress,
          };

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'My Address',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 22, // Increased font size
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: Get.back,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with location icon - Fixed visibility
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors
                    .orange.shade800, // Darker orange for better text contrast
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Increased font size
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your saved address details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16, // Increased font size
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Street & City Card
            _ModernAddressCard(
              title: 'Location Details',
              icon: Icons.home_outlined,
              children: [
                _AddressItem(
                  icon: Icons.route,
                  label: 'Street',
                  value: addrMap['Street'] ?? '',
                ),
                _AddressItem(
                  icon: Icons.location_city,
                  label: 'City',
                  value: addrMap['city'] ?? '',
                ),
                _AddressItem(
                  icon: Icons.apartment,
                  label: 'Town/Suburb',
                  value: addrMap['town'] ?? '',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // State & Postal Code Card
            _ModernAddressCard(
              title: 'Regional Information',
              icon: Icons.map_outlined,
              children: [
                _AddressItem(
                  icon: Icons.account_balance,
                  label: 'State',
                  value: addrMap['state'] ?? '',
                ),
                _AddressItem(
                  icon: Icons.markunread_mailbox,
                  label: 'Postal Code',
                  value: addrMap['zipcode'] ?? '',
                ),
                _AddressItem(
                  icon: Icons.public,
                  label: 'Country',
                  value: addrMap['country'] ?? '',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Full Address Card
            _ModernAddressCard(
              title: 'Complete Address',
              icon: Icons.pin_drop_outlined,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.orange,
                          size: 18, // Slightly increased icon size
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          addrMap['fullAddress']?.isNotEmpty == true
                              ? addrMap['fullAddress']!
                              : 'Complete address not available',
                          style: TextStyle(
                            color: addrMap['fullAddress']?.isNotEmpty == true
                                ? Colors.black87
                                : Colors.grey.shade500,
                            fontSize: 17, // Increased font size
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ModernAddressCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ModernAddressCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.orange,
                    size: 22, // Increased icon size
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18, // Increased font size
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AddressItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.orange,
              size: 18, // Increased icon size
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14, // Increased font size
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not set',
                  style: TextStyle(
                    fontSize: 17, // Increased font size
                    fontWeight: FontWeight.w500,
                    color: value.isNotEmpty
                        ? Colors.black87
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
