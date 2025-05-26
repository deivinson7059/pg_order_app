// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  clientId: json['clientId'] as String,
  clientName: json['clientName'] as String,
  clientAddress: json['clientAddress'] as String,
  clientLat: (json['clientLat'] as num).toDouble(),
  clientLng: (json['clientLng'] as num).toDouble(),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  synced: json['synced'] as bool? ?? false,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'clientId': instance.clientId,
  'clientName': instance.clientName,
  'clientAddress': instance.clientAddress,
  'clientLat': instance.clientLat,
  'clientLng': instance.clientLng,
  'items': instance.items,
  'total': instance.total,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'synced': instance.synced,
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.inProgress: 'in_progress',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  subtotal: (json['subtotal'] as num).toDouble(),
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'productName': instance.productName,
  'price': instance.price,
  'quantity': instance.quantity,
  'subtotal': instance.subtotal,
};
