import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/client.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';

// Events
abstract class ClientsEvent extends Equatable {
  const ClientsEvent();
  @override
  List<Object> get props => [];
}

class LoadClients extends ClientsEvent {}

class RefreshClients extends ClientsEvent {}

// States
abstract class ClientsState extends Equatable {
  const ClientsState();
  @override
  List<Object> get props => [];
}

class ClientsInitial extends ClientsState {}

class ClientsLoading extends ClientsState {}

class ClientsLoaded extends ClientsState {
  final List<Client> clients;
  const ClientsLoaded(this.clients);
  @override
  List<Object> get props => [clients];
}

class ClientsError extends ClientsState {
  final String message;
  const ClientsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;

  ClientsBloc(this._databaseHelper, this._apiService)
    : super(ClientsInitial()) {
    on<LoadClients>(_onLoadClients);
    on<RefreshClients>(_onRefreshClients);
  }

  Future<void> _onLoadClients(
    LoadClients event,
    Emitter<ClientsState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      final clients = await _databaseHelper.getClients();
      emit(ClientsLoaded(clients));
    } catch (e) {
      emit(ClientsError('Error al cargar clientes: $e'));
    }
  }

  Future<void> _onRefreshClients(
    RefreshClients event,
    Emitter<ClientsState> emit,
  ) async {
    try {
      final clients = await _apiService.getClients();
      await _databaseHelper.insertClients(clients);
      emit(ClientsLoaded(clients));
    } catch (e) {
      emit(ClientsError('Error al actualizar clientes: $e'));
    }
  }
}
