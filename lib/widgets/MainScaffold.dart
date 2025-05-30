import 'package:erp_tool/widgets/sidebar_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/chats/ChatRoomListPage.dart';
import '../modules/providers/notification_provider.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? leading;

  const MainScaffold(
      {super.key,
      required this.title,
      required this.child,
      this.actions,
      this.floatingActionButton,
      this.leading});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>().notifications;
    final unreadCount = notifications.where((n) => n['seen'] != 1).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () =>
                SidebarController.of(context)?.openPage(const ChatMainPage()),
            icon: const Icon(Icons.chat),
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(child: child),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  void _showNotificationsPopup(
      BuildContext context, List<Map<String, dynamic>> notifications) {
    final unreadCount = notifications.where((n) => n['seen'] != 1).length;
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("🔔 Notifications"),
              if (unreadCount > 0)
                TextButton(
                  onPressed: () async {
                    provider.markAllAsSeen();
                    Navigator.pop(context);
                  },
                  child: const Text("Mark All as Read",
                      style: TextStyle(fontSize: 12)),
                ),
              TextButton.icon(
                onPressed: () async {
                  provider.clearAll();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text("Clear All"),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: notifications.isEmpty
                ? const Center(child: Text("You're all caught up 🎉"))
                : ListView.builder(
                    itemCount: notifications.length,
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
                          ),
                        ),
                        subtitle: Text(notif['message'] ?? ''),
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
}
