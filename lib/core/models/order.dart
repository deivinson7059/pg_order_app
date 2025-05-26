import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String id;
  final String clientId;
  final String clientName;
  final String clientAddress;
  final double clientLat;
  final double clientLng;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool synced;

  Order({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientAddress,
    required this.clientLat,
    required this.clientLng,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.synced = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  Order copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientAddress,
    double? clientLat,
    double? clientLng,
    List<OrderItem>? items,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? synced,
  }) {
    return Order(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAddress: clientAddress ?? this.clientAddress,
      clientLat: clientLat ?? this.clientLat,
      clientLng: clientLng ?? this.clientLng,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      synced: synced ?? this.synced,
    );
  }
}

@JsonSerializable()
class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

enum OrderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}
