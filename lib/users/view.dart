// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_rtc/users/user.dart';

class UsersList extends StatelessWidget {
  final String? username;
  final UserModel? chosenUser;
  final void Function(UserModel token) onTapped;
  const UsersList(
      {Key? key, this.username, this.chosenUser, required this.onTapped})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _usersStream =
        FirebaseFirestore.instance.collection('users').snapshots();
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }

        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: ListView(
            shrinkWrap: true,
            children: snapshot.data!.docs
                .where((element) =>
                    (element.data()! as Map<String, dynamic>)['user'] !=
                    username)
                .map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return Center(
                child: InkWell(
                  onTap: () => onTapped(
                      UserModel(name: data['user'], deviceId: data['token'])),
                  child: Text(
                    data['user'],
                    style: TextStyle(
                        color: chosenUser?.name == data['user']
                            ? Colors.red
                            : null),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
