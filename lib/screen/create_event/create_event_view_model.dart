import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tubes/data/models/events_models.dart';
import 'package:tubes/data/repositories/event_repository.dart';

class CreateEventViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  // Tambahkan auth service atau gunakan FirebaseAuth langsung
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // atau final AuthService _authService;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // State variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedCategory = 'Work';
  bool _isLoading = false;
  String _errorMessage = '';

  // Categories list
  final List<String> _categories = [
    'Work',
    'Personal',
    'Education',
    'Entertainment',
    'Sports',
    'Travel',
    'Other',
  ];

  CreateEventViewModel({required EventRepository eventRepository})
    : _eventRepository = eventRepository;

  // Getters
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Method untuk mendapatkan current user ID
  String? getCurrentUserId() {
    final user = _auth.currentUser;
    return user?.uid;
  }

  // Method untuk mendapatkan current user data
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Setters
  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedTime(TimeOfDay? time) {
    _selectedTime = time;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Form validation
  bool validateForm() {
    _clearError();

    // Validasi user authentication
    if (getCurrentUserId() == null) {
      _setError('User not authenticated. Please login first.');
      return false;
    }

    if (nameController.text.trim().isEmpty) {
      _setError('Event name is required');
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      _setError('Description is required');
      return false;
    }

    if (locationController.text.trim().isEmpty) {
      _setError('Location is required');
      return false;
    }

    if (_selectedDate == null) {
      _setError('Please select a date');
      return false;
    }

    if (_selectedTime == null) {
      _setError('Please select a time');
      return false;
    }

    // Validate that the selected date is not in the past
    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (eventDateTime.isBefore(DateTime.now())) {
      _setError('Event date and time cannot be in the past');
      return false;
    }

    return true;
  }

  Future<bool> createEvent() async {
    if (!validateForm()) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null) {
        _setError('User not authenticated. Please login first.');
        _setLoading(false);
        return false;
      }

      final event = _buildEventModel(currentUserId);
      final eventId = await _eventRepository.createEvent(event);

      event.id = eventId;

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create event: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Build event model dari form data
  EventModel _buildEventModel(String ownerId) {
    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    return EventModel(
      id: '', // Will be set by Firestore
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      location: locationController.text.trim(),
      date: eventDateTime,
      category: _selectedCategory,
      code: _generateEventCode(),
      ownerId: ownerId, // ID user yang membuat event
      docLinks: [],
      members: [ownerId], // Owner sebagai member pertama
      rsvp: {ownerId: true}, // Owner otomatis accept
      tasks: [],
    );
  }

  // Generate random event code
  String _generateEventCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Reset form ke initial state
  void resetForm() {
    nameController.clear();
    descriptionController.clear();
    locationController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _selectedCategory = 'Work';
    _isLoading = false;
    _errorMessage = '';
    notifyListeners();
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
    nameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
