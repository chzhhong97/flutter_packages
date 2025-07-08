import 'dart:io';
import 'package:dio/dio.dart';

class APIException implements Exception {
  final DioException? dioException;
  final String? message;
  final int errorCode;

  static const int timeoutException = 1000;
  static const int badCertificateException = 1001;
  static const int badResponseException = 1002;
  static const int connectionException = 1003;
  static const int cancelException = 1004;
  static const int typeErrorException = 1005;
  static const int dioUnknownException = 1006;
  static const int unknownException = -1;

  APIException({this.dioException, this.message, this.errorCode = unknownException});

  APIException.dioException({
    required this.dioException,
    this.message
  }) : errorCode = _getErrorCodeForDio(dioException);

  @override
  String toString() {
    return 'Error Code: $errorCode${_getErrorMessage().isNotEmpty ? "\n${_getErrorMessage()}" : ''}';
    return 'DioExceptionType: ${dioException?.type}\nMessage: $message';
  }

  String _getErrorMessage(){
    if(errorCode == timeoutException){
      return "Connection timeout";
    }

    if(errorCode == badCertificateException){
      return "Bad certificate";
    }

    if(errorCode == connectionException){
      return "Connection interrupted";
    }

    return '';
  }

  static int _getErrorCodeForDio(DioException? dioException){
    switch(dioException?.type){
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return timeoutException;
      case DioExceptionType.badCertificate:
        return badCertificateException;
      case DioExceptionType.badResponse:
        return badResponseException;
      case DioExceptionType.cancel:
        return cancelException;
      case DioExceptionType.connectionError:
        return connectionException;
      case DioExceptionType.unknown:
        if(dioException?.error is HttpException ||
            dioException?.error is SocketException){
          return connectionException;
        }
        return dioUnknownException;
      default:
        return unknownException;
    }
  }
}