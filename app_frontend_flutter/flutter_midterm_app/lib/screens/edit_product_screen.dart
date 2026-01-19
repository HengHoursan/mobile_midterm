import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
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
    _productNameController = TextEditingController(text: widget.product.productName);
    _categoryController = TextEditingController(text: widget.product.category);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _qtyController = TextEditingController(text: widget.product.qty.toString());
    _unitPriceController =
        TextEditingController(text: widget.product.unitPrice.toString());
  }

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
      final updatedProduct = Product(
        productId: widget.product.productId,
        productName: _productNameController.text,
        category:
            _categoryController.text.isEmpty ? null : _categoryController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        qty: int.parse(_qtyController.text),
        unitPrice: double.parse(_unitPriceController.text),
        productImage:
            widget.product.productImage, // Keep existing image if not updated
      );

      try {
        await _apiService.updateProduct(updatedProduct, _imageFile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Go back and indicate success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: $e'),
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
        title: const Text('Edit Product'),
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
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Update Product'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white,
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
    final currentImageUrl = (widget.product.productImage != null &&
            widget.product.productImage!.isNotEmpty)
        ? '${_apiService.baseUrl}/uploads/${widget.product.productImage!}'
        : null;

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                : (currentImageUrl != null
                    ? Image.network(
                        currentImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Text('Could not load image',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : const Center(
                        child: Text('No image provided.',
                            style: TextStyle(color: Colors.grey)))),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_search),
          label: const Text('Change Image'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3949AB),
          ),
        ),
      ],
    );
  }
}
