import 'dart:convert';

import 'package:dio/dio.dart';

class CancelInterceptor extends Interceptor{
  CancelInterceptor({this.onLog});

  final Map<String, CancelToken> _cancelTokens = {};
  static const CANCEL_ID = 'api_cancel_id';
  final Function(String log)? onLog;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {

    final key = getKey(options);
    options.extra.update(CANCEL_ID, (v) => key, ifAbsent: () => key);

    if(options.cancelToken != null){
      _cancelTokens[key] = options.cancelToken!;
    }
    else{
      final cancelToken = CancelToken();
      options.cancelToken = cancelToken;
      _cancelTokens[key] = cancelToken;
    }

    _log(_getRequestLog(options));
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _removeFromRecord(response.requestOptions);

    _log(_getResponseLog(response));
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _removeFromRecord(err.requestOptions);

    _log(_getErrorLog(err));
    super.onError(err, handler);
  }

  void _removeFromRecord(RequestOptions options){
    _cancelTokens.remove(options.extra[CANCEL_ID]);
  }

  String getKey(RequestOptions options){
    return 'cancel_${options.path}_${DateTime.now().toIso8601String()}';
  }

  void cancelAllRequest(){
    for(final c in _cancelTokens.values){
      if(!c.isCancelled) c.cancel();
    }

    _cancelTokens.removeWhere((k,v) => v.isCancelled);
  }

  String _getRequestLog(RequestOptions requestOptions){
    StringBuffer buffer = StringBuffer();
    buffer.writeln('OnRequest - [${requestOptions.method}]${requestOptions.uri.toString()}');
    if(requestOptions.data != null){
      if(requestOptions.data is FormData){
        final formData = requestOptions.data as FormData;
        buffer.writeln('  FormData');
        buffer.writeln(_parseJson(Map.fromEntries(formData.fields), prefix: '  '));
        if(formData.files.isNotEmpty){
          buffer.writeln('  Files');
          buffer.writeln(_parseJson(Map.fromEntries(formData.files.map((e) => MapEntry(e.key, e.value.filename))), prefix: '  '));
        }
      }
      else if (requestOptions.data is Map<String, dynamic>){
        buffer.writeln('  RequestBody');
        buffer.writeln(_parseJson((requestOptions.data as Map<String, dynamic>), prefix: '  '));
      }
    }
    return buffer.toString();
  }

  String _getResponseLog(Response response){
    StringBuffer buffer = StringBuffer();
    buffer.writeln('OnResponse - [${response.requestOptions.method}]${response.requestOptions.uri.toString()}');
    if(response.data != null){
      if (response.data is Map<String, dynamic>){
        buffer.writeln('  ResponseBody');
        buffer.writeln(_parseJson((response.data as Map<String, dynamic>), prefix: '  '));
      }
      else if(response.data is List<int>){
        buffer.writeln('  ResponseBody: bytes');
      }
    }
    return buffer.toString();
  }

  String _getErrorLog(DioException err){
    StringBuffer buffer = StringBuffer();
    buffer.writeln('OnError - [${err.requestOptions.method}]${err.requestOptions.uri.toString()}');
    buffer.writeln('  DioExceptionType: ${err.type.name}');
    buffer.writeln('  ErrorMessage: ${err.message}');
    if(err.response?.data != null){
      if (err.response!.data is Map<String, dynamic>){
        buffer.writeln('  ResponseBody');
        buffer.writeln(_parseJson((err.response!.data as Map<String, dynamic>), prefix: '  '));
      }
      else if(err.response!.data is List<int>){
        buffer.writeln('  ResponseBody: bytes');
      }
    }
    return buffer.toString();
  }

  String _parseJson(Map<String, dynamic> json, {String prefix = ''}){
    try{
      StringBuffer buffer = StringBuffer();
      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(json);
      prettyJson.split('\n').forEach((e) => buffer.writeln('$prefix$e'));

      return buffer.toString();
    }
    catch(e){

    }
    return 'Unable to parse this json';
  }

  void _log(String log){
    onLog?.call(log);
  }
}