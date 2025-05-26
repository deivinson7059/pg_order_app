import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/orders/orders_bloc.dart';
import '../../core/models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${order.id.substring(0, 8)}'),
        actions: [
          if (order.status == OrderStatus.pending)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'start') {
                  context.read<OrdersBloc>().add(
                    UpdateOrderStatus(order.id, OrderStatus.inProgress),
                  );
                  Navigator.pop(context);
                } else if (value == 'complete') {
                  context.read<OrdersBloc>().add(
                    UpdateOrderStatus(order.id, OrderStatus.completed),
                  );
                  Navigator.pop(context);
                } else if (value == 'cancel') {
                  context.read<OrdersBloc>().add(
                    UpdateOrderStatus(order.id, OrderStatus.cancelled),
                  );
                  Navigator.pop(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'start',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Iniciar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('Completar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel),
                      SizedBox(width: 8),
                      Text('Cancelar'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado del pedido
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estado del pedido',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getStatusText(order.status),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Creado: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                    ),
                    if (order.completedAt != null)
                      Text(
                        'Completado: ${DateFormat('dd/MM/yyyy HH:mm').format(order.completedAt!)}',
                      ),
                    if (!order.synced)
                      Text(
                        'Pendiente de sincronización',
                        style: TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Información del cliente
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text(order.clientName),
                      subtitle: Text(order.clientAddress),
                      trailing: IconButton(
                        icon: Icon(Icons.directions),
                        onPressed: () {
                          // Abrir en Google Maps o navegador interno
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Productos del pedido
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text(
                            'Precio unitario: \$${NumberFormat.currency(locale: 'es_CO', symbol: '').format(item.price)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Qty: ${item.quantity}'),
                              Text(
                                NumberFormat.currency(
                                  locale: 'es_CO',
                                  symbol: '\$',
                                ).format(item.subtotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Divider(thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '\$${NumberFormat.currency(locale: 'es_CO', symbol: '').format(order.total)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
