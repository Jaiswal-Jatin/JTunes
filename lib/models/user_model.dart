import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String mobile;
  final String address;
  final DateTime dob;
  String? profileImagePath;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobile,
    required this.address,
    required this.dob,
    this.profileImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'mobile': mobile,
      'address': address,
      'dob': Timestamp.fromDate(dob),
      'profileImagePath': profileImagePath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      dob: (map['dob'] as Timestamp? ?? Timestamp.now()).toDate(),
      profileImagePath: map['profileImagePath'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? mobile,
    String? address,
    DateTime? dob,
    String? profileImagePath,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}