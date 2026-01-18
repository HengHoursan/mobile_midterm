import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/item_model.dart';
import '../services/api_service.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _itemNameController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _qtyController;
  late TextEditingController _unitPriceController;
  XFile? _imageFile; // For new image
  Uint8List? _imageBytes;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(text: widget.item.itemName);
    _categoryController = TextEditingController(text: widget.item.category);
    _descriptionController = TextEditingController(text: widget.item.description);
    _qtyController = TextEditingController(text: widget.item.qty.toString());
    _unitPriceController = TextEditingController(text: widget.item.unitPrice.toString());
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    } else {
      setState(() {
        _imageFile = null;
        _imageBytes = null;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final updatedItem = Item(
        itemId: widget.item.itemId,
        itemName: _itemNameController.text,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        qty: int.parse(_qtyController.text),
        unitPrice: double.parse(_unitPriceController.text),
        itemImage: widget.item.itemImage, // Keep existing image if not updated
      );

      try {
        await _apiService.updateItem(updatedItem, _imageFile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully!')),
        );
        Navigator.pop(context, true); // Go back and indicate success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update item: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        backgroundColor: const Color.fromARGB(255, 138, 10, 119),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category (Optional)'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Display current image or new picked image
              _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      height: 150,
                      fit: BoxFit.cover,
                    )
                  : (widget.item.itemImage != null && widget.item.itemImage!.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            final imageUrl = '${_apiService.baseUrl}/uploads/${widget.item.itemImage!}';
                            print('Attempting to load image from EditScreen: $imageUrl'); // Debug print
                            return Image.network(
                              imageUrl,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image from EditScreen $imageUrl: $error'); // Log network image loading errors
                                return const Icon(Icons.image_not_supported, size: 150);
                              },
                            );
                          },
                        )
                      : const Text('No image selected.')),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick New Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Update Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
