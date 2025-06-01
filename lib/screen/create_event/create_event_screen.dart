import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tubes/bloc/event/event_state.dart';
import 'package:tubes/bloc/navigation/navigation_bloc.dart';
import 'package:tubes/bloc/navigation/navigation_event.dart';
import 'package:tubes/helper/widget_app.dart';
import 'package:tubes/bloc/event/event_bloc.dart';
import 'package:tubes/bloc/event/event_event.dart';
import 'package:tubes/screen/create_event/create_event_view_model.dart';
import 'package:tubes/screen/home/home_screen.dart';

class CreateEventScreen extends StatelessWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateEventViewModel(eventRepository: context.read()),
      child: const CreateEventScreenBody(),
    );
  }
}

class CreateEventScreenBody extends StatefulWidget {
  const CreateEventScreenBody({super.key});

  @override
  State<CreateEventScreenBody> createState() => _CreateEventScreenBodyState();
}

class _CreateEventScreenBodyState extends State<CreateEventScreenBody>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: GradientBackground.decoration,
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildHeader(context),
              ),

              // Form Section
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(76),
                border: Border.all(
                  color: const Color(0xFFFFEB3B).withAlpha(51),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFFFFEB3B),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      YellowGradients.primary.createShader(bounds),
                  child: const Text(
                    'Create Event',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set up your new event',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Consumer<CreateEventViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show error message if any
                if (viewModel.errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Event Name
                _buildSectionTitle('Event Details'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: viewModel.nameController,
                  label: 'Event Name',
                  hint: 'Enter event name',
                  icon: Icons.event,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Event name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                _buildTextField(
                  controller: viewModel.descriptionController,
                  label: 'Description',
                  hint: 'Describe your event',
                  icon: Icons.description,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location
                _buildTextField(
                  controller: viewModel.locationController,
                  label: 'Location',
                  hint: 'Event location',
                  icon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Location is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Date & Time Section
                _buildSectionTitle('Date & Time'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeSelector(
                        label: 'Date',
                        value: viewModel.selectedDate != null
                            ? '${viewModel.selectedDate!.day}/${viewModel.selectedDate!.month}/${viewModel.selectedDate!.year}'
                            : 'Select date',
                        icon: Icons.calendar_today,
                        onTap: () => _selectDate(viewModel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimeSelector(
                        label: 'Time',
                        value: viewModel.selectedTime != null
                            ? viewModel.selectedTime!.format(context)
                            : 'Select time',
                        icon: Icons.access_time,
                        onTap: () => _selectTime(viewModel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Section
                _buildSectionTitle('Category'),
                const SizedBox(height: 16),
                _buildCategorySelector(viewModel),
                const SizedBox(height: 32),

                // Create Button
                GradientButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _createEvent(viewModel),
                  child: viewModel.isLoading
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
                          'Create Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: const Color(0xFFFFEB3B)),
            filled: true,
            fillColor: Colors.black.withAlpha(76),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFFFEB3B).withAlpha(51),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFFFEB3B).withAlpha(51),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFEB3B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(76),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFEB3B).withAlpha(51),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFFEB3B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value.contains('Select')
                          ? Colors.grey[400]
                          : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(CreateEventViewModel viewModel) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: viewModel.categories.map((category) {
        final isSelected = viewModel.selectedCategory == category;
        return GestureDetector(
          onTap: () => viewModel.setSelectedCategory(category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFEB3B).withAlpha(51)
                  : Colors.black.withAlpha(76),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFEB3B)
                    : const Color(0xFFFFEB3B).withAlpha(51),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFEB3B) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate(CreateEventViewModel viewModel) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFEB3B),
              onPrimary: Colors.black87,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      viewModel.setSelectedDate(picked);
    }
  }

  Future<void> _selectTime(CreateEventViewModel viewModel) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: viewModel.selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFEB3B),
              onPrimary: Colors.black87,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      viewModel.setSelectedTime(picked);
    }
  }

  void _createEvent(CreateEventViewModel viewModel) async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Buat event menggunakan current user ID dari ViewModel
    await viewModel.createEvent();

    try {
      final currentUserId = viewModel.getCurrentUserId();
      // Navigasi ke home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );

      // Reload event dari owner
      context.read<EventBloc>().add(LoadEventsByOwner(currentUserId!));

      // Tampilkan pesan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Event "${viewModel.nameController.text}" created successfully!',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Tangani error dan tampilkan pesan kesalahan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Gagal memproses: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset form untuk penggunaan selanjutnya
      viewModel.resetForm();
    }
  }

  // Error message sudah ditangani di ViewModel dan ditampilkan di UI
}
