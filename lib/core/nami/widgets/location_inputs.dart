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
  
  void _useCurrentLocation() {
    widget.onStartLocationChanged(
      true, 
      widget.currentPosition, 
      "Current Location"
    );
  }

  void _selectLocation(String type, Map<String, dynamic> location) {
    final point = LatLng(location['lat'], location['lng']);

    if (type == 'start') {
      widget.onStartLocationChanged(false, point, location['name']);
    } else {
      widget.onDestinationChanged(point, location['name']);
    }
  }

  void _showLocationPicker(String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400.h,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'start' ? 'Select Starting Point' : 'Select Destination',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (type == 'start' && widget.currentPosition != null) ...[
              ListTile(
                leading: Icon(
                  Icons.gps_fixed, 
                  color: Theme.of(context).colorScheme.primary
                ),
                title: const Text("Use Current Location"),
                subtitle: const Text("Live location tracking"),
                trailing: widget.useCurrentLocation 
                    ? const Icon(Icons.check_circle, color: Colors.green) 
                    : null,
                onTap: () {
                  _useCurrentLocation();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: widget.locationSuggestions.length,
                itemBuilder: (context, index) {
                  final location = widget.locationSuggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(location['name']),
                    onTap: () {
                      _selectLocation(type, location);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
          LocationTextField(
            controller: widget.startController,
            labelText: 'From',
            prefixIcon: Icons.my_location,
            onTap: () => _showLocationPicker('start'),
            suffixIcon: CurrentLocationButton(
              onPressed: _useCurrentLocation,
              isActive: widget.useCurrentLocation,
            ),
            helperText: widget.useCurrentLocation 
                ? "📍 Live location tracking enabled" 
                : null,
          ),
          const SizedBox(height: 12),
          LocationTextField(
            controller: widget.destinationController,
            labelText: 'To',
            prefixIcon: Icons.location_on,
            onTap: () => _showLocationPicker('destination'),
          ),
          const SizedBox(height: 12),
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

class LocationTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final VoidCallback onTap;
  final Widget? suffixIcon;
  final String? helperText;

  const LocationTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    required this.onTap,
    this.suffixIcon,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        helperText: helperText,
      ),
      onTap: onTap,
      readOnly: true,
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
        color: isActive 
          ? Theme.of(context).colorScheme.primary 
          : null,
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
              color: hasRoute
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
            label: Text(
              isNavigating ? 'Stop' : 'Navigate',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: hasRoute
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
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
