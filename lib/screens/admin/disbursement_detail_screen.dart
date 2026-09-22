import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/report_json_service.dart';

class DisbursementDetailScreen extends StatefulWidget {
  const DisbursementDetailScreen({super.key});

  @override
  State<DisbursementDetailScreen> createState() => _DisbursementDetailScreenState();
}

class _DisbursementDetailScreenState extends State<DisbursementDetailScreen> {
  final ReportJsonService _service = ReportJsonService();
  bool _isLoading = true;
  String? _error;
  num _grandTotal = 0;
  int _totalLoans = 0;
  List<dynamic> _months = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _service.disbursementSummary();
      setState(() {
        _grandTotal = res['grandTotal'] ?? 0;
        _totalLoans = res['totalLoans'] ?? 0;
        _months = (res['months'] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Loan Disbursements'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text('Failed to load disbursements', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.heroCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL LOANS DISBURSED',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                '$_totalLoans Loans Issued',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Formatters.currency(_grandTotal),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Capital deployed across all finance loan types',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search customer name or loan number...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ],
              ),
            ),
          ),
          if (_months.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No disbursement records found.', style: TextStyle(color: Colors.grey))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final m = _months[index];
                    final monthKey = m['month'] as String? ?? '-';
                    final totalDisbursed = (m['totalDisbursed'] as num?) ?? 0;
                    final count = m['count'] ?? 0;
                    final loans = (m['loans'] as List<dynamic>?) ?? [];

                    final filteredLoans = _searchQuery.isEmpty
                        ? loans
                        : loans.where((l) {
                            final name = (l['customerName'] ?? '').toString().toLowerCase();
                            final phone = (l['customerPhone'] ?? '').toString().toLowerCase();
                            final loanNo = (l['loanNumber'] ?? '').toString().toLowerCase();
                            return name.contains(_searchQuery) || phone.contains(_searchQuery) || loanNo.contains(_searchQuery);
                          }).toList();

                    if (_searchQuery.isNotEmpty && filteredLoans.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: index == 0,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                            child: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                          ),
                          title: Text(
                            monthKey,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '$count loans disbursed',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.currency(totalDisbursed),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 15),
                              ),
                              const Icon(Icons.expand_more, size: 18, color: Colors.grey),
                            ],
                          ),
                          children: [
                            const Divider(height: 1),
                            ...filteredLoans.map((l) => _buildLoanItem(l)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _months.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanItem(dynamic loan) {
    final name = loan['customerName'] ?? 'Unknown';
    final phone = loan['customerPhone'] ?? '';
    final loanNumber = loan['loanNumber'] ?? '-';
    final type = loan['type'] ?? '-';
    final amount = (loan['disbursedAmount'] as num?) ?? 0;
    final status = loan['status'] ?? 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Loan #$loanNumber', style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(phone, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(amount),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryColor, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.statusColor(status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
