// ignore_for_file: prefer_final_fields

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/socket_service.dart';
import 'dart:async';

// Events
abstract class LocationEvent extends Equatable {
  const LocationEvent();
  @override
  List<Object> get props => [];
}

class StartLocationTracking extends LocationEvent {}

class StopLocationTracking extends LocationEvent {}

class GetCurrentLocation extends LocationEvent {}

class UpdateLocation extends LocationEvent {
  final double latitude;
  final double longitude;
  const UpdateLocation(this.latitude, this.longitude);
  @override
  List<Object> get props => [latitude, longitude];
}

// States
abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationUpdated extends LocationState {
  final double latitude;
  final double longitude;
  const LocationUpdated(this.latitude, this.longitude);
  @override
  List<Object> get props => [latitude, longitude];
}

class RouteUpdated extends LocationState {
  final List<LatLng> routePoints;
  const RouteUpdated(this.routePoints);
  @override
  List<Object> get props => [routePoints];
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final DatabaseHelper _databaseHelper;
  final SocketService _socketService;
  StreamSubscription<Position>? _positionSubscription;
  List<LatLng> _routePoints = [];

  LocationBloc(this._databaseHelper, this._socketService)
    : super(LocationInitial()) {
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<UpdateLocation>(_onUpdateLocation);
  }

  Future<void> _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(LocationError('Los servicios de ubicación están deshabilitados'));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(LocationError('Permisos de ubicación denegados'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(LocationError('Permisos de ubicación denegados permanentemente'));
        return;
      }

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // Actualizar cada 10 metros
            ),
          ).listen((Position position) {
            add(UpdateLocation(position.latitude, position.longitude));
          });
    } catch (e) {
      emit(LocationError('Error al iniciar seguimiento: $e'));
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTracking event,
    Emitter<LocationState> emit,
  ) async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      emit(LocationUpdated(position.latitude, position.longitude));
    } catch (e) {
      emit(LocationError('Error al obtener ubicación: $e'));
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<LocationState> emit,
  ) async {
    // Guardar punto en la base de datos local
    await _databaseHelper.insertRoutePoint(event.latitude, event.longitude);

    // Enviar ubicación via socket
    _socketService.sendLocation(event.latitude, event.longitude);

    // Añadir punto a la ruta
    _routePoints.add(LatLng(event.latitude, event.longitude));

    // Limitar puntos de ruta para rendimiento
    if (_routePoints.length > 100) {
      _routePoints.removeAt(0);
    }

    emit(LocationUpdated(event.latitude, event.longitude));
    emit(RouteUpdated(_routePoints));
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
