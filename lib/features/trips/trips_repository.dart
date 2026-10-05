import 'package:cloud_firestore/cloud_firestore.dart';

import 'trip_model.dart';

class TripsRepository {
  final FirebaseFirestore _firestore;

  TripsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tripsRef =>
      _firestore.collection('trips');

  Stream<List<Trip>> getUserTripsStream(String userId) {
    return _tripsRef
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Trip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<Trip>> getTripsOnce(String userId) async {
    final snap = await _tripsRef
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.map((doc) => Trip.fromMap(doc.data(), doc.id)).toList();
  }

  Stream<Trip?> getTripByIdStream(String tripId) {
    return _tripsRef.doc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Trip.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> createTrip(Trip trip) async {
    await _tripsRef.add(trip.toMap());
  }

  Future<void> updateTrip(Trip trip) async {
    await _tripsRef.doc(trip.id).update({
      'title': trip.title,
      'date': Timestamp.fromDate(trip.date),
      'locationName': trip.locationName,
      'species': trip.species,
      'notes': trip.notes,
    });
  }

  Future<void> deleteTrip(String tripId) async {
    await _tripsRef.doc(tripId).delete();
  }
}
