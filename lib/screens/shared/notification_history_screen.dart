import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/notification_provider.dart';

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key, required this.customerId, this.customerName});
  final String customerId;
  final String? customerName;

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'SMS':
        return Icons.sms_outlined;
      case 'EMAIL':
        return Icons.email_outlined;
      case 'PUSH':
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _showSendDialog(BuildContext context, WidgetRef ref) async {
    final messageController = TextEditingController();
    String channel = 'PUSH';
    bool isSending = false;
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send Manual Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: channel,
                items: const [
                  DropdownMenuItem(value: 'PUSH', child: Text('Push Notification')),
                  DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                  DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                ],
                onChanged: (value) => setDialogState(() => channel = value ?? 'PUSH'),
                decoration: const InputDecoration(labelText: 'Channel'),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppTheme.errorColor)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (messageController.text.trim().isEmpty) {
                        setDialogState(() => error = 'Enter a message');
                        return;
                      }
                      setDialogState(() {
                        isSending = true;
                        error = null;
                      });
                      try {
                        await ref.read(notificationHistoryServiceProvider).sendManual(
                              customerId: customerId,
                              message: messageController.text.trim(),
                              channel: channel,
                            );
                        ref.invalidate(customerNotificationsProvider(customerId));
                        if (context.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        setDialogState(() {
                          error = e.toString();
                          isSending = false;
                        });
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(customerNotificationsProvider(customerId));

    return Scaffold(
      appBar: AppBar(title: Text(customerName != null ? 'Notifications — $customerName' : 'Notification History')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSendDialog(context, ref),
        icon: const Icon(Icons.send_outlined),
        label: const Text('Send Manual'),
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) =>
            ErrorView(message: err.toString(), onRetry: () => ref.refresh(customerNotificationsProvider(customerId))),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateView(message: 'No notifications sent yet', icon: Icons.notifications_none);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(customerNotificationsProvider(customerId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Card(
                  child: ListTile(
                    leading: Icon(_channelIcon(n.channel), color: AppTheme.primaryColor),
                    title: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${n.type.replaceAll('_', ' ')} • ${n.channel} • ${Formatters.dateTime(n.createdAt)}',
                    ),
                    trailing: StatusBadge(status: n.status),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
