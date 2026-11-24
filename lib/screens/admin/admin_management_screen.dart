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
    bool canEdit = false;
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: canEdit ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: canEdit ? Colors.green.shade300 : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        canEdit ? Icons.edit_note : Icons.visibility_outlined,
                        color: canEdit ? Colors.green.shade700 : Colors.grey.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Allow Edit Access',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              canEdit
                                  ? 'Can do everything like a Super Admin'
                                  : 'View-only access (cannot edit or create)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: canEdit,
                        activeColor: Colors.green,
                        onChanged: (v) => setDialogState(() => canEdit = v),
                      ),
                    ],
                  ),
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
                              canEdit: canEdit,
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
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final admin = admins[index];
                final isSuperAdmin = admin.role == 'SUPER_ADMIN';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSuperAdmin
                                  ? AppTheme.primaryColor
                                  : (admin.canEdit ? Colors.teal : Colors.blueGrey),
                              radius: 20,
                              child: Icon(
                                isSuperAdmin
                                    ? Icons.shield_outlined
                                    : (admin.canEdit ? Icons.edit_note : Icons.visibility_outlined),
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        admin.phone,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isSuperAdmin)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'SUPER ADMIN',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        )
                                      else ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: admin.canEdit ? Colors.green.shade50 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: admin.canEdit ? Colors.green.shade300 : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            admin.canEdit ? 'EDIT ACCESS' : 'VIEW ONLY',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: admin.canEdit ? Colors.green.shade800 : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (admin.email != null && admin.email!.isNotEmpty)
                                    Text(
                                      admin.email!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  Text(
                                    'Created ${Formatters.date(admin.createdAt)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Controls for VIEW_ADMIN
                        if (!isSuperAdmin) ...[
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Allow Edit Access toggle
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      admin.canEdit ? Icons.edit_note : Icons.edit_off_outlined,
                                      size: 18,
                                      color: admin.canEdit ? Colors.green : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Allow Edit Access',
                                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            admin.canEdit ? 'Can edit like super admin' : 'Read-only',
                                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: admin.canEdit,
                                      activeColor: Colors.green,
                                      onChanged: (value) async {
                                        try {
                                          await ref
                                              .read(adminManagementServiceProvider)
                                              .setAdminCanEdit(admin.id, value);
                                          ref.invalidate(adminListProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  value
                                                      ? 'Edit access granted to ${admin.phone}'
                                                      : 'Edit access revoked for ${admin.phone}',
                                                ),
                                                backgroundColor:
                                                    value ? AppTheme.successColor : Colors.grey.shade800,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Active / Inactive switch
                              Row(
                                children: [
                                  Text(
                                    admin.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: admin.isActive ? Colors.black87 : Colors.red,
                                    ),
                                  ),
                                  Switch(
                                    value: admin.isActive,
                                    onChanged: (value) async {
                                      try {
                                        await ref
                                            .read(adminManagementServiceProvider)
                                            .setAdminActive(admin.id, value);
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
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Super Admin account — has full permissions',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
