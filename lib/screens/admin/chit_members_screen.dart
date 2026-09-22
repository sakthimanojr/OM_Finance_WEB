import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/chit_fund_provider.dart';
import '../../providers/customer_provider.dart';

class ChitMembersScreen extends ConsumerStatefulWidget {
  const ChitMembersScreen({super.key, required this.chitId});
  final String chitId;

  @override
  ConsumerState<ChitMembersScreen> createState() => _ChitMembersScreenState();
}

class _ChitMembersScreenState extends ConsumerState<ChitMembersScreen> {
  bool _adding = false;
  String? _selectedCustomerId;

  Future<void> _addMember() async {
    if (_selectedCustomerId == null) return;
    setState(() => _adding = true);
    try {
      await ref.read(chitFundServiceProvider).addMember(widget.chitId, _selectedCustomerId!);
      setState(() => _selectedCustomerId = null);
      ref.refresh(chitMemberListProvider(widget.chitId));
      ref.refresh(chitFundDetailProvider(widget.chitId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeMember(String memberId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Remove $name from this chit fund?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(chitFundServiceProvider).removeMember(widget.chitId, memberId);
      ref.refresh(chitMemberListProvider(widget.chitId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(chitMemberListProvider(widget.chitId));
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Chit Members',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: membersAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(chitMemberListProvider(widget.chitId)),
        ),
        data: (members) => Column(
          children: [
            // ── Add Member Panel ──────────────────────────────────
            customersAsync.when(
              loading: () => Container(
                height: 4,
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                child: const LinearProgressIndicator(
                  color: AppTheme.primaryColor,
                  backgroundColor: Colors.transparent,
                ),
              ),
              error: (_, __) => const SizedBox(),
              data: (customers) {
                final existingIds = members.map((m) => m.customerId).toSet();
                final available =
                    customers.where((c) => !existingIds.contains(c.id)).toList();
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCustomerId,
                          hint: const Text(
                            'Select customer to add',
                            style: TextStyle(fontSize: 13),
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.person_add_outlined,
                              color: AppTheme.primaryColor,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: AppTheme.surfaceLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 1.5),
                            ),
                          ),
                          items: available
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.name} (${c.phone})'),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCustomerId = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Add button — jet-black style
                      GestureDetector(
                        onTap: _selectedCustomerId == null || _adding
                            ? null
                            : _addMember,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _selectedCustomerId == null || _adding
                                ? Colors.grey.shade300
                                : AppTheme.buttonBlack,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _selectedCustomerId == null || _adding
                                ? []
                                : [
                                    BoxShadow(
                                      color:
                                          AppTheme.buttonBlack.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _adding
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Icon(Icons.add,
                                    color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Member count badge ────────────────────────────────
            if (members.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.transparent,
                child: Text(
                  '${members.length} member${members.length == 1 ? '' : 's'} enrolled',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),

            // ── Member List ───────────────────────────────────────
            Expanded(
              child: members.isEmpty
                  ? const EmptyStateView(
                      message: 'No members yet. Add customers above.',
                      icon: Icons.people_outline,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final m = members[index];
                        return _MemberListItem(
                          index: index,
                          member: m,
                          onRemove: (!m.hasWonAuction && m.status == 'ACTIVE')
                              ? () => _removeMember(
                                  m.id, m.customerName ?? 'this member')
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member List Item ──────────────────────────────────────────────────────────

class _MemberListItem extends StatefulWidget {
  const _MemberListItem({
    required this.index,
    required this.member,
    this.onRemove,
  });
  final int index;
  final dynamic member;
  final VoidCallback? onRemove;

  @override
  State<_MemberListItem> createState() => _MemberListItemState();
}

class _MemberListItemState extends State<_MemberListItem>
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
    final m = widget.member;
    final isActive = m.status == 'ACTIVE';
    final avatarColor =
        isActive ? AppTheme.primaryColor : Colors.grey.shade400;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: avatarColor.withValues(alpha: 0.08),
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
            backgroundColor: avatarColor,
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            m.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.customerPhone ?? '',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              if (m.chitCount != null && m.chitCount! > 1)
                Text(
                  'Member of ${m.chitCount} chit funds',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.hasWonAuction)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLime,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentLime.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Won #${m.wonAuctionNumber}',
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else if (m.auctionEligible)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.successColor,
                    size: 18,
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.block_outlined,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTapDown: (_) => _ctrl.forward(),
                  onTapUp: (_) {
                    _ctrl.reverse();
                    widget.onRemove!();
                  },
                  onTapCancel: () => _ctrl.reverse(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline,
                      color: AppTheme.errorColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

