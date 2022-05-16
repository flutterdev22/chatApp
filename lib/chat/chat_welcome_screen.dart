import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_app/widgets/default_button.dart';
import 'package:transition_pages_jr/transition_pages_jr.dart';

import 'chat_verification_screen.dart';

class ChatWelcomeScreen extends StatelessWidget {
  const ChatWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: // 1. Local image
        Container(
          height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            padding:const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              image: DecorationImage(
                alignment: Alignment.center,
                  image: AssetImage("images/welcomeImage.jpeg"),
                  fit: BoxFit.fitWidth),
            ),
            child: Padding(
              padding:const EdgeInsets.only(left: 22,right: 22,top: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   SizedBox(height: 50.h,),
                  Text("We are here",style: GoogleFonts.rubik(fontWeight: FontWeight.w600,fontSize: 35.sp,color: const Color(0xFF1E263C)),),
                  Text("to help",style: GoogleFonts.rubik(fontWeight: FontWeight.w600,fontSize: 35.sp,color: const Color(0xFF1E263C)),),
                   SizedBox(height: 40.h,),
                  Text("Get Godly Advise, Chat anonymously",style: GoogleFonts.rubik(fontWeight: FontWeight.w300,fontSize: 16.sp,color: const Color(0xFF12558A)),),
                  const Spacer(flex: 2,),
                  Center(
                    child: DefaultButton(onTap: (){
                      RouteTransitions(
                        context: context,
                        child: const ChatVerificationScreen(),
                        animation: AnimationType.fadeIn,
                      );

                    }, text: "Start Chat"),
                  ),
                  const Spacer(),
                ],
              ),
            )
        )



      ),
    );
  }
}
