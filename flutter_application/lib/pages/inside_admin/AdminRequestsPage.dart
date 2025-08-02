import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage>
    with TickerProviderStateMixin {
  List<dynamic> requests = [];
  List<dynamic> filteredRequests = [];
  bool isLoading = true;
  String filterStatus = 'all';
  TextEditingController searchController = TextEditingController();

  AnimationController? _listAnimationController;
  Animation<double>? _fadeAnimation;
  AnimationController? _filterAnimationController;
  Animation<double>? _filterSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchRequests();
    searchController.addListener(_filterRequests);
  }

  void _initializeAnimations() {
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _listAnimationController!,
      curve: Curves.easeInOut,
    );

    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterSlideAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: _filterAnimationController!,
        curve: Curves.easeOut,
      ),
    );

    _filterAnimationController!.forward();
  }

  @override
  void dispose() {
    _listAnimationController?.dispose();
    _filterAnimationController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _filterRequests() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredRequests = requests.where((request) {
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          String fullName =
              '${request['name'] ?? ''} ${request['surname'] ?? ''}'
                  .toLowerCase();
          String email = (request['email'] ?? '').toLowerCase();
          matchesSearch = fullName.contains(query) || email.contains(query);
        }

        bool matchesStatus =
            filterStatus == 'all' || request['status'] == filterStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showMessage('Authentication error: Please log in again', isError: true);
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://flutter-backend-xhrw.onrender.com/api/account-requests',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedRequests = jsonDecode(response.body);
        setState(() {
          requests = fetchedRequests;
          filteredRequests = fetchedRequests;
          isLoading = false;
        });
        _listAnimationController?.forward(from: 0);
      } else {
        setState(() => isLoading = false);
        _showMessage(
          'Failed to load requests: ${response.statusCode}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage(
        'Network error: Please check your connection',
        isError: true,
      );
    }
  }

  Future<void> handleAction(String id, bool approve, String userName) async {
    final confirmed = await _showActionConfirmation(approve, userName);
    if (!confirmed) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showMessage('Authentication error: Please log in again', isError: true);
      return;
    }

    final url =
        'https://flutter-backend-xhrw.onrender.com/api/account-requests/$id/${approve ? 'approve' : 'reject'}';

    try {
      setState(() => isLoading = true);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _showMessage(
          'Request ${approve ? 'approved' : 'rejected'} successfully!',
          isError: false,
        );
        await fetchRequests();
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage(
          'Error: ${errorData['message'] ?? 'Unknown error'}',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Network error: Please try again', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _showActionConfirmation(bool approve, String userName) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    approve ? Icons.check_circle : Icons.cancel,
                    color: approve ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(approve ? 'Approve Request' : 'Reject Request'),
                ],
              ),
              content: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  children: [
                    TextSpan(text: 'Are you sure you want to '),
                    TextSpan(
                      text: approve ? 'approve' : 'reject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: approve ? Colors.green : Colors.red,
                      ),
                    ),
                    TextSpan(text: ' the account request for '),
                    TextSpan(
                      text: userName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '?'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: approve ? Colors.green : Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    approve ? 'Approve' : 'Reject',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getInitials(String name, String surname) {
    String first = name.isNotEmpty ? name[0] : '';
    String second = surname.isNotEmpty ? surname[0] : '';
    return (first + second).toUpperCase();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString.substring(0, 10);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(-1, 0),
          end: Offset.zero,
        ).animate(_filterSlideAnimation!),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildFilterChip('all', 'All', Icons.list),
            SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending', Icons.schedule),
            SizedBox(width: 8),
            _buildFilterChip('approved', 'Approved', Icons.check_circle),
            SizedBox(width: 8),
            _buildFilterChip('rejected', 'Rejected', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    bool isSelected = filterStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          filterStatus = value;
          _filterRequests();
        });
      },
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    searchController.clear();
                    _filterRequests();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) => _filterRequests(),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request, int index) {
    final initials = _getInitials(
      request['name'] ?? '',
      request['surname'] ?? '',
    );
    final status = request['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRequestDetails(request),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'avatar_${request['_id']}',
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${request['name'] ?? ''} ${request['surname'] ?? ''}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  request['email'] ?? 'No email',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    SizedBox(width: 6),
                    Text(
                      'Requested on ${_formatDate(request['createdAt'])}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                if (status == 'pending') ...[
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => handleAction(
                            request['_id'],
                            false,
                            '${request['name']} ${request['surname']}',
                          ),
                          icon: Icon(Icons.close, size: 18),
                          label: Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => handleAction(
                            request['_id'],
                            true,
                            '${request['name']} ${request['surname']}',
                          ),
                          icon: Icon(Icons.check, size: 18),
                          label: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(dynamic request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${request['_id']}',
              child: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                child: Text(
                  _getInitials(request['name'] ?? '', request['surname'] ?? ''),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request['name'] ?? ''} ${request['surname'] ?? ''}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Account Request Details',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              Icons.person,
              'Full Name',
              '${request['name'] ?? ''} ${request['surname'] ?? ''}',
            ),
            _buildDetailRow(
              Icons.email,
              'Email',
              request['email'] ?? 'Not provided',
            ),
            _buildDetailRow(
              Icons.access_time,
              'Request Date',
              _formatDate(request['createdAt']),
            ),
            _buildDetailRow(
              _getStatusIcon(request['status']),
              'Status',
              (request['status'] ?? 'Unknown').toUpperCase(),
              statusColor: _getStatusColor(request['status']),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          if (request['status'] == 'pending') ...[
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                handleAction(
                  request['_id'],
                  false,
                  '${request['name']} ${request['surname']}',
                );
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                handleAction(
                  request['_id'],
                  true,
                  '${request['name']} ${request['surname']}',
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Approve', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: statusColor ?? Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: statusColor ?? Colors.black87,
                    fontWeight: statusColor != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filterStatus == 'all'
                ? Icons.inbox_outlined
                : Icons.filter_list_off,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            filterStatus == 'all'
                ? 'No requests yet'
                : 'No $filterStatus requests',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchController.text.isNotEmpty
                ? 'Try adjusting your search or filters'
                : filterStatus == 'all'
                ? 'Account requests will appear here'
                : 'No requests match the current filter',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    int totalCount = requests.length;
    int pendingCount = requests.where((r) => r['status'] == 'pending').length;
    int approvedCount = requests.where((r) => r['status'] == 'approved').length;
    int rejectedCount = requests.where((r) => r['status'] == 'rejected').length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total', totalCount.toString(), Icons.list),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Pending',
              pendingCount.toString(),
              Icons.schedule,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Approved',
              approvedCount.toString(),
              Icons.check_circle,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Rejected',
              rejectedCount.toString(),
              Icons.cancel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Account Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : fetchRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isLoading && requests.isNotEmpty) _buildStatsBar(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading requests...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : filteredRequests.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: fetchRequests,
                    color: Theme.of(context).primaryColor,
                    child: FadeTransition(
                      opacity: _fadeAnimation!,
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 20),
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          return AnimatedContainer(
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            curve: Curves.easeOutBack,
                            child: _buildRequestCard(
                              filteredRequests[index],
                              index,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
