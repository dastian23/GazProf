enum OrderStatus {
  waiting('In asteptare'),
  allocated('Alocata'),
  pickedUp('Preluata'),
  completed('Finalizata'),
  cancelled('Anulata');

  final String label;
  const OrderStatus(this.label);

  static OrderStatus fromString(String s) {
    return OrderStatus.values.firstWhere(
      (e) => e.label == s,
      orElse: () => OrderStatus.waiting,
    );
  }
}

enum PaymentType {
  cash('cash'),
  card('card'),
  invoice('factura');

  final String value;
  const PaymentType(this.value);

  static PaymentType fromString(String s) {
    return PaymentType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => PaymentType.cash,
    );
  }
}

class FirestoreCollections {
  static const String orders = 'comenzi';
  static const String users = 'users';
  static const String products = 'produse';
  static const String passwordResets = 'password_resets';
}

class AppConstants {
  static const double discountPerBottle = 5.0;
  static const Duration refreshInterval = Duration(seconds: 30);
  static const String addressTypeCity = 'oras';
  static const String addressTypeRoute = 'rute';
  static const String navigationWaze = 'Waze';
  static const String navigationGoogleMaps = 'Google Maps';
}
