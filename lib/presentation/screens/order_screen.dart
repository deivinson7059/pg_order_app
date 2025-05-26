import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/orders/orders_bloc.dart';
import '../../core/models/order.dart';
import 'order_detail_screen.dart';
import 'create_edit_order_screen.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _filterStatus;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BlocListener<OrdersBloc, OrdersState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Pedidos en Ruta'),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withAlpha(204),
                      ],
                    ),
                  ),
                  child: BlocBuilder<OrdersBloc, OrdersState>(
                    builder: (context, state) {
                      if (state is OrdersLoaded && state.statistics != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: _buildStatistics(state.statistics!),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () {
                    context.read<OrdersBloc>().add(SyncOrders());
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Barra de búsqueda
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por cliente o ID...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Filtros de estado
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Todos',
                            isSelected: _filterStatus == null,
                            onSelected: () {
                              setState(() {
                                _filterStatus = null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Pendientes',
                            isSelected: _filterStatus == OrderStatus.pending,
                            color: Colors.orange,
                            onSelected: () {
                              setState(() {
                                _filterStatus = OrderStatus.pending;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'En Progreso',
                            isSelected: _filterStatus == OrderStatus.inProgress,
                            color: Colors.blue,
                            onSelected: () {
                              setState(() {
                                _filterStatus = OrderStatus.inProgress;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Completados',
                            isSelected: _filterStatus == OrderStatus.completed,
                            color: Colors.green,
                            onSelected: () {
                              setState(() {
                                _filterStatus = OrderStatus.completed;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Cancelados',
                            isSelected: _filterStatus == OrderStatus.cancelled,
                            color: Colors.red,
                            onSelected: () {
                              setState(() {
                                _filterStatus = OrderStatus.cancelled;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is OrdersError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<OrdersBloc>().add(LoadOrders());
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is OrdersLoaded) {
                  final filteredOrders = _filterOrders(state.orders);

                  if (filteredOrders.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No se encontraron pedidos'
                                  : 'No hay pedidos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final order = filteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: OrderCard(order: order),
                      );
                    }, childCount: filteredOrders.length),
                  );
                }
                return const SliverFillRemaining(child: SizedBox());
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEditOrderScreen(),
            ),
          ).then((_) {
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            context.read<OrdersBloc>().add(LoadOrders());
          });
        },
        label: const Text('Nuevo Pedido'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> stats) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total',
              '${stats['totalOrders']}',
              Icons.receipt_long,
            ),
            _buildStatItem(
              'Completados',
              '${stats['completedOrders']}',
              Icons.check_circle,
            ),
            _buildStatItem(
              'Pendientes',
              '${stats['pendingOrders']}',
              Icons.pending,
            ),
            _buildStatItem(
              'Ingresos',
              NumberFormat.currency(
                locale: 'es_CO',
                symbol: '\$',
                decimalDigits: 0,
              ).format(stats['totalRevenue']),
              Icons.attach_money,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: (color ?? Theme.of(context).primaryColor).withAlpha(20),
      checkmarkColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? (color ?? Theme.of(context).primaryColor)
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    var filtered = orders;

    // Filtrar por estado
    if (_filterStatus != null) {
      filtered = filtered
          .where((order) => order.status == _filterStatus)
          .toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        return order.clientName.toLowerCase().contains(_searchQuery) ||
            order.id.toLowerCase().contains(_searchQuery) ||
            order.clientAddress.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class OrderCard extends StatefulWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          ).then((_) {
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            context.read<OrdersBloc>().add(LoadOrders());
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pedido #${order.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.clientAddress,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${order.items.length} productos',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'es_CO',
                      symbol: '\$',
                      decimalDigits: 0,
                    ).format(order.total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (!order.synced)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 12,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sin sincronizar',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (order.status == OrderStatus.pending ||
                  order.status == OrderStatus.inProgress)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
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
                              context.read<OrdersBloc>().add(LoadOrders());
                            });
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showStatusChangeDialog(context, order);
                          },
                          icon: Icon(
                            order.status == OrderStatus.pending
                                ? Icons.play_arrow
                                : Icons.check,
                            size: 18,
                          ),
                          label: Text(
                            order.status == OrderStatus.pending
                                ? 'Iniciar'
                                : 'Completar',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: order.status == OrderStatus.pending
                                ? Colors.blue
                                : Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        text = 'Pendiente';
        break;
      case OrderStatus.inProgress:
        color = Colors.blue;
        icon = Icons.directions_car;
        text = 'En Progreso';
        break;
      case OrderStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Completado';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          order.status == OrderStatus.pending
              ? 'Iniciar Pedido'
              : 'Completar Pedido',
        ),
        content: Text(
          order.status == OrderStatus.pending
              ? '¿Deseas iniciar este pedido?'
              : '¿Deseas marcar este pedido como completado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<OrdersBloc>().add(
                UpdateOrderStatus(
                  order.id,
                  order.status == OrderStatus.pending
                      ? OrderStatus.inProgress
                      : OrderStatus.completed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: order.status == OrderStatus.pending
                  ? Colors.blue
                  : Colors.green,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
