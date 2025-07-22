import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_application/pages/login_page.dart'; // adjust to your real path

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _selectedPage = "Dashboard";

  Widget getPageContent() {
    switch (_selectedPage) {
      case "Dashboard":
        return const Center(child: Text("Welcome to Dashboard!"));
      case "Stock":
        return const Center(child: Text("Manage your stock here."));
      case "Orders":
        return const Center(child: Text("Orders overview."));
      default:
        return const Center(child: Text("Unknown page"));
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sign Out"),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPage),
        backgroundColor: Colors.grey[700],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey),
              child: Text(
                "Admin Panel",
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                setState(() => _selectedPage = "Dashboard");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Stock"),
              onTap: () {
                setState(() => _selectedPage = "Stock");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("Orders"),
              onTap: () {
                setState(() => _selectedPage = "Orders");
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sign Out"),
              onTap: _confirmSignOut,
            ),
          ],
        ),
      ),
      body: getPageContent(),
    );
  }
}
