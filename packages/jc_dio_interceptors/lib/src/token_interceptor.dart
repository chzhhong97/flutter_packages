import 'dart:async';

import 'package:dio/dio.dart';

class TokenInterceptor extends QueuedInterceptor{
  final Dio dio;
  final FutureOr<String?> Function() getAuthorizationToken;
  final FutureOr<void> Function(Dio dio, DioException err, ErrorInterceptorHandler handler) onUnauthorized;
  final String _authorizationHeader = "Authorization";
  
  TokenInterceptor({required this.dio, required this.getAuthorizationToken, required this.onUnauthorized});
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {

    final token = await getAuthorizationToken();
    if(token != null){
      options.headers[_authorizationHeader] = token;
    }
    
    super.onRequest(options, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if(err.response?.statusCode == 401){
      onUnauthorized(dio, err, handler);
    }
    else{
      handler.next(err);
    }
  }
}