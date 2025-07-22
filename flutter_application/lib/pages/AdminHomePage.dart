import 'package:flutter/material.dart';
import 'login_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePage();
}

class _AdminHomePage extends State<AdminHomePage> {
  int _selectedIndex = 0;
  final List<String> titles = ['Dashboard', 'Stock', 'Settings'];

  final List<Widget> _pages = [
    Center(child: Text('dashboard page')),
    Center(child: Text('Storage page')),
    Center(child: Text('setting page')),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _pages[_selectedIndex],
        backgroundColor: Colors.grey[700],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey),
              child: Text(
                'Admin menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: Text('Storage'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('Settings'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(); // ❌ Cancel, just close dialog
                        },
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ); // ✅ Sign out
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
