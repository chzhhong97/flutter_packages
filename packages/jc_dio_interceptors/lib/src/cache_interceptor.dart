import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jc_utils/jc_utils.dart';

class CacheInterceptor extends Interceptor{
  final List<CacheSetting> _settings;
  late StorageService<NetworkCacheEntry> _cacheService;
  final Set<int> _includedStatusCode;

  Map<String, CacheSetting> _forceCacheSettings = {};

  final FutureOr<bool> Function() onInternetCheck;

  static const String FORCE_REFRESH = "force_refresh";
  final bool callFollowingResponseInterceptor;
  final bool debugPrint;

  CacheInterceptor({
    List<CacheSetting> settings = const [],
    Set<int> includedStatusCode = const {},
    this.callFollowingResponseInterceptor = true,
    this.onInternetCheck = _onInternetCheck,
    this.debugPrint = false,
    StorageService<NetworkCacheEntry>? storageService,
    String? environment,
    String? userId,
  }) : _includedStatusCode = includedStatusCode, _settings = settings {
    _cacheService = storageService ?? HiveNetworkCacheService(environment: environment, userId: userId);
    for(final s in _settings){
      if(s.forceUseCache){
        _forceCacheSettings[s.apiUrl] = s;
      }
    }
  }

  static FutureOr<bool> _onInternetCheck() => true;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {

    if(options.extra.containsKey(FORCE_REFRESH)){
      final forceRefresh = options.extra[FORCE_REFRESH];
      //options.headers.remove("Force-Refresh");

      if(forceRefresh == true) return handler.next(options);
    }

    //use cache for forceCache api
    final url = options.path;

    final internetStatus = await onInternetCheck();

    if(internetStatus){
      // check for force cache
      for(final k in _forceCacheSettings.keys){
        if(url.contains(k)){
          final cacheKey = '${options.method}-${options.uri}';
          final cachedEntry = await _cacheService.getEntry(cacheKey);

          if(cachedEntry != null){
            if(cachedEntry.isForceCacheValid){
              _print("Force cache for $url");
              final response = _buildResponse(cachedEntry, options);
              return handler.resolve(response, callFollowingResponseInterceptor);
            }
          }
          break;
        }
      }
    }
    else{
      // check if the api url is include in cache setting list
      CacheSetting? cacheSetting = _getCacheSettings(url, method: options.method);
      if(cacheSetting == null) return handler.next(options);

      final cacheKey = '${options.method}-${options.uri}';
      final cachedEntry = await _cacheService.getEntry(cacheKey);

      _print("No internet");
      if(cachedEntry != null){
        _print("Use cache for $url");
        final response = _buildResponse(cachedEntry, options);
        return handler.resolve(response, callFollowingResponseInterceptor);
      }
      /*else{
          print("No cache for $url");
          return handler.reject(
              DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  message: 'Invalid Cache'
              )
          );
        }*/
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {

    final statusCode = response.statusCode;
    if(statusCode != null && statusCode >= 200 && statusCode < 300){
      final apiUrl = response.requestOptions.path;
      CacheSetting? cacheSetting = _getCacheSettings(apiUrl, method: response.requestOptions.method);

      if(cacheSetting == null) return handler.next(response);

      final entry = NetworkCacheEntry.fromResponse(
          response,
          cacheSetting.expiry,
          cacheSetting.forceCacheExpiry
      );

      await _cacheService.putEntry(entry);
      _print("Cached $apiUrl");
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {

    if(_connectionError(err)){
      final url = err.requestOptions.path;
      final cacheSettings = _getCacheSettings(url, method: err.requestOptions.method);
      if(cacheSettings == null){
        return handler.next(err);
      }

      final cacheKey = '${err.requestOptions.method}-${err.requestOptions.uri}';
      final cachedEntry = await _cacheService.getEntry(cacheKey);

      _print("Connectivity error");
      if(cachedEntry != null){
        _print("Use cache for $url");
        final response = _buildResponse(cachedEntry, err.requestOptions);
        return handler.resolve(response);
      }
    }

    return handler.next(err);
  }

  bool _connectionError(DioException err){
    if(_includedStatusCode.contains(err.response?.statusCode)){
      _print('Cache Interceptor On Error -> Url: ${err.response?.requestOptions.path}, StatusCode:${err.response?.statusCode}');
      return true;
    }

    if(err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) return true;

    return
      err.type == DioExceptionType.unknown &&
          err.error != null &&
          err.error is SocketException;
  }

  Response _buildResponse(
      NetworkCacheEntry cachedEntry,
      RequestOptions options,
      ){
    return Response(requestOptions: options, statusCode: cachedEntry.statusCode, data: cachedEntry.value);
  }

  CacheSetting? _getCacheSettings(String url, {String? method}){
    final index = _settings.indexWhere((e){
      return url.contains(e.apiUrl) && (method != null ? e.method.toUpperCase() == method.toUpperCase() : true);
    });

    if(index == -1) return null;

    return _settings[index];
  }

  bool isContainApiUrl(String url){
    for(final s in _settings){
      if(s.apiUrl == url){
        return true;
      }
    }
    return false;
  }

  Future<void> clearCache() {
    return _cacheService.clearAllCache();
  }

  Future<void> flush() => _cacheService.flush();

  void _print(Object? object){
    if(debugPrint) print(object);
  }
}

class HiveNetworkCacheService extends StorageService<NetworkCacheEntry>{
  bool _initialized = false;
  bool get initialized => _initialized;

  late final Box<String> _box;
  final String _boxName = "hive_network_cache";
  final String _boxNamePath = "networkCache";
  final String? _environment;
  final String? _userId;
  final bool _debugPrint;
  Completer? completer;

  HiveNetworkCacheService({String? environment, String? userId, bool debugPrint = false})
      : _environment = environment,
        _userId = userId,
      _debugPrint = debugPrint
  {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    if (completer != null && !completer!.isCompleted) return completer?.future;

    completer = Completer();

    await Hive.initFlutter();

    String boxName = _boxName;
    if(_userId != null) boxName = "${_boxName}_$_userId";

    try {
      final dir = await getApplicationSupportDirectory();

      String dirPath = '${dir.path}/$_boxNamePath';
      if(_environment != null) dirPath = "$dirPath/$_environment";

      _box = await Hive.openBox<String>(boxName, path: dirPath);
    } on MissingPlatformDirectoryException catch (e) {
      if(_environment != null) boxName = "${_environment}_$boxName";
      _box = await Hive.openBox<String>(boxName);
      _print(e);
    } on MissingPluginException catch (e) {
      if(_environment != null) boxName = "${_environment}_$boxName";
      _box = await Hive.openBox<String>(boxName);
      _print(e);
    } catch (e) {
      _print(e);
    }

    _initialized = true;
    completer?.complete();
  }

  @override
  Future<bool> get isEmpty => Future(() async {
    if(!_initialized) await _init();
    return _box.isEmpty;
  });

  @override
  Future<bool> get isNotEmpty => Future(() async {
    if(!_initialized) await _init();
    return _box.isNotEmpty;
  });

  @override
  Future<NetworkCacheEntry?> getEntry(String key, {bool ignoreValid = false}) async {
    if(!_initialized) await _init();

    final cachedEntry = _box.get(key);
    if(cachedEntry == null) return null;

    final entry = NetworkCacheEntry.fromJson(
        jsonDecode(cachedEntry) as Map<String, dynamic>
    );

    if(!entry.isValid && !ignoreValid){
      await _box.delete(entry.key);
      return null;
    }

    return entry;
  }

  @override
  Future<bool> putEntry(NetworkCacheEntry entry) async {
    if(!_initialized) await _init();

    final json = jsonEncode(entry.toJson());

    try{
      await _box.put(entry.key, json);
    }
    catch (e){
      _print(e);
      return false;
    }

    return true;
  }

  @override
  Future<void> clearAllCache() async {
    if(!_initialized) await _init();

    await _box.clear();
  }

  @override
  Future<List<NetworkCacheEntry>> getAllEntry() async {
    if(!_initialized) await _init();

    return _box.values.map((e) => NetworkCacheEntry.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  @override
  Future<bool> removeEntry(String key) async {
    if(!_initialized) await _init();

    try{
      await _box.delete(key);
    }
    catch (e){
      _print(e);
      return false;
    }

    return true;
  }

  void _print(Object? object){
    if(_debugPrint) print(object);
  }
}

class CacheSetting{
  final String apiUrl;
  final bool forceUseCache;
  final Duration? forceCacheExpiry;
  ///if put null mean forever
  final Duration? expiry;
  final String method;

  const CacheSetting({
    required this.apiUrl,
    this.method = 'GET',
    this.forceUseCache = false,
    this.forceCacheExpiry = const Duration(minutes: 5),
    this.expiry = const Duration(days: 7),
  });
}

class NetworkCacheEntry{
  final String key;
  final String method;
  final int? statusCode;
  final String? statusMessage;
  final dynamic value;
  final DateTime? forceCacheExpiry;
  final DateTime? expiry;

  const NetworkCacheEntry({
    required this.key,
    required this.method,
    this.statusCode,
    this.statusMessage,
    required this.value,
    required this.forceCacheExpiry,
    required this.expiry,
  });

  bool get isForceCacheValid => forceCacheExpiry != null ? forceCacheExpiry!.isAfter(DateTime.now()) : true;
  bool get isValid => expiry != null ? expiry!.isAfter(DateTime.now()) : true;

  factory NetworkCacheEntry.fromResponse(
      Response response,
      Duration? cacheLife,
      Duration? forceCacheLife,
      ){
    return NetworkCacheEntry(
      key: '${response.requestOptions.method}-${response.requestOptions.uri}',
      method: response.requestOptions.method,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      value: response.data,
      forceCacheExpiry: forceCacheLife != null ? DateTime.now().add(forceCacheLife) : null,
      expiry: cacheLife != null ? DateTime.now().add(cacheLife) : null,
    );
  }

  factory NetworkCacheEntry.fromJson(Map<String, dynamic> json) {
    return NetworkCacheEntry(
      key: json['key'] as String,
      method: json['key'] as String,
      statusCode: json['statusCode'] as int?,
      statusMessage: json['statusMessage'] as String?,
      value: json['value'] as dynamic,
      forceCacheExpiry: json['forceCacheExpiry'] != null ? DateTime.tryParse(json['forceCacheExpiry'] as String) : null,
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'method': method,
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'value': value,
      'forceCacheExpiry': forceCacheExpiry != null ? forceCacheExpiry!.toIso8601String() : 'forever',
      'expiry': expiry != null ? expiry!.toIso8601String() : 'forever',
    };
  }
}