import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:trunriproject/chat_module/services/auth_service.dart';

class CreateAdvertisementScreen extends StatefulWidget {
  const CreateAdvertisementScreen({super.key});

  @override
  State<CreateAdvertisementScreen> createState() =>
      _CreateAdvertisementScreenState();
}

class _CreateAdvertisementScreenState extends State<CreateAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final Map<String, List<String>> australiaStatesWithCities = {
    'New South Wales': [
      'Sydney',
      'Newcastle',
      'Wollongong',
      'Albury',
      'Bathurst',
      'Coffs Harbour',
      'Dubbo',
      'Gosford',
      'Maitland',
      'Tamworth',
      'Wagga Wagga',
      'Nowra',
      'Orange',
      'Port Macquarie',
      'Lismore',
      'Tweed Heads',
      'Shellharbour',
      'Queanbeyan'
    ],
    'Victoria': [
      'Melbourne',
      'Geelong',
      'Ballarat',
      'Bendigo',
      'Shepparton',
      'Mildura',
      'Warrnambool',
      'Wodonga',
      'Traralgon',
      'Melton',
      'Sunbury',
      'Bacchus Marsh',
      'Horsham',
      'Echuca',
      'Wangaratta',
      'Sale'
    ],
    'Queensland': [
      'Brisbane',
      'Gold Coast',
      'Cairns',
      'Townsville',
      'Toowoomba',
      'Mackay',
      'Rockhampton',
      'Bundaberg',
      'Hervey Bay',
      'Caloundra',
      'Gladstone',
      'Ipswich',
      'Logan City',
      'Gympie',
      'Palm Cove',
      'Mount Isa',
      'Maryborough'
    ],
    'Western Australia': [
      'Perth',
      'Fremantle',
      'Bunbury',
      'Albany',
      'Kalgoorlie',
      'Geraldton',
      'Mandurah',
      'Broome',
      'Karratha',
      'Port Hedland',
      'Busselton'
    ],
    'South Australia': [
      'Adelaide',
      'Mount Gambier',
      'Murray Bridge',
      'Port Lincoln',
      'Whyalla',
      'Port Augusta',
      'Victor Harbor',
      'Gawler'
    ],
    'Tasmania': [
      'Hobart',
      'Launceston',
      'Devonport',
      'Burnie',
      'Ulverstone',
      'Kingston',
      'Glenorchy'
    ],
    'Northern Territory': [
      'Darwin',
      'Alice Springs',
      'Tennant Creek',
      'Katherine'
    ],
    'Australian Capital Territory': [
      'Canberra',
      'Belconnen',
      'Gungahlin',
      'Woden Valley',
      'Tuggeranong'
    ],
  };

  String? _selectedState;
  String? _selectedCity;

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController(text: 'AUD');
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  // final _cityController = TextEditingController();
  // final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'Australia');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _tagController = TextEditingController();

  // Form Data
  String _selectedType = 'service';
  final List<String> _selectedTags = [];
  final List<File> _selectedImages = [];
  final List<String> _uploadedImageUrls = [];

  final List<String> _adTypes = [
    'service',
    'restaurant',
    'retail',
    'event',
    'other'
  ];
  final List<String> _currencies = ['AUD'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tagController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Create Advertisement',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: Colors.deepOrange.withOpacity(0.3),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.deepOrangeAccent),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildBasicInfoPage(),
                _buildLocationPage(),
                _buildContactPage(),
                _buildImagesAndTagsPage(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepCircle(0, 'Basic Info'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Location'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Contact'),
          _buildStepLine(2),
          _buildStepCircle(3, 'Media'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String title) {
    final isActive = step <= _currentPage;
    final isCurrent = step == _currentPage;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.deepOrange : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent ? Colors.deepOrange : Colors.transparent,
                width: 3,
              ),
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.deepOrange : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32),
        color: step < _currentPage ? Colors.deepOrange : Colors.grey[300],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Information', Icons.info_rounded),
          const SizedBox(height: 24),
          _buildTextFormField(
            controller: _titleController,
            label: 'Advertisement Title',
            hint: 'Enter a catchy title for your ad',
            icon: Icons.title_rounded,
            validator: (value) =>
                value?.isEmpty == true ? 'Title is required' : null,
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Describe your offer in detail',
            icon: Icons.description_rounded,
            maxLines: 4,
            validator: (value) =>
                value?.isEmpty == true ? 'Description is required' : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextFormField(
                  controller: _priceController,
                  label: 'Price',
                  hint: '0',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Price is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _currencyController.text,
                  label: 'Currency',
                  items: _currencies,
                  onChanged: (value) =>
                      _currencyController.text = value ?? 'INR',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            value: _selectedType,
            label: 'Advertisement Type',
            items: _adTypes,
            onChanged: (value) =>
                setState(() => _selectedType = value ?? 'service'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Location Details', Icons.location_on_rounded),
          const SizedBox(height: 24),
          _buildTextFormField(
            controller: _addressController,
            label: 'Address',
            hint: 'Street address, building name, etc.',
            icon: Icons.home_rounded,
            maxLines: 2,
            validator: (value) =>
                value?.isEmpty == true ? 'Address is required' : null,
          ),
          const SizedBox(height: 20),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildTextFormField(
          //         controller: _cityController,
          //         label: 'City',
          //         hint: 'Enter city',
          //         icon: Icons.location_city_rounded,
          //         validator: (value) =>
          //             value?.isEmpty == true ? 'City is required' : null,
          //       ),
          //     ),
          //     const SizedBox(width: 16),
          //     Expanded(
          //       child: _buildTextFormField(
          //         controller: _stateController,
          //         label: 'State',
          //         hint: 'Enter state',
          //         icon: Icons.map_rounded,
          //         validator: (value) =>
          //             value?.isEmpty == true ? 'State is required' : null,
          //       ),
          //     ),
          //   ],
          // ),

          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'State',
                      labelStyle: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Colors.deepOrange, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    items: australiaStatesWithCities.keys
                        .map((state) => DropdownMenuItem(
                              value: state,
                              child: Text(
                                state,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                        // _cityController.clear();
                        _selectedCity = null;
                      });
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'State is required'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'City',
                      labelStyle: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: Colors.deepOrange, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    items: _selectedState == null
                        ? []
                        : australiaStatesWithCities[_selectedState!]!
                            .map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                    onChanged: _selectedState == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCity = value;
                            });
                          },
                    validator: (value) => value == null || value.isEmpty
                        ? 'City is required'
                        : null,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _countryController,
            label: 'Country',
            hint: 'Enter country',
            icon: Icons.public_rounded,
            validator: (value) =>
                value?.isEmpty == true ? 'Country is required' : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _latitudeController,
                  label: 'Latitude',
                  hint: '0.0',
                  icon: Icons.gps_fixed_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFormField(
                  controller: _longitudeController,
                  label: 'Longitude',
                  hint: '0.0',
                  icon: Icons.gps_fixed_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLocationButton(),
        ],
      ),
    );
  }

  Widget _buildContactPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Contact Information', Icons.contact_phone_rounded),
          const SizedBox(height: 24),
          _buildTextFormField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'your.email@example.com',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty == true) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value!)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+61 987654321',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value?.isEmpty == true ? 'Phone number is required' : null,
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _websiteController,
            label: 'Website (Optional)',
            hint: 'https://www.yourwebsite.com',
            icon: Icons.web_rounded,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesAndTagsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Images & Tags', Icons.image_rounded),
          const SizedBox(height: 24),
          _buildImageSection(),
          const SizedBox(height: 32),
          _buildTagsSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepOrange, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.deepOrange),
          labelStyle: const TextStyle(
            color: Colors.deepOrange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        focusColor: Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.deepOrange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 2),
      ),
      child: Material(
        color: Colors.deepOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _getCurrentLocation,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.my_location_rounded,
                    color: Colors.deepOrange, size: 24),
                SizedBox(width: 12),
                Text(
                  'Get Current Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedImages.isEmpty)
          _buildImagePickerButton()
        else
          _buildImageGrid(),
        const SizedBox(height: 16),
        _buildAddMoreImagesButton(),
      ],
    );
  }

  Widget _buildImagePickerButton() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pickImages,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Add Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap to select photos from gallery',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: FileImage(_selectedImages[index]),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddMoreImagesButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.3), width: 2),
      ),
      child: Material(
        color: Colors.deepOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pickImages,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded,
                    color: Colors.deepOrange, size: 24),
                const SizedBox(width: 12),
                Text(
                  _selectedImages.isEmpty ? 'Add Images' : 'Add More Images',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildTagInput(),
        const SizedBox(height: 16),
        if (_selectedTags.isNotEmpty) _buildTagsDisplay(),
      ],
    );
  }

  Widget _buildTagInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: _tagController,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Enter a tag',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon:
                    const Icon(Icons.tag_rounded, color: Colors.deepOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Colors.deepOrange, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              onFieldSubmitted: _addTag,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _addTag(_tagController.text),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            iconSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsDisplay() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _selectedTags
          .map((tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A65), Color(0xFFFFAB40)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: ElevatedButton(
                onPressed: _previousPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_currentPage < 3 ? _nextPage : _submitForm),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentPage < 3 ? 'Next' : 'Create Ad',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _titleController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty &&
            _priceController.text.isNotEmpty;
      case 1:
        return _addressController.text.isNotEmpty &&
            _selectedCity!.isNotEmpty &&
            _selectedState!.isNotEmpty &&
            _countryController.text.isNotEmpty;
      case 2:
        return _emailController.text.isNotEmpty &&
            _phoneController.text.isNotEmpty;
      case 3:
        return true; // Images and tags are optional
      default:
        return true;
    }
  }

  void _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty &&
        !_selectedTags.contains(tag.trim().toLowerCase())) {
      setState(() {
        _selectedTags.add(tag.trim().toLowerCase());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _getCurrentLocation() {
    // Implement location picker functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location picker functionality to be implemented'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  Future<void> _uploadImages() async {
    _uploadedImageUrls.clear();

    for (File image in _selectedImages) {
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('advertisements')
            .child('$fileName.jpg');

        UploadTask uploadTask = storageRef.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        _uploadedImageUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<void> _submitForm() async {
    // if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload images first
      await _uploadImages();

      // Create advertisement data
      final adData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'currency': _currencyController.text,
        'type': _selectedType,
        'contact': {
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'website': _websiteController.text.trim(),
        },
        'location': {
          'address': _addressController.text.trim(),
          'city': _selectedCity,
          'state': _selectedState,
          'country': _countryController.text.trim(),
          'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
        },
        'images': _uploadedImageUrls,
        'tags': _selectedTags,
        'isActive': true,
        'isApproved': false, // Requires approval
        'likes': 0,
        'views': 0,
        'ownerId':
            AuthServices().getCurrentUser()!.uid, // Replace with actual user ID
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('Advertisements').add(adData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Advertisement sent for review successfully, It will be published, as soon as it is approved'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating advertisement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
