import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';
import '../../services/auth_service.dart';

// --- Events ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  const AuthRegisterSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleSignInSubmitted extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class _AuthUserChanged extends AuthEvent {
  final User? user;
  const _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}

// --- States ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthPasswordResetSent extends AuthState {
  final String email;
  const AuthPasswordResetSent(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({required AuthService authService})
      : _authService = authService,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<AuthRegisterSubmitted>(_onAuthRegisterSubmitted);
    on<AuthGoogleSignInSubmitted>(_onAuthGoogleSignInSubmitted);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<_AuthUserChanged>(_onAuthUserChanged);

    _authSubscription = _authService.authStateChanges.listen((user) {
      add(_AuthUserChanged(user));
    });
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final user = _authService.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) async {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  String _mapAuthError(Object error) {
    final message = error.toString().replaceAll('Exception: ', '');
    final lower = message.toLowerCase();
    if (lower.contains('user-not-found') || lower.contains('wrong-password') || lower.contains('invalid-credential')) {
      return 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.';
    }
    if (lower.contains('email-already-in-use') || lower.contains('account-exists')) {
      return 'Email này đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.';
    }
    if (lower.contains('weak-password')) {
      return 'Mật khẩu quá yếu. Vui lòng sử dụng ít nhất 6 ký tự.';
    }
    if (lower.contains('invalid-email') || lower.contains('malformed')) {
      return 'Địa chỉ email không hợp lệ.';
    }
    if (lower.contains('network-request-failed') || lower.contains('timeout')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại Internet và thử lại.';
    }
    if (lower.contains('popup-blocked')) {
      return 'Trình duyệt đã chặn cửa sổ đăng nhập Google. Vui lòng cho phép popup và thử lại.';
    }
    if (lower.contains('popup-closed-by-user') || lower.contains('cancelled')) {
      return 'Đăng nhập Google bị hủy. Vui lòng thử lại.';
    }
    if (lower.contains('operation-not-allowed')) {
      return 'Đăng nhập bằng Google chưa được bật. Vui lòng liên hệ quản trị viên.';
    }
    if (lower.contains('unauthorized-domain') || lower.contains('auth/unauthorized')) {
      return 'Domain không được phép. Vui lòng liên hệ quản trị viên.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Quá nhiều yêu cầu. Vui lòng chờ vài phút rồi thử lại.';
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
  }

  Future<void> _onAuthLoginSubmitted(AuthLoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.login(event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthFailure('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.'));
      }
    } catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    }
  }

  Future<void> _onAuthRegisterSubmitted(AuthRegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.register(event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthFailure('Đăng ký thất bại. Vui lòng thử lại.'));
      }
    } catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    }
  }

  Future<void> _onAuthGoogleSignInSubmitted(AuthGoogleSignInSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated()); // Canceled by user
      }
    } catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    }
  }

  Future<void> _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authService.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthPasswordResetRequested(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent(event.email));
    } catch (e) {
      emit(AuthFailure(_mapAuthError(e)));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
