part of 'auth_cubit.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final List<String> accountIds;

  AuthSuccess({required this.accountIds});
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthInfo extends AuthState {
  final String message;
  AuthInfo(this.message);
}
