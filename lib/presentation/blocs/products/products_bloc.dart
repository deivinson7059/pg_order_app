import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/product.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/api_service.dart';

// Events
abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object> get props => [];
}

class LoadProducts extends ProductsEvent {}

class RefreshProducts extends ProductsEvent {}

// States
abstract class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  const ProductsLoaded(this.products);
  @override
  List<Object> get props => [products];
}

class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final DatabaseHelper _databaseHelper;
  final ApiService _apiService;

  ProductsBloc(this._databaseHelper, this._apiService)
    : super(ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<RefreshProducts>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await _databaseHelper.getProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductsError('Error al cargar productos: $e'));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      final products = await _apiService.getProducts();
      await _databaseHelper.insertProducts(products);
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductsError('Error al actualizar productos: $e'));
    }
  }
}
