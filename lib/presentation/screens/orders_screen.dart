import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/orders/orders_bloc.dart';
import '../../core/models/order.dart';
import 'order_detail_screen.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos en Ruta'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              context.read<OrdersBloc>().add(SyncOrders());
            },
          ),
        ],
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is OrdersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrdersBloc>().add(LoadOrders());
                    },
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (state is OrdersLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<OrdersBloc>().add(LoadOrders());
              },
              child: ListView.builder(
                itemCount: state.orders.length,
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return OrderCard(order: order);
                },
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status),
          child: Icon(_getStatusIcon(order.status), color: Colors.white),
        ),
        title: Text(order.clientName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.clientAddress),
            Text(
              'Total: \$${NumberFormat.currency(locale: 'es_CO', symbol: '').format(order.total)}',
            ),
            Text('Estado: [1m${_getStatusText(order.status)}[0m'),
            if (!order.synced)
              Text(
                'Sin sincronizar',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'complete') {
              context.read<OrdersBloc>().add(
                UpdateOrderStatus(order.id, OrderStatus.completed),
              );
            } else if (value == 'cancel') {
              context.read<OrdersBloc>().add(
                UpdateOrderStatus(order.id, OrderStatus.cancelled),
              );
            }
          },
          itemBuilder: (context) => [
            if (order.status == OrderStatus.pending)
              PopupMenuItem(value: 'complete', child: Text('Completar')),
            if (order.status != OrderStatus.cancelled)
              PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.inProgress:
        return Icons.directions_car;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.inProgress:
        return 'En Progreso';
      case OrderStatus.completed:
        return 'Completado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}
