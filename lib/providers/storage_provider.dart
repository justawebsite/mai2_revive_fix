import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/user.dart';

class GStorageList<T> {
  final GetStorage storage;
  final String key;
  final T Function(Map<String, dynamic> json) fact;
  final bool Function(T newItem, T oldItem)? compare;

  GStorageList(this.storage, this.key, this.fact, this.compare);  //创建并初始化函数定义

  List<T> get() {
    String? recordsJson = storage.read(key);
    return recordsJson == null
        ? []
        : (jsonDecode(recordsJson) as List<dynamic>)
            .where((item) => item != null)
            .map((item) => fact(item as Map<String, dynamic>))
            .toList();
  } //从存储中读取数据，并将其解析为 List<T>。

  T operator [](int index) => get()[index]; //重载操作符，获取指定索引的项。

  Future<void> set(List<T> records) async {
    return await storage.write(key, jsonEncode(records));
  }  //将 List<T> 写入存储。

  Future<void> add(T newItem) async {
    List<T> records = get();
    if (records.isNotEmpty) {
      records.removeWhere((item) => compare!(newItem, item));
    }
    List<T> list = [newItem];
    list.addAll(records);
    await set(list);
  } //添加新项到存储。

  Future<void> update(T oldItem, T newItem) async {
    List<T> list = get();
    int index = list.indexWhere((element) => element == oldItem);
    list[index] = newItem;
    await set(list);
  }  //更新指定项。

  Future<void> updateWhere(bool Function(T item) test, T newItem) async {
    List<T> list = get();
    int index = list.indexWhere(test);
    list[index] = newItem;
    await set(list);
  }  //根据条件更新项。

  Future<void> delete(T item) async {
    List<T> list = get();
    list.remove(item);
    await set(list);
  }  //删除指定项。

  Future<void> deleteWhere(bool Function(T item) test) async {
    List<T> list = get();
    list.removeWhere(test);
    await set(list);
  }  //根据条件删除项。

  Future<void> deleteByIndex(int index) async {
    List<T> list = get();
    list.removeAt(index);
    await set(list);
  }  //删除指定索引的项。

  bool contains(T item) {
    List<T> list = get();
    return list.contains(item);
  }  //检查存储中是否包含指定项

  bool containsWhere(bool Function(T item) test) {
    List<T> list = get();
    return list.any(test);
  }  //根据条件检查存储中是否包含项。

  Future<void> clean() async {
    await set([]);
  }  //清空存储。

  T findWhere(bool Function(T item) test) {
    List<T> list = get();
    return list.firstWhere(test);
  }  //根据条件查找项。
}

class StorageProvider {
  static late GetStorage _storage;

  static Future<void> init() async {
    await GetStorage.init();
    _storage = GetStorage();
  }  //初始化 GetStorage 实例。

  static GStorageList<UserModel> userList = GStorageList(
    _storage,
    "userList",
    UserModel.fromJson,
    (UserModel newItem, UserModel oldItem) => newItem.userId == oldItem.userId,
  );  //GStorageList<UserModel> 实例，用于管理用户数据。
}
