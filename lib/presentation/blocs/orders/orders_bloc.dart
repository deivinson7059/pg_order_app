// ignore_for_file: avoid_print

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/order.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object> get props => [];
}

class LoadOrders extends OrdersEvent {}

class CreateOrder extends OrdersEvent {
  final Order order;
  const CreateOrder(this.order);
  @override
  List<Object> get props => [order];
}

class UpdateOrderStatus extends OrdersEvent {
  final String orderId;
  final OrderStatus status;
  const UpdateOrderStatus(this.orderId, this.status);
  @override
  List<Object> get props => [orderId, status];
}

class SyncOrders extends OrdersEvent {}

// States
abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  const OrdersLoaded(this.orders);
  @override
  List<Object> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;

  OrdersBloc(this._databaseHelper, this._apiService) : super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<SyncOrders>(_onSyncOrders);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final orders = await _databaseHelper.getOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrdersError('Error al cargar pedidos: $e'));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final orderWithId = event.order.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
      );

      await _databaseHelper.insertOrder(orderWithId);
      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al crear pedido: $e'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _databaseHelper.updateOrderStatus(event.orderId, event.status);
      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al actualizar pedido: $e'));
    }
  }

  Future<void> _onSyncOrders(
    SyncOrders event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final unsyncedOrders = await _databaseHelper.getUnsyncedOrders();

      for (Order order in unsyncedOrders) {
        try {
          await _apiService.syncOrder(order);
          await _databaseHelper.markOrderAsSynced(order.id);
        } catch (e) {
          print('Error sincronizando pedido ${order.id}: $e');
        }
      }

      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al sincronizar pedidos: $e'));
    }
  }
}
