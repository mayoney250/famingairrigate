import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatar;
  final bool isActive;
  final DateTime createdAt;
  final List<String> tokens;
  final bool isOnline;
  final String? lastActive;
  final String? about;
  final bool isPublic;
  final String? district;
  final String? province;
  final String country;
  final String? address;
  final String role;
  final String? languagePreference;
  final String? themePreference;

  UserModel({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatar,
    this.isActive = true,
    required this.createdAt,
    this.tokens = const [],
    this.isOnline = false,
    this.lastActive,
    this.about,
    this.isPublic = true,
    this.district,
    this.province,
    this.country = 'Rwanda',
    this.address,
    this.role = 'farmer',
    this.languagePreference = 'en',
    this.themePreference = 'light',
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'tokens': tokens,
      'isOnline': isOnline,
      'lastActive': lastActive,
      'about': about,
      'isPublic': isPublic,
      'district': district,
      'province': province,
      'country': country,
      'address': address,
      'role': role,
      'languagePreference': languagePreference,
      'themePreference': themePreference,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'],
      avatar: map['avatar'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tokens: List<String>.from(map['tokens'] ?? []),
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'],
      about: map['about'],
      isPublic: map['isPublic'] ?? true,
      district: map['district'],
      province: map['province'],
      country: map['country'] ?? 'Rwanda',
      address: map['address'],
      role: map['role'] ?? 'farmer',
      languagePreference: map['languagePreference'] ?? 'en',
      themePreference: map['themePreference'] ?? 'light',
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatar,
    bool? isActive,
    DateTime? createdAt,
    List<String>? tokens,
    bool? isOnline,
    String? lastActive,
    String? about,
    bool? isPublic,
    String? district,
    String? province,
    String? country,
    String? address,
    String? role,
    String? languagePreference,
    String? themePreference,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      tokens: tokens ?? this.tokens,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      about: about ?? this.about,
      isPublic: isPublic ?? this.isPublic,
      district: district ?? this.district,
      province: province ?? this.province,
      country: country ?? this.country,
      address: address ?? this.address,
      role: role ?? this.role,
      languagePreference: languagePreference ?? this.languagePreference,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

