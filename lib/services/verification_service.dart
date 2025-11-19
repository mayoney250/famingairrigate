import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Identifies what type of identifier was provided (email, phone, or cooperative ID)
  static String _identifyRequesterType(String identifier) {
    if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(identifier)) {
      return 'email';
    }
    if (identifier.startsWith('+') || 
        (identifier.replaceAll(RegExp(r'\D'), '').length >= 10 && 
         identifier.contains(RegExp(r'\d')))) {
      return 'phone';
    }
    if (RegExp(r'^[A-Z0-9-]{5,}$', caseSensitive: false).hasMatch(identifier)) {
      return 'cooperative_id';
    }
    return 'unknown';
  }

  /// Creates a verification request in Firestore. Returns the document id.
  /// The [requesterIdentifier] can be email, phone number, or cooperative ID.
  Future<String> createVerificationRequest(
    Map<String, dynamic> payload, {
    String requesterIdentifier = '',
  }) async {
    final identifierType = _identifyRequesterType(requesterIdentifier);
    
    final docRef = await _firestore.collection('verifications').add({
      ...payload,
      'requesterEmail': requesterIdentifier,
      'requesterIdentifierType': identifierType,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Reads admin email from settings/verification doc. Returns default if not present.
  Future<String> getAdminEmail({String defaultEmail = 'julieisaro01@gmail.com'}) async {
    try {
      final doc = await _firestore.collection('settings').doc('verification').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['adminEmail'] as String?) ?? defaultEmail;
      }
    } catch (_) {}
    return defaultEmail;
  }

  /// Updates verification request status (approve/reject)
  Future<void> updateVerificationStatus(
    String verificationId, {
    required String status,
    String? rejectionReason,
    String? approvedBy,
  }) async {
    final updateData = {
      'status': status,
      if (status == 'approved') 'approvedAt': FieldValue.serverTimestamp(),
      if (status == 'approved' && approvedBy != null) 'approvedBy': approvedBy,
      if (status == 'rejected') 'rejectedAt': FieldValue.serverTimestamp(),
      if (status == 'rejected' && rejectionReason != null) 'rejectionReason': rejectionReason,
    };
    await _firestore.collection('verifications').doc(verificationId).update(updateData);
  }

  /// Retrieves a verification request
  Future<Map<String, dynamic>?> getVerificationRequest(String verificationId) async {
    final doc = await _firestore.collection('verifications').doc(verificationId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }
}
