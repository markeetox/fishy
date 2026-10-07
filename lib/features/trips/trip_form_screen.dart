import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_scaffold.dart';
import '../../core/floating_top_bar.dart';
import '../auth/auth_providers.dart';
import '../profile/badge_service.dart';
import 'trip_model.dart';
import 'trips_providers.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const TripFormScreen({super.key, this.tripId});

  bool get isEditing => tripId != null;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _speciesTextController = TextEditingController();

  late DateTime _initialDate;
  DateTime _selectedDate = DateTime.now();
  final List<String> _speciesList = [];

  bool _isSaving = false;
  bool _isLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialDate = _selectedDate;
    _titleController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _speciesTextController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    if (_titleController.text.trim().isNotEmpty) return true;
    if (_locationController.text.trim().isNotEmpty) return true;
    if (_notesController.text.trim().isNotEmpty) return true;
    if (_speciesList.isNotEmpty) return true;
    if (_selectedDate.year != _initialDate.year ||
        _selectedDate.month != _initialDate.month ||
        _selectedDate.day != _initialDate.day) {
      return true;
    }
    return false;
  }

  Future<bool> _showDiscardDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B2250),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
          ),
          title: const Text(
            'Discard this trip?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Keep editing',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1142A),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Discard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _handleClose(BuildContext context) async {
    if (_isDirty) {
      final shouldDiscard = await _showDiscardDialog(context);
      if (!mounted || !context.mounted) return;
      if (shouldDiscard) {
        context.pop();
      }
    } else {
      context.pop();
    }
  }

  void _addSpecies() {
    final text = _speciesTextController.text.trim();
    if (text.isNotEmpty && !_speciesList.contains(text)) {
      setState(() {
        _speciesList.add(text);
        _speciesTextController.clear();
      });
    }
  }

  void _removeSpecies(String species) {
    setState(() {
      _speciesList.remove(species);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTrip(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(tripsRepositoryProvider);

      if (widget.isEditing) {
        final updatedTrip = Trip(
          id: widget.tripId!,
          userId: userId,
          title: _titleController.text.trim(),
          date: _selectedDate,
          locationName: _locationController.text.trim(),
          species: List.from(_speciesList),
          notes: _notesController.text.trim(),
        );
        await repository.updateTrip(updatedTrip);
      } else {
        final newTrip = Trip(
          id: '',
          userId: userId,
          title: _titleController.text.trim(),
          date: _selectedDate,
          locationName: _locationController.text.trim(),
          species: List.from(_speciesList),
          notes: _notesController.text.trim(),
        );
        await repository.createTrip(newTrip);

        final badgeService = ref.read(badgeServiceProvider);
        final trips = await repository.getTripsOnce(userId);
        final result = await badgeService.onTripLogged(userId, trips.length);

        if (mounted) {
          showBadgeUnlocks(context, result);
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving trip: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _populateTripData(Trip trip) {
    if (_isLoaded) return;
    _titleController.text = trip.title;
    _locationController.text = trip.locationName;
    _notesController.text = trip.notes;
    _selectedDate = trip.date;
    _initialDate = trip.date;
    _speciesList.clear();
    _speciesList.addAll(trip.species);
    _isLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;

    if (user == null) {
      return AppScaffold(
        topBar: FloatingTopBar(
          leading: FloatingTopBarButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('User not authenticated.')),
      );
    }

    if (widget.isEditing) {
      final tripDetailAsync = ref.watch(tripDetailStreamProvider(widget.tripId!));

      return tripDetailAsync.when(
        data: (trip) {
          if (trip == null) {
            return AppScaffold(
              topBar: FloatingTopBar(
                leading: FloatingTopBarButton(
                  icon: Icons.close,
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                ),
              ),
              body: const Center(child: Text('Trip not found.')),
            );
          }
          _populateTripData(trip);
          return _buildFormScaffold(context, user.uid);
        },
        loading: () => AppScaffold(
          topBar: FloatingTopBar(
            leading: FloatingTopBarButton(
              icon: Icons.close,
              tooltip: 'Close',
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => AppScaffold(
          topBar: FloatingTopBar(
            leading: FloatingTopBarButton(
              icon: Icons.close,
              tooltip: 'Close',
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(child: Text('Error loading trip: $e')),
        ),
      );
    }

    return _buildFormScaffold(context, user.uid);
  }

  Widget _buildFormScaffold(BuildContext context, String userId) {
    final titleText = widget.isEditing ? 'Edit trip' : 'Log a trip';

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog(context);
        if (!mounted || !context.mounted) return;
        if (shouldDiscard) {
          Navigator.of(context).pop();
        }
      },
      child: AppScaffold(
        topBar: FloatingTopBar(
          leading: FloatingTopBarButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: () => _handleClose(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 88, left: 24, right: 24, bottom: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Trip Title *',
                        hintText: 'e.g., Morning Catch at Blue Bay',
                        border: OutlineInputBorder(),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a trip title.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat.yMMMMd().format(_selectedDate),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Select Date'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location Name *',
                        hintText: 'e.g., Cape Marina, Dock B',
                        prefixIcon: Icon(Icons.place_outlined),
                        border: OutlineInputBorder(),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a location.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Species Targeted or Caught',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _speciesTextController,
                            decoration: const InputDecoration(
                              hintText: 'Add a species (e.g., Bass, Tuna)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addSpecies(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addSpecies,
                          icon: const Icon(Icons.add),
                          tooltip: 'Add species',
                        ),
                      ],
                    ),
                    if (_speciesList.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _speciesList.map((species) {
                          return Chip(
                            label: Text(species),
                            onDeleted: () => _removeSpecies(species),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Weather, gear used, catch details, etc.',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveTrip(userId),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isEditing ? 'Save Changes' : 'Log Trip'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
