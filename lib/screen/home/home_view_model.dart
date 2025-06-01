import 'package:flutter/material.dart';
import 'package:tubes/data/models/events_models.dart';
import 'package:tubes/data/repositories/event_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;

  HomeViewModel({required EventRepository eventRepository})
    : _eventRepository = eventRepository;

  // State variables
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String? _selectedCategory;

  // Getters
  List<EventModel> get events => _filteredEvents;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  bool get hasEvents => _events.isNotEmpty;
  int get totalEvents => _events.length;

  // Statistics
  int get upcomingEventsCount =>
      _events.where((e) => e.date.isAfter(DateTime.now())).length;
  int get pastEventsCount =>
      _events.where((e) => e.date.isBefore(DateTime.now())).length;
  int get totalPendingTasks => _events.fold(
    0,
    (sum, event) => sum + event.tasks.where((task) => !task.done).length,
  );

  // Initialize and load data
  Future<void> initialize(String userId) async {
    debugPrint('HomeViewModel: Initializing with userId: $userId');
    await loadUserEvents(userId);
  }

  // Load user events (both owned and joined)
  Future<void> loadUserEvents(String userId) async {
    debugPrint('HomeViewModel: Loading events for userId: $userId');
    _setLoading(true);
    _clearError();

    try {
      // Load both owned events and events user is member of
      debugPrint('HomeViewModel: Fetching owned events...');
      final ownedEvents = await _eventRepository.getEventsByOwner(userId);
      debugPrint('HomeViewModel: Found ${ownedEvents.length} owned events');

      debugPrint('HomeViewModel: Fetching member events...');
      final memberEvents = await _eventRepository.getEventsByMember(userId);
      debugPrint('HomeViewModel: Found ${memberEvents.length} member events');

      // Combine and remove duplicates
      final allEvents = <String, EventModel>{};

      // Add owned events
      for (final event in ownedEvents) {
        allEvents[event.id] = event;
        debugPrint('HomeViewModel: Added owned event: ${event.name}');
      }

      // Add member events (won't duplicate owned events)
      for (final event in memberEvents) {
        if (!allEvents.containsKey(event.id)) {
          allEvents[event.id] = event;
          debugPrint('HomeViewModel: Added member event: ${event.name}');
        }
      }

      _events = allEvents.values.toList();
      _events.sort((a, b) => a.date.compareTo(b.date)); // Sort by date

      debugPrint('HomeViewModel: Total events loaded: ${_events.length}');

      _applyFilters();
    } catch (e) {
      debugPrint('HomeViewModel: Error loading events: $e');
      _setError('Failed to load events: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Search events
  void searchEvents(String query) {
    debugPrint('HomeViewModel: Searching events with query: $query');
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Apply search and category filters
  void _applyFilters() {
    debugPrint(
      'HomeViewModel: Applying filters. Search: "$_searchQuery", Category: $_selectedCategory',
    );
    _filteredEvents = _events.where((event) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          event.name.toLowerCase().contains(_searchQuery) ||
          event.description.toLowerCase().contains(_searchQuery) ||
          event.location.toLowerCase().contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          event.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    debugPrint(
      'HomeViewModel: Filtered events count: ${_filteredEvents.length}',
    );
    notifyListeners();
  }

  // Join event by code
  Future<bool> joinEventByCode(String code, String userId) async {
    debugPrint('HomeViewModel: Joining event with code: $code');
    _setLoading(true);
    _clearError();

    try {
      // Check if event exists with this code
      final event = await _eventRepository.getEventByCode(code);

      if (event == null) {
        debugPrint('HomeViewModel: Event not found with code: $code');
        _setError('Event not found with code: $code');
        return false;
      }

      // Check if user is already a member
      if (event.members.contains(userId)) {
        debugPrint(
          'HomeViewModel: User already member of event: ${event.name}',
        );
        _setError('You are already a member of this event');
        return false;
      }

      // Join the event
      await _eventRepository.joinEvent(event.id, userId);
      debugPrint('HomeViewModel: Successfully joined event: ${event.name}');

      // Reload events to reflect changes
      await loadUserEvents(userId);

      return true;
    } catch (e) {
      debugPrint('HomeViewModel: Error joining event: $e');
      _setError('Failed to join event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Leave event
  Future<bool> leaveEvent(String eventId, String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await _eventRepository.leaveEvent(eventId, userId);

      // Remove event from local list
      _events.removeWhere((event) => event.id == eventId);
      _applyFilters();

      return true;
    } catch (e) {
      _setError('Failed to leave event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete event (only for owners)
  Future<bool> deleteEvent(String eventId, String userId) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if user is the owner
      final event = _events.firstWhere((e) => e.id == eventId);
      if (event.ownerId != userId) {
        _setError('You can only delete events you own');
        return false;
      }

      await _eventRepository.deleteEvent(eventId);

      // Remove event from local list
      _events.removeWhere((event) => event.id == eventId);
      _applyFilters();

      return true;
    } catch (e) {
      _setError('Failed to delete event: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update RSVP
  Future<bool> updateRSVP(
    String eventId,
    String userId,
    bool isAttending,
  ) async {
    try {
      await _eventRepository.updateRSVP(eventId, userId, isAttending);

      // Update local event
      final eventIndex = _events.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        // Reload the specific event
        final refreshedEvent = await _eventRepository.getEventById(eventId);
        if (refreshedEvent != null) {
          _events[eventIndex] = refreshedEvent;
          _applyFilters();
        }
      }

      return true;
    } catch (e) {
      _setError('Failed to update RSVP: ${e.toString()}');
      return false;
    }
  }

  // Get events by status
  List<EventModel> getEventsByStatus({required bool upcoming}) {
    final now = DateTime.now();
    return _filteredEvents.where((event) {
      return upcoming ? event.date.isAfter(now) : event.date.isBefore(now);
    }).toList();
  }

  // Get events by category
  List<EventModel> getEventsByCategory(String category) {
    return _filteredEvents
        .where((event) => event.category == category)
        .toList();
  }

  // Get unique categories from events
  List<String> getAvailableCategories() {
    final categories = _events.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Get events with pending tasks
  List<EventModel> getEventsWithPendingTasks() {
    return _filteredEvents.where((event) {
      return event.tasks.any((task) => !task.done);
    }).toList();
  }

  // Get user's role in event
  String getUserRoleInEvent(EventModel event, String userId) {
    if (event.ownerId == userId) {
      return 'Owner';
    } else if (event.members.contains(userId)) {
      return 'Member';
    }
    return 'Not a member';
  }

  // Check if user can edit event
  bool canUserEditEvent(EventModel event, String userId) {
    return event.ownerId == userId;
  }

  // Get RSVP status for user
  bool? getUserRSVPStatus(EventModel event, String userId) {
    return event.rsvp[userId];
  }

  // Refresh data
  Future<void> refresh(String userId) async {
    debugPrint('HomeViewModel: Refreshing data for userId: $userId');
    await loadUserEvents(userId);
  }

  // Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _applyFilters();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
