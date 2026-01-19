class Product {
  final int? productId;
  final String productName;
  final String? category;
  final String? description;
  final int qty;
  final double unitPrice;
  final String? productImage;
  final String? status;

  Product({
    this.productId,
    required this.productName,
    this.category,
    this.description,
    required this.qty,
    required this.unitPrice,
    this.productImage,
    this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: int.tryParse(json['product_id'].toString()),
      productName: json['product_name'],
      category: json['category'],
      description: json['description'],
      qty: int.parse(json['qty'].toString()),
      unitPrice: double.parse(json['unit_price'].toString()),
      productImage: json['product_image'],
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'description': description,
      'qty': qty,
      'unit_price': unitPrice,
      'product_image': productImage,
      'status': status,
    };
  }
}
