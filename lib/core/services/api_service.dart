import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/client.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: "https://api.tusitio.com/")
abstract class ApiService {
  factory ApiService(Dio dio, {String? baseUrl}) = _ApiService;

  @GET("/products")
  Future<List<Product>> getProducts();

  @GET("/clients")
  Future<List<Client>> getClients();

  @POST("/orders")
  Future<void> syncOrder(@Body() Order order);

  @POST("/route-points")
  Future<void> syncRoutePoints(@Body() List<dynamic> points);

  @GET("/orders/{id}")
  Future<Order> getOrder(@Path("id") String id);
}
