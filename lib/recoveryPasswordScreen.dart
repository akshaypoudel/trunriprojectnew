import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:trunriproject/signinscreen.dart';
import 'package:trunriproject/widgets/customTextFormField.dart';
import 'package:trunriproject/widgets/helper.dart';

class RecoveryPasswordScreen extends StatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  State<RecoveryPasswordScreen> createState() => _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends State<RecoveryPasswordScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  bool show = true;

  void checkEmailInFirestore(BuildContext context) async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    final QuerySnapshot result =
        await FirebaseFirestore.instance.collection('User').where('email', isEqualTo: emailController.text).get();

    if (result.docs.isNotEmpty) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim()).then((value) {
        setState(() {
          show = false;
        });

      });
    } else {
      showSnackBar(context,"User is not registered with this email");
    }

    NewHelper.hideLoader(loader);
  }

  void changePassword(BuildContext context) async {
    OverlayEntry loader = NewHelper.overlayLoader(context);
    Overlay.of(context).insert(loader);

    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('User')
          .where('email', isEqualTo: emailController.text.trim())
          .get();

      if (result.docs.isNotEmpty) {
        String userUid = result.docs.first.id;

        await FirebaseFirestore.instance
            .collection('User')
            .doc(userUid)
            .update({"password": passwordController.text.trim()});

        NewHelper.hideLoader(loader);
        showSnackBar(context,"Password changed successfully");
        Get.to(const SignInScreen());
      } else {
        NewHelper.hideLoader(loader);
        showSnackBar(context,"User is not registered with this email");
      }
    } catch (e) {
      NewHelper.hideLoader(loader);
      showSnackBar(context,"Error: ${e.toString()}");
    }
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Colors.white,
        body: Form(
          key: formKey,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Container(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: SafeArea(
                  child: ListView(
                children: [
                  Lottie.asset("assets/loti/lock.json", height: 300),
                  const Text(
                    "Forget Your Password ?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, color: Colors.black, height: 1.2),
                  ),
                  SizedBox(height: size.height * 0.04),
                  const Text(
                    "Enter your email address and we'll send you instructions on how to reset your password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.2),
                  ),
                  SizedBox(height: size.height * 0.04),
                  show
                      ? CommonTextField(
                          hintText: 'Email your Email',
                          controller: emailController,
                          labelText: "Email",
                          validator: MultiValidator([
                            RequiredValidator(errorText: 'Please enter a valid email'),
                            EmailValidator(errorText: 'Please enter valid email'.tr),
                          ]).call,
                          onEditingCompleted: () {
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : CommonTextField(
                    hintText: 'Password',
                    controller: passwordController,
                    validator: MultiValidator([
                      RequiredValidator(errorText: 'Please enter your password'.tr),
                      MinLengthValidator(8,
                          errorText: 'Password must be at least 8 characters, with 1 special character & 1 numerical'.tr),
                      // MaxLengthValidator(16, errorText: "Password maximum length is 16"),
                      PatternValidator(r"(?=.*\W)(?=.*?[#?!@()$%^&*-_])(?=.*[0-9])",
                          errorText: "Password must be at least 8 characters, with 1 special character & 1 numerical".tr),
                    ]).call,
                  ),
                  SizedBox(height: size.height * 0.07),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        // for sign in button
                        show
                            ? GestureDetector(
                                onTap: () {
                                  if (formKey.currentState!.validate()) {
                                    checkEmailInFirestore(context);
                                  }
                                },
                                child: Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFF730A),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Check Email",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  if (formKey.currentState!.validate()) {
                                    changePassword(context);
                                  }
                                },
                                child: Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFF730A),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Change",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              )),
            ),
          ),
        ));
  }
}
