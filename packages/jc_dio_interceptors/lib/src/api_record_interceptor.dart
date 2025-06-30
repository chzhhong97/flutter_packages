import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:jc_utils/jc_utils.dart';

class ApiRecordInterceptor extends Interceptor{

  ApiRecordInterceptor({this.antiSpam = false, this.debugPrint = false});

  final List<String> _records = [];
  List<String> get records => _records;
  final Set<String> _onGoingRequests = {};

  final bool antiSpam;
  final bool debugPrint;

  void clearRecord() {
    _records.clear();
    _apiCallingList.add([]);
  }

  Stream<List<String>> get apiCallingList => _apiCallingList.stream;
  final _apiCallingList = StreamControllerReEmit<List<String>>(initialValue: []);

  bool isApiRecorded(String path) => _records.contains(path);
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {

    if(antiSpam){
      final requestKey = _getRequestKey(options);
      if(_onGoingRequests.contains(requestKey)){
        // Cancel the request to avoid spamming
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Duplicate request [$requestKey]',
            type: DioExceptionType.cancel,
          ),
        );
      }
    }

    _records.add(options.path);
    _updateStream();
    _printRecord();
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {

    if(antiSpam){
      final requestKey = _getRequestKey(response.requestOptions);
      _onGoingRequests.remove(requestKey);
    }

    _records.remove(response.requestOptions.path);
    _updateStream();
    _printRecord();
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {

    if(antiSpam){
      final requestKey = _getRequestKey(err.requestOptions);
      _onGoingRequests.remove(requestKey);
    }

    _records.remove(err.requestOptions.path);
    _updateStream();
    _printRecord();
    return handler.next(err);
  }

  void _updateStream(){
    _apiCallingList.add(_records);
  }

  void _printRecord(){
    if(debugPrint) print('Current Calling API: $_records');
  }

  String _getRequestKey(RequestOptions options) {
    final method = options.method;
    final url = options.uri.toString();
    String data;

    if (options.data is FormData) {
      // Serialize FormData
      data = _formDataToString(options.data as FormData);
    } else if (options.data != null) {
      // Serialize other types of data (e.g., JSON)
      data = jsonEncode(options.data);
    } else {
      data = '';
    }

    return '$method-$url-$data';
  }

  String _formDataToString(FormData formData) {
    final fields = <String, dynamic>{};
    for (final field in formData.fields) {
      fields[field.key] = field.value;
    }
    for (final file in formData.files) {
      fields[file.key] = file.value.filename; // You can customize how you serialize files if needed
    }
    return jsonEncode(fields);
  }
}