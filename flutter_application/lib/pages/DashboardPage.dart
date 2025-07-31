import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application/pages/AdminHomePage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = false;
  String totalClients = '0';
  String pendingOrders = '0';
  String productsInStock = '0';
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

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final headers = await _getHeaders();

      // Fetch total clients
      final clientsResponse = await http.get(
        Uri.parse('$apiUrl/api/clients'),
        headers: headers,
      );
      if (clientsResponse.statusCode == 200) {
        final clients = jsonDecode(clientsResponse.body) as List;
        setState(() => totalClients = clients.length.toString());
      } else {
        _showError('Error fetching clients: ${clientsResponse.statusCode}');
      }

      // Fetch pending orders
      final ordersResponse = await http.get(
        Uri.parse('$apiUrl/api/orders'),
        headers: headers,
      );
      if (ordersResponse.statusCode == 200) {
        final orders = jsonDecode(ordersResponse.body) as List;
        final pending = orders
            .where((order) => order['status'] == 'Pending')
            .length;
        setState(() => pendingOrders = pending.toString());
      } else {
        _showError('Error fetching orders: ${ordersResponse.statusCode}');
      }

      // Fetch products in stock
      final productsResponse = await http.get(
        Uri.parse('$apiUrl/api/products'),
        headers: headers,
      );
      if (productsResponse.statusCode == 200) {
        final products = jsonDecode(productsResponse.body) as List;
        final totalStock = products.fold<int>(
          0,
          (sum, product) => sum + (product['quantity'] as int),
        );
        setState(() => productsInStock = totalStock.toString());
      } else {
        _showError('Error fetching products: ${productsResponse.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching data: $e');
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

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
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
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildDashboardCard(
                        title: 'Total Clients',
                        count: totalClients,
                        icon: Icons.people,
                        color: Colors.blueAccent,
                      ),
                      _buildDashboardCard(
                        title: 'Pending Orders',
                        count: pendingOrders,
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                      ),
                      _buildDashboardCard(
                        title: 'Products in Stock',
                        count: productsInStock,
                        icon: Icons.inventory,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
