import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tubes/data/models/events_models.dart';
import 'package:tubes/data/models/task_item_model.dart';
import 'package:flutter/material.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Mendapatkan referensi collection
  CollectionReference get _eventsCollection =>
      _firestore.collection(_collection);

  // Membuat event baru
  Future<String> createEvent(EventModel event) async {
    try {
      debugPrint('EventRepository: Creating event: ${event.name}');
      DocumentReference docRef = await _eventsCollection.add(event.toMap());
      debugPrint('EventRepository: Event created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('EventRepository: Error creating event: $e');
      throw Exception('Gagal membuat event: $e');
    }
  }

  // Mendapatkan event berdasarkan ID
  Future<EventModel?> getEventById(String id) async {
    try {
      debugPrint('EventRepository: Getting event by ID: $id');
      DocumentSnapshot doc = await _eventsCollection.doc(id).get();
      if (doc.exists) {
        final event = EventModel.fromFirestore(doc);
        debugPrint('EventRepository: Found event: ${event.name}');
        return event;
      }
      debugPrint('EventRepository: Event not found with ID: $id');
      return null;
    } catch (e) {
      debugPrint('EventRepository: Error getting event by ID: $e');
      throw Exception('Gagal mendapatkan event: $e');
    }
  }

  // Mendapatkan event berdasarkan kode
  Future<EventModel?> getEventByCode(String code) async {
    try {
      debugPrint('EventRepository: Getting event by code: $code');
      QuerySnapshot query = await _eventsCollection
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final event = EventModel.fromFirestore(query.docs.first);
        debugPrint('EventRepository: Found event by code: ${event.name}');
        return event;
      }
      debugPrint('EventRepository: Event not found with code: $code');
      return null;
    } catch (e) {
      debugPrint('EventRepository: Error getting event by code: $e');
      throw Exception('Gagal mendapatkan event dengan kode: $e');
    }
  }

  // Mendapatkan semua event milik user
  Future<List<EventModel>> getEventsByOwner(String ownerId) async {
    try {
      debugPrint('EventRepository: Getting events by owner: $ownerId');
      QuerySnapshot query = await _eventsCollection
          .where('ownerId', isEqualTo: ownerId)
          .get(); // Remove orderBy to avoid composite index requirement

      final events = query.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      // Sort in memory instead
      events.sort((a, b) => a.date.compareTo(b.date));

      debugPrint('EventRepository: Found ${events.length} events by owner');
      return events;
    } catch (e) {
      debugPrint('EventRepository: Error getting events by owner: $e');
      throw Exception('Gagal mendapatkan event milik user: $e');
    }
  }

  // Mendapatkan event yang diikuti user
  Future<List<EventModel>> getEventsByMember(String userId) async {
    try {
      debugPrint('EventRepository: Getting events by member: $userId');
      QuerySnapshot query = await _eventsCollection
          .where('members', arrayContains: userId)
          .get(); // Remove orderBy to avoid composite index requirement

      final events = query.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      // Sort in memory instead
      events.sort((a, b) => a.date.compareTo(b.date));

      debugPrint('EventRepository: Found ${events.length} events by member');
      return events;
    } catch (e) {
      debugPrint('EventRepository: Error getting events by member: $e');
      throw Exception('Gagal mendapatkan event yang diikuti: $e');
    }
  }

  // Mendapatkan event berdasarkan kategori
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      debugPrint('EventRepository: Getting events by category: $category');
      QuerySnapshot query = await _eventsCollection
          .where('category', isEqualTo: category)
          .get();

      final events = query.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      events.sort((a, b) => a.date.compareTo(b.date));

      debugPrint('EventRepository: Found ${events.length} events by category');
      return events;
    } catch (e) {
      debugPrint('EventRepository: Error getting events by category: $e');
      throw Exception('Gagal mendapatkan event berdasarkan kategori: $e');
    }
  }

  // Mendapatkan event berdasarkan rentang tanggal
  Future<List<EventModel>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint('EventRepository: Getting events by date range');
      QuerySnapshot query = await _eventsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: false)
          .get();

      final events = query.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      debugPrint(
        'EventRepository: Found ${events.length} events by date range',
      );
      return events;
    } catch (e) {
      debugPrint('EventRepository: Error getting events by date range: $e');
      throw Exception('Gagal mendapatkan event berdasarkan tanggal: $e');
    }
  }

  // Update event
  Future<void> updateEvent(String id, EventModel event) async {
    try {
      debugPrint('EventRepository: Updating event: $id');
      await _eventsCollection.doc(id).update(event.toMap());
      debugPrint('EventRepository: Event updated successfully');
    } catch (e) {
      debugPrint('EventRepository: Error updating event: $e');
      throw Exception('Gagal mengupdate event: $e');
    }
  }

  // Hapus event
  Future<void> deleteEvent(String id) async {
    try {
      debugPrint('EventRepository: Deleting event: $id');
      await _eventsCollection.doc(id).delete();
      debugPrint('EventRepository: Event deleted successfully');
    } catch (e) {
      debugPrint('EventRepository: Error deleting event: $e');
      throw Exception('Gagal menghapus event: $e');
    }
  }

  // Bergabung dengan event
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      debugPrint('EventRepository: User $userId joining event $eventId');
      await _eventsCollection.doc(eventId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
      debugPrint('EventRepository: User joined event successfully');
    } catch (e) {
      debugPrint('EventRepository: Error joining event: $e');
      throw Exception('Gagal bergabung dengan event: $e');
    }
  }

  // Keluar dari event
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      debugPrint('EventRepository: User $userId leaving event $eventId');
      await _eventsCollection.doc(eventId).update({
        'members': FieldValue.arrayRemove([userId]),
        'rsvp.$userId': FieldValue.delete(),
      });
      debugPrint('EventRepository: User left event successfully');
    } catch (e) {
      debugPrint('EventRepository: Error leaving event: $e');
      throw Exception('Gagal keluar dari event: $e');
    }
  }

  // Update RSVP
  Future<void> updateRSVP(
    String eventId,
    String userId,
    bool isAttending,
  ) async {
    try {
      debugPrint(
        'EventRepository: Updating RSVP for user $userId in event $eventId: $isAttending',
      );
      await _eventsCollection.doc(eventId).update({
        'rsvp.$userId': isAttending,
      });
      debugPrint('EventRepository: RSVP updated successfully');
    } catch (e) {
      debugPrint('EventRepository: Error updating RSVP: $e');
      throw Exception('Gagal mengupdate RSVP: $e');
    }
  }

  // Menambahkan task baru
  Future<void> addTask(String eventId, TaskItem task) async {
    try {
      debugPrint(
        'EventRepository: Adding task to event $eventId: ${task.title}',
      );
      await _eventsCollection.doc(eventId).update({
        'tasks': FieldValue.arrayUnion([task.toMap()]),
      });
      debugPrint('EventRepository: Task added successfully');
    } catch (e) {
      debugPrint('EventRepository: Error adding task: $e');
      throw Exception('Gagal menambahkan task: $e');
    }
  }

  // Update task (mengganti seluruh array tasks)
  Future<void> updateTasks(String eventId, List<TaskItem> tasks) async {
    try {
      debugPrint('EventRepository: Updating tasks for event $eventId');
      await _eventsCollection.doc(eventId).update({
        'tasks': tasks.map((t) => t.toMap()).toList(),
      });
      debugPrint('EventRepository: Tasks updated successfully');
    } catch (e) {
      debugPrint('EventRepository: Error updating tasks: $e');
      throw Exception('Gagal mengupdate tasks: $e');
    }
  }

  // Menambahkan document link
  Future<void> addDocumentLink(String eventId, String docLink) async {
    try {
      await _eventsCollection.doc(eventId).update({
        'docLinks': FieldValue.arrayUnion([docLink]),
      });
    } catch (e) {
      throw Exception('Gagal menambahkan link dokumen: $e');
    }
  }

  // Menghapus document link
  Future<void> removeDocumentLink(String eventId, String docLink) async {
    try {
      await _eventsCollection.doc(eventId).update({
        'docLinks': FieldValue.arrayRemove([docLink]),
      });
    } catch (e) {
      throw Exception('Gagal menghapus link dokumen: $e');
    }
  }

  // Stream untuk real-time updates event tertentu
  Stream<EventModel?> streamEvent(String id) {
    return _eventsCollection.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Stream untuk real-time updates semua event milik user
  Stream<List<EventModel>> streamEventsByOwner(String ownerId) {
    return _eventsCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((query) {
          final events = query.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
          events.sort((a, b) => a.date.compareTo(b.date));
          return events;
        });
  }

  // Stream untuk real-time updates event yang diikuti user
  Stream<List<EventModel>> streamEventsByMember(String userId) {
    return _eventsCollection
        .where('members', arrayContains: userId)
        .snapshots()
        .map((query) {
          final events = query.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
          events.sort((a, b) => a.date.compareTo(b.date));
          return events;
        });
  }

  // Mendapatkan event dengan paginasi
  Future<List<EventModel>> getEventsWithPagination({
    DocumentSnapshot? lastDocument,
    int limit = 10,
    String? category,
    String? ownerId,
  }) async {
    try {
      Query query = _eventsCollection;

      // Filter berdasarkan kategori jika ada
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Filter berdasarkan owner jika ada
      if (ownerId != null && ownerId.isNotEmpty) {
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      // Order by a field that doesn't conflict with filters
      query = query.orderBy(FieldPath.documentId);

      // Untuk paginasi
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      QuerySnapshot snapshot = await query.get();
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      // Sort by date in memory
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } catch (e) {
      debugPrint('EventRepository: Error getting events with pagination: $e');
      throw Exception('Gagal mendapatkan event dengan paginasi: $e');
    }
  }

  // Pencarian event berdasarkan nama
  Future<List<EventModel>> searchEventsByName(String searchTerm) async {
    try {
      // For simple search, get all events and filter in memory
      // For production, consider using Algolia or similar service
      QuerySnapshot query = await _eventsCollection.get();

      final allEvents = query.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      final filteredEvents = allEvents.where((event) {
        return event.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
            event.description.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();

      filteredEvents.sort((a, b) => a.date.compareTo(b.date));
      return filteredEvents;
    } catch (e) {
      debugPrint('EventRepository: Error searching events: $e');
      throw Exception('Gagal mencari event: $e');
    }
  }

  // Batch operations untuk efisiensi
  Future<void> batchCreateEvents(List<EventModel> events) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (EventModel event in events) {
        DocumentReference docRef = _eventsCollection.doc();
        batch.set(docRef, event.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal membuat events secara batch: $e');
    }
  }

  // Mendapatkan statistik event
  Future<Map<String, int>> getEventStatistics(String ownerId) async {
    try {
      QuerySnapshot allEvents = await _eventsCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();

      int totalEvents = allEvents.docs.length;
      int upcomingEvents = 0;
      int pastEvents = 0;
      DateTime now = DateTime.now();

      for (DocumentSnapshot doc in allEvents.docs) {
        EventModel event = EventModel.fromFirestore(doc);
        if (event.date.isAfter(now)) {
          upcomingEvents++;
        } else {
          pastEvents++;
        }
      }

      return {
        'total': totalEvents,
        'upcoming': upcomingEvents,
        'past': pastEvents,
      };
    } catch (e) {
      throw Exception('Gagal mendapatkan statistik event: $e');
    }
  }
}
