abstract class StorageService<T>{
  Future<bool> get isNotEmpty;
  Future<bool> get isEmpty;
  Future<List<T>> getAllEntry();
  Future<T?> getEntry(String key, {bool ignoreValid = false});
  Future<bool> putEntry(T entry);
  Future<bool> removeEntry(String key);
  Future<void> clearAllCache() async {}
  Future<void> flush() async {}
  Future<void> dispose() async {}
}