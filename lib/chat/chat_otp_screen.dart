import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/chat/chat_username_screen.dart';
import 'package:test_app/utils.dart';
import 'package:test_app/widgets/customToast.dart';
import 'package:test_app/widgets/default_button.dart';
import 'package:transition_pages_jr/transition_pages_jr.dart';

import 'chat_home_screen.dart';

class ChatOtpScreen extends StatefulWidget {
  String phone;
  bool isTimeOut2;
  String verifyId;
   ChatOtpScreen({Key? key,required this.phone,required this.verifyId,required this.isTimeOut2}) : super(key: key);

  @override
  State<ChatOtpScreen> createState() => _ChatOtpScreenState();
}

class _ChatOtpScreenState extends State<ChatOtpScreen> {
TextEditingController otpController = TextEditingController();
bool verifyText = false;
bool loading = false;
bool isTimeOut = false;
String myVerificationId = "";
final FirebaseAuth _auth = FirebaseAuth.instance;


@override
  void initState() {
    // TODO: implement initState
    super.initState();
    myVerificationId = widget.verifyId;
    isTimeOut = widget.isTimeOut2;
  }

void signInWithPhoneAuthCredential(PhoneAuthCredential phoneAuthCredential) async {
  if(mounted) {
    setState(() {
    loading = true;
  });
  }

  try {
    final authCredential = await _auth.signInWithCredential(phoneAuthCredential);

    if(authCredential.user != null){
      if(mounted){
        setState(() {
          verifyText = true;
        });
      }
      ToastUtils.showCustomToast(context, "Verification Success",Colors.green);
      postDetailsToFirestore(context, widget.phone);
    }


  } on FirebaseAuthException catch (e) {
    if(mounted) {
      setState(() {
      loading = false;
    });
    }
    ToastUtils.showCustomToast(context, e.message.toString(),Colors.red);
  }
}

void postDetailsToFirestore(BuildContext context, phone) async {
  SharedPreferences preferences =await SharedPreferences.getInstance();
  final _auth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  User? user = _auth.currentUser;

  await firebaseFirestore.collection("users").doc(user!.uid).set({
    'uid': user.uid,
    'phone': phone,
    'username': '',
  }).then((value) {
    if(mounted) {
      setState(() {
        loading = false;
      });
    }
    preferences.setString("uid", user.uid.toString());
    preferences.setString("logStatus", "true");
    RouteTransitions(
      context: context,
      child:const ChatUsernameScreen(),
      animation: AnimationType.fadeIn,
    );
  }).catchError((e) {});
  if(mounted) {
    setState(() {
      loading = false;
    });
  }

}

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child:  Icon(
            Icons.chevron_left,
            color: AppColors.darkBlueColor,
            size: 30.sp,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 25.0,right: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                 SizedBox(
                  height: 30.h,
                ),
                Text(
                  "Phone \nVerification",
                  style: GoogleFonts.rubik(
                      fontWeight: FontWeight.w500,
                      fontSize: 35.sp,
                      color: const Color(0xFF1E263C)),
                ),
                 SizedBox(
                  height: 30.h,
                ),
                Text(
                  "Enter your OTP code.",
                  style: GoogleFonts.rubik(
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                      color: const Color(0xFF1E263C)),
                ),
                 SizedBox(
                  height: 50.h,
                ),
                Center(
                  child: Pinput(
                    length: 6,
                    defaultPinTheme: PinTheme(
                      width: 67.w,
                      height: 90.h,
                      textStyle: GoogleFonts.rubik(fontSize: 35.sp, color: AppColors.blackColor, fontWeight: FontWeight.w500),
                      decoration: BoxDecoration(
                        color: AppColors.greyColor,
                        border: Border.all(color: AppColors.greyColor),

                      ),
                    ),
                    controller: otpController,
                    forceErrorState: true,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    validator: (pin) {
                      if (pin!.length < 6) {
                        return "You should enter all SMS code";
                      }
                      else {
                        return null;
                      }
                    },
                  ),
                ),
                 SizedBox(
                  height: 80.h,
                ),
                loading ? Center(
                  child: CircularProgressIndicator(color: AppColors.darkBlueColor,),
                ): Center(
                  child: DefaultButton(
                    onTap: (){

                      PhoneAuthCredential phoneAuthCredential =
                      PhoneAuthProvider.credential(
                          verificationId: myVerificationId, smsCode: otpController.text);

                      signInWithPhoneAuthCredential(phoneAuthCredential);

                    },
                      text: "VERIFY"),
                ),
                 SizedBox(
                  height: 10.h,
                ),
               verifyText == false?const SizedBox.shrink()
                  :Center(
                    child: Text(
                    "Successful!",
                    style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w400,
                        fontSize: 16.sp,
                        color: const Color.fromARGB(255, 45, 253, 52)),
                    textAlign: TextAlign.center,
                  ),
                ),
                 SizedBox(
                  height: 20.h,
                ),
                Center(
                  child: Text(
                    "Didn't you receive any code?",
                    style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w400,
                        fontSize: 14.sp,
                        color: AppColors.lightBlueColor),
                  ),
                ),
                 SizedBox(
                  height: 30.h,
                ),
                GestureDetector(
                  onTap: isTimeOut ? () async {
                    if(mounted) {
                      setState(() {
                      isTimeOut =  false;
                    });
                    }
                    await FirebaseAuth.instance.verifyPhoneNumber(
                      phoneNumber: widget.phone,
                      verificationCompleted: (PhoneAuthCredential credential) {},
                      verificationFailed: (FirebaseAuthException e) {
                        if(mounted) {
                          setState(() {
                          loading = false;
                        });
                        }

                      },
                      codeSent: (String verificationId, int? resendToken) {
                        if(mounted) {
                          setState(() {
                          loading = false;
                          myVerificationId = verificationId;
                        });
                        }
                      },
                      timeout: const Duration(seconds: 20),
                      codeAutoRetrievalTimeout: (String verificationId) {
                        if(mounted) {
                          setState(() {
                          isTimeOut =  true;
                        });
                        }
                      },
                    );
                  } : null,
                  child: Center(
                    child: Text(
                      "RESEND NEW CODE",
                      style: GoogleFonts.rubik(
                          fontWeight: FontWeight.w400,
                          fontSize: 16.sp,
                          color: AppColors.blackColor),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: Text(
                    "wait 1:30 sec",
                    style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w400,
                        fontSize: 14.sp,
                        color: AppColors.lightBlueColor),
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
