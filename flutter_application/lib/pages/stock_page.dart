import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application/pages/AdminHomePage.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<Map<String, dynamic>> products = [];
  final String apiUrl =
      'https://flutter-backend-g7p6.onrender.com/api/products';
  bool isLoading = false;

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
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

  Future<void> _addProduct(String name, int quantity) async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'quantity': quantity}),
      );
      if (response.statusCode == 201) {
        await _fetchProducts();
      } else {
        _showError('Error adding product: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error adding product: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editProduct(String id, String newName, int newQuantity) async {
    setState(() => isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': newName, 'quantity': newQuantity}),
      );
      if (response.statusCode == 200) {
        await _fetchProducts();
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
        content: Text('Are you sure you want to delete "$name"?'),
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
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 200) {
        await _fetchProducts();
        _showError('Product deleted successfully', isError: false);
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

  void _showAddDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (name.isNotEmpty && quantity > 0) {
                await _addProduct(name, quantity);
                Navigator.pop(context);
              } else {
                _showError('Please enter valid product name and quantity');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    final nameController = TextEditingController(text: products[index]['name']);
    final quantityController = TextEditingController(
      text: products[index]['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Edit Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (name.isNotEmpty && quantity > 0) {
                await _editProduct(products[index]['_id'], name, quantity);
                Navigator.pop(context);
              } else {
                _showError('Please enter valid product name and quantity');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
          'Stock Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.teal,
        elevation: 4,
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
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            )
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
              itemBuilder: (_, index) {
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
                    subtitle: Text(
                      'Quantity: ${product['quantity']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () => _showEditDialog(index),
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
        onPressed: _showAddDialog,
        backgroundColor: Colors.teal,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
