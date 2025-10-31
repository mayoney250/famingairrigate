import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'user_model.g.dart';

@HiveType(typeId: 5)
class UserModel extends HiveObject {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String firstName;
  @HiveField(3)
  final String lastName;
  @HiveField(4)
  final String? phoneNumber;
  @HiveField(5)
  final String? avatar;
  @HiveField(6)
  final bool isActive;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final List<String> tokens;
  @HiveField(9)
  final bool isOnline;
  @HiveField(10)
  final String? lastActive;
  @HiveField(11)
  final String? about;
  @HiveField(12)
  final bool isPublic;
  @HiveField(13)
  final String? district;
  @HiveField(14)
  final String? province;
  @HiveField(15)
  final String country;
  @HiveField(16)
  final String? address;
  @HiveField(17)
  final String role;
  @HiveField(18)
  final String? languagePreference;
  @HiveField(19)
  final String? themePreference;
  @HiveField(20)
  final String? idNumber;
  @HiveField(21)
  final String? gender;
  @HiveField(22)
  final DateTime? dateOfBirth;

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
    this.idNumber,
    this.gender,
    this.dateOfBirth,
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
      'idNumber': idNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
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
      idNumber: map['idNumber'],
      gender: map['gender'],
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
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
    String? idNumber,
    String? gender,
    DateTime? dateOfBirth,
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
      idNumber: idNumber ?? this.idNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}

