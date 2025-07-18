import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.iconUrl,
    required this.text,
    required this.press,
  });

  final String iconUrl, text;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            height: 56,
            width: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CachedNetworkImage(
                imageUrl: iconUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4), // Add space between the image and the text
          Container(
            margin: const EdgeInsets.only(right: 10),
            width: 56, // Adjust width if needed
            child: Text(
              text.toString().toUpperCase() ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10, // Adjust the font size as needed
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Allow text to wrap to 2 lines if needed
            ),
          ),
        ],
      ),
    );
  }
}
