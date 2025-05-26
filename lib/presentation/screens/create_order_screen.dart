import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/orders/orders_bloc.dart';
import '../blocs/products/products_bloc.dart';
import '../blocs/clients/clients_bloc.dart';
import '../../core/models/order.dart';
import '../../core/models/product.dart';
import '../../core/models/client.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  CreateOrderScreenState createState() => CreateOrderScreenState();
}

class CreateOrderScreenState extends State<CreateOrderScreen> {
  Client? selectedClient;
  List<OrderItem> orderItems = [];
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(LoadProducts());
    context.read<ClientsBloc>().add(LoadClients());
  }

  void _addProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        product: product,
        onAdd: (quantity) {
          setState(() {
            final existingIndex = orderItems.indexWhere(
              (item) => item.productId == product.id,
            );

            if (existingIndex >= 0) {
              final existingItem = orderItems[existingIndex];
              orderItems[existingIndex] = OrderItem(
                productId: product.id,
                productName: product.name,
                price: product.price,
                quantity: existingItem.quantity + quantity,
                subtotal: product.price * (existingItem.quantity + quantity),
              );
            } else {
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
          });
        },
      ),
    );
  }

  void _calculateTotal() {
    total = orderItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _createOrder() {
    if (selectedClient == null || orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecciona un cliente y añade productos')),
      );
      return;
    }

    final order = Order(
      id: '', // Se generará en el bloc
      clientId: selectedClient!.id,
      clientName: selectedClient!.name,
      clientAddress: selectedClient!.address,
      clientLat: selectedClient!.lat,
      clientLng: selectedClient!.lng,
      items: orderItems,
      total: total,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );

    context.read<OrdersBloc>().add(CreateOrder(order));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Pedido'),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _createOrder)],
      ),
      body: Column(
        children: [
          // Selector de cliente
          Card(
            margin: EdgeInsets.all(8.0),
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
                  BlocBuilder<ClientsBloc, ClientsState>(
                    builder: (context, state) {
                      if (state is ClientsLoaded) {
                        return DropdownButton<Client>(
                          value: selectedClient,
                          hint: Text('Seleccionar cliente'),
                          isExpanded: true,
                          items: state.clients.map((client) {
                            return DropdownMenuItem<Client>(
                              value: client,
                              child: Text(client.name),
                            );
                          }).toList(),
                          onChanged: (client) {
                            setState(() {
                              selectedClient = client;
                            });
                          },
                        );
                      }
                      return CircularProgressIndicator();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Lista de productos
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Productos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ProductsBloc, ProductsState>(
                    builder: (context, state) {
                      if (state is ProductsLoaded) {
                        return ListView.builder(
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            final product = state.products[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  '\${product.price.toStringAsFixed(0)}',
                                ),
                              ),
                              title: Text(product.name),
                              subtitle: Text(product.description),
                              trailing: IconButton(
                                icon: Icon(Icons.add_shopping_cart),
                                onPressed: () => _addProduct(product),
                              ),
                            );
                          },
                        );
                      }
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ],
            ),
          ),

          // Carrito de compras
          if (orderItems.isNotEmpty)
            SizedBox(
              height: 200,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Carrito',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text('Cantidad: ${item.quantity}'),
                          trailing: Text(
                            '\${item.subtotal.toStringAsFixed(2)}',
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    color: Colors.grey[200],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '\${total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final Product product;
  final Function(int) onAdd;

  const AddProductDialog({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

class AddProductDialogState extends State<AddProductDialog> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Precio: \${widget.product.price.toStringAsFixed(2)}'),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: quantity > 1
                    ? () {
                        setState(() {
                          quantity--;
                        });
                      }
                    : null,
                icon: Icon(Icons.remove),
              ),
              Text('$quantity'),
              IconButton(
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                },
                icon: Icon(Icons.add),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Subtotal: \$${NumberFormat.currency(locale: 'es_CO', symbol: '').format(widget.product.price * quantity)}',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(quantity);
            Navigator.pop(context);
          },
          child: Text('Añadir'),
        ),
      ],
    );
  }
}
