import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trunriproject/accommodation/lookingForAPlaceScreen.dart';
import 'package:trunriproject/events/eventHomeScreen.dart';
import 'package:trunriproject/home/Components/category_card.dart';
import 'package:trunriproject/home/groceryStoreListScreen.dart';
import 'package:trunriproject/home/resturentItemListScreen.dart';
import 'package:trunriproject/job/jobHomePageScreen.dart';
import 'package:trunriproject/model/categoryModel.dart';
import 'package:trunriproject/temple/templeHomePageScreen.dart';

class GetCategoriesVisuals extends StatelessWidget {
  const GetCategoriesVisuals({
    super.key,
    required this.restaurants,
    required this.temples,
    required this.groceryStores,
    required this.eventList,
    required this.accomodationList,
  });
  final List<dynamic> restaurants;
  final List<dynamic> temples;
  final List<dynamic> groceryStores;
  final List<Map<String, dynamic>> eventList;
  final List<Map<String, dynamic>> accomodationList;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Error fetching products'),
          );
        }

        List<Category> category = snapshot.data!.docs.map((doc) {
          return Category.fromMap(doc.id, doc.data());
        }).toList();
        return Padding(
          padding: const EdgeInsets.only(left: 20),
          child: SizedBox(
            height: 100,
            child: CarouselSlider.builder(
              itemCount: category.length,
              itemBuilder: (context, index, realIndex) {
                return CategoryCard(
                    iconUrl: category[index].imageUrl,
                    text: category[index].name,
                    press: () {
                      if (category[index].name == 'Temples') {
                        Get.to(TempleHomePageScreen(
                          templesList: temples,
                        ));
                      } else if (category[index].name == 'Grocery stores') {
                        Get.to(
                          GroceryStoreListScreen(
                            groceryStores: groceryStores,
                          ),
                        );
                      } else if (category[index].name == 'Accommodation') {
                        Get.to(
                          LookingForAPlaceScreen(
                            accommodationList: accomodationList,
                          ),
                        );
                      } else if (category[index].name == 'Restaurants') {
                        if (restaurants.isNotEmpty) {
                          Get.to(ResturentItemListScreen(
                            restaurant_List: restaurants,
                          ));
                        }
                      } else if (category[index].name == 'Jobs') {
                        Get.to(const JobHomePageScreen());
                      } else if (category[index].name == 'Events') {
                        Get.to(EventDiscoveryScreen(eventList: eventList));
                      }
                    });
              },
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.25,
                enableInfiniteScroll: true,
                enlargeCenterPage: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
