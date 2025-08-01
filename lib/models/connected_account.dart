enum AccountType { gmail }

class ConnectedAccount {
  final String email;
  final AccountType type;

  ConnectedAccount({
    required this.email,
    required this.type,
  });
}
