import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trunriproject/model/bannerModel.dart';

class GetBannersVisual extends StatelessWidget {
  const GetBannersVisual({super.key, required this.onPageChanged});
  final Function(int, dynamic) onPageChanged;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
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
        List<BannerModel> banner = snapshot.data!.docs.map((doc) {
          return BannerModel.fromMap(doc.id, doc.data());
        }).toList();
        final bannerLength = banner.length;

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                  viewportFraction: 1,
                  autoPlay: true,
                  onPageChanged: onPageChanged,
                  autoPlayCurve: Curves.ease,
                  height: height * .20),
              items: List.generate(
                bannerLength,
                (index) => Container(
                  width: width,
                  margin: EdgeInsets.symmetric(horizontal: width * .01),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: banner[index].imageUrl,
                      errorWidget: (_, __, ___) => const SizedBox(),
                      placeholder: (_, __) => const SizedBox(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
