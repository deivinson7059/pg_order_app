// ignore_for_file: avoid_print

import 'package:workmanager/workmanager.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../di/injection_container.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "syncData":
        await _syncData();
        break;
      case "refreshProducts":
        await _refreshProducts();
        break;
      case "syncRoutePoints":
        await _syncRoutePoints();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _syncData() async {
  try {
    final databaseHelper = getIt<DatabaseHelper>();
    final apiService = getIt<ApiService>();

    final unsyncedOrders = await databaseHelper.getUnsyncedOrders();

    for (final order in unsyncedOrders) {
      try {
        await apiService.syncOrder(order);
        await databaseHelper.markOrderAsSynced(order.id);
      } catch (e) {
        print('Error sincronizando pedido ${order.id}: $e');
      }
    }
  } catch (e) {
    print('Error en sincronización: $e');
  }
}

Future<void> _refreshProducts() async {
  try {
    final databaseHelper = getIt<DatabaseHelper>();
    final apiService = getIt<ApiService>();

    final products = await apiService.getProducts();
    await databaseHelper.insertProducts(products);

    final clients = await apiService.getClients();
    await databaseHelper.insertClients(clients);
  } catch (e) {
    print('Error actualizando datos: $e');
  }
}

Future<void> _syncRoutePoints() async {
  try {
    final databaseHelper = getIt<DatabaseHelper>();
    final apiService = getIt<ApiService>();

    final unsyncedPoints = await databaseHelper.getUnsyncedRoutePoints();

    if (unsyncedPoints.isNotEmpty) {
      await apiService.syncRoutePoints(unsyncedPoints);

      final ids = unsyncedPoints.map((point) => point['id'] as int).toList();
      await databaseHelper.markRoutePointsAsSynced(ids);
    }
  } catch (e) {
    print('Error sincronizando puntos de ruta: $e');
  }
}

class BackgroundService {
  static void startPeriodicTasks() {
    // Sincronizar datos cada 30 minutos
    Workmanager().registerPeriodicTask(
      "sync-data",
      "syncData",
      frequency: Duration(minutes: 30),
    );

    // Actualizar productos y clientes cada 5 horas
    Workmanager().registerPeriodicTask(
      "refresh-data",
      "refreshProducts",
      frequency: Duration(hours: 5),
    );

    // Sincronizar puntos de ruta cada 15 minutos
    Workmanager().registerPeriodicTask(
      "sync-route",
      "syncRoutePoints",
      frequency: Duration(minutes: 15),
    );
  }
}
