import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tubes/bloc/navigation/navigation_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_event.dart';
import 'package:tubes/data/models/events_models.dart';
import 'package:tubes/data/models/user_models.dart';
import 'package:tubes/data/repositories/user_repository.dart';
import 'package:tubes/helper/widget_app.dart';
import 'package:tubes/screen/event_detail/event_detail_view_model.dart';
import 'package:tubes/screen/home/home_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventDetailViewModel(
        eventRepository: context.read(),
        eventBloc: context.read(),
      )..initialize(event),
      child: Scaffold(
        body: const EventDetailScreenBody(),
        floatingActionButton: const _EventActionButtons(),
      ),
    );
  }
}

class EventDetailScreenBody extends StatefulWidget {
  const EventDetailScreenBody({super.key});

  @override
  State<EventDetailScreenBody> createState() => _EventDetailScreenBodyState();
}

class _EventDetailScreenBodyState extends State<EventDetailScreenBody>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EventDetailViewModel>();
    final event = viewModel.event;

    final Widget child = viewModel.isLoading
        ? _buildLoadingState()
        : viewModel.errorMessage != null
        ? _buildErrorState(viewModel)
        : event == null
        ? _buildEmptyState()
        : _buildEventDetailContent(context, event);

    return child;
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: GradientBackground.decoration,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFEB3B)),
        ),
      ),
    );
  }

  Widget _buildEventDetailContent(BuildContext context, EventModel event) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: GradientBackground.decoration,
        child: CustomScrollView(
          slivers: [
            _EventAppBar(event: event),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _EventInfoCard(event: event),
                    const SizedBox(height: 16),
                    _MembersSection(event: event),
                    const SizedBox(height: 16),
                    _TasksSection(event: event),
                    const SizedBox(height: 16),
                    _EventStatisticsCard(event: event),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(EventDetailViewModel viewModel) {
    return Container(
      decoration: GradientBackground.decoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.errorMessage ?? 'An error occurred',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: viewModel.refreshEvent,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: GradientBackground.decoration,
      child: const Center(
        child: Text('Event not found', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _EventAppBar extends StatelessWidget {
  final EventModel event;

  const _EventAppBar({required this.event});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          'https://picsum.photos/seed/${event.id}/600/400',
          fit: BoxFit.cover,
        ),
        title: Text(event.name),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        stretchModes: const [StretchMode.zoomBackground],
      ),
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE0E0E0), // Abu terang atau sesuaikan warna
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE0E0E0), // Sama seperti di atas
            ),
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showShareDialog(context, event),
            ),
          ),
        ),
      ],
    );
  }

  void _showShareDialog(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Use this code to share the event:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.code,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _EventActionButtons extends StatelessWidget {
  const _EventActionButtons();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<EventDetailViewModel>();
    final isOwner = viewModel.isOwner;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isOwner) ...[
          FloatingActionButton(
            heroTag: 'edit',
            onPressed: () => _navigateToEdit(context),
            child: const Icon(Icons.edit),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'delete',
            onPressed: () => _confirmDelete(context, viewModel),
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
        if (!isOwner) ...[
          FloatingActionButton.extended(
            heroTag: 'rsvp',
            onPressed: () => _toggleRSVP(context, viewModel),
            label: const Text('RSVP'),
            icon: const Icon(Icons.event_available),
          ),
        ],
      ],
    );
  }

  void _navigateToEdit(BuildContext context) {
    // TODO: Implement edit navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _confirmDelete(BuildContext context, EventDetailViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Tampilkan loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Deleting event...'),
                    ],
                  ),
                ),
              );

              try {
                await viewModel.deleteEvent();

                // Tutup loading
                if (context.mounted)
                  Navigator.pop(context); // Tutup loading dialog
                Navigator.pop(context); // Tutup dialog konfirmasi hapus

                // Tampilkan snackbar sukses
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                // Navigasi ke HomeScreen, hapus semua route sebelumnya
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                }
              } catch (error) {
                // Tutup loading
                if (context.mounted) Navigator.pop(context);

                // Tampilkan snackbar error
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete event: $error'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleRSVP(BuildContext context, EventDetailViewModel viewModel) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || viewModel.event == null) return;

    final currentStatus = viewModel.event!.rsvp[currentUser.uid] ?? false;
    viewModel.updateRSVP(currentUser.uid, !currentStatus);
  }
}

class _EventInfoCard extends StatelessWidget {
  final EventModel event;

  const _EventInfoCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(event.date)} at ${_formatTime(event.date)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Text(event.location, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            if (event.description.isNotEmpty) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(event.description),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MembersSection extends StatelessWidget {
  final EventModel event;

  const _MembersSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (event.members.isEmpty)
              const Center(child: Text('No members yet'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.members.map((memberId) {
                  return FutureBuilder<UserModel?>(
                    future: context.read<UserRepository>().getUserById(
                      memberId,
                    ),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl == null
                              ? Text(user?.name[0] ?? '?')
                              : null,
                        ),
                        label: Text(user?.name ?? 'Loading...'),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  final EventModel event;

  const _TasksSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final completedCount = event.tasks.where((t) => t.done).length;
    final totalCount = event.tasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('$completedCount/$totalCount'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            if (event.tasks.isEmpty)
              const Center(child: Text('No tasks yet'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: event.tasks.length,
                itemBuilder: (context, index) {
                  final task = event.tasks[index];
                  return CheckboxListTile(
                    title: Text(task.title),
                    subtitle: task.assignedTo.isNotEmpty
                        ? Text('Assigned to: ${task.assignedTo}')
                        : null,
                    value: task.done,
                    onChanged: (value) {
                      // TODO: Implement task completion toggle
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EventStatisticsCard extends StatelessWidget {
  final EventModel event;

  const _EventStatisticsCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final daysUntil = event.date.difference(DateTime.now()).inDays;
    final isPast = daysUntil < 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatItem(
                  icon: Icons.group,
                  value: event.members.length.toString(),
                  label: 'Members',
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.assignment,
                  value: event.tasks.length.toString(),
                  label: 'Tasks',
                  color: Colors.orange,
                ),
                _StatItem(
                  icon: Icons.check_circle,
                  value: event.tasks.where((t) => t.done).length.toString(),
                  label: 'Completed',
                  color: Colors.green,
                ),
                _StatItem(
                  icon: isPast ? Icons.history : Icons.schedule,
                  value: isPast ? '${-daysUntil}d ago' : '$daysUntil days',
                  label: isPast ? 'Ended' : 'Remaining',
                  color: isPast ? Colors.grey : Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
