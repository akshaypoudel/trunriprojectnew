import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:trunriproject/accommodation/accomodationDetailsScreen.dart';
import 'package:trunriproject/accommodation/whichYouListScreen.dart';
import 'package:trunriproject/subscription/subscription_data.dart';
import 'filterOptionScreen.dart';

class LookingForAPlaceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> accommodationList;

  const LookingForAPlaceScreen({super.key, required this.accommodationList});

  @override
  State<LookingForAPlaceScreen> createState() => _LookingForAPlaceScreenState();
}

class _LookingForAPlaceScreenState extends State<LookingForAPlaceScreen> {
  final List<String> cityList = [
    'All',
    'Delhi',
    'Mumbai',
    'Bangalore',
    'Noida',
    'Kolkata',
    'Chennai',
    'Hyderabad'
  ];

  final List<String> cityImages = [
    'https://cdn.pixabay.com/photo/2019/04/07/07/52/taj-mahal-4109110_1280.jpg',
    'https://cdn.pixabay.com/photo/2022/08/19/15/21/akshardham-7397135_1280.jpg',
    'https://cdn.pixabay.com/photo/2010/11/29/india-294_1280.jpg',
    'https://cdn.pixabay.com/photo/2017/12/17/13/10/architecture-3024174_1280.jpg',
    'https://cdn.pixabay.com/photo/2023/06/08/05/36/sunset-8048741_1280.jpg',
    'https://cdn.pixabay.com/photo/2017/06/12/08/29/victoria-memorial-2394784_1280.jpg',
    'https://cdn.pixabay.com/photo/2018/05/16/10/44/chennai-3405413_1280.jpg',
    'https://cdn.pixabay.com/photo/2019/02/12/14/53/golconda-fort-3992421_1280.jpg',
  ];

  List<Map<String, dynamic>> displayedList = [];
  String? selectedCity = 'All';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    displayedList = widget.accommodationList;
    searchController.addListener(searchAccommodations);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void filterByCity(String city) {
    selectedCity = city;
    searchAccommodations();
  }

  void searchAccommodations() {
    final query = searchController.text.toLowerCase();
    setState(() {
      displayedList = widget.accommodationList.where((item) {
        final matchesCity = selectedCity == 'All' ||
            (item['state'] ?? '').toString().toLowerCase() ==
                selectedCity!.toLowerCase();

        final name = item['fullAddress']?.toString().toLowerCase() ?? '';
        final city = item['city']?.toString().toLowerCase() ?? '';
        final state = item['state']?.toString().toLowerCase() ?? '';

        final matchesSearch = name.contains(query) ||
            city.contains(query) ||
            state.contains(query);

        return matchesCity && matchesSearch;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return const FilterOptionScreen();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubscriptionData>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search accommodations...',
            prefixIcon: const Icon(Icons.search, color: Colors.orange),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showFilterBottomSheet,
                        icon: const Icon(Icons.filter_list),
                        label: const Text("Filter"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark),
                        label: const Text("Saved"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_home_outlined),
                            label: const Text(
                              'Post an Accommodation',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Get.to(() => const WhichYouListScreen());
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: cityList.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => filterByCity(cityList[index]),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(cityImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                    border: selectedCity == cityList[index]
                                        ? Border.all(
                                            color: Colors.orange, width: 2)
                                        : null,
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color:
                                                Colors.black.withOpacity(0.4),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          cityList[index],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        displayedList.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Text("No accommodations found"),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedList.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemBuilder: (context, index) {
                                  final data = displayedList[index];
                                  List images = data['images'] ?? [];
                                  String imageUrl = images.isNotEmpty
                                      ? images.first.toString()
                                      : '';

                                  return GestureDetector(
                                    onTap: () {
                                      Get.to(
                                        () => AccommodationDetailsScreen(
                                          accommodation: displayedList[index],
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 2,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(14),
                                            ),
                                            child: imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: 120,
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                        child:
                                                            Text("No image")),
                                                  ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              data['city'] ?? 'Unknown City',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              data['fullAddress'] ??
                                                  'Address not available',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
