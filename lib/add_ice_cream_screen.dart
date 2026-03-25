import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AddIceCreamScreen extends StatefulWidget {
  const AddIceCreamScreen({super.key});

  @override
  State<AddIceCreamScreen> createState() => _AddIceCreamScreenState();
}

class _AddIceCreamScreenState extends State<AddIceCreamScreen> {
  final name = TextEditingController();
  final sku = TextEditingController();
  final category = TextEditingController();
  final basePrice = TextEditingController();
  final discountedPrice = TextEditingController();
  final stock = TextEditingController();
  final description = TextEditingController();
  final supplier = TextEditingController();
  final imageUrl = TextEditingController();
  final dateAdded = TextEditingController();

  bool _isSubmitting = false;

  File? _selectedImage;
  bool _isUploadingImage = false;

  // Image picker!!!
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // Upload image to Firebase storage HEHEHE
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images/$fileName.jpg');

      await ref.putFile(_selectedImage!);

      final url = await ref.getDownloadURL();

      setState(() => _isUploadingImage = false);

      return url;
    } catch (e) {
      setState(() => _isUploadingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image upload failed'),
          backgroundColor: Colors.red,
        ),
      );

      return null;
    }
  }

  Future<void> _addItem() async {
    if (_isSubmitting) return;

    if (name.text.trim().isEmpty ||
        basePrice.text.trim().isEmpty ||
        stock.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, Base Price, and Stock Qty are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String finalImageUrl = imageUrl.text.trim();

      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage();
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      }

      final product = Product(
        name: name.text.trim(),
        sku: sku.text.trim(),
        category: category.text.trim(),
        basePrice: double.tryParse(basePrice.text.trim()) ?? 0,
        discountedPrice: double.tryParse(discountedPrice.text.trim()) ?? 0,
        stockQty: int.tryParse(stock.text.trim()) ?? 0,
        description: description.text.trim(),
        supplier: supplier.text.trim(),
        imageUrl: finalImageUrl,
        dateAdded: dateAdded.text.trim(),
      );

      await DBHelper().insertItem(product);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          field('Name', name),
          field('SKU', sku),
          field('Category', category),
          field('Base Price', basePrice),
          field('Discounted Price', discountedPrice),
          field('Stock Qty', stock),
          field('Description', description),
          field('Supplier', supplier),
          field('Image URL (optional)', imageUrl),

          ElevatedButton(
            onPressed: _pickImage,
            child: const Text('Select Image'),
          ),

          const SizedBox(height: 10),

          if (_selectedImage != null)
            Image.file(_selectedImage!, height: 150),

          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Center(child: CircularProgressIndicator()),
            ),

          field('Date Added (e.g. 2026-03-25)', dateAdded),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _addItem,
            child: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }
}
