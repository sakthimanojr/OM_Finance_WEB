import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/admin_management_provider.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Management',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentLime,
          indicatorWeight: 3.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Admins'), Tab(text: 'System Config')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_AdminsTab(), _SystemConfigTab()],
      ),
    );
  }
}

class _AdminsTab extends ConsumerWidget {
  const _AdminsTab();

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSubmitting = false;
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New View Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(labelText: 'Phone Number *', counterText: ''),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password *'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: AppTheme.errorColor)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (phoneController.text.trim().length != 10 || passwordController.text.length < 6) {
                        setDialogState(() => error = 'Enter a valid 10-digit phone and a 6+ char password');
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        error = null;
                      });
                      try {
                        await ref.read(adminManagementServiceProvider).createViewAdmin(
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                            );
                        ref.invalidate(adminListProvider);
                        if (context.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        setDialogState(() {
                          error = e.toString();
                          isSubmitting = false;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New View Admin'),
      ),
      body: adminsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.refresh(adminListProvider)),
        data: (admins) {
          if (admins.isEmpty) {
            return const EmptyStateView(message: 'No admin accounts found');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: admins.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final admin = admins[index];
                final isSuperAdmin = admin.role == 'SUPER_ADMIN';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSuperAdmin ? AppTheme.primaryColor : Colors.blueGrey,
                      child: Icon(isSuperAdmin ? Icons.shield_outlined : Icons.visibility_outlined, color: Colors.white),
                    ),
                    title: Text(admin.phone),
                    subtitle: Text(
                      '${admin.role.replaceAll('_', ' ')}${admin.email != null ? ' • ${admin.email}' : ''}\n'
                      'Created ${Formatters.date(admin.createdAt)}',
                    ),
                    isThreeLine: true,
                    trailing: isSuperAdmin
                        ? const Chip(label: Text('Protected'))
                        : Switch(
                            value: admin.isActive,
                            onChanged: (value) async {
                              try {
                                await ref.read(adminManagementServiceProvider).setAdminActive(admin.id, value);
                                ref.invalidate(adminListProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                                  );
                                }
                              }
                            },
                          ),
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

class _SystemConfigTab extends ConsumerStatefulWidget {
  const _SystemConfigTab();

  @override
  ConsumerState<_SystemConfigTab> createState() => _SystemConfigTabState();
}

class _SystemConfigTabState extends ConsumerState<_SystemConfigTab> {
  final _upiIdController = TextEditingController();
  final _smsProviderController = TextEditingController();
  final _smsApiKeyController = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(systemConfigProvider);

    return configAsync.when(
      loading: () => const LoadingView(),
      error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.refresh(systemConfigProvider)),
      data: (config) {
        if (!_initialized) {
          _upiIdController.text = config.upiId ?? '';
          _smsProviderController.text = config.smsProvider ?? '';
          _initialized = true;
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Payment Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _upiIdController,
              decoration: const InputDecoration(labelText: 'UPI ID', hintText: 'merchant@upi'),
            ),
            const SizedBox(height: 20),
            Text('SMS Settings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _smsProviderController,
              decoration: const InputDecoration(labelText: 'SMS Provider', hintText: 'e.g. msg91, twilio, or none'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _smsApiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'SMS API Key',
                hintText: config.smsApiKey != null ? '•••••••• (set — leave blank to keep)' : 'Not set',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SMTP email settings can be configured directly via the backend .env file for now.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                        await ref.read(adminManagementServiceProvider).updateConfig(
                              upiId: _upiIdController.text.trim(),
                              smsProvider: _smsProviderController.text.trim(),
                              smsApiKey: _smsApiKeyController.text.trim(),
                            );
                        ref.invalidate(systemConfigProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings saved'), backgroundColor: AppTheme.successColor),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor));
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Settings'),
            ),
          ],
        );
      },
    );
  }
}
