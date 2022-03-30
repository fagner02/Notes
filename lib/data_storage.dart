import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'main.dart';

class DataStorage {
  String _title = '';
  Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<Directory> get directory async {
    final path = await localPath;
    var dir = Directory('$path/notes');
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    return dir;
  }

  Future<File> get localFile async {
    final path = await dirPath;
    return File('$path/$_title.txt');
  }

  Future<String> get dirPath async {
    String path;
    path = await localPath + '/' + 'notes';
    return path;
  }

  Future<void> delete(String title, HomeState home) async {
    _title = title;
    final file = await localFile;
    file.delete();
    home.update();
  }

  Future<File> rename(String newtitle, String filename, HomeState home) async {
    var oldPath = await dirPath + '/$filename.txt';
    var newPath = await dirPath + '/$newtitle.txt';
    final oldFile = File(oldPath);
    final newfile = File(newPath);
    String text = await oldFile.readAsString();
    newfile.create().whenComplete(() {
      newfile.writeAsString(text).whenComplete(() {
        oldFile.delete().whenComplete(() async {
          if (!(await oldFile.exists()) && await newfile.exists()) {
            print("yeah" + newfile.toString());
            home.update();
          }
        });
      });
    });
    return newfile;
  }

  Future<List> write(
      String text, String title, HomeState home, String composedTitle,
      {bool overwrite = false}) async {
    if (title.isEmpty) {
      int x;
      final file = File(await localPath + '/' + 'data.txt');
      if (!file.existsSync()) {
        title = "Sem título";
        file.create();
        file.writeAsString('1');
      } else {
        x = int.parse(await file.readAsString());
        title = "Sem título " + x.toString();
        file.writeAsString((x + 1).toString());
      }
    }
    _title = title;
    final file = await localFile;
    if (await file.exists() && title != composedTitle && !overwrite) {
      return ['', true];
    }
    file.writeAsString('$text');
    home.update();
    return [title, false];
  }

  Future<List<String>> read(String title) async {
    try {
      _title = title;
      print(await dirPath + " path");
      final file = await localFile;
      String contents = await file.readAsString();
      return [contents, title];
    } catch (e) {
      return ["", ""];
    }
  }
}
