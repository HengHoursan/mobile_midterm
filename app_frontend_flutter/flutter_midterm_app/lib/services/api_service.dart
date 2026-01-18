import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/item_model.dart';

class ApiService {
  // With `php -S localhost:8000 -t public`, the document root is `public`,
  // so endpoints are like http://localhost:8000/fetch_items.php
  final String baseUrl = "http://10.0.2.2:8080";

  Future<List<Item>> fetchItems() async {
    final response = await http.get(Uri.parse('$baseUrl/fetch_items.php'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Handle error responses from PHP
      if (decoded is Map && decoded['success'] == false) {
        throw Exception(decoded['message'] ?? 'Unknown error from API');
      }

      // Support both { success, data: [] } and plain [] for flexibility
      final List<dynamic> itemsJson;
      if (decoded is List) {
        itemsJson = decoded;
      } else if (decoded is Map && decoded['data'] != null) {
        itemsJson = decoded['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected API response format');
      }

      return itemsJson.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items from API');
    }
  }

  Future<void> insertItem(Item item, XFile? imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/insert_item.php'),
    );
    request.fields['item_name'] = item.itemName;
    request.fields['category'] = item.category ?? '';
    request.fields['description'] = item.description ?? '';
    request.fields['qty'] = item.qty.toString();
    request.fields['unit_price'] = item.unitPrice.toString();
    if (item.status != null) {
      request.fields['status'] = item.status.toString();
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;
      request.files.add(
        http.MultipartFile.fromBytes('item_image', bytes, filename: fileName),
      );
    }

    var response = await request.send();
    final responseBody = (await response.stream.bytesToString()).trim();

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(responseBody);
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to insert item.');
        }
      } on FormatException {
        // If JSON decoding fails, check if the response body contains "success"
        if (!responseBody.toLowerCase().contains('success')) {
          throw Exception(
            'Failed to insert item. Unexpected response: $responseBody',
          );
        }
      }
    } else {
      throw Exception(
        'Failed to insert item. Status code: ${response.statusCode}',
      );
    }
  }

  Future<void> updateItem(Item item, XFile? imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/update_item.php'),
    );
    request.fields['item_id'] = item.itemId.toString();
    request.fields['item_name'] = item.itemName;
    request.fields['category'] = item.category ?? '';
    request.fields['description'] = item.description ?? '';
    request.fields['qty'] = item.qty.toString();
    if (item.status != null) {
      request.fields['status'] = item.status.toString();
    }
    request.fields['unit_price'] = item.unitPrice.toString();
    // Assuming itemImage in Item model holds the current i
    if (item.itemImage != null && imageFile == null) {
      request.fields['current_item_image'] = item.itemImage!;
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.name;
      request.files.add(
        http.MultipartFile.fromBytes('item_image', bytes, filename: fileName),
      );
    }

    var response = await request.send();
    final responseBody = (await response.stream.bytesToString()).trim();

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(responseBody);
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to update item.');
        }
      } on FormatException {
        if (!responseBody.toLowerCase().contains('success')) {
          throw Exception(
            'Failed to update item. Unexpected response: $responseBody',
          );
        }
      }
    } else {
      throw Exception(
        'Failed to update item. Status code: ${response.statusCode}',
      );
    }
  }

Future<void> deleteItem(int itemId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_item.php'),
      body: {'item_id': itemId.toString()},
    );

    if (response.statusCode == 200) {
      final responseBody = response.body.trim();
      try {
        final decoded = json.decode(responseBody);
        if (decoded is Map && decoded['success'] == false) {
          throw Exception(decoded['message'] ?? 'Failed to delete item.');
        }
      } on FormatException {
        if (!responseBody.toLowerCase().contains('success')) {
          throw Exception(
            'Failed to delete item. Unexpected response: $responseBody',
          );
        }
      }
    } else {
      throw Exception(
        'Failed to delete item. Status code: ${response.statusCode}',
      );
    }
  }
}
