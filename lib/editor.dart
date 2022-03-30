import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notes/main.dart';
// import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';
import 'data_storage.dart';

const String font = 'Couriert';

class Editor extends StatefulWidget {
  const Editor(
      {Key key,
      this.storage,
      this.transitionAnimation,
      this.title = '',
      this.home})
      : super(key: key);
  final HomeState home;
  final String title;
  final Animation<double> transitionAnimation;
  final DataStorage storage;
  @override
  EditorState createState() => EditorState(
      transitionAnimation: transitionAnimation, title: title, home: home);
}

class EditorState extends State<Editor> with TickerProviderStateMixin {
  EditorState({this.transitionAnimation, this.title, this.home});

  final HomeState home;
  final Animation<double> transitionAnimation;
  final FocusNode focus = FocusNode();
  final FocusNode focusNode = FocusNode();
  final textController = TextEditingController();
  final titleControl = TextEditingController();
  AnimationController scaleControl;
  Animation<double> scaleTransition;
  bool enter = true;
  bool saved = true;
  bool keyboardOn = false;
  List<bool> changed = [false, false];
  double scale = 0;
  double edges = 0;
  String composedText;
  String composedTitle;
  String text = '';
  String title = '';
  double size = 30;
  var curves = [Curves.elasticOut, Curves.ease];
  CurvedAnimation curve;

  @override
  void initState() {
//--------------------[GET FILE]---------------
    if (title != null) {
      titleControl.value = TextEditingValue(text: title);
      widget.storage.read(title).then((value) {
        setState(() {
          text = value[0];
          title = value[1];
          composedTitle = title;
          composedText = text;
          titleControl.value = TextEditingValue(text: title);
          textController.value = TextEditingValue(text: text);
        });
      });
    } else {
      title = "";
      text = "";
      composedTitle = title;
      composedText = text;
    }

//--------------------[SET ANIMATIONS]---------------------------
    scaleControl = AnimationController(
        duration: const Duration(milliseconds: 700),
        reverseDuration: const Duration(milliseconds: 200),
        vsync: this,
        value: 0.0);
    curve = CurvedAnimation(parent: scaleControl, curve: Curves.linear);
    scaleTransition = curve;
    scaleControl.addListener(() {
      if (scaleControl.value == 0.0 && saved) {
        curve.curve = Curves.elasticOut;
        setState(() {
          boxReverse();
        });
      }
      if (scaleControl.value == 0.0 && !saved) {
        if (scale == 1) {
          curve.curve = curves[0];
          scaleControl.forward();
        }
        setState(() {
          boxforward();
        });
      }
    });
//------------------[CHECK IF KEYBOARD ON]-------------------
    // KeyboardVisibilityController().onChange.listen((event) {
    //   if (!event) {
    //     focus.unfocus();
    //     focusNode.unfocus();
    //   }
    // });
//--------------------------------------------------------------------
    super.initState();
  }

  void boxforward() {
    setState(() {
      scale = 1;
      edges = 15;
    });
  }

  void boxReverse() {
    setState(() {
      scale = 0;
      edges = 0;
    });
  }

  @override
  void dispose() {
    scaleControl.dispose();
    super.dispose();
  }

  Future<void> requestOverwrite() {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 320),
            padding: const EdgeInsets.all(0),

            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Título já existe.\nsubtituir?',
                        style: TextStyle(
                            fontFamily: font,
                            color: Colors.white,
                            fontSize: 20,
                            decoration: TextDecoration.none)),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Flexible(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextButton(
                          onPressed: () {
                            save(overwrite: true);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Sim',
                              style: TextStyle(
                                  //color: Colors.,
                                  fontFamily: font,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                    Flexible(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancelar',
                              style: TextStyle(
                                  //color: Colors.,
                                  fontFamily: font,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ]),
                ]),

            //           actions: [
            //             TextButton(
            //                 onPressed: () {
            //                   save(overwrite: true);
            //                   Navigator.of(context).pop();
            //                 },
            //                 child: Text('Sim')),
            //             TextButton(
            //                 onPressed: () {
            //                   Navigator.of(context).pop();
            //                 },
            //                 child: Text('Cancelar'))
            //           ],
          );
        });
  }

  Future<bool> save({bool update = false, bool overwrite = false}) async {
    if (titleControl.text.isEmpty) {
      var value = await widget.storage.write(text, "", home, composedTitle);
      composedTitle = value[0];
      title = value[0];
      titleControl.text = value[0];
      setSaved();
      return true;
    }
    if (update) {
      await widget.storage.rename(title, composedTitle, home);
      await widget.storage.write(text, title, home, composedTitle);
      setSaved();
      return true;
    } else {
      var value = await widget.storage.write(text, title, home, composedTitle);
      if (value[1] && title != composedTitle) {
        if (overwrite) {
          await widget.storage
              .write(text, title, home, composedTitle, overwrite: true);
          setSaved();
          return true;
        }
        requestOverwrite();
        return false;
      }
      setSaved();
      return true;
    }
  }

  setSaved() {
    setState(() {
      curve.curve = curves[1];
      scaleControl.reverse();
      saved = true;
      composedText = textController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!home.enabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
          overlays: SystemUiOverlay.values);
    }
    Color topAppBar = Color.fromRGBO(20, 20, 20, 1);

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          enter = false;
          home.enabled = true;
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
            overlays: SystemUiOverlay.values);
        Navigator.pop(context);
        return false;
      },
      child: MaterialApp(
        title: 'Editor',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.grey.shade900,
          body: Center(
//--------------[SCENE TRANSITION]-------------------
            child: AnimatedBuilder(
              animation: transitionAnimation,
              builder: (context, child) {
                return SlideTransition(
                    child: child,
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.9),
                            end: const Offset(0, 0))
                        .animate(CurvedAnimation(
                            parent: transitionAnimation,
                            curve: enter
                                ? Curves.elasticOut
                                : Curves.easeOutCubic)));
              },
//-------------------------------------------------------------
              child: Container(
                alignment: Alignment.topCenter,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        constraints: const BoxConstraints.expand(height: 60),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration:
                            BoxDecoration(color: Colors.black12, boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 10),
                          BoxShadow(color: topAppBar, blurRadius: 0),
                        ]),

//------------------------[BACK BUTTON]--------------------------------
                        child: Row(
                          children: [
                            IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
                                onPressed: () {
                                  setState(() {
                                    enter = false;
                                    home.enabled = true;
                                  });

                                  SystemChrome.setEnabledSystemUIMode(
                                      SystemUiMode.edgeToEdge,
                                      overlays: SystemUiOverlay.values);
                                  Navigator.pop(context);
                                }),

//-----------------------------------------------------------------------
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 10),
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(20)),
                                alignment: Alignment.center,
//------------------------------[TITLE]----------------------------------
                                child: TextField(
                                  controller: titleControl,
                                  focusNode: focusNode,
                                  textAlign: TextAlign.left,
                                  textAlignVertical: TextAlignVertical.top,
                                  //strutStyle: StrutStyle(height: 0),
                                  cursorWidth: 2,
                                  cursorRadius: Radius.circular(3),
                                  //mouseCursor: MouseCursor.defer,
                                  selectionWidthStyle: BoxWidthStyle.max,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: font,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                  //cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                      contentPadding: EdgeInsets.only(
                                        left: 0,
                                        top: 0,
                                        bottom: 5,
                                      ),
                                      border: InputBorder.none,
                                      hintText: "Insert title",
                                      hintStyle: TextStyle(
                                          color: Colors.grey.shade800)),
                                  onChanged: (String value) {
                                    title = titleControl.text;
                                    if (composedTitle != titleControl.text) {
                                      changed[0] = true;
                                      saved = false;
                                      if (scaleControl.value == 0) {
                                        print("box start forward 1");
                                        boxforward();
                                      }
                                    } else {
                                      changed[0] = false;
                                      if (!changed[1]) {
                                        if (scaleControl.value == 0) {
                                          boxReverse();
                                        }
                                        saved = true;
                                        curve.curve = curves[1];
                                        scaleControl.reverse();
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),

//-------------------------[SAVE BUTTON]---------------------------
                            GestureDetector(
                              onTap: () {
                                if (composedTitle.isNotEmpty &&
                                    title != composedTitle) {
                                  print("call r");
                                  save(update: true);
                                  composedTitle = titleControl.text;
                                } else {
                                  save();
                                }
                                focus.unfocus();
                                focusNode.unfocus();
                              },

//-------------------------[SAVE BUTTON ANIMATION]---------------------
                              child: AnimatedContainer(
                                onEnd: () {
                                  if (!saved) {
                                    print("icon forward, box end");
                                    scaleControl.reset();
                                    curve.curve = curves[0];
                                    scaleControl.forward();
                                  }
                                },
                                duration: Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(horizontal: edges),
                                padding: EdgeInsets.all(0),
                                child: AnimatedOpacity(
                                  opacity: scale,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                  child: ScaleTransition(
                                      scale: scaleTransition,
                                      child: Icon(
                                        Icons.done_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

//-------------------[Text]------------------------------
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints.expand(),
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            focusNode: focus,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            controller: textController,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: font,
                                fontSize: 16),
                            decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade800)),
                                hintStyle: TextStyle(color: Colors.grey),
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.all(10),
                                border: OutlineInputBorder(
                                    //borderSide: BorderSide(color: Colors.white),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5))),
                                hintText: "Insert text"),
                            onChanged: (String value) {
//--------------------------[SAVE BUTTON ANIMTION + TEXT]-------------------
                              if (composedText != textController.text) {
                                changed[1] = true;
                                text = textController.text;
                                saved = false;
                                if (scaleControl.value == 0) {
                                  print("box start forward 1");
                                  boxforward();
                                }
                              } else {
                                changed[1] = false;
                                if (!changed[0]) {
                                  if (scaleControl.value == 0) {
                                    boxReverse();
                                  }
                                  saved = true;
                                  curve.curve = curves[1];
                                  scaleControl.reverse();
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
