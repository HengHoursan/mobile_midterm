import 'package:flutter/material.dart';
import 'package:flutter_midterm_app/screens/add_item_screen.dart';
import 'package:flutter_midterm_app/screens/edit_item_screen.dart';

import '../models/item_model.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Item>> _itemsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  void _fetchItems() {
    setState(() {
      _itemsFuture = _apiService.fetchItems();
    });
  }

  void _navigateToAddItemScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );
    if (result == true) {
      _fetchItems();
    }
  }

  void _editItem(Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditItemScreen(item: item)),
    );
    if (result == true) {
      _fetchItems();
    }
  }

  void _deleteItem(int itemId) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteItem(itemId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchItems();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchItems,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Item>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchItems,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 100, color: Colors.grey.shade400),
                    const SizedBox(height: 20),
                    const Text('No items found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 10),
                    const Text('Tap the "+" button to add a new item.',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  final imageUrl = (item.itemImage != null &&
                          item.itemImage!.isNotEmpty)
                      ? '${_apiService.baseUrl}/uploads/${item.itemImage!}'
                      : null;

                  return Card(
                    elevation: 5,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0),
                      leading: SizedBox(
                        width: 80,
                        height: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image,
                                      color: Colors.grey),
                                ),
                        ),
                      ),
                      title: Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (item.category != null &&
                              item.category!.isNotEmpty)
                            Text('Category: ${item.category}',
                                style: TextStyle(color: Colors.grey.shade600)),
                          Text('Qty: ${item.qty}',
                              style: TextStyle(color: Colors.grey.shade600)),
                          Text(
                            'Price: ${item.unitPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3949AB)),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => _editItem(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(item.itemId!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddItemScreen,
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF5C6BC0),
      ),
    );
  }
}