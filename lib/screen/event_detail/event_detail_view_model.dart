import 'package:flutter/material.dart';
import 'package:tubes/data/models/events_models.dart';
import 'package:tubes/data/repositories/event_repository.dart';
import 'package:tubes/bloc/event/event_bloc.dart';
import 'package:tubes/bloc/event/event_event.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailViewModel with ChangeNotifier {
  final EventRepository eventRepository;
  final EventBloc eventBloc;

  EventModel? _event;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isLoading = false;
  String? _errorMessage;

  EventDetailViewModel({
    required this.eventRepository,
    required this.eventBloc,
  });

  // Getters
  EventModel? get event => _event;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isOwner {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null &&
        _event != null &&
        _event!.ownerId == currentUser.uid;
  }

  // Initialize method to set the event
  void initialize(EventModel event) {
    _event = event;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh event data
  Future<void> refreshEvent() async {
    if (_event == null) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedEvent = await eventRepository.getEventById(_event!.id);
      if (updatedEvent != null) {
        _event = updatedEvent;
      } else {
        _errorMessage = 'Event not found';
      }
    } catch (e) {
      _errorMessage = 'Failed to refresh event: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update event
  Future<bool> updateEvent(EventModel updatedEvent) async {
    try {
      _isSaving = true;
      _errorMessage = null;
      notifyListeners();

      await eventRepository.updateEvent(updatedEvent.id, updatedEvent);

      // Update local event data
      _event = updatedEvent;

      // Refresh the event list in bloc
      eventBloc.add(LoadEventsByOwner(updatedEvent.ownerId));

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update event: ${e.toString()}';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent() async {
    if (_event == null) return false;

    try {
      _isDeleting = true;
      _errorMessage = null;
      notifyListeners();

      await eventRepository.deleteEvent(_event!.id);

      // Refresh the event list in bloc
      eventBloc.add(LoadEventsByOwner(_event!.ownerId));

      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete event: ${e.toString()}';
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  // Update RSVP status
  Future<bool> updateRSVP(String userId, bool isAttending) async {
    if (_event == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create updated RSVP map
      final updatedRSVP = Map<String, bool>.from(_event!.rsvp);
      updatedRSVP[userId] = isAttending;

      // Create updated event with new RSVP
      final updatedEvent = EventModel(
        id: _event!.id,
        name: _event!.name,
        description: _event!.description,
        location: _event!.location,
        date: _event!.date,
        category: _event!.category,
        code: _event!.code,
        ownerId: _event!.ownerId,
        docLinks: _event!.docLinks,
        members: _event!.members,
        rsvp: updatedRSVP,
        tasks: _event!.tasks,
      );

      await eventRepository.updateEvent(_event!.id, updatedEvent);
      _event = updatedEvent;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update RSVP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add member to event
  Future<bool> addMember(String userId) async {
    if (_event == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (_event!.members.contains(userId)) {
        _errorMessage = 'User is already a member';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updatedMembers = List<String>.from(_event!.members)..add(userId);

      final updatedEvent = EventModel(
        id: _event!.id,
        name: _event!.name,
        description: _event!.description,
        location: _event!.location,
        date: _event!.date,
        category: _event!.category,
        code: _event!.code,
        ownerId: _event!.ownerId,
        docLinks: _event!.docLinks,
        members: updatedMembers,
        rsvp: _event!.rsvp,
        tasks: _event!.tasks,
      );

      await eventRepository.updateEvent(_event!.id, updatedEvent);
      _event = updatedEvent;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add member: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove member from event
  Future<bool> removeMember(String userId) async {
    if (_event == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updatedMembers = List<String>.from(_event!.members)..remove(userId);
      final updatedRSVP = Map<String, bool>.from(_event!.rsvp)..remove(userId);

      final updatedEvent = EventModel(
        id: _event!.id,
        name: _event!.name,
        description: _event!.description,
        location: _event!.location,
        date: _event!.date,
        category: _event!.category,
        code: _event!.code,
        ownerId: _event!.ownerId,
        docLinks: _event!.docLinks,
        members: updatedMembers,
        rsvp: updatedRSVP,
        tasks: _event!.tasks,
      );

      await eventRepository.updateEvent(_event!.id, updatedEvent);
      _event = updatedEvent;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove member: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
