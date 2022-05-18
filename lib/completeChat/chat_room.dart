// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:test_app/utils.dart';
import 'package:test_app/widgets/customToast.dart';
import 'package:uuid/uuid.dart';
import 'fullPagePhoto.dart';
import 'model/chat_room_model.dart';
import 'model/message_model.dart';
import 'model/user_model.dart';
import 'dart:io';

class ChatRoom extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatRoom;
  final UserModel userModel;

  const ChatRoom({
    Key? key,
    required this.targetUser,
    required this.chatRoom,
    required this.userModel,
  }) : super(key: key);

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  TextEditingController masgContrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var uuid = Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FocusNode focusNode = FocusNode();
  bool isShowSticker = false;


  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
  }
  bool isLoading = false;
  File? imageFile;
  String imageUrl = "";

  Future getImage() async {
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        uploadImage();
      }
    });
  }

  Future uploadImage() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = uploadFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      if(mounted) {
        setState(() {
        isLoading = false;
        sendMsg("image",imageUrl);
      });
      }
    } on FirebaseException catch (e) {
      if(mounted) {
        setState(() {
        isLoading = false;
      });
      }
      ToastUtils.showCustomToast(context, e.message ?? e.toString(), AppColors.darkBlueColor);
    }

  }
  UploadTask uploadFile(File image, String fileName) {
    Reference reference = storage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  sendMsg(String mType,String mText) async {
    MessageModel newMessage = MessageModel(
      messageid: uuid.v1(),
      sender: widget.userModel.uid.toString(),
      text: mText,
      seen: false,
      type: mType,
      createdon: DateTime.now(),
    );

    FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(widget.chatRoom.chatroomid)
        .collection('messages')
        .doc(newMessage.messageid)
        .set(newMessage.toMap());

    widget.chatRoom.lastMessage = masgContrl.text;
    FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(widget.chatRoom.chatroomid)
        .set(widget.chatRoom.toMap());


    masgContrl.clear();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      if(mounted) {
        setState(() {
        isShowSticker = false;
      });
      }
    }
  }
  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    if(mounted) {
      setState(() {
      isShowSticker = !isShowSticker;
    });
    }
  }


  Future<bool> onBackPress() {
    if (isShowSticker) {
      if(mounted) {
        setState(() {
        isShowSticker = false;
      });
      }
    } else {

      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        backgroundColor: AppColors.darkBlueColor,
        title: Row(
          children: [
            Container(
                width: 40.w,
                height: 40.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: ExactAssetImage(
                        'images/userImage.jpeg'),
                    fit: BoxFit.fitHeight,
                  ),
                )),
            SizedBox(
              width: 10,
            ),
            Text(
              widget.targetUser.fullname.toString(),
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body:  WillPopScope(
        child:   Container(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("chatrooms")
                          .doc(widget.chatRoom.chatroomid)
                          .collection("messages")
                          .orderBy("createdon", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.active) {
                          if (snapshot.hasData) {
                            QuerySnapshot dataSnapshot =
                            snapshot.data as QuerySnapshot;

                            return ListView.builder(
                              reverse: true,
                              itemCount: dataSnapshot.docs.length,
                              itemBuilder: (context, index) {
                                MessageModel currentMessage =
                                MessageModel.fromMap(dataSnapshot.docs[index]
                                    .data() as Map<String, dynamic>);

                                return currentMessage.type == "text"
                                // Text
                                    ?  Row(
                                  mainAxisAlignment: (currentMessage.sender ==
                                      widget.userModel.uid)
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: (currentMessage.sender ==
                                          widget.userModel.uid)
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 30.w,
                                            ),
                                            decoration: currentMessage.sender ==
                                                widget.userModel.uid
                                                ? BoxDecoration(
                                              color: AppColors.greyColor2,
                                              borderRadius:
                                              BorderRadius.circular(5),
                                            )
                                                : BoxDecoration(
                                              color: AppColors.greyColor,
                                              borderRadius:
                                              BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              currentMessage.text.toString(),
                                              style: GoogleFonts.rubik(
                                                fontSize: 15.sp,
                                                color: Colors.black,
                                              ),
                                            )),
                                        Text(DateFormat.jm().format(currentMessage.createdon!), style: GoogleFonts.rubik(
                                          fontSize: 10.sp,
                                          color: AppColors.lightBlackColor,
                                        ),),
                                      ],
                                    ),
                                  ],
                                )
                                    : currentMessage.type == "image"
                                 // Image
                                    ? isLoading? CircularProgressIndicator(color: AppColors.darkBlueColor,): Row(
                                      mainAxisAlignment: (currentMessage.sender ==
                                      widget.userModel.uid)
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                      children: [
                                        Column(
                                         crossAxisAlignment: (currentMessage.sender ==
                                          widget.userModel.uid)
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              child: OutlinedButton(
                                            child: Material(
                                              child: Image.network(
                                                currentMessage.text!,
                                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: AppColors.blackColor,
                                                      borderRadius: BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                    ),
                                                    width: 200,
                                                    height: 200,
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        color: AppColors.darkBlueColor,
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, object, stackTrace) {
                                                  return Material(
                                                    child: Image.asset(
                                                      'images/img_not_available.jpeg',
                                                      width: 200,
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius: BorderRadius.all(
                                                      Radius.circular(8),
                                                    ),
                                                    clipBehavior: Clip.hardEdge,
                                                  );
                                                },
                                                width: 200,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                              borderRadius: BorderRadius.all(Radius.circular(8)),
                                              clipBehavior: Clip.hardEdge,
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => FullPhotoPage(
                                                    url: currentMessage.text!,
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ButtonStyle(padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(0))),
                                  ),
                                  margin: EdgeInsets.only(bottom:  10, right: 10),
                                ),
                                            Text(DateFormat.jm().format(currentMessage.createdon!), style: GoogleFonts.rubik(
                                              fontSize: 10.sp,
                                              color: AppColors.lightBlackColor,
                                            ),),
                                          ],
                                        ),
                                      ],
                                    )
                                // Sticker
                                    : Row(
                                  mainAxisAlignment: (currentMessage.sender ==
                                      widget.userModel.uid)
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment: (currentMessage.sender ==
                                              widget.userModel.uid)
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                             child: Image.asset(
                                            'images/${currentMessage.text}.gif',
                                            width: 50.w,
                                            height: 50.h,
                                            fit: BoxFit.fitHeight,
                                              ),
                                              margin: EdgeInsets.only(bottom: 10, right: 10),
                                            ),
                                            Text(DateFormat.jm().format(currentMessage.createdon!), style: GoogleFonts.rubik(
                                              fontSize: 10.sp,
                                              color: AppColors.lightBlackColor,
                                            ),),
                                          ],
                                        ),
                                      ],
                                    );


                              },
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                  "An error occurred! Please check your internet connection."),
                            );
                          } else {
                            return Center(
                              child: Text("Say hi to your new friend",style: GoogleFonts.rubik(fontWeight: FontWeight.w600,fontSize: 20.sp),),
                            );
                          }
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10.h,),
                // Sticker
                isShowSticker ? buildSticker() : SizedBox.shrink(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      children: [
                        Icon(FeatherIcons.mic,color: AppColors.lightBlackColor,),
                        IconButton(
                          icon: Icon(Icons.face),
                          onPressed: getSticker,
                          color: AppColors.lightBlackColor,
                        ),
                        Flexible(child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextFormField(
                            validator: (value) {
                              if (value!.isEmpty || value == null) {
                                return "Message Required!";
                              }
                            },
                            controller: masgContrl,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Write text here",
                                hintStyle: GoogleFonts.rubik(fontSize: 15.sp)
                            ),
                          ),
                        )),
                        IconButton(
                          icon: Icon(FeatherIcons.share),
                          onPressed: getImage,
                          color: AppColors.lightBlackColor,
                        ),
                        Container(
                          width: 40.w,
                          height: 40.h,
                          margin: EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                              color: AppColors.darkBlueColor,
                              shape: BoxShape.circle
                          ),
                          child: IconButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  sendMsg("text",masgContrl.text.trim().toString());
                                }
                              },
                              icon: Icon(
                                Icons.send,
                                color: Colors.white,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        onWillPop: onBackPress,
      ),



    );
  }

  Widget buildSticker() {
    return Expanded(
      child: Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi1"),
                  child: Image.asset(
                    'images/mimi1.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi2"),
                  child: Image.asset(
                    'images/mimi2.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi3"),
                  child: Image.asset(
                    'images/mimi3.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi4"),
                  child: Image.asset(
                    'images/mimi4.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi5"),
                  child: Image.asset(
                    'images/mimi5.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi6"),
                  child: Image.asset(
                    'images/mimi6.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi7"),
                  child: Image.asset(
                    'images/mimi7.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi8"),
                  child: Image.asset(
                    'images/mimi8.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => sendMsg("sticker","mimi9"),
                  child: Image.asset(
                    'images/mimi9.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.greyColor, width: 0.5)), color: Colors.white),
        padding: EdgeInsets.all(5),
        height: 180,
      ),
    );
  }
}
