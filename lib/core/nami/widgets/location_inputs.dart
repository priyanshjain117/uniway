import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

class LocationInputWidget extends StatefulWidget {
  final TextEditingController startController;
  final TextEditingController destinationController;
  final bool useCurrentLocation;
  final bool showGetRoute;
  final bool isNavigating;
  final bool hasRoute;
  final LatLng? currentPosition;
  final List<Map<String, dynamic>> locationSuggestions;

  final Function(bool useCurrentLocation, LatLng? position, String text) onStartLocationChanged;
  final Function(LatLng endPoint, String text) onDestinationChanged;
  final VoidCallback? onGetRoute;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onStopNavigation;

  const LocationInputWidget({
    super.key,
    required this.startController,
    required this.destinationController,
    required this.useCurrentLocation,
    required this.showGetRoute,
    required this.isNavigating,
    required this.hasRoute,
    required this.currentPosition,
    required this.locationSuggestions,
    required this.onStartLocationChanged,
    required this.onDestinationChanged,
    this.onGetRoute,
    this.onStartNavigation,
    this.onStopNavigation,
  });

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  List<Map<String, dynamic>> _filteredStart = [];
  List<Map<String, dynamic>> _filteredDest = [];
  
  // Add focus nodes to track which field is active
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _destFocusNode = FocusNode();
  
  // Track which field is currently showing suggestions
  bool _showStartSuggestions = false;
  bool _showDestSuggestions = false;

  @override
  void initState() {
    super.initState();
    
    // Add listeners to focus nodes
    _startFocusNode.addListener(() {
      if (_startFocusNode.hasFocus) {
        setState(() {
          _showStartSuggestions = true;
          _showDestSuggestions = false;
          // Close destination suggestions and select top if available
          if (_filteredDest.isNotEmpty) {
            _selectTopSuggestion('destination');
          }
        });
      }
    });
    
    _destFocusNode.addListener(() {
      if (_destFocusNode.hasFocus) {
        setState(() {
          _showDestSuggestions = true;
          _showStartSuggestions = false;
          // Close start suggestions and select top if available
          if (_filteredStart.isNotEmpty) {
            _selectTopSuggestion('start');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _startFocusNode.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  void _selectTopSuggestion(String type) {
    if (type == 'start' && _filteredStart.isNotEmpty) {
      final topSuggestion = _filteredStart.first;
      _selectLocation('start', topSuggestion);
    } else if (type == 'destination' && _filteredDest.isNotEmpty) {
      final topSuggestion = _filteredDest.first;
      _selectLocation('destination', topSuggestion);
    }
  }

  void _useCurrentLocation() {
    widget.onStartLocationChanged(
      true,
      widget.currentPosition,
      "Current Location",
    );
    setState(() {
      _filteredStart.clear();
      _showStartSuggestions = false;
    });
  }

  void _selectLocation(String type, Map<String, dynamic> location) {
    final point = LatLng(location['lat'], location['lng']);
    if (type == 'start') {
      widget.onStartLocationChanged(false, point, location['name']);
      widget.startController.text = location['name'];
      setState(() {
        _filteredStart.clear();
        _showStartSuggestions = false;
      });
    } else {
      widget.onDestinationChanged(point, location['name']);
      widget.destinationController.text = location['name'];
      setState(() {
        _filteredDest.clear();
        _showDestSuggestions = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSuggestions(String pattern) {
    if (pattern.isEmpty) {
      return widget.locationSuggestions.take(4).toList();
    }

    final query = pattern.toLowerCase().trim();
    List<Map<String, dynamic>> filtered = widget.locationSuggestions.where((location) {
      final name = location['name'].toString().toLowerCase();
      return name.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aName = a['name'].toString().toLowerCase();
      final bName = b['name'].toString().toLowerCase();

      if (aName == query) return -1;
      if (bName == query) return 1;
      if (aName.startsWith(query)) return -1;
      if (bName.startsWith(query)) return 1;

      return aName.compareTo(bName);
    });

    return filtered.take(4).toList();
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    if (!lowerText.contains(lowerQuery)) {
      return Text(text, style: const TextStyle(fontSize: 14));
    }

    final startIndex = lowerText.indexOf(lowerQuery);
    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  Widget _buildTypeAheadField({
    required String label,
    required TextEditingController controller,
    required List<Map<String, dynamic>> filteredList,
    required Function(String) onChanged,
    required Function(Map<String, dynamic>) onTapLocation,
    required FocusNode focusNode,
    required bool showSuggestions,
    Widget? suffix,
    bool includeCurrentLocation = false,
    VoidCallback? onUseCurrentLocation,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: suffix,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        if (filteredList.isNotEmpty && showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  spreadRadius: 2,
                  color: Colors.black12,
                )
              ],
            ),
            child: Column(
              children: [
                if (includeCurrentLocation && widget.currentPosition != null)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.gps_fixed,
                        color: Theme.of(context).colorScheme.primary),
                    title: const Text("Use Current Location"),
                    subtitle: const Text("Live location tracking"),
                    onTap: () {
                      controller.text = "Current Location";
                      if (onUseCurrentLocation != null) onUseCurrentLocation();
                    },
                  ),
                ...filteredList.map((location) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on,
                        size: 20, color: Colors.grey),
                    title: _buildHighlightedText(
                      location['name'],
                      controller.text,
                    ),
                    onTap: () => onTapLocation(location),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _showStartSuggestions = false;
          _showDestSuggestions = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withAlpha(160),
              theme.colorScheme.primary.withAlpha(80),
              theme.colorScheme.surfaceDim,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTypeAheadField(
              label: "From",
              controller: widget.startController,
              filteredList: _filteredStart,
              focusNode: _startFocusNode,
              showSuggestions: _showStartSuggestions,
              onChanged: (pattern) =>
                  setState(() => _filteredStart = _getSuggestions(pattern)),
              onTapLocation: (loc) => _selectLocation('start', loc),
              suffix: CurrentLocationButton(
                onPressed: _useCurrentLocation,
                isActive: widget.useCurrentLocation,
              ),
              includeCurrentLocation: true,
              onUseCurrentLocation: _useCurrentLocation,
            ),
            SizedBox(height: 8.h),
        
            _buildTypeAheadField(
              label: "To",
              controller: widget.destinationController,
              filteredList: _filteredDest,
              focusNode: _destFocusNode,
              showSuggestions: _showDestSuggestions,
              onChanged: (pattern) =>
                  setState(() => _filteredDest = _getSuggestions(pattern)),
              onTapLocation: (loc) => _selectLocation('destination', loc),
            ),
            SizedBox(height: 6.h),
        
            RouteActionButtons(
              showGetRoute: widget.showGetRoute,
              isNavigating: widget.isNavigating,
              hasRoute: widget.hasRoute,
              onGetRoute: widget.onGetRoute,
              onStartNavigation: widget.onStartNavigation,
              onStopNavigation: widget.onStopNavigation,
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const CurrentLocationButton({
    super.key,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.gps_fixed,
        color: isActive ? Theme.of(context).colorScheme.primary : null,
      ),
      onPressed: onPressed,
      tooltip: "Use current location",
    );
  }
}

class RouteActionButtons extends StatelessWidget {
  final bool showGetRoute;
  final bool isNavigating;
  final bool hasRoute;
  final VoidCallback? onGetRoute;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onStopNavigation;

  const RouteActionButtons({
    super.key,
    required this.showGetRoute,
    required this.isNavigating,
    required this.hasRoute,
    this.onGetRoute,
    this.onStartNavigation,
    this.onStopNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: showGetRoute ? onGetRoute : null,
            icon: Icon(
              Icons.route,
              color: showGetRoute
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
            label: Text(
              'Get Route',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: showGetRoute
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (hasRoute && !isNavigating)
                ? onStartNavigation
                : isNavigating
                    ? onStopNavigation
                    : null,
            icon: Icon(
              isNavigating ? Icons.stop : Icons.navigation,
              color:
                  hasRoute ? Theme.of(context).colorScheme.primary : Colors.white,
            ),
            label: Text(
              isNavigating ? 'Stop' : 'Navigate',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color:
                    hasRoute ? Theme.of(context).colorScheme.primary : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isNavigating ? Colors.red : null,
            ),
          ),
        ),
      ],
    );
  }
}
