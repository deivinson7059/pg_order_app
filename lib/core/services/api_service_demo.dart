// ignore_for_file: unused_field, prefer_final_fields

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'api_service.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/order.dart';

class ApiServiceDemo implements ApiService {
  List<Order> _orders = [];
  List<dynamic> _routePoints = [];

  @override
  Future<List<Product>> getProducts() async {
    final data = await rootBundle.loadString('assets/data/productos.json');
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Product.fromJson(e)).toList();
  }

  @override
  Future<List<Client>> getClients() async {
    final data = await rootBundle.loadString('assets/data/clientes.json');
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Client.fromJson(e)).toList();
  }

  @override
  Future<void> syncOrder(Order order) async {
    _orders.removeWhere((o) => o.id == order.id);
    _orders.add(order.copyWith(synced: true));
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> syncRoutePoints(List<dynamic> points) async {
    _routePoints = points;
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<Order> getOrder(String id) async {
    final order = _orders.firstWhere(
      (o) => o.id == id,
      orElse: () => throw Exception('Pedido no encontrado'),
    );
    return order;
  }
}
