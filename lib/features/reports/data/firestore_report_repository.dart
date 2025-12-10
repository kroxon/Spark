import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iskra/features/reports/domain/report_person.dart';
import 'package:iskra/features/reports/domain/report_template.dart';

class FirestoreReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreReportRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // --- Persons ---

  CollectionReference<Map<String, dynamic>> _getPersonsCollection() {
    final uid = _userId;
    if (uid == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .doc('data')
        .collection('persons');
  }

  Stream<List<ReportPerson>> watchPersons() {
    try {
      return _getPersonsCollection().snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ReportPerson.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> addPerson(ReportPerson person) async {
    await _getPersonsCollection().add(person.toMap());
  }

  Future<void> updatePerson(ReportPerson person) async {
    if (person.id.isEmpty) return;
    await _getPersonsCollection().doc(person.id).update(person.toMap());
  }

  Future<void> deletePerson(String personId) async {
    await _getPersonsCollection().doc(personId).delete();
  }

  // --- Templates ---

  CollectionReference<Map<String, dynamic>> _getTemplatesCollection() {
    final uid = _userId;
    if (uid == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .doc('data')
        .collection('templates');
  }

  Stream<List<ReportTemplate>> watchCustomTemplates() {
    try {
      return _getTemplatesCollection().snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ReportTemplate.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> addTemplate(ReportTemplate template) async {
    await _getTemplatesCollection().add(template.toMap());
  }

  Future<void> updateTemplate(ReportTemplate template) async {
    if (template.id.isEmpty) return;
    await _getTemplatesCollection().doc(template.id).update(template.toMap());
  }

  Future<void> deleteTemplate(String templateId) async {
    await _getTemplatesCollection().doc(templateId).delete();
  }
}
