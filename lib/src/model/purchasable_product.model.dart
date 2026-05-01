import 'package:in_app_purchase/in_app_purchase.dart';

enum ProductStatus { purchasable, purchased, pending }

class PurchasableProduct {
  PurchasableProduct(this.productDetails) : status = ProductStatus.purchasable;
  String get id => productDetails.id;
  String get title => productDetails.title;
  String get description => productDetails.description;
  String get price => productDetails.price;
  ProductStatus status;
  ProductDetails productDetails;
}
