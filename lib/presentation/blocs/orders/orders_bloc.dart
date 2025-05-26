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

class UpdateOrder extends OrdersEvent {
  final Order order;
  const UpdateOrder(this.order);
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

class DeleteOrder extends OrdersEvent {
  final String orderId;
  const DeleteOrder(this.orderId);
  @override
  List<Object> get props => [orderId];
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
  final Map<String, dynamic>? statistics;

  const OrdersLoaded(this.orders, {this.statistics});

  @override
  List<Object> get props => [orders, statistics ?? {}];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object> get props => [message];
}

class OrderOperationSuccess extends OrdersState {
  final String message;
  const OrderOperationSuccess(this.message);
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
    on<UpdateOrder>(_onUpdateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<DeleteOrder>(_onDeleteOrder);
    on<SyncOrders>(_onSyncOrders);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final orders = await _databaseHelper.getOrders();
      final statistics = await _databaseHelper.getOrderStatistics();
      emit(OrdersLoaded(orders, statistics: statistics));
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
        id: event.order.id.isEmpty ? const Uuid().v4() : event.order.id,
        createdAt: DateTime.now(),
      );

      await _databaseHelper.insertOrder(orderWithId);

      // Eliminar el borrador si existe
      if (event.order.id.isNotEmpty) {
        await _databaseHelper.deleteDraftOrder(event.order.id);
      }

      emit(const OrderOperationSuccess('Pedido creado exitosamente'));
      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al crear pedido: $e'));
    }
  }

  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _databaseHelper.updateOrder(event.order);
      emit(const OrderOperationSuccess('Pedido actualizado exitosamente'));
      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al actualizar pedido: $e'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _databaseHelper.updateOrderStatus(event.orderId, event.status);

      String message;
      switch (event.status) {
        case OrderStatus.completed:
          message = 'Pedido completado';
          break;
        case OrderStatus.cancelled:
          message = 'Pedido cancelado';
          break;
        case OrderStatus.inProgress:
          message = 'Pedido en progreso';
          break;
        default:
          message = 'Estado actualizado';
      }

      emit(OrderOperationSuccess(message));
      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al actualizar estado: $e'));
    }
  }

  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('orders', where: 'id = ?', whereArgs: [event.orderId]);

      emit(const OrderOperationSuccess('Pedido eliminado'));
      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al eliminar pedido: $e'));
    }
  }

  Future<void> _onSyncOrders(
    SyncOrders event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final unsyncedOrders = await _databaseHelper.getUnsyncedOrders();

      int syncedCount = 0;
      for (Order order in unsyncedOrders) {
        try {
          await _apiService.syncOrder(order);
          await _databaseHelper.markOrderAsSynced(order.id);
          syncedCount++;
        } catch (e) {
          print('Error sincronizando pedido ${order.id}: $e');
        }
      }

      if (syncedCount > 0) {
        emit(OrderOperationSuccess('$syncedCount pedidos sincronizados'));
      } else if (unsyncedOrders.isEmpty) {
        emit(
          const OrderOperationSuccess('Todos los pedidos están sincronizados'),
        );
      } else {
        emit(const OrdersError('Error al sincronizar algunos pedidos'));
      }

      add(LoadOrders());
    } catch (e) {
      emit(OrdersError('Error al sincronizar pedidos: $e'));
    }
  }
}
