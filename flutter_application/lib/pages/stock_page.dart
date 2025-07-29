import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/pages/AdminHomePage.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = false;
  final String apiUrl = 'https://flutter-backend-xhrw.onrender.com';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      print('No JWT token found');
      throw Exception('No JWT token found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$apiUrl/api/products'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          products = data
              .map(
                (item) => {
                  '_id': item['_id'],
                  'name': item['name'],
                  'quantity': item['quantity'],
                },
              )
              .toList();
        });
      } else {
        _showError('Error fetching products: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching products: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addProduct(Map<String, dynamic> productData) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = jsonEncode(productData);
      final response = await http.post(
        Uri.parse('$apiUrl/api/products'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 201) {
        await _fetchProducts();
        _showError('Produit ajouté avec succès', isError: false);
      } else {
        _showError('Error adding product: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error adding product: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editProduct(String id, Map<String, dynamic> productData) async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final body = jsonEncode(productData);
      final response = await http.put(
        Uri.parse('$apiUrl/api/products/$id'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        await _fetchProducts();
        _showError('Produit modifié avec succès', isError: false);
      } else {
        _showError('Error editing product: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error editing product: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete product "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$apiUrl/api/products/$id'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        await _fetchProducts();
        _showError('Produit supprimé avec succès', isError: false);
      } else {
        _showError('Error deleting product: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error deleting product: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? product}) async {
    final nameController = TextEditingController(text: product?['name']);
    final quantityController = TextEditingController(
      text: product?['quantity'].toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity *'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  quantityController.text.isEmpty) {
                _showError('Name and quantity are required');
                return;
              }
              final quantity = int.tryParse(quantityController.text);
              if (quantity == null || quantity < 0) {
                _showError('Invalid quantity');
                return;
              }
              Navigator.pop(context);
              final productData = {
                'name': nameController.text,
                'quantity': quantity,
              };
              if (product == null) {
                _addProduct(productData);
              } else {
                _editProduct(product['_id'], productData);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No products available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      product['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Quantity: ${product['quantity']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => _showAddEditDialog(product: product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteProduct(product['_id'], product['name']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
