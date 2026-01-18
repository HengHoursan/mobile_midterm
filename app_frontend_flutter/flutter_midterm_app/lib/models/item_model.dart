class Item {
  final int? itemId;
  final String itemName;
  final String? category;
  final String? description;
  final int qty;
  final double unitPrice;
  final String? itemImage;
  final int? status;

  Item({
    this.itemId,
    required this.itemName,
    this.category,
    this.description,
    required this.qty,
    required this.unitPrice,
    this.itemImage,
    this.status,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: int.tryParse(json['item_id'].toString()),
      itemName: json['item_name'],
      category: json['category'],
      description: json['description'],
      qty: int.parse(json['qty'].toString()),
      unitPrice: double.parse(json['unit_price'].toString()),
      itemImage: json['item_image'],
      status: json['status'] != null
          ? int.tryParse(json['status'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'category': category,
      'description': description,
      'qty': qty,
      'unit_price': unitPrice,
      'item_image': itemImage,
      'status': status,
    };
  }
}
