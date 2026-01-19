import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitPriceController = TextEditingController();
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newProduct = Product(
        productName: _productNameController.text,
        category:
            _categoryController.text.isEmpty ? null : _categoryController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        qty: int.parse(_qtyController.text),
        unitPrice: double.parse(_unitPriceController.text),
        status: 'active', // Default status to active
      );

      try {
        await _apiService.insertProduct(newProduct, _imageFile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Go back and indicate success
      } catch (e) {
        print('Error adding product: $e'); // Added for debugging
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
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
        title: const Text('Add New Product'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTextField(
                  controller: _productNameController,
                  label: 'Product Name',
                  icon: Icons.label_important),
              _buildTextField(
                  controller: _categoryController,
                  label: 'Category (Optional)',
                  icon: Icons.category),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                icon: Icons.description,
                maxLines: 3,
              ),
              _buildTextField(
                controller: _qtyController,
                label: 'Quantity',
                icon: Icons.format_list_numbered,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _unitPriceController,
                label: 'Unit Price',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white, // Added for text visibility
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo.shade800),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide:
                const BorderSide(color: Color(0xFF3949AB), width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
        validator: validator ??
            (value) {
              if (label.contains('Optional')) return null;
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white.withOpacity(0.8),
          ),
          child: _imageBytes == null
              ? const Center(
                  child: Text('No image selected.',
                      style: TextStyle(color: Colors.grey)))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_search),
          label: const Text('Pick Image from Gallery'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3949AB),
          ),
        ),
      ],
    );
  }
}