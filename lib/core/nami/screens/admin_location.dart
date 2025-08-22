import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:student_helper/core/nami/controllers/navigation_controller.dart';

class AdminLocationPage extends StatefulWidget {
  const AdminLocationPage({super.key});

  @override
  State<AdminLocationPage> createState() => _AdminLocationPageState();
}

class _AdminLocationPageState extends State<AdminLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isDeleting = false;
  String? _deletingId;
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterLocations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLocations = _locations.where((location) {
        return location['name'].toLowerCase().contains(query) ||
            location['description'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _loadLocations() {
    final NavigationController  navController= Get.find<NavigationController>();
    setState(() {
      _locations =navController.locationSuggestions;
      _filteredLocations = List.from(_locations);
    });
  }

  Future<void> _addLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final newLocation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'lat': double.parse(_latitudeController.text.trim()),
        'lng': double.parse(_longitudeController.text.trim()),
        'createdAt': DateTime.now(),
      };

      setState(() {
        _locations.insert(0, newLocation);
        _filterLocations();
      });

      _clearForm();
      _showSuccessSnackBar(
          '✅ Location "${newLocation['name']}" added successfully!');
    } catch (e) {
      _showErrorSnackBar('❌ Failed to add location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLocation(String id, String name) async {
    print('hi');
    final confirmed = await _showDeleteConfirmDialog(name);
    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
      _deletingId = id;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _locations.removeWhere((location) => location['id'] == id);
        _filterLocations();
      });

      _showSuccessSnackBar('✅ Location "$name" deleted successfully!');
    } catch (e) {
      _showErrorSnackBar('❌ Failed to delete location: $e');
    } finally {
      setState(() {
        _isDeleting = false;
        _deletingId = null;
      });
    }
  }

  Future<void> _deleteAllLocations() async {
    if (_locations.isEmpty) return;

    final confirmed = await _showBulkDeleteConfirmDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _locations.clear();
        _filteredLocations.clear();
      });

      _showSuccessSnackBar('✅ All locations deleted successfully!');
    } catch (e) {
      _showErrorSnackBar('❌ Failed to delete all locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<bool> _showDeleteConfirmDialog(String locationName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🗑️ Delete Location'),
            content: Text('Are you sure you want to delete "$locationName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showBulkDeleteConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Delete All Locations'),
            content: Text(
                'Are you sure you want to delete ALL ${_locations.length} locations?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Delete All'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          '🛠️ Admin Dashboard',
          style: GoogleFonts.exo2(
            fontWeight: FontWeight.w700,
            fontSize: 24.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary.withAlpha(200),
        foregroundColor: theme.colorScheme.surface,
        actions: [
          if (_locations.isNotEmpty)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: _deleteAllLocations,
                  child: const Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete All'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceDim,
              theme.colorScheme.primary.withAlpha(204),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                          color: Colors.white),  
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white
                            .withOpacity(0.1), 
                        labelText: 'Location Name *',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon:
                            const Icon(Icons.place, color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white70),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter name' : null,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon:
                            Icon(Icons.description, color: Colors.white),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white70),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter description' : null,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Latitude *',
                              labelStyle: const TextStyle(color: Colors.white),
                              prefixIcon:
                                  Icon(Icons.my_location, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white70),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Longitude *',
                              labelStyle: const TextStyle(color: Colors.white),
                              prefixIcon:
                                  Icon(Icons.location_on, color: Colors.white),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white70),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addLocation,
                      icon: _isLoading
                          ?  SizedBox(
                              width: 16.h,
                              height: 16.h,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label:
                          Text(_isLoading ? 'Creating...' : 'Create Location'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(
              color: Colors.white70,
            ),
            SizedBox(height: 8.h),

            if (_locations.isNotEmpty)
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white), 
                cursorColor: Colors.white, 
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  hintStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white), 
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterLocations();
                          },
                          icon: const Icon(Icons.clear, color: Colors.white),
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Colors.white60, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            SizedBox(height: 16.h),

            if (_filteredLocations.isEmpty)
              Center(
                child: Text(
                  _locations.isEmpty
                      ? 'No locations created yet'
                      : 'No locations match your search',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._filteredLocations.map(
                (loc) => LocationCard(
                  location: loc,
                  isDeleting: _isDeleting && _deletingId == loc['id'],
                  onDelete: () => _deleteLocation(loc['id'], loc['name']),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  final Map<String, dynamic> location;
  final bool isDeleting;
  final VoidCallback onDelete;

  const LocationCard({
    super.key,
    required this.location,
    required this.onDelete,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.5.h),
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: isDeleting
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onDelete,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
