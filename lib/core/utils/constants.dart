class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.tusitio.com/';
  static const String socketUrl = 'https://socket.tusitio.com';
  static const bool demo = true;

  // Database
  static const String databaseName = 'pedidos_ruta.db';
  static const int databaseVersion = 1;

  // Location Settings
  static const int locationUpdateIntervalSeconds = 30;
  static const double minimumDistanceFilter = 10.0; // metros

  // Sync Settings
  static const int syncIntervalMinutes = 30;
  static const int productRefreshHours = 5;
  static const int routeSyncMinutes = 15;

  // SharedPreferences Keys
  static const String keyUserId = 'user_id';
  static const String keyUsername = 'username';
  static const String keyLastProductSync = 'last_product_sync';
  static const String keyLastClientSync = 'last_client_sync';

  // Map Settings
  static const double defaultLat = 10.3910; // Cartagena
  static const double defaultLng = -75.4794;
  static const double defaultZoom = 14.0;
}
