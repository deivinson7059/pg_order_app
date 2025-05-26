// ignore_for_file: avoid_print

import 'dart:async';
//import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../network/network_info.dart';

class SyncService {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;
  final NetworkInfo _networkInfo;

  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  SyncService(this._databaseHelper, this._apiService, this._networkInfo);

  void startAutoSync() {
    // Sincronizar cada 30 minutos
    _syncTimer = Timer.periodic(Duration(minutes: 30), (_) {
      syncAll();
    });

    // Sincronizar cuando se recupere la conexión
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen((
      isConnected,
    ) {
      if (isConnected) {
        syncAll();
      }
    });
  }

  Future<void> syncAll() async {
    if (!await _networkInfo.isConnected) return;

    try {
      await syncOrders();
      await syncRoutePoints();
    } catch (e) {
      print('Error en sincronización automática: $e');
    }
  }

  Future<void> syncOrders() async {
    try {
      final unsyncedOrders = await _databaseHelper.getUnsyncedOrders();

      for (final order in unsyncedOrders) {
        try {
          await _apiService.syncOrder(order);
          await _databaseHelper.markOrderAsSynced(order.id);
        } catch (e) {
          print('Error sincronizando pedido ${order.id}: $e');
        }
      }
    } catch (e) {
      print('Error en sincronización de pedidos: $e');
    }
  }

  Future<void> syncRoutePoints() async {
    try {
      final unsyncedPoints = await _databaseHelper.getUnsyncedRoutePoints();

      if (unsyncedPoints.isNotEmpty) {
        await _apiService.syncRoutePoints(unsyncedPoints);

        final ids = unsyncedPoints.map((point) => point['id'] as int).toList();
        await _databaseHelper.markRoutePointsAsSynced(ids);
      }
    } catch (e) {
      print('Error sincronizando puntos de ruta: $e');
    }
  }

  Future<void> refreshMasterData() async {
    if (!await _networkInfo.isConnected) return;

    try {
      // Actualizar productos
      final products = await _apiService.getProducts();
      await _databaseHelper.insertProducts(products);

      // Actualizar clientes
      final clients = await _apiService.getClients();
      await _databaseHelper.insertClients(clients);
    } catch (e) {
      print('Error actualizando datos maestros: $e');
    }
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  void dispose() {
    stopAutoSync();
  }
}
