import 'package:erp_tool/SuperAdminDashboard.dart';
import 'package:erp_tool/widgets/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/auth/pages/login_page.dart';
import '../modules/auth/providers/auth_provider.dart';
import '../modules/chats/ChatRoomListPage.dart';
import '../modules/customer/pages/customer_list_page.dart';
import '../modules/estimate/pages/estimate_home_page.dart';
import '../modules/material/pages/material_home.dart';
import '../modules/providers/notification_provider.dart';
import '../modules/sales/sales_dhashboard.dart';
import '../modules/user/user_list_page.dart';
import '../modules/estimate/pages/new_woodwork_estimate_page.dart';
import '../modules/estimate/pages/electrical_estimate_page.dart';
import '../modules/estimate/pages/false_ceiling_estimate_page.dart';
import '../modules/estimate/pages/wallpaper.dart';
import '../modules/estimate/pages/charcoal_estimate.dart';
import '../modules/estimate/pages/Quartz_Slab_Page.dart';
import '../modules/estimate/pages/granite_stone_estimate.dart';
import '../modules/estimate/pages/weinscoating_estimate.dart';
import '../modules/estimate/pages/Flooring_Estimate.dart';
import '../modules/estimate/pages/grass_estimate.dart';
import '../modules/estimate/pages/mosquito_Net_Estimate.dart';
import '../modules/estimate/pages/estimate_list_page.dart';
import '../services/customer_database_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

class SidebarLayout extends StatefulWidget {
  const SidebarLayout({super.key});

  @override
  SidebarLayoutState createState() => SidebarLayoutState();
}

class SidebarLayoutState extends State<SidebarLayout> {
  List<Map<String, dynamic>> _customers = [];
  late List<Widget> _pages;
  bool _isSidebarExpanded = true; // Sidebar toggle state
  int _selectedIndex = 0;
  bool _isEstimateExpanded = false; // Controls estimate dropdown
  Map<String, dynamic>? _selectedCustomer;
  final _dbService = CustomerDatabaseService();
  final int _itemsPerPage = 30;
  int _currentPage = 1;
  int _totalCustomers = 100;
  List<Map<String, dynamic>> _filteredCustomers = [];
  final List<Widget> _navigationStack = [];
  bool _showChatPreview = false;
  final bool _isLoadingNotifications = true;

  bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  Future<void> _loadCustomers({int page = 1}) async {
    final response =
        await _dbService.fetchCustomers(page: page, perPage: _itemsPerPage);

    setState(() {
      _customers =
          response['customers']; // Fetch customers for the current page
      _filteredCustomers = List.from(_customers);
      _currentPage = page;
      _totalCustomers =
          response['totalCustomers']; // Fetch total customers count
    });
  }

  // List of estimate types
  final List<String> estimateTypes = [
    'Woodwork',
    'Electrical',
    'False Ceiling',
    'Wallpaper Estimate',
    'Charcoal Estimate',
    'Quartz Slab Estimate',
    'Granite Estimate',
    'Wainscoting Estimate',
    'Flooring Estimate',
    'Grass Estimate',
    'Mosquito Net Estimate',
  ];

  // Mapping pages to indexes
  @override
  void initState() {
    super.initState();
    _loadCustomers();
    // Trigger notification load after the first frame to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final moduleRoles = authProvider.moduleRoles;
    final userModuleRole = moduleRoles['user'] ?? '';

    _pages = [
      // if (userModuleRole == 'Super Admin')
      //   SuperAdminDashboard(
      //       isAuthenticated: authProvider.isAuthenticated,
      //       userRole: userModuleRole,
      //       userName: authProvider.userName ?? 'User')
      // else
      SuperAdminDashboard(
        isAuthenticated: authProvider.isAuthenticated,
        userName: authProvider.userName ?? 'User',
        userRole: userModuleRole,
      ),
      const EstimateSummaryPage(), // Index 1: Sales Dashboard (accessible if permitted)
      const EstimateHomePage(), // Index 2: Estimate Menu
      const CustomerListPage(), // Index 3
      const MaterialHomePage(), // Index 4
      const UserListPage(), // Index 5
      Container(), // Index 6: Dynamic estimate pages
    ];
  }

  //notification

  Widget _buildNotificationBell(List<Map<String, dynamic>> notifications) {
    int unreadCount = notifications.where((n) => n['seen'] != 1).length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            _showNotificationsPopup(context, notifications);
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsPopup(
      BuildContext context, List<Map<String, dynamic>> notifications) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade50,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🔔 Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (notifications.any((n) => n['seen'] != 1))
                TextButton(
                  onPressed: () async {
                    await markAllNotificationsAsRead();
                    Navigator.pop(context);
                    await Provider.of<NotificationProvider>(context,
                            listen: false)
                        .refreshNotifications();
                  },
                  child: const Text("Mark All as Read",
                      style: TextStyle(fontSize: 12)),
                ),
              TextButton.icon(
                onPressed: () async {
                  await clearAllNotifications();
                  Navigator.pop(context);
                  Provider.of<NotificationProvider>(context, listen: false)
                      .refreshNotifications();
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Clear All'),
              )
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: notifications.isEmpty
                ? const Center(child: Text("You're all caught up 🎉"))
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final isUnread = notif['seen'] != 1;

                      return ListTile(
                        tileColor: isUnread ? Colors.orange.shade50 : null,
                        title: Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif['message'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(notif['created_at']),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isUnread)
                              const Icon(Icons.circle,
                                  size: 10, color: Colors.red),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 20),
                              tooltip: 'Delete',
                              onPressed: () async {
                                await deleteNotification(notif['id']);
                                Provider.of<NotificationProvider>(context,
                                        listen: false)
                                    .refreshNotifications();
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          await markNotificationAsSeen(notif['id']);
                          Provider.of<NotificationProvider>(context,
                                  listen: false)
                              .refreshNotifications();

                          Navigator.pop(context); // close after update
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return '';
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> markNotificationAsSeen(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse("http://127.0.0.1:4000/api/notifications/$id/seen"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print("✅ Notification $id marked as seen");
    } else {
      print("❌ Failed to mark as seen: ${response.body}");
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');

    if (token == null || userId == null) {
      print("❌ Cannot mark all as read: missing token/userId");
      return;
    }

    final response = await http.patch(
      Uri.parse("http://127.0.0.1:4000/api/notifications/mark-all"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      print("✅ All notifications marked as read");
    } else {
      print("❌ Failed to mark all as read: ${response.body}");
    }
  }

  Future<void> deleteNotification(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse("http://127.0.0.1:4000/api/notifications/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print("🗑 Notification $id deleted");
    } else {
      print("❌ Failed to delete notification: ${response.body}");
    }
  }

  Future<void> clearAllNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');
    final response = await http.delete(
      Uri.parse(
          "http://127.0.0.1:4000/api/notifications/clear-all?user_id=$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print(" All notifications cleared");
    } else {
      print(" Failed to clear notifications: ${response.body}");
    }
  }

  //end

  // Method to navigate to the selected estimate type page
  void _navigateToEstimateType(BuildContext context, String estimateType) {
    Widget page;

    switch (estimateType) {
      case 'Woodwork':
        page = NewWoodworkEstimatePage(
          customerId: _selectedCustomer!['id'],
          customerName: _selectedCustomer!['name'],
          customerEmail: _selectedCustomer!['email'],
          customerPhone: _selectedCustomer!['phone'],
        );
        break;
      case 'Electrical':
        page = ElectricalEstimatePage(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
        );
        break;
      case 'False Ceiling':
        page = FalseCeilingEstimatePage(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
        );
        break;
      case 'Charcoal Estimate':
        page = CharcoalEstimate(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          estimateData: const {},
        );
        break;
      case 'Quartz Slab Estimate':
        page = QuartzSlabPage(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          estimateData: const {},
        );
        break;
      case 'Granite Estimate':
        page = GraniteStoneEstimate(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          estimateData: const {},
        );
        break;
      case 'Wainscoting Estimate':
        page = WeinscoatingEstimatePage(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
        );
        break;
      case 'Wallpaper Estimate':
        page = Wallpaper(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          estimateData: const {},
        );
        break;
      case 'Flooring Estimate':
        page = FlooringEstimate(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          estimateData: const {},
        );
        break;
      case 'Grass Estimate':
        page = GrassEstimate(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          estimateData: const {},
        );
        break;
      case 'Mosquito Net Estimate':
        page = MosquitoNetEstimate(
          customerId: _selectedCustomer!['id'],
          customerInfo: {
            'name': _selectedCustomer!['name'],
            'email': _selectedCustomer!['email'],
            'phone': _selectedCustomer!['phone'],
          },
          customerName: '',
          customerEmail: '',
          customerPhone: '',
          estimateData: const {},
        );
        break;
      default:
        page = EstimateListPage(
          customerId: _selectedCustomer!['id'],
        );
    }

    // ✅ Open the estimate inside the same layout instead of a new page
    setState(() {
      _pages[6] = page; // Replace the placeholder
      _selectedIndex = 6; // Switch to the new estimate page
    });
  }

  Future<Map<String, dynamic>> _fetchLatestEstimateForCustomer(
      int customerId) async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api";
      final response = await http.get(Uri.parse("$baseUrl/latest/$customerId"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Failed to fetch latest estimate for customer $customerId");
      }
    } catch (e) {
      print("Error fetching latest estimate: $e");
      return {};
    }
  }

  void _toggleEstimateMenu() {
    setState(() {
      _isEstimateExpanded = !_isEstimateExpanded;
    });
  }

  // Method to handle navigation
  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void openPage(Widget page) {
    if (_selectedIndex == 6) {
      _navigationStack.add(_pages[6]); // Save current page before changing
    }

    setState(() {
      _pages[6] = page;
      _selectedIndex = 6;
    });
  }

  void goBack() {
    if (_navigationStack.isNotEmpty) {
      Widget previousPage = _navigationStack.removeLast();
      setState(() {
        _pages[6] = previousPage;
        _selectedIndex = 6;
      });
    } else {
      setState(() {
        _selectedIndex = 0; // Go to home if no history
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarColor = isDark ? Colors.grey[850] : Colors.white;
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 1,
              title: SvgPicture.asset("assets/logoBlack.svg", height: 40),
              leading: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: Icon(Icons.menu,
                        color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: Container(
                  color: Colors.white,
                  child: _buildSidebarContent(isExpanded: true)))
          : null,
      body: isMobile
          ? _pages[_selectedIndex] // Just the content in mobile
          : Row(
              children: [
                // Sidebar (Tablet/Desktop)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSidebarExpanded ? 200 : 80,
                  color: Colors.white,
                  child: _buildSidebarContent(isExpanded: _isSidebarExpanded),
                ),

                // Main Content
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
    );
  }

  Widget _buildSidebarContent({required bool isExpanded}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? Colors.grey[900] : Colors.white;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;
        final unreadCount = notifications.where((n) => n['seen'] == 0).length;

        return Container(
          color: sidebarBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Collapse Button
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    if (isExpanded)
                      SvgPicture.asset("assets/logoBlack.svg", height: 40),
                    const Spacer(),
                    if (!isMobile(context)) // Hide collapse button in mobile
                      IconButton(
                        icon: Icon(isExpanded
                            ? Icons.chevron_left
                            : Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _isSidebarExpanded = !_isSidebarExpanded;
                          });
                        },
                      ),
                    if (isExpanded)
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications,
                                color: Colors.orange),
                            onPressed: () =>
                                _showNotificationsPopup(context, notifications),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.red,
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const Divider(),

              // Scrollable Sidebar Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // if (authProvider.moduleRoles['user'] == 'Super Admin')
                      _buildSidebarItem(
                          context, "Admin", Icons.admin_panel_settings, 0),
                      _buildSidebarItem(
                          context, "Sales", Icons.point_of_sale_sharp, 1),
                      _buildExpandableEstimateMenu(),
                      _buildSidebarItem(context, "Customers", Icons.people, 3),
                      _buildSidebarItem(context, "Materials", Icons.build, 4),
                      _buildSidebarItem(context, "Users", Icons.person, 5),
                    ],
                  ),
                ),
              ),

              const Divider(),

              // User Info + Logout + Theme Toggle
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final isLoggedIn = authProvider.isAuthenticated;
                  final userName = authProvider.userName ?? 'Guest';
                  final userRole = authProvider.userRole ?? 'Not logged in';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'profile') {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const CustomerListPage()));
                                    } else if (value == 'message') {
                                      setState(() {
                                        _showChatPreview = !_showChatPreview;
                                      });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                        value: 'profile',
                                        child: Text('View Profile')),
                                    const PopupMenuItem(
                                        value: 'message',
                                        child: Text('Message')),
                                  ],
                                  child: const CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        AssetImage('assets/profile.jpg'),
                                  ),
                                ),
                                if (authProvider.isAuthenticated)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            if (_isSidebarExpanded)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        Text(
                                          userRole,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message: 'Logout',
                                          child: InkWell(
                                            onTap: () async {
                                              await Provider.of<AuthProvider>(
                                                      context,
                                                      listen: false)
                                                  .logout();
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        const LoginPage()),
                                              );
                                            },
                                            child: const Icon(Icons.logout,
                                                size: 18, color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 🔽 Folding chat preview box
                      if (_showChatPreview)
                        Container(
                          margin: const EdgeInsets.only(top: 8, right: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Quick Chat",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              ElevatedButton.icon(
                                onPressed: () {
                                  SidebarController.of(context)
                                      ?.openPage(const ChatMainPage());
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text("Open Messages"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 1),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Toggle Theme',
                          icon: Image.asset(
                            isDark ? 'assets/sun.png' : 'assets/moon.png',
                            height: 26,
                          ),
                          onPressed: () {
                            Provider.of<ThemeProvider>(context, listen: false)
                                .toggleTheme();
                          },
                        ),
                      ),
                    ],
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }

  // Expandable Sidebar Item for Estimates
  Widget _buildExpandableEstimateMenu() {
    final isSelected = _selectedIndex == 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isSelected ? Colors.orange : Colors.transparent;
    final textColor = isSelected
        ? Colors.white
        : isDark
            ? Colors.white70
            : Colors.black87;
    final iconColor = isSelected ? Colors.white : Colors.orange;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: _isSidebarExpanded ? 16 : 10, vertical: 12),
          color: backgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.calculate, color: iconColor, size: 20),
                      if (_isSidebarExpanded) const SizedBox(width: 12),
                      if (_isSidebarExpanded)
                        Text(
                          "Estimates Home",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _toggleEstimateMenu,
                child: Icon(
                  _isEstimateExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isDark ? Colors.white70 : Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // 🔹 Expandable Estimate Options
        if (_isEstimateExpanded)
          Column(
            children: estimateTypes.map((estimateType) {
              return _buildEstimateWidget(
                  context, estimateType, Icons.circle, Colors.orange);
            }).toList(),
          ),
      ],
    );
  }

  // 📌 Sidebar Item Builder
  Widget _buildSidebarItem(
      BuildContext context, String title, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isSelected ? Colors.orange : Colors.transparent;
    final textColor =
        isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87);
    final iconColor = isSelected ? Colors.white : Colors.orange;

    return InkWell(
      onTap: () => _onItemSelected(index),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: _isSidebarExpanded ? 16 : 10, vertical: 12),
        color: backgroundColor,
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            if (_isSidebarExpanded) const SizedBox(width: 12),
            if (_isSidebarExpanded)
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 📌 Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child:
                  const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Method to show the customer selection dialog (popup)
  void _showCustomerSelectionDialog(BuildContext context, String estimateType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown to select a customer
              DropdownButton<Map<String, dynamic>>(
                value: _selectedCustomer,
                hint: const Text('Select a customer'),
                items: _customers.map((customer) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: customer,
                    child: Text(customer['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomer = value;
                  });
                },
              ),
              // If a customer is selected, show their details
              if (_selectedCustomer != null) ...[
                const SizedBox(height: 16),
                Text('Customer Name: ${_selectedCustomer!['name']}'),
                Text('Customer Email: ${_selectedCustomer!['email']}'),
                Text('Customer Phone: ${_selectedCustomer!['phone']}'),
              ]
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Confirm button to navigate to the selected estimate page
            ElevatedButton(
              onPressed: () {
                if (_selectedCustomer != null) {
                  Navigator.of(context).pop(); // Close the dialog
                  _navigateToEstimateType(context, estimateType);
                } else {
                  // Show a message if no customer is selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a customer')),
                  );
                }
              },
              child: const Text('Go to Estimate Page'),
            ),
          ],
        );
      },
    );
  }

  // Estimate Type Button
  Widget _buildEstimateWidget(BuildContext context, String estimateType,
      IconData icon, Color iconColor) {
    ValueNotifier<bool> isHovered = ValueNotifier(false); // Track hover state

    return Padding(
      padding: const EdgeInsets.only(
          left: 30.0, top: 4.0, bottom: 4.0), // Indentation for hierarchy
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => isHovered.value = true, // ✅ Set hover to true
        onExit: (_) => isHovered.value = false, // ✅ Set hover to false
        child: ValueListenableBuilder<bool>(
          valueListenable: isHovered,
          builder: (context, hovering, child) {
            return InkWell(
              onTap: () {
                _showCustomerSelectionDialog(
                    context, estimateType); // ✅ Open Customer Selection Popup
              },
              child: Row(
                children: [
                  Icon(icon, size: 10, color: iconColor), // Static icon
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estimateType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: hovering
                            ? Colors.orange
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SidebarController extends InheritedWidget {
  final void Function(Widget page) openPage;
  final void Function() goBack;

  const SidebarController({
    required this.openPage,
    required this.goBack,
    required super.child,
    super.key,
  });

  static SidebarController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SidebarController>();
  }

  @override
  bool updateShouldNotify(SidebarController oldWidget) => false;
}
