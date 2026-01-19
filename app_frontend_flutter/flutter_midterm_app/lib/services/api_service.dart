import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';

class ApiService {
  // With `php -S localhost:8000 -t public`, the document root is `public`,
  // so endpoints are like http://localhost:8000/fetch_products.php
  final String baseUrl = "http://10.0.2.2:8080";

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/fetch_products.php'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Handle error responses from PHP
      if (decoded is Map && decoded['success'] == false) {
        throw Exception(decoded['message'] ?? 'Unknown error from API');
      }

      // Support both { success, data: [] } and plain [] for flexibility
      final List<dynamic> productsJson;
      if (decoded is List) {
        productsJson = decoded;
      } else if (decoded is Map && decoded['data'] != null) {
        productsJson = decoded['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected API response format');
      }

      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products from API');
    }
  }

  Future<void> insertProduct(Product product, XFile? imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/insert_product.php'),
    );
    request.fields['product_name'] = product.productName;
    request.fields['category'] = product.category ?? '';
    request.fields['description'] = product.description ?? '';
    request.fields['qty'] = product.qty.toString();
    request.fields['unit_price'] = product.unitPrice.toString();
    if (product.status != null) {
      request.fields['status'] = product.status.toString();
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;
      request.files.add(
        http.MultipartFile.fromBytes('product_image', bytes, filename: fileName),
      );
    }

    var response = await request.send();
    final responseBody = (await response.stream.bytesToString()).trim();

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(responseBody);
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to insert product.');
        }
      } on FormatException {
        // If JSON decoding fails, check if the response body contains "success"
        if (!responseBody.toLowerCase().contains('success')) {
          throw Exception(
            'Failed to insert product. Unexpected response: $responseBody',
          );
        }
      }
    }
 else {
      throw Exception(
        'Failed to insert product. Status code: ${response.statusCode}',
      );
    }
  }

  Future<void> updateProduct(Product product, XFile? imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/update_product.php'),
    );
    request.fields['product_id'] = product.productId.toString();
    request.fields['product_name'] = product.productName;
    request.fields['category'] = product.category ?? '';
    request.fields['description'] = product.description ?? '';
    request.fields['qty'] = product.qty.toString();
    if (product.status != null) {
      request.fields['status'] = product.status.toString();
    }
    request.fields['unit_price'] = product.unitPrice.toString();
    // Assuming productImage in Product model holds the current i
    if (product.productImage != null && imageFile == null) {
      request.fields['current_product_image'] = product.productImage!;
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;
      request.files.add(
        http.MultipartFile.fromBytes('product_image', bytes, filename: fileName),
      );
    }

    var response = await request.send();
    final responseBody = (await response.stream.bytesToString()).trim();

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(responseBody);
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to update product.');
        }
      }
 on FormatException {
        if (!responseBody.toLowerCase().contains('success')) {
          throw Exception(
            'Failed to update product. Unexpected response: $responseBody',
          );
        }
      }
    }
 else {
      throw Exception(
        'Failed to update product. Status code: ${response.statusCode}',
      );
    }
  }

Future<void> deleteProduct(int productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_product.php'),
      body: {'product_id': productId.toString()},
    );

    if (response.statusCode == 200) {
      final responseBody = response.body.trim();
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to delete product.');
        }
      }
 on FormatException {
        if (!responseBody.toLowerCase().contains('success')) {
          throw Exception(
            'Failed to delete product. Unexpected response: $responseBody',
          );
        }
      }
    }
 else {
      throw Exception(
        'Failed to delete product. Status code: ${response.statusCode}',
      );
    }
  }
}

