import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/orders/orders_bloc.dart';
import '../blocs/products/products_bloc.dart';
import '../blocs/clients/clients_bloc.dart';
import '../blocs/location/location_bloc.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'clients_screen.dart';
import 'map_screen.dart';
import 'create_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    OrdersScreen(),
    ProductsScreen(),
    ClientsScreen(),
    MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    context.read<OrdersBloc>().add(LoadOrders());
    context.read<ProductsBloc>().add(LoadProducts());
    context.read<ClientsBloc>().add(LoadClients());
    context.read<LocationBloc>().add(StartLocationTracking());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Productos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Navegar a crear pedido
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateOrderScreen()),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
