// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_keyboard_flutter/emoji_keyboard_flutter.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:test_app/utils.dart';
import 'package:test_app/widgets/customToast.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'fullPagePhoto.dart';
import 'model/chat_room_model.dart';
import 'model/message_model.dart';
import 'model/user_model.dart';
import 'dart:io';
import 'package:http/http.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

class _ChatRoomState extends State<ChatRoom> with WidgetsBindingObserver{
  double progress = 0.0;

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
    BackButtonInterceptor.add(myInterceptor);
  }


  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  ImagePicker picker = ImagePicker();
  bool isLoading = false;
  bool isLoadingVideo = false;
  File? imageFile;
  String imageUrl = "";
  String videoUrl = "";

  PlatformFile? file;
  UploadTask? uploadTask;

  Future selectFile() async{
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4','mov','.avi'],
    );
    if(result == null) return;
    if(mounted) {
      setState(() {
        isLoading = true;
      file = result.files.first;
    });
    }
    uploadVideoFile();
  }

  Future getImage() async {
    Navigator.pop(context);
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.gallery).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        if(mounted){
          setState(() {
            isLoading = true;
          });
        }
        uploadImage();
      }
    });
  }

  Future getCameraImage() async {
    Navigator.pop(context);
    ImagePicker _picker = ImagePicker();

    await _picker.pickImage(source: ImageSource.camera).then((xFile) {
      if (xFile != null) {
        imageFile = File(xFile.path);
        if(mounted){
          setState(() {
            isLoading = true;
          });
        }
        uploadImage();
      }
    });
  }

  Future uploadVideoFile() async{
    final path = 'videoFiles/${file!.name}';
    final fle = File(file!.path!);
    final ref = FirebaseStorage.instance.ref().child(path);
    if(mounted) {
      setState(() {
      uploadTask =ref.putFile(fle);
    });
    }
    try{
      final snap = await uploadTask!.whenComplete(() => {});
      videoUrl = await snap.ref.getDownloadURL();
      if(mounted) {
        setState(() {
          isLoading =false;
          uploadTask =null;
          sendMsg("video",videoUrl);
        });
      }
    }on FirebaseException catch (e) {
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ToastUtils.showCustomToast(context, e.message ?? e.toString(), AppColors.darkBlueColor);
    }
  }

  Future uploadImage() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'imageFiles/$fileName';
    final fle = File(imageFile!.path);
    final ref = FirebaseStorage.instance.ref().child(path);
    if(mounted) {
      setState(() {
        uploadTask =ref.putFile(fle);
      });
    }
    try{
      final snap = await uploadTask!.whenComplete(() => {});
      imageUrl = await snap.ref.getDownloadURL();
      if(mounted) {
        setState(() {
          isLoading =false;
          uploadTask =null;
          sendMsg("image",imageUrl);
        });
      }
    }on FirebaseException catch (e) {
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ToastUtils.showCustomToast(context, e.message ?? e.toString(), AppColors.darkBlueColor);
    }

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

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    if(mounted) {
      setState(() {
        emojiShowing = !emojiShowing;
      //isShowSticker = !isShowSticker;
    });
    }
  }

  bool isPlayingMsg = false, isRecording = false, isSending = false;

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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: (){
           Navigator.pop(context);
          },
          child: Icon(FeatherIcons.chevronLeft,color: Colors.white,),
        ),
        automaticallyImplyLeading: false,
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
              width: 10.w,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetUser.fullname.toString(),
                  style: GoogleFonts.rubik(
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.lightGreenAccent
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      "Active Now / Last Seem 2 min ago",
                      style: GoogleFonts.rubik(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body:Form(
        key: _formKey,
        child: isLoading ?
        Center(
          child: StreamBuilder<TaskSnapshot>(
              stream: uploadTask?.snapshotEvents,
              builder: (context, snapshot){
                if(snapshot.hasData){
                  final data = snapshot.data;
                  double progress = (data!.bytesTransferred / data.totalBytes);
                  return SizedBox(
                    width: 100.w,
                    height: 100.h,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                            value: progress,
                            color: AppColors.darkBlueColor,
                            backgroundColor: Colors.grey
                        ),

                        Center(
                          child: Text('${(100 * progress).roundToDouble()} %',style: GoogleFonts.rubik(
                              fontWeight: FontWeight.bold,fontSize: 20.sp
                          ),
                          ),
                        )
                      ],
                    ),
                  );
                }
                else{
                  return SizedBox();
                }
              }),
        )
        :Column(
          children: [
            SizedBox(height: 10.h,),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: StreamBuilder  (
                  stream: FirebaseFirestore.instance
                      .collection("chatrooms")
                      .doc(widget.chatRoom.chatroomid)
                      .collection("messages")
                      .orderBy("createdon", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.hasData) {
                        QuerySnapshot dataSnapshot = snapshot.data as QuerySnapshot;

                        return ListView.builder(
                          reverse: true,
                          itemCount: dataSnapshot.docs.length,
                          itemBuilder: (context, index) {
                            MessageModel currentMessage = MessageModel.fromMap(dataSnapshot.docs[index].data() as Map<String, dynamic>);

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
                                    GestureDetector(
                                      onTap:(){
                                        Clipboard.setData(ClipboardData(text: currentMessage.text)).then((value) =>
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                duration:
                                                const Duration(seconds: 1),
                                                backgroundColor: AppColors.lgColor,
                                                content: Text(
                                                  'Message Copied',
                                                  style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 12.sp,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ));

                                      },
                                      child: Container(
                                          constraints:  BoxConstraints(
                                              maxWidth: 300.w,
                                              minWidth: 50.w
                                          ),
                                          //width:MediaQuery.of(context).size.width * 0.7,
                                          margin: EdgeInsets.symmetric(
                                            vertical: 0,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 20,
                                          ),
                                          decoration: currentMessage.sender ==
                                              widget.userModel.uid
                                              ? BoxDecoration(
                                            color: AppColors.blueColor,
                                            borderRadius:
                                            BorderRadius.circular(10.r),
                                          )
                                              : BoxDecoration(
                                            color: AppColors.lBlueColor,
                                            borderRadius:
                                            BorderRadius.circular(10.r),
                                          ),
                                          child: Text(
                                            currentMessage.text.toString(),
                                            style: GoogleFonts.rubik(
                                              fontSize: 14.sp,
                                              color: Colors.black,
                                            ),
                                          )),
                                    ),
                                    SizedBox(height: 5.h,),
                                    Text(DateFormat.jm().format(currentMessage.createdon!), style: GoogleFonts.rubik(
                                      fontSize: 10.sp,
                                      color: AppColors.lgColor,
                                    ),),
                                    SizedBox(height: 10.h,),
                                  ],
                                ),
                              ],
                            )
                                : currentMessage.type == "image"
                                 // Image
                                ? Row(
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
                                          child:currentMessage.text != ""?
                                          Image.network(
                                            currentMessage.text!,
                                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.blackColor,
                                                  borderRadius: BorderRadius.all(
                                                    Radius.circular(8.r),
                                                  ),
                                                ),
                                                width: 200.w,
                                                height: 200.h,
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
                                                  width: 200.w,
                                                  height: 200.h,
                                                  fit: BoxFit.cover,
                                                ),
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8.r),
                                                ),
                                                clipBehavior: Clip.hardEdge,
                                              );
                                            },
                                            width: 200.w,
                                            height: 200.h,
                                            fit: BoxFit.cover,
                                          )
                                          :StreamBuilder<TaskSnapshot>(
                                              stream: uploadTask?.snapshotEvents,
                                              builder: (context, snapshot){
                                                if(snapshot.hasData){
                                                  final data = snapshot.data;
                                                  double progress = (data!.bytesTransferred / data.totalBytes);

                                                  return SizedBox(
                                                    height: 50,
                                                    child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        LinearProgressIndicator(value: progress,
                                                          color: Colors.green,backgroundColor: Colors.grey,),
                                                        Center(
                                                          child: Text('${(100 * progress).roundToDouble()} %'
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                }
                                                else{
                                                  return SizedBox();
                                                }
                                              }),
                                          borderRadius: BorderRadius.all(Radius.circular(8)),
                                          clipBehavior: Clip.hardEdge,
                                        ),
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
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
                                    SizedBox(height: 5.h,),
                                    Text(DateFormat.jm().format(currentMessage.createdon!), style: GoogleFonts.rubik(
                                      fontSize: 10.sp,
                                      color: AppColors.lgColor,
                                    ),),
                                    SizedBox(height: 10.h,),
                                  ],
                                ),
                              ],
                            )
                                 // Audio
                                 :currentMessage.type == "audio"
                                 ? Padding(
                              padding: EdgeInsets.only(
                                  top: 8,
                                  bottom: 10,
                                  left: (currentMessage.sender == widget.userModel.uid? 64 : 10),
                                  right: (currentMessage.sender == widget.userModel.uid? 10 : 64)),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: currentMessage.sender == widget.userModel.uid
                                      ? AppColors.blueColor
                                      : AppColors.lBlueColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: GestureDetector(
                                    onTap: () {
                                      _loadFile(currentMessage.text);
                                    },
                                    onSecondaryTap: () {
                                      stopRecord();
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                                width: 40.w,
                                                height: 40.h,
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 0,
                                                ),
                                                decoration: BoxDecoration(
                                                    color: AppColors.darkBlueColor2,
                                                    shape: BoxShape.circle
                                                ),
                                                child: Icon(isPlayingMsg == true? FeatherIcons.pause : FeatherIcons.play,color: Colors.white,)),

                                          ],
                                        ),
                                        Text(
                                          DateFormat.jm().format(currentMessage.createdon!),
                                          style: TextStyle(fontSize: 10),
                                        ),

                                      ],
                                    )),
                              ),
                            )
                                 : SizedBox.shrink();
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
                      return Center();
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 10.h,),
            Container(
              decoration: BoxDecoration(
                color: AppColors.lBlueColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Container(
                        height: 40.h,
                        margin: EdgeInsets.fromLTRB(5, 5, 10, 5),
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                              color: isRecording
                                  ? Colors.white
                                  : Colors.black12,
                              spreadRadius: 4.r)
                        ], color: AppColors.darkBlueColor, shape: BoxShape.circle),
                        child: GestureDetector(
                          onLongPress: () {
                            startRecord();
                            if(mounted) {
                              setState(() {
                              isRecording = true;
                            });
                            }
                          },
                          onLongPressEnd: (details) {
                            stopRecord();
                            if(mounted) {
                              setState(() {
                              isRecording = false;
                            });
                            }
                          },
                          child: Container(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 20.sp,
                              )),
                        )),
                    IconButton(
                      icon: Icon(Icons.face),
                      onPressed: getSticker,
                      color: AppColors.lgColor,
                    ),
                    Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lBlueColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextFormField(
                            maxLines: 5,
                            minLines: 1,
                            validator: (value) {
                              if (value!.isEmpty || value == null) {
                                return "Message Required!";
                              }
                            },
                            controller: masgContrl,
                            decoration: InputDecoration.collapsed(
                                border: InputBorder.none,
                                hintText: "Write text here",
                                hintStyle: GoogleFonts.rubik(fontSize: 15.sp,color: AppColors.lgColor)
                            ),
                          ),
                        )),
                    IconButton(
                      icon: Icon(Icons.attach_file),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        showModalBottomSheet(
                            backgroundColor:
                            Colors.transparent,
                            context: context,
                            builder: (builder) => bottomSheet());
                      },
                    ),
                    Container(
                      width: 40.w,
                      height: 40.h,
                      margin: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                          color: AppColors.darkBlueColor2,
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
            Offstage(
              offstage: !emojiShowing,
              child: EmojiKeyboard(
                  emotionController: masgContrl,
                  emojiKeyboardHeight: 300,
                  showEmojiKeyboard: emojiShowing,
                  darkMode: true),
            ),
          ],
        ),
      ),

    );
  }


  bool emojiShowing = false;

  void onTapEmojiField() {
    if (!emojiShowing) {
      if(mounted) {
        setState(() {
        emojiShowing = true;
      });
      }
    }
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (emojiShowing) {
      if(mounted) {
        setState(() {
        emojiShowing = false;
      });
      }
      return true;
    } else {
      return false;
    }
  }

  Future _loadFile(var url) async {
    final bytes = await readBytes(Uri.parse(url));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/audio.mp3');

    await file.writeAsBytes(bytes);
    if (await file.exists()) {
      if(mounted) {
        setState(() {
        recordFilePath = file.path;
        isPlayingMsg = true;

      });
      }
      await play();
      if(mounted) {
        setState(() {
        isPlayingMsg = false;
      });
      }
    }
  }

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    final record = Record();
    if (hasPermission) {
      recordFilePath = await getFilePath();
      // Check and request permission
      if (await record.hasPermission()) {
        // Start recording
        await record.start(
          path: recordFilePath,
          encoder: AudioEncoder.aacLc, // by default
          bitRate: 128000, // by default
        );
      }

    } else {}
    if(mounted) {
      setState(() {});
    }
  }

  void stopRecord() async {
    final record = Record();
    String? s =await record.stop();

        if (s!.isNotEmpty) {
      if(mounted) {
        setState(() {
        isSending = true;
      });
      }
      await uploadAudio();
      if(mounted) {
        setState(() {
        isPlayingMsg = false;
      });
      }
    }
  }

  String recordFilePath ="";

  Future<void> play() async {
    if (File(recordFilePath).existsSync()) {
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.play(
        recordFilePath,
        isLocal: true,
      );
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_${i++}.mp3";
  }

  uploadAudio() {
    final FirebaseStorage firebaseStorageRef = FirebaseStorage.instance;
    Reference ref = storage.ref().child('audioFiles/${DateTime.now().millisecondsSinceEpoch.toString()}}.mp3');
    UploadTask uploadTask = ref.putFile(File(recordFilePath));
    uploadTask.then((res) async{
      var audioURL = await res.ref.getDownloadURL();
      String strVal = audioURL.toString();
      await sendMsg("audio", strVal);
    });

  }

  Widget bottomSheet() {
    return SizedBox(
      height: 180.h,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(18.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconCreation(FeatherIcons.video, Colors.blueAccent, "Video",selectFile),
              SizedBox(
                width: 40.w,
              ),
              iconCreation(FeatherIcons.image, Colors.purple, "Image",getImage),
              SizedBox(
                width: 40.w,
              ),
              iconCreation(FeatherIcons.camera, Colors.pink, "Camera",getCameraImage),
            ],
          ),
        ),
      ),
    );
  }
  Widget iconCreation(IconData icons, Color color, String text,GestureTapCallback tap) {
    return InkWell(
      onTap: tap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: color,
            child: Icon(
              icons,
              size: 29.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 5.h,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              // fontWeight: FontWeight.w100,
            ),
          )
        ],
      ),
    );
  }
  

}
