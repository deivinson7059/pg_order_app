import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';
import 'core/di/injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/orders/orders_bloc.dart';
import 'presentation/blocs/products/products_bloc.dart';
import 'presentation/blocs/clients/clients_bloc.dart';
import 'presentation/blocs/location/location_bloc.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/services/background_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'core/database/database_helper.dart';
import 'core/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limpiar la base de datos si está en modo demo
  if (AppConstants.demo) {
    await DatabaseHelper().clearAllTables();
  }

  // Inicializar dependencias
  await initializeDependencies();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Inicializar servicio en segundo plano
    await Workmanager().initialize(callbackDispatcher);
  }

  runApp(PedidosRutaApp());
}

class PedidosRutaApp extends StatelessWidget {
  const PedidosRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<OrdersBloc>()),
        BlocProvider(create: (_) => getIt<ProductsBloc>()),
        BlocProvider(create: (_) => getIt<ClientsBloc>()),
        BlocProvider(create: (_) => getIt<LocationBloc>()),
      ],
      child: MaterialApp(
        title: 'PgFacture®',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
