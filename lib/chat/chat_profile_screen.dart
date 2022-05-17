import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils.dart';
import '../widgets/default_button.dart';
class ChatProfilePage extends StatelessWidget {
  const ChatProfilePage({Key? key}) : super(key: key);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("images/userImage.jpeg",width: 100.w,height: 100.h,),
                  SizedBox(width: 20.w,),
                  Text.rich(
                    TextSpan(

                      children: [
                        TextSpan(text: 'Hey ',
                          style: GoogleFonts.rubik(
                              fontWeight: FontWeight.w500,
                              fontSize: 35.sp,
                              color: AppColors.blackColor),),
                        TextSpan(
                          text: ' \nUsername',
                          style: GoogleFonts.rubik(
                              fontWeight: FontWeight.w500,
                              fontSize: 35.sp,
                              color: AppColors.blackColor),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text("Adam is cool and super smart to take care o 4 big projects in XYZ company. He loves to travel and work remotely.", style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w300,
                        fontSize: 16.sp,
                        color: AppColors.blackColor)),
                    SizedBox(height: 50.h,),
                    Row(

                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                         Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(5.r)
                        ),
                        child: IconButton(
                          color: Colors.white,
                            onPressed: (){}, icon: Icon(FeatherIcons.facebook),
                        ),
                      ),
                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xFF0077B5),
                              borderRadius: BorderRadius.circular(5.r)
                          ),
                          child: IconButton(
                            color: Colors.white,
                            onPressed: (){}, icon: Icon(FeatherIcons.linkedin),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xFF50ABF1),
                              borderRadius: BorderRadius.circular(5.r)
                          ),
                          child: IconButton(
                            color: Colors.white,
                            onPressed: (){}, icon: Icon(FeatherIcons.twitter),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: Color(0xFF0077B5),
                              borderRadius: BorderRadius.circular(5.r)
                          ),
                          child: IconButton(
                            color: Colors.white,
                            onPressed: (){}, icon: Icon(FeatherIcons.facebook),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 50.h,),
              DefaultButton(onTap: (){


              }, text: "LOG-OUT"),
            ],
          ),
        ),
      ),
    );
  }
}
