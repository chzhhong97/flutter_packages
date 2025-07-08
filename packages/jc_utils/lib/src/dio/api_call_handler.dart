import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jc_utils/src/dio/api_exception.dart';
import 'package:jc_utils/src/dio/duplicate_path_check.dart';
import 'package:json_annotation/json_annotation.dart' show CheckedFromJsonException;

class APICallHandler {
  final Future<bool> Function() onCheckUnauthorized;

  /// Provide the list of API path that you don't want to call duplicate
  final List<DuplicatePathCheck> duplicateAPIPathBlacklist;
  /// Block others API call whenever there is API calling from this list
  final List<String> onGoingAPIBlock;
  final Function(String log)? onLog;

  APICallHandler({
    required this.onCheckUnauthorized,
    this.duplicateAPIPathBlacklist = const [],
    this.onGoingAPIBlock = const [],
    this.onLog,
  });

  final Map<String, Future> _onGoingRequests = {};

  Future<T?> callAPI<T>(
      Future<T> Function() api,
      String method,
      String apiName,
      Function(T response)? onSuccess,
      Function(APIException exception)? onFailure) async {

    if(_onGoingRequests.keys.any((e) => onGoingAPIBlock.contains(e))){
      _log("Blocked API Call: $apiName");
      return null as T?;
    }

    final index =
    duplicateAPIPathBlacklist.indexWhere((e) => e.isSameAPIPath(apiName));
    if (index == -1 && !onGoingAPIBlock.contains(apiName)) {
      return onCallAPI(api, method, apiName, onSuccess, onFailure);
    }

    if (_onGoingRequests.containsKey(apiName)) {
      return _onGoingRequests[apiName] as Future<T?>;
    }

    final future = onCallAPI(api, method, apiName, onSuccess, onFailure);
    _onGoingRequests[apiName] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _onGoingRequests.remove(apiName);
    }
  }

  Future<T?> onCallAPI<T>(
      Future<T> Function() api,
      String method,
      String apiName,
      Function(T response)? onSuccess,
      Function(APIException exception)? onFailure) async {
    if (await onCheckUnauthorized()) {
      return null;
    }

    try {
      _log('Start calling $apiName');
      final response = await api();
      _log('Call $apiName success');

      //differentiate between onSuccess exception and Api exception
      try {
        await onSuccess?.call(response);
        return response;
      } on TypeError catch (e) {
        String error = "$apiName onSuccess Type Error -> ${e.stackTrace}";
        _log(error);
        onFailure?.call(APIException(message: error));
      } catch (e) {
        String error = "$apiName onSuccess Error -> ${e.toString()}";
        _log(error);
        onFailure?.call(APIException(message: error));
      }

      return null;
    } on DioException catch (e) {
      if (kDebugMode) debugPrint(e.type.toString());
      if (kDebugMode) debugPrint(e.error.toString());
      if (kDebugMode) debugPrint(e.message);
      _log('DioException -> $e}');
      onFailure?.call(APIException.dioException(dioException: e, message: e.error?.toString() ?? e.message));
    } on CheckedFromJsonException catch (e) {
      String error = "$apiName Json Error -> ${e.toString()}";
      _log(error);
      onFailure?.call(APIException(message: error, errorCode: APIException.typeErrorException));
    } on TypeError catch (e) {
      String error = "$apiName Type Error -> \n${e.stackTrace}";
      _log(error);
      onFailure?.call(APIException(message: error, errorCode: APIException.typeErrorException));
    } on SocketException catch (e) {
      String error = "$apiName Type Error -> \n${e.message}";
      _log(error);
      onFailure?.call(APIException(message: error, errorCode: APIException.connectionException));
    } catch (e) {
      String error = "$apiName Unknown Error -> $e";
      if (kDebugMode) debugPrint("Type ${e.runtimeType.toString()}");
      if (kDebugMode) debugPrint(error);
      _log(error);
      onFailure?.call(APIException(message: error, errorCode: APIException.unknownException));
    }
    return null;
  }

  void reset() {
    _onGoingRequests.values.forEach((e) => e.ignore());
    _onGoingRequests.clear();
  }

  void _log(String log) {
    onLog?.call(log);
  }
}