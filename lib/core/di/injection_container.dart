import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:pg_order_app/presentation/blocs/auth/auth_bloc.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../services/api_service_demo.dart';
import '../services/socket_service.dart';
import '../../presentation/blocs/orders/orders_bloc.dart';
import '../../presentation/blocs/products/products_bloc.dart';
import '../../presentation/blocs/clients/clients_bloc.dart';
import '../../presentation/blocs/location/location_bloc.dart';
import '../utils/constants.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());
  getIt.registerSingleton<SocketService>(SocketService());

  // Dio
  final dio = Dio();
  dio.options.connectTimeout = Duration(seconds: 30);
  dio.options.receiveTimeout = Duration(seconds: 30);
  getIt.registerSingleton<Dio>(dio);

  // API Service
  if (AppConstants.demo) {
    getIt.registerSingleton<ApiService>(ApiServiceDemo());
  } else {
    getIt.registerSingleton<ApiService>(ApiService(getIt<Dio>()));
  }

  // Blocs
  getIt.registerFactory<AuthBloc>(() => AuthBloc());
  getIt.registerFactory<OrdersBloc>(() => OrdersBloc(getIt(), getIt()));
  getIt.registerFactory<ProductsBloc>(() => ProductsBloc(getIt(), getIt()));
  getIt.registerFactory<ClientsBloc>(() => ClientsBloc(getIt(), getIt()));
  getIt.registerFactory<LocationBloc>(() => LocationBloc(getIt(), getIt()));
}
