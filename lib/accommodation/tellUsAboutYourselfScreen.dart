import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/appTheme.dart';
import '../widgets/commomButton.dart';

class Tellusaboutyourselfscreen extends StatefulWidget {
  const Tellusaboutyourselfscreen({super.key});

  @override
  State<Tellusaboutyourselfscreen> createState() =>
      _TellusaboutyourselfscreenState();
}

class _TellusaboutyourselfscreenState extends State<Tellusaboutyourselfscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Us About YourSelf'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Your Full Name",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.only(right: 50),
                child: CommonButton(
                  text: '',
                  color: AppTheme.primaryColor,
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Age",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.only(right: 150),
                child: CommonButton(
                  text: '20',
                  color: AppTheme.primaryColor,
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Who plan to live in the rented Space",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'Me',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'My Friend',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'me & my friend',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'my family',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'couple',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'others',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Could you please specify your gender identity",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: CommonButton(
                      text: 'Male',
                      color: const Color(0xffFF730A),
                      textColor: Colors.white,
                      onPressed: () {
                        // Add your logic for button press
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'Female',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      text: 'Non Binary',
                      color: AppTheme.primaryColor,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: TextFormField(
                  minLines: 5,
                  maxLines: 5,
                  decoration: InputDecoration(
                    fillColor: Colors.grey,
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 0.2),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Introduce yourself to your potential ",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Padding(
            padding: const EdgeInsets.all(15.0).copyWith(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: CommonButton(
                    text: 'Return',
                    color: const Color(0xffFF730A),
                    textColor: Colors.white,
                    onPressed: () {
                      // Add your logic for button press
                    },
                  ),
                ),
                Expanded(
                  child: CommonButton(
                    text: 'Next',
                    color: AppTheme.primaryColor,
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
