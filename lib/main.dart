import 'dart:io';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'data_storage.dart';
import 'editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:english_words/english_words.dart';
// import 'package:flutter_statusbar_manager/flutter_statusbar_manager.dart';

const String font = 'Couriert';

class EditorPage extends PageRouteBuilder {
  EditorPage({String title, HomeState home})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              Editor(
            storage: DataStorage(),
            transitionAnimation: animation,
            home: home,
            title: title,
          ),
          transitionDuration: Duration(milliseconds: 1500),
        ) {
    home.enabled = false;
  }
}

void main() {
  runApp(MaterialApp(
    //initialRoute: '/home',
    title: 'Notes',
    debugShowCheckedModeBanner: false,
    home: Home(
      dataStorage: DataStorage(),
    ),
  ));
}

class Home extends StatefulWidget {
  Home({Key key, @required this.dataStorage}) : super(key: key);
  final DataStorage dataStorage;
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  double barHeight = 0;
  bool enabled = true;
  Directory dir;
  List<String> files = [];
  List<Tile> tiles = [];
  ScrollController scroll;
  AlwaysScrollableScrollPhysics scrollPhysics = AlwaysScrollableScrollPhysics();

  void update() {
    widget.dataStorage.directory.then((value) {
      dir = value;
      files = [];
      dir.list(recursive: false, followLinks: false).forEach((element) {
        var fileName = element
            .toString()
            .replaceFirst('File: \'' + dir.path + "/", "")
            .replaceFirst('.txt\'', "");

        if (!files.contains(fileName)) {
          files.add(fileName);
        }

        var found = false;

        for (var tile in tiles) {
          if (fileName == tile.text) {
            found = true;
          }
        }

        if (!found) {
          tiles.insert(
              0,
              Tile(
                text: fileName,
                storage: widget.dataStorage,
                tiles: tiles,
                home: this,
              ));
        }
      }).whenComplete(() {
        var toremove = [];
        for (var tile in tiles) {
          if (!files.contains(tile.text)) {
            toremove.add(tile);
          }
        }

        setState(() {
          for (var tile in toremove) {
            tiles.remove(tile);
          }
          print("update");
          tiles = tiles;
        });
      });
    });
  }

  @override
  void initState() {
    // SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values);
    widget.dataStorage.directory.then((value) => {
          dir = value,
          dir.list(recursive: false, followLinks: false).forEach((element) {
            files.add(element.toString());
            setState(() {
              var t = element
                  .toString()
                  .replaceFirst('File: \'' + dir.path + "/", "")
                  .replaceFirst('.txt\'', "");

              Tile tile = Tile(
                text: t,
                storage: widget.dataStorage,
                tiles: tiles,
                home: this,
              );
              tiles.add(tile);
            });
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    if (barHeight == 0) {
      barHeight = MediaQuery.of(context).viewPadding.top;
    }
    if (enabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
          overlays: SystemUiOverlay.values);
    }
    //
    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color.fromRGBO(51, 51, 51, 1),
        body: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 5),
              padding: EdgeInsets.only(left: 19, top: barHeight),
              constraints: BoxConstraints.expand(height: 60 + barHeight),
              decoration: BoxDecoration(color: Color.fromRGBO(33, 33, 33, 1)),
              alignment: Alignment.centerLeft,
              child: Text('Notes',
                  style: TextStyle(
                      fontFamily: font,
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Stack(children: [
                Container(
                    constraints: BoxConstraints.expand(),
                    margin: EdgeInsets.only(bottom: 0, top: 0),
                    child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(parent: scrollPhysics),
                        child: Column(children: tiles))),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey.shade700),
                      height: 40,
                      width: 40,
                      margin: EdgeInsets.all(50),
//------------------[ADD BUTTON]----------------------------
                      child: IconButton(
                          splashRadius: 1,
                          iconSize: 30,
                          padding: EdgeInsets.all(0),
                          //constraints: BoxConstraints.expand(),
                          alignment: Alignment.center,
                          icon: Icon(Icons.add_rounded, color: Colors.white),
                          onPressed: () {
                            nav();
                          })),
                ),
              ]),
            )
          ],
        ),
      ),
    );
  }

  void nav() {
    enabled = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values);
    Timer(Duration(milliseconds: 100), () {
      Navigator.of(context).push(EditorPage(home: this));
    });
  }
}

class Tile extends StatelessWidget {
  Tile({this.text, this.storage, this.tiles, this.home});
  final HomeState home;
  final List<Tile> tiles;
  final DataStorage storage;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        home.enabled = false;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
            overlays: SystemUiOverlay.values);
        Timer(Duration(milliseconds: 100), () {
          Navigator.of(context).push(EditorPage(home: home, title: text));
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints.expand(height: 60),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: Colors.white12),
        child: Row(
          children: [
            Text(text,
                style: TextStyle(
                  fontFamily: font,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                )),
            Flexible(
              child: Container(
                alignment: Alignment.centerRight,
                child: IconButton(
                    alignment: Alignment.centerRight,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      tiles.remove(this);
                      home.update();
                      storage.delete(text, home);
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }
}

//END CLASS--------------------------------------
class Chat extends StatefulWidget {
  const Chat({
    Key key,
  }) : super(key: key);

  @override
  ChatState createState() => ChatState();
}

class Message extends StatelessWidget {
  Message({this.text, this.name, this.animationController});
  final String text;
  final String name;
  final AnimationController animationController;
  //final String name = "Koi";

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
          parent: animationController, curve: Curves.elasticOut),
      axisAlignment: 0,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: Text(name[0])),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.headline6),
                Container(
                  margin: EdgeInsets.only(top: 1.0),
                  child: Text(text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatState extends State<Chat> with TickerProviderStateMixin {
  final List<Message> messages = [];
  final textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    for (var message in messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.blue),
      home: ScrollConfiguration(
        behavior: NoScrollGlow(),
        child: Scaffold(
          appBar: AppBar(title: Text('FriendlyChat')),
          body: Column(
            children: [
              Flexible(
                child: ListView.builder(
                  physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.all(8.0),
                  reverse: true,
                  itemBuilder: (context, int index) => messages[index],
                  itemCount: messages.length,
                ),
              ),
              Divider(height: 1.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: buildChat(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  var hide = false;
  Widget buildChat() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).secondaryHeaderColor),
      child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Flexible(
                  child: TextField(
                focusNode: _focusNode,
                controller: textController,
                onSubmitted: submitted,
                onTap: () => {},
                onEditingComplete: () =>
                    {SystemChannels.textInput.invokeMethod('TextInput.hide')},
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(5),

                    //isDense: true,
                    isCollapsed: true,
                    border: OutlineInputBorder(
                        borderSide:
                            BorderSide(width: 1, color: Colors.deepPurple),
                        borderRadius: BorderRadius.all(Radius.circular(8))),
                    hintText: "Insert text"),
              )),
              IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () => {submitted(textController.text)})
            ],
          )),
    );
  }

  void submitted(String text) {
    textController.clear();
    Message message = Message(
      text: text,
      name: "Koi",
      animationController: AnimationController(
          duration: Duration(milliseconds: 700), vsync: this),
    );
    setState(() {
      messages.insert(0, message);
    });
    message.animationController.forward();
    _focusNode.requestFocus();
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Colors.white,
          primarySwatch: Colors.pink,
        ),
        home: Scaffold(
            body: Center(
          child: DisplayScreen(),
          //  child: Column(mainAxisSize: MainAxisSize.min, children: [
          //Text("This is an app\n"),
          //DisplayScreen()
        )));
  }
}

class DisplayScreen extends StatefulWidget {
  @override
  DisplayScreenState createState() => DisplayScreenState();
}

class DisplayScreenState extends State<DisplayScreen> {
  final words = <WordPair>[];
  final favorited = <WordPair>{};
  final biggerFont = TextStyle(fontSize: 18);

  void openFavorited() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      final cells = favorited.map((WordPair pair) {
        return ListTile(title: Text(pair.asPascalCase, style: biggerFont));
      });

      final divided = ListTile.divideTiles(
        context: context,
        tiles: cells,
      ).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text("Favorited"),
        ),
        body: ListView(children: divided),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(icon: Icon(Icons.list_rounded), onPressed: openFavorited)
          ],
          title: Text("Home"),
        ),
        body: showWords());
    //return Container(child: Text(words.asPascalCase));
  }

  Widget showWords() {
    return ScrollConfiguration(
        behavior: NoScrollGlow(),
        child: ListView.builder(
            physics:
                BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.all(16.0),
            itemBuilder: (context, x) {
              if (x.isOdd) return Divider();

              final index = x ~/ 2;

              if (index >= words.length) {
                words.addAll(generateWordPairs().take(10));
              }
              return buildRow(words[index]);
            }));
  }

  Widget buildRow(WordPair pair) {
    final isFavorited = favorited.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: biggerFont,
      ),
      trailing: Icon(
          isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorited ? Colors.red : null),
      onTap: () {
        setState(() {
          if (isFavorited) {
            favorited.remove(pair);
          } else {
            favorited.add(pair);
          }
        });
      },
    );
  }
}

class NoScrollGlow extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
