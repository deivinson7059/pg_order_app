import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LogIn extends AuthEvent {
  final String username;
  final String password;
  const LogIn(this.username, this.password);
  @override
  List<Object> get props => [username, password];
}

class LogOut extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String username;
  const AuthAuthenticated(this.userId, this.username);
  @override
  List<Object> get props => [userId, username];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LogIn>(_onLogIn);
    on<LogOut>(_onLogOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final username = prefs.getString('username');

      if (userId != null && username != null) {
        emit(AuthAuthenticated(userId, username));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogIn(LogIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Solo permite usuario y contraseña 'danisoft'
      if (event.username == 'danisoft' && event.password == 'danisoft') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', 'user_123');
        await prefs.setString('username', event.username);

        emit(AuthAuthenticated('user_123', event.username));
      } else {
        emit(AuthError('Credenciales inválidas'));
      }
    } catch (e) {
      emit(AuthError('Error al iniciar sesión: $e'));
    }
  }

  Future<void> _onLogOut(LogOut event, Emitter<AuthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Error al cerrar sesión: $e'));
    }
  }
}
