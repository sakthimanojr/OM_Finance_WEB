import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/due_provider.dart';

class DuesScreen extends ConsumerStatefulWidget {
  const DuesScreen({super.key, this.initialTab});
  final String? initialTab;

  @override
  ConsumerState<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends ConsumerState<DuesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab == 'overdue') {
      initialIndex = 2;
    }
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: initialIndex);
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
          'Dues',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentLime,
          indicatorWeight: 3.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Today's Due"),
            Tab(text: 'By Customer'),
            Tab(text: 'Overdue'),
          ],

        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TodaysDuesTab(),
          _DuesByCustomerTab(),
          _OverdueDuesTab(),
        ],
      ),
    );
  }
}

// ── Today's Dues Tab ─────────────────────────────────────────────────────────

class _TodaysDuesTab extends ConsumerWidget {
  const _TodaysDuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(todaysDuesProvider);
    final todayStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Column(
      children: [
        // Date banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.accentLime,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentLime.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textDark),
              const SizedBox(width: 8),
              Text(
                'Dues for $todayStr',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: duesAsync.when(
            loading: () => const LoadingView(),
            error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(todaysDuesProvider)),
            data: (dues) {
              if (dues.isEmpty) {
                return const EmptyStateView(
                    message: 'No dues scheduled for today',
                    icon: Icons.check_circle_outline);
              }

              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async => ref.refresh(todaysDuesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: dues.length,
                  itemBuilder: (context, index) {
                    final due = dues[index];
                    return _DueListItem(
                      avatarContent: Text(
                        '${due.dueNumber}',
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      avatarBg: AppTheme.accentColor.withValues(alpha: 0.10),
                      title: due.customerName ?? 'Unknown customer',
                      subtitle:
                          '${due.loanType?.replaceAll('_', ' ') ?? ''} • Due #${due.dueNumber}',
                      amount: Formatters.currency(due.amount),
                      status: due.status,
                      borderColor: AppTheme.accentColor.withValues(alpha: 0.08),
                      onTap: () => context.push('/admin/loans/${due.loanId}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Dues By Customer Tab ─────────────────────────────────────────────────────

class _DuesByCustomerTab extends ConsumerWidget {
  const _DuesByCustomerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(duesByCustomerProvider);
    return groupsAsync.when(
      loading: () => const LoadingView(),
      error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(duesByCustomerProvider)),
      data: (groups) {
        if (groups.isEmpty) {
          return const EmptyStateView(
              message: 'No pending dues',
              icon: Icons.check_circle_outline);
        }
        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async => ref.refresh(duesByCustomerProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final customerName = group['customerName'] as String;
              final customerPhone = group['customerPhone'] as String;
              final pendingCount = group['pendingCount'] as int;
              final totalAmount = group['totalAmount'] as num;
              final customerId = group['customerId'] as String;

              return _CustomerGroupItem(
                name: customerName,
                phone: customerPhone,
                pendingCount: pendingCount,
                totalAmount: totalAmount,
                onTap: () => context.push('/admin/customers/$customerId'),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Overdue Tab ───────────────────────────────────────────────────────────────

class _OverdueDuesTab extends ConsumerWidget {
  const _OverdueDuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(overdueDuesProvider);

    return Column(
      children: [
        // Overdue banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.10),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: AppTheme.errorColor),
              SizedBox(width: 8),
              Text(
                'All Overdue Dues',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.errorColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: duesAsync.when(
            loading: () => const LoadingView(),
            error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(overdueDuesProvider)),
            data: (dues) {
              if (dues.isEmpty) {
                return const EmptyStateView(
                    message: 'No overdue dues',
                    icon: Icons.check_circle_outline);
              }

              return RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async => ref.refresh(overdueDuesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: dues.length,
                  itemBuilder: (context, index) {
                    final due = dues[index];
                    return _DueListItem(
                      avatarContent: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.errorColor,
                        size: 18,
                      ),
                      avatarBg: AppTheme.errorColor.withValues(alpha: 0.10),
                      title: due.customerName ?? 'Unknown customer',
                      subtitle:
                          '${due.loanType?.replaceAll('_', ' ') ?? ''} • Due #${due.dueNumber}\n'
                          'Due: ${Formatters.date(due.dueDate)}',
                      isThreeLine: true,
                      amount: Formatters.currency(due.amount),
                      status: due.status,
                      borderColor: AppTheme.errorColor.withValues(alpha: 0.12),
                      onTap: () => context.push('/admin/loans/${due.loanId}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Reusable Due List Item ────────────────────────────────────────────────────

class _DueListItem extends StatefulWidget {
  const _DueListItem({
    required this.avatarContent,
    required this.avatarBg,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.onTap,
    this.borderColor,
    this.isThreeLine = false,
  });
  final Widget avatarContent;
  final Color avatarBg;
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final VoidCallback onTap;
  final Color? borderColor;
  final bool isThreeLine;

  @override
  State<_DueListItem> createState() => _DueListItemState();
}

class _DueListItemState extends State<_DueListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.borderColor ?? Colors.transparent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: widget.avatarBg,
              child: widget.avatarContent,
            ),
            title: Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            subtitle: Text(
              widget.subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            isThreeLine: widget.isThreeLine,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: widget.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Customer Group Item ───────────────────────────────────────────────────────

class _CustomerGroupItem extends StatefulWidget {
  const _CustomerGroupItem({
    required this.name,
    required this.phone,
    required this.pendingCount,
    required this.totalAmount,
    required this.onTap,
  });
  final String name;
  final String phone;
  final int pendingCount;
  final num totalAmount;
  final VoidCallback onTap;

  @override
  State<_CustomerGroupItem> createState() => _CustomerGroupItemState();
}

class _CustomerGroupItemState extends State<_CustomerGroupItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.errorColor.withValues(alpha: 0.10),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorColor.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.errorColor.withValues(alpha: 0.10),
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            title: Text(
              widget.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            subtitle: Text(
              widget.phone,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(widget.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.pendingCount} dues',
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
