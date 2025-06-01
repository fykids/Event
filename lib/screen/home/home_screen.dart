import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tubes/bloc/app/app_bloc.dart';
import 'package:tubes/bloc/app/app_event.dart';
import 'package:tubes/bloc/navigation/navigation_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_event.dart';
import 'package:tubes/helper/widget_app.dart';
import 'package:tubes/screen/create_event/create_event_screen.dart';
import 'package:tubes/screen/event_detail/event_detail_screen.dart';
import 'package:tubes/screen/home/home_view_model.dart';
import 'package:tubes/data/models/events_models.dart';
import 'package:tubes/data/repositories/event_repository.dart';
import 'package:tubes/bloc/event/event_bloc.dart';
import 'package:tubes/bloc/event/event_state.dart';
import 'package:tubes/bloc/event/event_event.dart';
import 'package:tubes/screen/login/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              HomeViewModel(eventRepository: context.read<EventRepository>()),
        ),
      ],
      child: BlocListener<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: const HomeScreenBody(),
      ),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  State<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String get _userId => _currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAuth();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeAuth() {
    // Get current user
    _currentUser = _auth.currentUser;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });

        // Load data when user changes
        if (user != null) {
          _loadInitialData();
        }
      }
    });

    // Load initial data if user is already signed in
    if (_currentUser != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    if (_userId.isEmpty) {
      debugPrint('Warning: User ID is empty, cannot load events');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('HomeScreen: Loading initial data for user: $_userId');

        // Initialize HomeViewModel
        context.read<HomeViewModel>().initialize(_userId).catchError((error) {
          debugPrint('HomeScreen: Error initializing HomeViewModel: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading events: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });

        // Load events via EventBloc
        context.read<EventBloc>().add(LoadEventsByOwner(_userId));
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Add navigation function for event detail
  void _navigateToEventDetail(EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    // Show loading if user is not authenticated
    if (_currentUser == null) {
      return Scaffold(
        body: Container(
          decoration: GradientBackground.decoration,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFEB3B)),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading user data...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: GradientBackground.decoration,
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _HeaderSection(user: _currentUser!),
              ),

              // Search & Actions Section
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _SearchAndActionsSection(
                    searchController: _searchController,
                    onSearchChanged: (query) => viewModel.searchEvents(query),
                  ),
                ),
              ),

              // Events List Section
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _EventsListSection(
                      events: viewModel.events,
                      isLoading: viewModel.isLoading,
                      onRefresh: () => viewModel.refresh(_userId),
                      onEventTap:
                          _navigateToEventDetail, // Pass the navigation function
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showJoinEventDialog(context),
          backgroundColor: const Color(0xFFFFEB3B),
          foregroundColor: Colors.black87,
          label: const Text(
            'Join Event',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showJoinEventDialog(BuildContext context) {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _JoinEventDialog(
        onJoinPressed: (code) async {
          debugPrint('HomeScreen: Attempting to join event with code: $code');

          final homeViewModel = context.read<HomeViewModel>();
          final success = await homeViewModel.joinEventByCode(code, _userId);

          if (context.mounted) {
            if (success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(child: Text('Successfully joined event!')),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );

              // Force refresh setelah berhasil join
              debugPrint('HomeScreen: Forcing refresh after successful join');
              await homeViewModel.refresh(_userId);
            } else {
              // Error sudah di-handle di HomeViewModel dan akan ditampilkan melalui error message
              final errorMessage = homeViewModel.errorMessage;
              if (errorMessage.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final User user;

  const _HeaderSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      YellowGradients.primary.createShader(bounds),
                  child: const Text(
                    'EventConnect',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back, ${user.displayName ?? user.email ?? 'User'}!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showUserMenu(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: YellowGradients.primary,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFEB3B).withAlpha(76),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: user.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user.photoURL!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Colors.black87,
                            size: 24,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.black87, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(229),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(
            color: const Color(0xFFFFEB3B).withAlpha(76),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      appBloc: context.read<AppBloc>()..add(AppStarted()),
                    ),
                  ),
                  (route) => false,
                );
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAndActionsSection extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _SearchAndActionsSection({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(76),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFEB3B).withAlpha(51),
                width: 1,
              ),
            ),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFEB3B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(height: 16),
          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.event,
                  label: 'Create Event',
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const CreateEventScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan QR',
                  onTap: () {
                    // Implement QR scanning
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR Scanner coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFEB3B).withAlpha(51),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFFEB3B), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsListSection extends StatelessWidget {
  final List<EventModel> events;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(EventModel) onEventTap; // Add this parameter

  const _EventsListSection({
    required this.events,
    required this.isLoading,
    required this.onRefresh,
    required this.onEventTap, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${events.length} events',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading && events.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFEB3B),
                      ),
                    ),
                  )
                : events.isEmpty
                ? const _EmptyEventsWidget()
                : RefreshIndicator(
                    onRefresh: () async => onRefresh(),
                    color: const Color(0xFFFFEB3B),
                    backgroundColor: Colors.black87,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _EventCard(
                          event: events[index],
                          onTap: () => onEventTap(
                            events[index],
                          ), // Pass the tap callback
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap; // Add tap callback

  const _EventCard({
    required this.event,
    required this.onTap, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Wrap with GestureDetector
      onTap: onTap, // Handle tap
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(76),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFEB3B).withAlpha(51),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: YellowGradients.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.location,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: event.date.isAfter(DateTime.now())
                        ? Colors.orange.withAlpha(51)
                        : Colors.green.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.date.isAfter(DateTime.now()) ? 'Upcoming' : 'Past',
                    style: TextStyle(
                      fontSize: 12,
                      color: event.date.isAfter(DateTime.now())
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFFFFEB3B),
                ),
                const SizedBox(width: 8),
                Text(
                  '${event.date.day}/${event.date.month}/${event.date.year}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Spacer(),
                const Icon(Icons.group, size: 16, color: Color(0xFFFFEB3B)),
                const SizedBox(width: 8),
                Text(
                  '${event.members.length} members',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            if (event.tasks.any((task) => !task.done)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(76), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_late,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${event.tasks.where((task) => !task.done).length} pending tasks',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyEventsWidget extends StatelessWidget {
  const _EmptyEventsWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
            ),
            child: Icon(Icons.event_note, size: 40, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Events Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join or create an event to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _JoinEventDialog extends StatefulWidget {
  final Function(String) onJoinPressed;

  const _JoinEventDialog({required this.onJoinPressed});

  @override
  State<_JoinEventDialog> createState() => _JoinEventDialogState();
}

class _JoinEventDialogState extends State<_JoinEventDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(229),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFEB3B).withAlpha(76),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  YellowGradients.primary.createShader(bounds),
              child: const Text(
                'Join Event',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the event access code to join',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            // Tampilkan error message jika ada
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter Event Code (e.g., ABC123)',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withAlpha(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFEB3B),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
              ),
              onChanged: (value) {
                // Clear error ketika user mulai mengetik
                if (_errorMessage.isNotEmpty) {
                  setState(() {
                    _errorMessage = '';
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    onPressed: _isLoading ? null : _joinEvent,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black87,
                              ),
                            ),
                          )
                        : const Text(
                            'Join Event',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _joinEvent() async {
    final code = _codeController.text.trim();

    // Validasi lokal
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an event code';
      });
      return;
    }

    if (code.length < 3) {
      setState(() {
        _errorMessage = 'Event code is too short';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await widget.onJoinPressed(code);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
