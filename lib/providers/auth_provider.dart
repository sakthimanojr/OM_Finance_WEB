import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/token_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  AuthState({this.user, this.isLoading = false, this.error});
  final AppUser? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _restoreSession();
  }

  final AuthService _authService = AuthService();

  Future<void> _restoreSession() async {
    final hasSession = await TokenStorage.hasSession();
    if (!hasSession) return;

    final role = await TokenStorage.getRole();
    final id = await TokenStorage.getUserId();
    final phone = await TokenStorage.getPhone();
    if (role != null && id != null && phone != null) {
      state = state.copyWith(user: AppUser(id: id, role: role, phone: phone));
    }
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(phone, password);
      state = state.copyWith(user: result.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.verifyOtp(phone, otp);
      state = state.copyWith(user: result.user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
