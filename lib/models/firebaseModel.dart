import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sanskrit_project/models/dataModel.dart';
import 'package:sanskrit_project/models/signInModel.dart';

import 'data.dart';

class FirebaseModel {
  static const String projectName = 'sanskrit';
  static const String messagingSenderId = '68627785713';
  static const String projectId = 'sanskrit-f24c2';
  static const String apiKey = 'AIzaSyAqdnYH3NngvrpLB4a0MsNnZIZHOXmreg4';
  static const String appId = '1:68627785713:android:39ee8d5ca584fb837e0650';
  static FirebaseFirestore _db = FirebaseFirestore.instance;
  static DocumentReference ref;

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      name: projectName,
      options: FirebaseOptions(
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        apiKey: apiKey,
        appId: appId,
      ),
    );
  }

  void initializeCollection(String userId) {
    ref = _db.collection('users').doc(userId);
  }

  Future<void> uploadUserData(User user) async {
    initializeCollection(user.uid);
    List<String> connectedUserIds = [];
    await ref.set(
        {
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'userId': user.uid,
          'label': 'Beginner',
          'connectedUserIds': connectedUserIds,
        },
        SetOptions(
          merge: true,
        ));
  }

  Future<void> updateUserLabel(String label) async {
    await ref.update({
      'label': label,
    });
  }

  Future<void> updateConnectedUserIds(List<String> connectedUserIds) async {
    await ref.update({
      'connectedUserIds': connectedUserIds,
    });
  }

  Future<DataModel> getUserDataFromUser(User user) async {
    initializeCollection(user.uid);
    DataModel data = DataModel(
      name: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      userId: user.uid,
      label: 'Beginner',
    );
    return data;
  }

  Future<DataModel> getUserDataFromCloud(String userId) async {
    initializeCollection(userId);
    DataModel data = DataModel();
    await ref.get().then((documentSnapshot) {
      List<String> connectedUserIds = [];
      List<dynamic> connectedIds = documentSnapshot.data()['connectedUserIds'];
      connectedUserIds = connectedIds.cast<String>();
      data = DataModel(
        name: documentSnapshot.data()['name'],
        email: documentSnapshot.data()['email'],
        photoUrl: documentSnapshot.data()['photoUrl'],
        userId: documentSnapshot.data()['userId'],
        label: documentSnapshot.data()['label'],
        connectedUserIds: connectedUserIds,
      );
    });
    return data;
  }

  Future<void> fetchConnectedUser(String uid, BuildContext context) async {
    initializeCollection(uid);
    List<String> connectedUserIds = [];
    await ref.get().then((documentSnapshot) {
      List<dynamic> connectedIds = documentSnapshot.data()['connectedUserIds'];
      connectedUserIds = connectedIds.cast<String>();
    });
    Provider.of<Data>(context, listen: false)
        .storeConnectedUserIds(connectedUserIds);
  }

  Future<bool> fetchUsers(BuildContext context) async {
    SignInModel signInModel = SignInModel();
    String userId = signInModel.getCurrentUser().uid;
    fetchConnectedUser(userId, context);
    CollectionReference reference = _db.collection('users');
    await reference.get().then((cs) {
      cs.docs.forEach((documentSnapshot) async {
        if (documentSnapshot.id != userId) {
          print(documentSnapshot.data()['name']);
          DataModel dataModel = DataModel(
            name: documentSnapshot.data()['name'],
            email: documentSnapshot.data()['email'],
            photoUrl: documentSnapshot.data()['photoUrl'],
            userId: documentSnapshot.data()['userId'],
            label: documentSnapshot.data()['label'],
          );
          Provider.of<Data>(context, listen: false).addDataModel(dataModel);
        }
      });
    });
    return true;
    // Provider.of<Data>(context, listen: false).removeDataModel(dataModel);
  }
}
