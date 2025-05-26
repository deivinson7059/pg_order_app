import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/orders/orders_bloc.dart';
import '../../core/models/order.dart';
import 'create_edit_order_screen.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _getStatusColor(order.status),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Pedido #${order.id.substring(0, 8).toUpperCase()}'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _getStatusColor(order.status),
                      _getStatusColor(order.status).withAlpha(179),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        size: 64,
                        color: Colors.white.withAlpha(230),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: Colors.white.withAlpha(230),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (order.status == OrderStatus.pending ||
                  order.status == OrderStatus.inProgress)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateEditOrderScreen(order: order),
                      ),
                    ).then((_) {
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    });
                  },
                ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  if (order.status == OrderStatus.pending)
                    const PopupMenuItem(
                      value: 'start',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow, color: Colors.blue),
                        title: Text('Iniciar Pedido'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (order.status == OrderStatus.inProgress)
                    const PopupMenuItem(
                      value: 'complete',
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Completar Pedido'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (order.status != OrderStatus.cancelled &&
                      order.status != OrderStatus.completed)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: ListTile(
                        leading: Icon(Icons.cancel, color: Colors.red),
                        title: Text('Cancelar Pedido'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Eliminar Pedido'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Información del pedido
                  _buildInfoCard(
                    context,
                    title: 'Información del Pedido',
                    icon: Icons.info_outline,
                    children: [
                      _buildInfoRow('Estado', _getStatusText(order.status)),
                      _buildInfoRow(
                        'Creado',
                        DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                      ),
                      if (order.completedAt != null)
                        _buildInfoRow(
                          'Completado',
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(order.completedAt!),
                        ),
                      _buildInfoRow(
                        'Sincronización',
                        order.synced
                            ? 'Sincronizado'
                            : 'Pendiente de sincronización',
                        valueColor: order.synced ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Información del cliente
                  _buildInfoCard(
                    context,
                    title: 'Cliente',
                    icon: Icons.person_outline,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          order.clientName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order.clientAddress,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openMaps(order.clientLat, order.clientLng),
                              icon: const Icon(Icons.map),
                              label: const Text('Ver en Mapa'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchNavigation(
                                order.clientLat,
                                order.clientLng,
                              ),
                              icon: const Icon(Icons.directions),
                              label: const Text('Navegar'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Productos del pedido
                  _buildProductsCard(context),
                  const SizedBox(height: 16),

                  // Notas del pedido (si existen)
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _buildInfoCard(
                      context,
                      title: 'Notas',
                      icon: Icons.note_outlined,
                      children: [
                        Text(
                          order.notes!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.order.items.length} items',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.order.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = widget.order.items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2),
                ),
                title: Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${item.quantity} x ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(item.price)}',
                ),
                trailing: Text(
                  NumberFormat.currency(
                    locale: 'es_CO',
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(item.subtotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'es_CO',
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(widget.order.total),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    if (widget.order.status == OrderStatus.completed ||
        widget.order.status == OrderStatus.cancelled) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.order.status == OrderStatus.pending ||
              widget.order.status == OrderStatus.inProgress)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateEditOrderScreen(order: widget.order),
                    ),
                  ).then((_) {
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Editar Pedido'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (widget.order.status == OrderStatus.pending ||
              widget.order.status == OrderStatus.inProgress)
            const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(context),
              icon: Icon(
                widget.order.status == OrderStatus.pending
                    ? Icons.play_arrow
                    : Icons.check_circle,
              ),
              label: Text(
                widget.order.status == OrderStatus.pending
                    ? 'Iniciar Pedido'
                    : 'Completar Pedido',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.order.status == OrderStatus.pending
                    ? Colors.blue
                    : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'start':
        _updateStatus(context);
        break;
      case 'complete':
        _updateStatus(context);
        break;
      case 'cancel':
        _showConfirmDialog(
          context,
          title: 'Cancelar Pedido',
          message: '¿Estás seguro de que deseas cancelar este pedido?',
          onConfirm: () {
            context.read<OrdersBloc>().add(
              UpdateOrderStatus(widget.order.id, OrderStatus.cancelled),
            );
            Navigator.pop(context);
          },
        );
        break;
      case 'delete':
        _showConfirmDialog(
          context,
          title: 'Eliminar Pedido',
          message:
              '¿Estás seguro de que deseas eliminar este pedido? Esta acción no se puede deshacer.',
          onConfirm: () {
            context.read<OrdersBloc>().add(DeleteOrder(widget.order.id));
            Navigator.pop(context);
          },
        );
        break;
    }
  }

  void _updateStatus(BuildContext context) {
    final newStatus = widget.order.status == OrderStatus.pending
        ? OrderStatus.inProgress
        : OrderStatus.completed;

    _showConfirmDialog(
      context,
      title: widget.order.status == OrderStatus.pending
          ? 'Iniciar Pedido'
          : 'Completar Pedido',
      message: widget.order.status == OrderStatus.pending
          ? '¿Deseas iniciar este pedido?'
          : '¿Deseas marcar este pedido como completado?',
      onConfirm: () {
        context.read<OrdersBloc>().add(
          UpdateOrderStatus(widget.order.id, newStatus),
        );
        Navigator.pop(context);
      },
    );
  }

  void _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final url = 'google.navigation:q=$lat,$lng&mode=d';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback to web URL
      final webUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
      final webUri = Uri.parse(webUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      }
    }
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
