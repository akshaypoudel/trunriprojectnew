import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'addSize.dart';
import 'helper.dart';

class ImageWidget extends StatefulWidget {
  const ImageWidget({
    super.key,
    required this.files,
    required this.validation,
    required this.filesPicked,
    this.imageOnly,
  });

  final List<File> files;
  final bool validation;
  final bool? imageOnly;
  final Function(List<File> files) filesPicked;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  List<File> files = [];

  bool get validation => widget.validation ? files.isEmpty : false;

  Future<void> pickImages() async {
    if (widget.imageOnly == true) {
      final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (pickedFiles != null) {
        files = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
        widget.filesPicked(files);
        setState(() {});
      }
    } else {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        files = result.paths.map((path) => File(path!)).toList();
        widget.filesPicked(files);
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    files = widget.files;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Text(
        //   widget.title,
        //   style: GoogleFonts.poppins(
        //       fontWeight: FontWeight.w500,
        //       color: const Color(0xff2F2F2F),
        //       fontSize: 16),
        // ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: pickImages,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: AddSize.padding16, vertical: AddSize.padding16),
            width: AddSize.screenWidth,
            height: context.width * .38,
            decoration: BoxDecoration(
                color: const Color(0xffE2E2E2).withValues(alpha: .4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !validation ? Colors.grey.shade300 : Colors.red,
                )),
            child: files.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text(
                      //   "Select ${widget.title}",
                      //   style: GoogleFonts.poppins(
                      //       fontWeight: FontWeight.w500,
                      //       color: validation ? Theme.of(context).colorScheme.error : const Color(0xff463B57),
                      //       fontSize: 15),
                      // ),
                      SizedBox(
                        height: AddSize.size10,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: validation
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.grey,
                              width: 1.8,
                            )),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.upload_file_outlined,
                          size: 24,
                          color: validation
                              ? Theme.of(context).colorScheme.error
                              : Colors.grey,
                        ),
                      )
                    ],
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      return Image.file(
                        files[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error),
                            Text(files[index].path.split("/").last),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
