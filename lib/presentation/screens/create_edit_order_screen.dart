import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/orders/orders_bloc.dart';
import '../blocs/products/products_bloc.dart';
import '../blocs/clients/clients_bloc.dart';
import '../../core/models/order.dart';
import '../../core/models/product.dart';
import '../../core/models/client.dart';
import '../../core/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class CreateEditOrderScreen extends StatefulWidget {
  final Order? order;

  const CreateEditOrderScreen({super.key, this.order});

  @override
  CreateEditOrderScreenState createState() => CreateEditOrderScreenState();
}

class CreateEditOrderScreenState extends State<CreateEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientSearchController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _notesController = TextEditingController();

  Client? selectedClient;
  List<OrderItem> orderItems = [];
  double total = 0.0;
  bool isEditMode = false;
  String? orderId;

  // Para el autocompletado
  List<Client> clientSuggestions = [];
  List<Product> productSuggestions = [];
  bool showClientSuggestions = false;
  bool showProductSuggestions = false;

  // Para guardar en borrador
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(LoadProducts());
    context.read<ClientsBloc>().add(LoadClients());

    if (widget.order != null) {
      isEditMode = true;
      orderId = widget.order!.id;
      selectedClient = null; // Necesitamos cargar el cliente
      orderItems = List.from(widget.order!.items);
      total = widget.order!.total;
      _loadOrderData();
    } else {
      orderId = const Uuid().v4();
      _loadDraftOrder();
    }
  }

  Future<void> _loadOrderData() async {
    if (widget.order != null) {
      // Cargar información del cliente
      final clients = await _databaseHelper.getClients();
      final client = clients.firstWhere(
        (c) => c.id == widget.order!.clientId,
        orElse: () => Client(
          id: widget.order!.clientId,
          name: widget.order!.clientName,
          address: widget.order!.clientAddress,
          lat: widget.order!.clientLat,
          lng: widget.order!.clientLng,
          phone: '',
          active: true,
          updatedAt: DateTime.now(),
        ),
      );

      setState(() {
        selectedClient = client;
        _clientSearchController.text = client.name;
      });
    }
  }

  Future<void> _loadDraftOrder() async {
    final draft = await _databaseHelper.getDraftOrder(orderId!);
    if (draft != null) {
      setState(() {
        orderItems = draft.items;
        total = draft.total;
        if (draft.clientId.isNotEmpty) {
          _loadClientFromDraft(draft.clientId);
        }
      });
    }
  }

  Future<void> _loadClientFromDraft(String clientId) async {
    final clients = await _databaseHelper.getClients();
    final client = clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => clients.first,
    );

    setState(() {
      selectedClient = client;
      _clientSearchController.text = client.name;
    });
  }

  Future<void> _saveDraft() async {
    if (_isSaving) return;

    _isSaving = true;
    final draft = Order(
      id: orderId!,
      clientId: selectedClient?.id ?? '',
      clientName: selectedClient?.name ?? '',
      clientAddress: selectedClient?.address ?? '',
      clientLat: selectedClient?.lat ?? 0.0,
      clientLng: selectedClient?.lng ?? 0.0,
      items: orderItems,
      total: total,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      synced: false,
    );

    await _databaseHelper.saveDraftOrder(draft);
    _isSaving = false;
  }

  void _onClientSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        showClientSuggestions = false;
      });
      return;
    }

    final state = context.read<ClientsBloc>().state;
    if (state is ClientsLoaded) {
      setState(() {
        clientSuggestions = state.clients
            .where(
              (client) =>
                  client.name.toLowerCase().contains(query.toLowerCase()) ||
                  client.address.toLowerCase().contains(query.toLowerCase()),
            )
            .take(5)
            .toList();
        showClientSuggestions = clientSuggestions.isNotEmpty;
      });
    }
  }

  void _onProductSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        showProductSuggestions = false;
      });
      return;
    }

    final state = context.read<ProductsBloc>().state;
    if (state is ProductsLoaded) {
      setState(() {
        productSuggestions = state.products
            .where(
              (product) =>
                  product.available &&
                  (product.name.toLowerCase().contains(query.toLowerCase()) ||
                      product.description.toLowerCase().contains(
                        query.toLowerCase(),
                      )),
            )
            .take(5)
            .toList();
        showProductSuggestions = productSuggestions.isNotEmpty;
      });
    }
  }

  void _selectClient(Client client) {
    setState(() {
      selectedClient = client;
      _clientSearchController.text = client.name;
      showClientSuggestions = false;
    });
    _saveDraft();
  }

  void _addOrUpdateProduct(Product product, int quantity) {
    setState(() {
      final existingIndex = orderItems.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex >= 0) {
        if (quantity <= 0) {
          orderItems.removeAt(existingIndex);
        } else {
          orderItems[existingIndex] = OrderItem(
            productId: product.id,
            productName: product.name,
            price: product.price,
            quantity: quantity,
            subtotal: product.price * quantity,
          );
        }
      } else if (quantity > 0) {
        orderItems.add(
          OrderItem(
            productId: product.id,
            productName: product.name,
            price: product.price,
            quantity: quantity,
            subtotal: product.price * quantity,
          ),
        );
      }

      _calculateTotal();
      _productSearchController.clear();
      showProductSuggestions = false;
    });
    _saveDraft();
  }

  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }

    setState(() {
      final item = orderItems[index];
      orderItems[index] = OrderItem(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: newQuantity,
        subtotal: item.price * newQuantity,
      );
      _calculateTotal();
    });
    _saveDraft();
  }

  void _removeItem(int index) {
    setState(() {
      orderItems.removeAt(index);
      _calculateTotal();
    });
    _saveDraft();
  }

  void _calculateTotal() {
    total = orderItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un cliente')),
      );
      return;
    }

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor añade al menos un producto')),
      );
      return;
    }

    final order = Order(
      id: orderId!,
      clientId: selectedClient!.id,
      clientName: selectedClient!.name,
      clientAddress: selectedClient!.address,
      clientLat: selectedClient!.lat,
      clientLng: selectedClient!.lng,
      items: orderItems,
      total: total,
      status: widget.order?.status ?? OrderStatus.pending,
      createdAt: widget.order?.createdAt ?? DateTime.now(),
      completedAt: widget.order?.completedAt,
      synced: false,
    );

    if (isEditMode) {
      context.read<OrdersBloc>().add(UpdateOrder(order));
    } else {
      context.read<OrdersBloc>().add(CreateOrder(order));
    }

    // Eliminar borrador al guardar
    await _databaseHelper.deleteDraftOrder(orderId!);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isEditMode ? 'Editar Pedido' : 'Nuevo Pedido'),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saveOrder,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header con información del total
            Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total del Pedido',
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'es_CO',
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${orderItems.length} productos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Sección de Cliente
                    Container(
                      margin: const EdgeInsets.all(16),
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
                                Icon(
                                  Icons.person,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cliente',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _clientSearchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar cliente...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onChanged: _onClientSearch,
                              validator: (value) {
                                if (selectedClient == null) {
                                  return 'Por favor selecciona un cliente';
                                }
                                return null;
                              },
                            ),
                            if (showClientSuggestions)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(26),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: clientSuggestions.map((client) {
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: client.active
                                            ? Colors.green
                                            : Colors.grey,
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(client.name),
                                      subtitle: Text(client.address),
                                      onTap: () => _selectClient(client),
                                    );
                                  }).toList(),
                                ),
                              ),
                            if (selectedClient != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.blue[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedClient!.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[900],
                                            ),
                                          ),
                                          Text(
                                            selectedClient!.address,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Sección de Productos
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                                Icon(
                                  Icons.shopping_cart,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Agregar Productos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _productSearchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar producto...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onChanged: _onProductSearch,
                            ),
                            if (showProductSuggestions)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(26),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: productSuggestions.map((product) {
                                    final existingItem = orderItems.firstWhere(
                                      (item) => item.productId == product.id,
                                      orElse: () => OrderItem(
                                        productId: '',
                                        productName: '',
                                        price: 0,
                                        quantity: 0,
                                        subtotal: 0,
                                      ),
                                    );

                                    return ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(Icons.inventory),
                                      ),
                                      title: Text(product.name),
                                      subtitle: Text(
                                        NumberFormat.currency(
                                          locale: 'es_CO',
                                          symbol: '\$',
                                          decimalDigits: 0,
                                        ).format(product.price),
                                      ),
                                      trailing:
                                          existingItem.productId.isNotEmpty
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${existingItem.quantity}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                      onTap: () {
                                        _showQuantityDialog(
                                          product,
                                          existingItem.quantity,
                                        );
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Lista de productos añadidos
                    if (orderItems.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
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
                                    Icons.list_alt,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Productos en el Pedido',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orderItems.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = orderItems[index];
                                return Dismissible(
                                  key: Key(item.productId),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red,
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    _removeItem(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${item.productName} eliminado',
                                        ),
                                        action: SnackBarAction(
                                          label: 'Deshacer',
                                          onPressed: () {
                                            setState(() {
                                              orderItems.insert(index, item);
                                              _calculateTotal();
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: ListTile(
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
                                      child: const Icon(Icons.inventory),
                                    ),
                                    title: Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      NumberFormat.currency(
                                        locale: 'es_CO',
                                        symbol: '\$',
                                        decimalDigits: 0,
                                      ).format(item.price),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed: () {
                                            if (item.quantity > 1) {
                                              _updateItemQuantity(
                                                index,
                                                item.quantity - 1,
                                              );
                                            }
                                          },
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed: () {
                                            _updateItemQuantity(
                                              index,
                                              item.quantity + 1,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          NumberFormat.currency(
                                            locale: 'es_CO',
                                            symbol: '\$',
                                            decimalDigits: 0,
                                          ).format(item.subtotal),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    // Notas del pedido
                    Container(
                      margin: const EdgeInsets.all(16),
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
                                Icon(
                                  Icons.note,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Notas del Pedido',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    'Agregar notas o instrucciones especiales...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 100,
                    ), // Espacio para el botón flotante
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: _saveOrder,
          label: Text(
            isEditMode ? 'Actualizar Pedido' : 'Crear Pedido',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.check),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showQuantityDialog(Product product, int currentQuantity) {
    int quantity = currentQuantity > 0 ? currentQuantity : 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Precio: ${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(product.price)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: quantity > 0
                      ? () {
                          setState(() {
                            quantity--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 32),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Subtotal: ${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(product.price * quantity)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _addOrUpdateProduct(product, quantity);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(currentQuantity > 0 ? 'Actualizar' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    _productSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
