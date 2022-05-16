import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_app/utils.dart';
import 'package:test_app/widgets/default_button.dart';

class ChatCounselorScreen extends StatefulWidget {
  String username;
   ChatCounselorScreen({Key? key,required this.username}) : super(key: key);

  @override
  State<ChatCounselorScreen> createState() => _ChatCounselorScreenState();
}

class _ChatCounselorScreenState extends State<ChatCounselorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30.h,
                ),
                Text(
                  "Welcome \n\"${widget.username}\"",
                  style: GoogleFonts.rubik(
                      fontWeight: FontWeight.w500,
                      fontSize: 35.sp,
                      color: AppColors.blackColor),
                  textAlign: TextAlign.start,
                ),
                 SizedBox(
                  height: 30.h,
                ),
                Text(
                  "You can ask your questions, we will be glad to assist you in any as possible.\nOur Counselors are here to help.",
                  style: GoogleFonts.rubik(
                      fontWeight: FontWeight.w400,
                      fontSize: 16.sp,
                      color: AppColors.blackColor),
                ),
                 SizedBox(
                  height: 50.h,
                ),
                Container(
                  color: Colors.white.withOpacity(0.4),
                  child: TextFormField(
                      textAlignVertical: TextAlignVertical.center,
                      textAlign: TextAlign.left,
                      maxLines: 5,
                     style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w400,
                        fontSize: 16.sp,
                        color: AppColors.blackColor),

                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.01,
                            left: 10),
                        labelStyle: GoogleFonts.rubik(
                            fontWeight: FontWeight.w400,
                            fontSize: 16.sp,
                            color: AppColors.blackColor),
                        hintStyle: GoogleFonts.rubik(
                            fontWeight: FontWeight.w400,
                            fontSize: 16.sp,
                            color: AppColors.blackColor),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        hintText: "Feel free to leave a voice note or text",
                        // labelText:"Your Name"
                      )),
                ),
                 SizedBox(
                  height: 80.h,
                ),
                Center(
                  child: DefaultButton(onTap: () {}, text: "ASK A COUNSELOR"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
