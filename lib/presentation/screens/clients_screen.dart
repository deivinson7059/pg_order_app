import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/clients/clients_bloc.dart';
import '../../core/models/client.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clientes'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<ClientsBloc>().add(RefreshClients());
            },
          ),
        ],
      ),
      body: BlocBuilder<ClientsBloc, ClientsState>(
        builder: (context, state) {
          if (state is ClientsLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is ClientsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ClientsBloc>().add(LoadClients());
                    },
                    child: Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (state is ClientsLoaded) {
            if (state.clients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay clientes disponibles'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ClientsBloc>().add(RefreshClients());
                      },
                      child: Text('Actualizar'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ClientsBloc>().add(RefreshClients());
              },
              child: ListView.builder(
                itemCount: state.clients.length,
                itemBuilder: (context, index) {
                  final client = state.clients[index];
                  return ClientCard(client: client);
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

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: client.active ? Colors.green : Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(client.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.address),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(client.phone),
              ],
            ),
            if (client.email != null)
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(client.email!),
                ],
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: client.active ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client.active ? 'Activo' : 'Inactivo',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        onTap: () {
          // Navegar a detalles del cliente o crear pedido
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(client.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dirección: ${client.address}'),
                  Text('Teléfono: ${client.phone}'),
                  if (client.email != null) Text('Email: ${client.email}'),
                  Text('Estado: ${client.active ? "Activo" : "Inactivo"}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar'),
                ),
                if (client.active)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navegar a crear pedido para este cliente
                    },
                    child: Text('Crear pedido'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
