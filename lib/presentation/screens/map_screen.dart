import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../blocs/location/location_bloc.dart';
import '../blocs/orders/orders_bloc.dart';
import '../../core/models/order.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  // ignore: unused_field
  late List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    context.read<LocationBloc>().add(StartLocationTracking());
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void _addOrderMarkers(List<Order> orders) {
    _markers.clear();

    for (Order order in orders) {
      if (order.status == OrderStatus.pending ||
          order.status == OrderStatus.inProgress) {
        _markers.add(
          Marker(
            markerId: MarkerId(order.id),
            position: LatLng(order.clientLat, order.clientLng),
            infoWindow: InfoWindow(
              title: order.clientName,
              snippet: 'Total: \${order.total.toStringAsFixed(2)}',
            ),
            icon: order.status == OrderStatus.pending
                ? BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  )
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
          ),
        );
      }
    }
  }

  void _updateRoute(List<LatLng> points) {
    _routePoints = points;
    _polylines.clear();

    if (points.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: points,
          color: Colors.blue,
          width: 3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Rutas'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              context.read<LocationBloc>().add(GetCurrentLocation());
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<OrdersBloc, OrdersState>(
            listener: (context, state) {
              if (state is OrdersLoaded) {
                setState(() {
                  _addOrderMarkers(state.orders);
                });
              }
            },
          ),
          BlocListener<LocationBloc, LocationState>(
            listener: (context, state) {
              if (state is LocationUpdated) {
                if (_controller != null) {
                  _controller!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(state.latitude, state.longitude),
                    ),
                  );
                }

                setState(() {
                  _markers.removeWhere(
                    (marker) => marker.markerId.value == 'current_location',
                  );
                  _markers.add(
                    Marker(
                      markerId: MarkerId('current_location'),
                      position: LatLng(state.latitude, state.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                      infoWindow: InfoWindow(title: 'Mi ubicación'),
                    ),
                  );
                });
              } else if (state is RouteUpdated) {
                setState(() {
                  _updateRoute(state.routePoints);
                });
              }
            },
          ),
        ],
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            LatLng initialPosition = LatLng(
              10.3910,
              -75.4794,
            ); // Cartagena por defecto

            if (state is LocationUpdated) {
              initialPosition = LatLng(state.latitude, state.longitude);
            }

            return GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 14.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            );
          },
        ),
      ),
    );
  }
}
