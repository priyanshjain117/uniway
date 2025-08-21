import 'package:flutter/material.dart';
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

  void _useCurrentLocation() {
    widget.onStartLocationChanged(
      true,
      widget.currentPosition,
      "Current Location",
    );
  }

  void _selectLocation(String type, Map<String, dynamic> location) {
    final point = LatLng(location['lat'], location['lng']);
    if (type == 'start') {
      widget.onStartLocationChanged(false, point, location['name']);
      widget.startController.text = location['name'];
      setState(() => _filteredStart.clear());
    } else {
      widget.onDestinationChanged(point, location['name']);
      widget.destinationController.text = location['name'];
      setState(() => _filteredDest.clear());
    }
  }

  List<Map<String, dynamic>> _getSuggestions(String pattern) {
    if (pattern.isEmpty) {
      return widget.locationSuggestions.take(8).toList();
    }

    final query = pattern.toLowerCase().trim();
    List<Map<String, dynamic>> filtered = widget.locationSuggestions.where((location) {
      final name = location['name'].toString().toLowerCase();
      return name.contains(query);
    }).toList();

    // Sort by relevance
    filtered.sort((a, b) {
      final aName = a['name'].toString().toLowerCase();
      final bName = b['name'].toString().toLowerCase();

      if (aName == query) return -1;
      if (bName == query) return 1;
      if (aName.startsWith(query)) return -1;
      if (bName.startsWith(query)) return 1;

      return aName.compareTo(bName);
    });

    return filtered.take(8).toList();
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
    Widget? suffix,
    bool includeCurrentLocation = false,
    VoidCallback? onUseCurrentLocation,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
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
        if (filteredList.isNotEmpty)
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
                      setState(() => filteredList.clear());
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

    return Container(
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
          // From Field
          _buildTypeAheadField(
            label: "From",
            controller: widget.startController,
            filteredList: _filteredStart,
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
          const SizedBox(height: 12),

          // To Field
          _buildTypeAheadField(
            label: "To",
            controller: widget.destinationController,
            filteredList: _filteredDest,
            onChanged: (pattern) =>
                setState(() => _filteredDest = _getSuggestions(pattern)),
            onTapLocation: (loc) => _selectLocation('destination', loc),
          ),
          const SizedBox(height: 12),

          // Route Buttons
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
    );
  }
}

// Current Location Button
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

// Route Buttons
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
        const SizedBox(width: 12),
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
