import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webrtc_flutter/ws.dart';
import 'screen_select_dialog.dart';

class HomePage extends StatefulWidget {
  final String userType;
  const HomePage({Key? key, required this.userType}) : super(key: key);
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? userType;
  DateTime? compareDate;
  int i = 0;

 String socketId = '';

  //HomePageState(this.userType);
  webSocket ws = webSocket();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  MediaStream? stream;
  bool? hangUpState;
  bool isRemoteConnected = false;
  //TextEditingController textEditingController = TextEditingController(text: '');


  //late io.Socket socket;

  @override
  void initState() {
    // init signalling service
    ws.connectToServer();
    
    print(
        '---------------------------------------------------------------------------1');
    hangUpState = false;
    userType = widget.userType;
    print(
        '---------------------------------------------------------------------------$userType');
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    print(
        '---------------------------------------------------------------------------2');
    if (userType == 'H') {
      ws
          .openUserMedia(_localRenderer, _remoteRenderer)
          .then((value) async {
        {
          //roomId = await ws.createRoom(_localRenderer);
          // textEditingController.text = roomId!;
          print(
              '---------------------------------------------------------------------------3');
          setState(() {});
        }
      });
    } else if (userType == 'V') {
      ws.openUserMedia(_localRenderer, _remoteRenderer);
      print(
          '---------------------------------------------------------------------------4');
      //signaling.getData();
    }
    ws.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;

      setState(() {
        isRemoteConnected = (!isRemoteConnected);
      });
    });
    print(
        '---------------------------------------------------------------------------5');
    // final tsToMillis = DateTime.now().millisecond;
    // final compareDate = DateTime(tsToMillis - (24 * 60 * 60 * 1000));
    print(
        '---------------------------------------------------------------------------6');
    super.initState();
  }

  void startLocalStreaming() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    ws.openUserMedia(_localRenderer, _remoteRenderer);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> selectScreenSourceDialog(BuildContext context) async {
    MediaStream? screenStream;
    if (WebRTC.platformIsDesktop) {
      final source = await showDialog<DesktopCapturerSource>(
        context: context,
        builder: (context) => ScreenSelectDialog(),
      );
      if (source != null) {
        try {
          var stream =
          await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
            'video': {
              'deviceId': {'exact': source.id},
              'mandatory': {'frameRate': 30.0}
            }
          });
          stream.getVideoTracks()[0].onEnded = () {
            print(
                'By adding a listener on onEnded you can: 1) catch stop video sharing on Web');
          };
          screenStream = stream;
        } catch (e) {
          print(e);
        }
      }
    } else if (WebRTC.platformIsWeb) {
      screenStream =
      await navigator.mediaDevices.getDisplayMedia(<String, dynamic>{
        'audio': false,
        'video': true,
      });
    }
    if (screenStream != null) ws?.switchToScreenSharing(screenStream, _localRenderer);
  }


  Widget bottomNavigationDesign(context) {
    return Container(
      //  margin: EdgeInsets.all(10),
      height: 100,
      color: Colors.white,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5.0,
                    spreadRadius: 0.0,
                    offset: Offset(2.0, 2.0), // shadow direction: bottom right
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          i == 0
                              ? Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                ),
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  i = 0;
                                });
                              },
                              icon: Icon(Icons.home)),
                          Text(
                            "Home",
                            style: GoogleFonts.nunito(
                                color: const Color.fromRGBO(108, 112, 114, 1),
                                fontSize: 14),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Column(
                        children: [
                          i == 1
                              ? Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                ),
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  i = 1;
                                });
                              },
                              icon: const Icon(Icons.volume_mute)),
                          Text(
                            "Mute",
                            style: GoogleFonts.nunito(
                                color: const Color.fromRGBO(108, 112, 114, 1),
                                fontSize: 14),
                          )
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          i == 2
                              ? Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                ),
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  i = 2;
                                });
                              },
                              icon: Icon(Icons.photo_camera_front)),
                          Text(
                            "Close Camera",
                            style: GoogleFonts.nunito(
                                color: const Color.fromRGBO(108, 112, 114, 1),
                                fontSize: 14),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 30,
                      ),
                      Column(
                        children: [
                          i == 3
                              ? Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                )
                              : Container(
                                  width: MediaQuery.of(context).size.width / 8,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(20.0),
                                        bottomLeft: Radius.circular(20.0)),
                                  ),
                                ),
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  i = 3;
                                });
                              },
                              icon: Icon(Icons.call)),
                          Text(
                            "Available User",
                            style: GoogleFonts.nunito(
                                color: const Color.fromRGBO(108, 112, 114, 1),
                                fontSize: 14),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
              alignment: const Alignment(0.0, 2.0),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      //signaling.hangUp(_localRenderer);
                      setState(() {
                        // hangUpState = true;
                      });
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(252, 48, 63, 0.2),
                        shape: BoxShape.circle,
                      ),
                      height: 59,
                      width: 59,
                      child: Container(
                        margin: EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end,
                            size: 40, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    "End Call",
                    style: GoogleFonts.nunito(
                        color: Color.fromRGBO(108, 112, 114, 1), fontSize: 14),
                  )
                ],
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: bottomNavigationDesign(context),
        body: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                !isRemoteConnected
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * .84,
                        width: MediaQuery.of(context).size.width,
                        child: RTCVideoView(_localRenderer, mirror: true))
                    : SizedBox(
                        height: MediaQuery.of(context).size.height * .84,
                        width: MediaQuery.of(context).size.width,
                        child: RTCVideoView(_remoteRenderer)),
                !isRemoteConnected
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height / 4,
                        width: MediaQuery.of(context).size.width / 4,
                        child: RTCVideoView(_remoteRenderer))
                    : SizedBox(
                        height: MediaQuery.of(context).size.height / 4,
                        width: MediaQuery.of(context).size.width / 4,
                        child: RTCVideoView(_localRenderer, mirror: true)),
                if (userType == 'V')
                  Row(
                    children: [
                      TextButton(
                        style:
                        TextButton.styleFrom(backgroundColor: Color(0xffF18265)),
                        onPressed: () {ws.joinRoom(
                            '2', _remoteRenderer);
                        },
                        child: Text(
                          "Join Room",
                          style: TextStyle(
                            color: Color(0xffffffff),
                          ),
                        ),
                      ),
                      TextButton(
                        style:
                        TextButton.styleFrom(backgroundColor: Color(0xffF18265)),
                        onPressed: () {ws.switchCamera();
                        },
                        child: Text(
                          "Switch Camera",
                          style: TextStyle(
                            color: Color(0xffffffff),
                          ),
                        ),
                      ),
                      TextButton(
                        style:
                        TextButton.styleFrom(backgroundColor: Color(0xffF18265)),
                        onPressed: () {selectScreenSourceDialog(context);
                        },
                        child: Text(
                          "Share Screen",
                          style: TextStyle(
                            color: Color(0xffffffff),
                          ),
                        ),
                      ),

                    ],
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}


