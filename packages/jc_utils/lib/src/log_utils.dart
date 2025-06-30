import 'dart:async';
import 'dart:io';

abstract class LogUtils{
  LogUtils();

  final List<String> _pendingList = [];
  Completer? _completer;
  String? _path;
  String? _fileName;

  void log(String log){
    _pendingList.add(log);
    writePendingList();
  }

  Future writePendingList() async {
    if(_completer != null && _completer?.isCompleted != true) return _completer?.future;
    _completer = Completer();
    _writePendingList();
    if( _completer?.isCompleted != true) return _completer?.future;
  }

  void _writePendingList() async {
    final currentList = List.from(_pendingList);
    _pendingList.removeWhere((element) => currentList.contains(element));
    for(final String log in currentList){
      //await FileHelper.writeToLogFile("${DateTime.fromMillisecondsSinceEpoch(l.timeStamp).toString()} -> ${l.action}\n\n");
      final result = await _writeToFile(
          log,
          _path ??= await getFilePath(),
          _fileName ??= await getFileName(),
          append: true
      );
      //write to txt;
      if(result){
        onWriteSuccess(log);
      }
      else{
        onWriteFail(log);
      }
      
    }

    //check if pendingList still have log, if have call writePendingList again
    if(_pendingList.isNotEmpty) {
      _writePendingList();
    } else {
      _completer?.complete();
    }
  }

  Future<bool> _writeToFile(String txt, String path, String fileName,
      {bool append = false}) async {
    try {
      final directory = Directory(path);
      if (!(await directory.exists())) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}$fileName');
      if (!await file.exists()) {
        await file.writeAsString('');
      }
      await file.writeAsString(txt, mode: append ? FileMode.append : FileMode.write);
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
  
  Future<String> getFilePath();
  Future<String> getFileName();
  void onWriteSuccess(String log){}
  void onWriteFail(String log){}
}

interface class Logger{
  void onLog(String log){}
}