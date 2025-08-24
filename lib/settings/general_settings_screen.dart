import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Models for dynamic settings structure
class SettingsItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final SettingsItemType type;
  final VoidCallback? onTap;
  final bool? value; // For switches
  final String? currentValue; // For selections
  final List<String>? options; // For dropdowns
  final ValueChanged<bool>? onToggle; // For switches
  final ValueChanged<String>? onChanged; // For selections

  SettingsItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.type,
    this.onTap,
    this.value,
    this.currentValue,
    this.options,
    this.onToggle,
    this.onChanged,
  });
}

class SettingsSection {
  final String title;
  final List<SettingsItem> items;

  SettingsSection({
    required this.title,
    required this.items,
  });
}

enum SettingsItemType {
  navigation, // Arrow with onTap
  toggle, // Switch
  selection, // Shows current value with arrow
  info, // Just displays info
}

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  // Settings state variables - easily manageable
  bool _pushNotifications = true;
  bool _newEventsNearby = true;
  bool _jobAlerts = false;
  bool _restaurantDeals = true;
  bool _accommodationAvailability = true;
  bool _eventReminders = true;
  // final bool _searchHistory = true;
  // final bool _personalizedRecommendations = true;
  // final bool _locationSharing = false;
  final bool _profileVisibility = true;
  // final bool _dataCollection = false;
  // final bool _autoDownload = true;
  // final bool _backgroundRefresh = true;
  final bool _darkMode = false;

  String _searchRadius = '10km';
  String _language = 'English';
  final String _currency = 'INR';
  // final String _defaultHomeTab = 'Restaurants';
  // final String _mapStyle = 'Default';
  String _textSize = 'Medium';
  final String _distanceUnit = 'Kilometers';
  // final String _timeFormat = '12 Hour';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'General Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200],
            height: 1.0,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: _getSettingsSections().length,
        itemBuilder: (context, index) {
          final section = _getSettingsSections()[index];
          return Column(
            children: [
              _buildSettingsSection(section),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // Dynamic settings configuration - Easy to modify!
  List<SettingsSection> _getSettingsSections() {
    return [
      // Location & Search Settings
      SettingsSection(
        title: 'Location & Search',
        items: [
          SettingsItem(
            title: 'Search Radius',
            subtitle: 'How far to search for nearby places',
            icon: Icons.radar,
            type: SettingsItemType.selection,
            currentValue: _searchRadius,
            options: ['1km', '5km', '10km', '25km', '50km'],
            onChanged: (value) => setState(() => _searchRadius = value),
          ),
          SettingsItem(
            title: 'Default Location',
            subtitle: 'Set home/work locations',
            icon: Icons.home,
            type: SettingsItemType.navigation,
            onTap: () => _showComingSoonSnackbar('Default Location'),
          ),
        ],
      ),

      // Notifications Settings
      SettingsSection(
        title: 'Notifications',
        items: [
          SettingsItem(
            title: 'Push Notifications',
            subtitle: 'Master toggle for all notifications',
            icon: Icons.notifications,
            type: SettingsItemType.toggle,
            value: _pushNotifications,
            onToggle: (value) => setState(() => _pushNotifications = value),
          ),
          SettingsItem(
            title: 'New Events Nearby',
            subtitle: 'Get notified about events in your area',
            icon: Icons.event,
            type: SettingsItemType.toggle,
            value: _newEventsNearby,
            onToggle: (value) => setState(() => _newEventsNearby = value),
          ),
          SettingsItem(
            title: 'Job Alerts',
            subtitle: 'Notifications for new job postings',
            icon: Icons.work,
            type: SettingsItemType.toggle,
            value: _jobAlerts,
            onToggle: (value) => setState(() => _jobAlerts = value),
          ),
          SettingsItem(
            title: 'Restaurant Deals',
            subtitle: 'Special offers and discounts',
            icon: Icons.restaurant,
            type: SettingsItemType.toggle,
            value: _restaurantDeals,
            onToggle: (value) => setState(() => _restaurantDeals = value),
          ),
          SettingsItem(
            title: 'Accommodation Availability',
            subtitle: 'New listings notifications',
            icon: Icons.hotel,
            type: SettingsItemType.toggle,
            value: _accommodationAvailability,
            onToggle: (value) =>
                setState(() => _accommodationAvailability = value),
          ),
          SettingsItem(
            title: 'Event Reminders',
            subtitle: 'Reminders for saved events',
            icon: Icons.alarm,
            type: SettingsItemType.toggle,
            value: _eventReminders,
            onToggle: (value) => setState(() => _eventReminders = value),
          ),
        ],
      ),

      // Display & Interface
      SettingsSection(
        title: 'Display & Interface',
        items: [
          // SettingsItem(
          //   title: 'Dark Mode',
          //   subtitle: 'Switch to dark theme',
          //   icon: Icons.dark_mode,
          //   type: SettingsItemType.toggle,
          //   value: _darkMode,
          //   onToggle: (value) => setState(() => _darkMode = value),
          // ),
          SettingsItem(
            title: 'Language',
            subtitle: 'App language preferences',
            icon: Icons.language,
            type: SettingsItemType.selection,
            currentValue: _language,
            options: ['English'],
            onChanged: (value) => setState(() => _language = value),
          ),
          SettingsItem(
            title: 'Text Size',
            subtitle: 'Font size adjustment',
            icon: Icons.text_fields,
            type: SettingsItemType.selection,
            currentValue: _textSize,
            options: ['Small', 'Medium', 'Large', 'Extra Large'],
            onChanged: (value) => setState(() => _textSize = value),
          ),
        ],
      ),

      // Content & Preferences
      // SettingsSection(
      //   title: 'Content & Preferences',
      //   items: [
      //     SettingsItem(
      //       title: 'Default Home Tab',
      //       subtitle: 'Choose which category opens first',
      //       icon: Icons.home_filled,
      //       type: SettingsItemType.selection,
      //       currentValue: _defaultHomeTab,
      //       options: [
      //         'Restaurants',
      //         'Events',
      //         'Jobs',
      //         'Accommodation',
      //         'Temples'
      //       ],
      //       onChanged: (value) => setState(() => _defaultHomeTab = value),
      //     ),
      //     SettingsItem(
      //       title: 'Search History',
      //       subtitle: 'Save your search history',
      //       icon: Icons.history,
      //       type: SettingsItemType.toggle,
      //       value: _searchHistory,
      //       onToggle: (value) => setState(() => _searchHistory = value),
      //     ),
      //     SettingsItem(
      //       title: 'Personalized Recommendations',
      //       subtitle: 'Based on your activity',
      //       icon: Icons.thumb_up,
      //       type: SettingsItemType.toggle,
      //       value: _personalizedRecommendations,
      //       onToggle: (value) =>
      //           setState(() => _personalizedRecommendations = value),
      //     ),
      //     SettingsItem(
      //       title: 'Favorite Categories',
      //       subtitle: 'Manage your preferred categories',
      //       icon: Icons.favorite,
      //       type: SettingsItemType.navigation,
      //       onTap: () => _showComingSoonSnackbar('Favorite Categories'),
      //     ),
      //     SettingsItem(
      //       title: 'Filter Preferences',
      //       subtitle: 'Save common search filters',
      //       icon: Icons.filter_list,
      //       type: SettingsItemType.navigation,
      //       onTap: () => _showComingSoonSnackbar('Filter Preferences'),
      //     ),
      //   ],
      // ),

      // Privacy & Security
      // SettingsSection(
      //   title: 'Privacy & Security',
      //   items: [
      //     // SettingsItem(
      //     //   title: 'Location Sharing',
      //     //   subtitle: 'Control who sees your location',
      //     //   icon: Icons.location_on,
      //     //   type: SettingsItemType.toggle,
      //     //   value: _locationSharing,
      //     //   onToggle: (value) => setState(() => _locationSharing = value),
      //     // ),
      //     SettingsItem(
      //       title: 'Profile Visibility',
      //       subtitle: 'Public/private profile settings',
      //       icon: Icons.visibility,
      //       type: SettingsItemType.toggle,
      //       value: _profileVisibility,
      //       onToggle: (value) => setState(() => _profileVisibility = value),
      //     ),
      //     // SettingsItem(
      //     //   title: 'Data Collection',
      //     //   subtitle: 'Analytics and tracking preferences',
      //     //   icon: Icons.analytics,
      //     //   type: SettingsItemType.toggle,
      //     //   value: _dataCollection,
      //     //   onToggle: (value) => setState(() => _dataCollection = value),
      //     // ),
      //     // SettingsItem(
      //     //   title: 'Two-Factor Authentication',
      //     //   subtitle: 'Enhanced security',
      //     //   icon: Icons.security,
      //     //   type: SettingsItemType.navigation,
      //     //   onTap: () => _showComingSoonSnackbar('Two-Factor Authentication'),
      //     // ),
      //   ],
      // ),

      // Data & Storage
      // SettingsSection(
      //   title: 'Data & Storage',
      //   items: [
      //     // SettingsItem(
      //     //   title: 'Auto-Download',
      //     //   subtitle: 'Images/maps on WiFi only',
      //     //   icon: Icons.download,
      //     //   type: SettingsItemType.toggle,
      //     //   value: _autoDownload,
      //     //   onToggle: (value) => setState(() => _autoDownload = value),
      //     // ),
      //     // SettingsItem(
      //     //   title: 'Background Refresh',
      //     //   subtitle: 'Limit background activity',
      //     //   icon: Icons.refresh,
      //     //   type: SettingsItemType.toggle,
      //     //   value: _backgroundRefresh,
      //     //   onToggle: (value) => setState(() => _backgroundRefresh = value),
      //     // ),
      //     SettingsItem(
      //       title: 'Cache Settings',
      //       subtitle: 'Clear app cache',
      //       icon: Icons.clear_all,
      //       type: SettingsItemType.navigation,
      //       onTap: () => _showClearCacheDialog(),
      //     ),
      //     SettingsItem(
      //       title: 'Storage Management',
      //       subtitle: 'Manage app storage',
      //       icon: Icons.storage,
      //       type: SettingsItemType.navigation,
      //       onTap: () => _showComingSoonSnackbar('Storage Management'),
      //     ),
      //   ],
      // ),

      // Regional Settings
      // SettingsSection(
      //   title: 'Regional Settings',
      //   items: [
      //     SettingsItem(
      //       title: 'Currency Display',
      //       subtitle: 'Local currency for prices',
      //       icon: Icons.currency_rupee,
      //       type: SettingsItemType.selection,
      //       currentValue: _currency,
      //       options: [
      //         'AUD',
      //         'USD',
      //       ],
      //       onChanged: (value) => setState(() => _currency = value),
      //     ),
      //     SettingsItem(
      //       title: 'Distance Units',
      //       subtitle: 'Kilometers or miles',
      //       icon: Icons.straighten,
      //       type: SettingsItemType.selection,
      //       currentValue: _distanceUnit,
      //       options: ['Kilometers', 'Miles'],
      //       onChanged: (value) => setState(() => _distanceUnit = value),
      //     ),
      //     // SettingsItem(
      //     //   title: 'Time Format',
      //     //   subtitle: '12 or 24 hour format',
      //     //   icon: Icons.access_time,
      //     //   type: SettingsItemType.selection,
      //     //   currentValue: _timeFormat,
      //     //   options: ['12 Hour', '24 Hour'],
      //     //   onChanged: (value) => setState(() => _timeFormat = value),
      //     // ),
      //   ],
      // ),
    ];
  }

  Widget _buildSettingsSection(SettingsSection section) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              section.title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...section.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == section.items.length - 1;
            return _buildSettingsItem(item, !isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(SettingsItem item, bool showDivider) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.type == SettingsItemType.navigation
                ? item.onTap
                : item.type == SettingsItemType.selection
                    ? () => _showSelectionDialog(item)
                    : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: Colors
                          .deepOrangeAccent, // Only icons get orange color
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87, // Black text
                          ),
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600], // Gray subtitle
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildTrailingWidget(item),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 76),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[100],
            ),
          ),
      ],
    );
  }

  Widget _buildTrailingWidget(SettingsItem item) {
    switch (item.type) {
      case SettingsItemType.toggle:
        return Switch(
          value: item.value ?? false,
          onChanged: item.onToggle,
          activeColor: Colors.deepOrangeAccent, // Orange for active switch
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[400],
        );

      case SettingsItemType.selection:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.currentValue ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        );

      case SettingsItemType.navigation:
        return Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        );

      case SettingsItemType.info:
      default:
        return const SizedBox.shrink();
    }
  }

  void _showSelectionDialog(SettingsItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: item.options?.map((option) {
                  final isSelected = option == item.currentValue;
                  return ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.deepOrange : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.deepOrange)
                        : null,
                    onTap: () {
                      item.onChanged?.call(option);
                      Navigator.pop(context);
                    },
                  );
                }).toList() ??
                [],
          ),
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Clear Cache',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'This will clear all cached data including images and temporary files. This action cannot be undone.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Get.snackbar(
                  'Cache Cleared',
                  'App cache has been cleared successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  borderRadius: 8,
                  margin: const EdgeInsets.all(16),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonSnackbar(String feature) {
    Get.snackbar(
      'Coming Soon',
      '$feature feature will be available in the next update',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.deepOrange,
      colorText: Colors.white,
      borderRadius: 8,
      margin: const EdgeInsets.all(16),
    );
  }
}
