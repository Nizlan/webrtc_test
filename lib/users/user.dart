import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../messaging.dart';

class UserModel {
  String name;
  String deviceId;
  UserModel({
    required this.name,
    required this.deviceId,
  });
}

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  Future<void> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('user');
    if (name == null) {
      state = null;
    } else {
      String? token = await Messaging.getToken();
      if (token != null) {
        state = UserModel(name: name, deviceId: token);
        await User().setUser(state!);
      }
    }
  }

  Future<void> setUser(String name) async {
    print('input');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', name);
    String? token = await Messaging.getToken();
    if (token != null) {
      UserModel user = UserModel(name: name, deviceId: token);
      await User().setUser(user);
      state = user;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

class User {
  FirebaseFirestore db = FirebaseFirestore.instance;
  Future<void> setUser(UserModel user) async {
    CollectionReference users = db.collection('users');
    var us = (await users.where('user', isEqualTo: user.name).get());
    if (us.docs.isNotEmpty) {
      var doc = us.docs[0].reference;
      await doc.update({'user': user.name, 'token': user.deviceId});
    } else {
      await users.add({'user': user.name, 'token': user.deviceId});
    }
  }
}
