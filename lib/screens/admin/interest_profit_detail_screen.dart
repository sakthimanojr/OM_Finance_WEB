import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/report_json_service.dart';

class InterestProfitDetailScreen extends StatefulWidget {
  const InterestProfitDetailScreen({super.key});

  @override
  State<InterestProfitDetailScreen> createState() => _InterestProfitDetailScreenState();
}

class _InterestProfitDetailScreenState extends State<InterestProfitDetailScreen> with SingleTickerProviderStateMixin {
  final ReportJsonService _service = ReportJsonService();
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _summary;
  List<dynamic> _byMonth = [];
  List<dynamic> _byType = [];
  List<dynamic> _loans = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _service.interestProfit();
      setState(() {
        _summary = res['summary'] as Map<String, dynamic>?;
        _byMonth = (res['byMonth'] as List<dynamic>?) ?? [];
        _byType = (res['byType'] as List<dynamic>?) ?? [];
        _loans = (res['loans'] as List<dynamic>?) ?? [];
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
        title: const Text('Interest & Profit Analysis'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'By Month'),
            Tab(text: 'By Loan Type'),
            Tab(text: 'Loans Detail'),
          ],
        ),
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
              Text('Failed to load profit data', style: Theme.of(context).textTheme.titleMedium),
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

    final totalDisbursed = _summary?['totalDisbursed'] ?? 0;
    final totalCollected = _summary?['totalCollected'] ?? 0;
    final totalProfit = _summary?['totalProfit'] ?? 0;

    return Column(
      children: [
        // Top Overview Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.heroCardDecoration,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FINANCE PROFIT & EARNINGS',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Interest Income', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Net Profit', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.currency(totalProfit),
                            style: const TextStyle(color: AppTheme.accentLime, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Disbursed', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.currency(totalDisbursed),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMonthTab(),
              _buildTypeTab(),
              _buildLoansTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthTab() {
    if (_byMonth.isEmpty) {
      return const Center(child: Text('No monthly profit data available.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _byMonth.length,
      itemBuilder: (context, index) {
        final m = _byMonth[index];
        final month = m['month'] ?? '-';
        final disbursed = (m['disbursed'] as num?) ?? 0;
        final collected = (m['collected'] as num?) ?? 0;
        final profit = (m['profit'] as num?) ?? 0;
        final count = m['count'] ?? 0;
        final margin = disbursed > 0 ? ((profit / disbursed) * 100).toStringAsFixed(1) : '0';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.trending_up, size: 18, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          month,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+$margin% Return',
                        style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _profitCol('Disbursed ($count loans)', Formatters.currency(disbursed), AppTheme.textDark),
                    ),
                    Expanded(
                      child: _profitCol('Collected', Formatters.currency(collected), AppTheme.primaryColor),
                    ),
                    Expanded(
                      child: _profitCol('Interest Profit', Formatters.currency(profit), AppTheme.successColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeTab() {
    if (_byType.isEmpty) {
      return const Center(child: Text('No loan type data available.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _byType.length,
      itemBuilder: (context, index) {
        final t = _byType[index];
        final type = t['type'] ?? 'UNKNOWN';
        final disbursed = (t['disbursed'] as num?) ?? 0;
        final collected = (t['collected'] as num?) ?? 0;
        final profit = (t['profit'] as num?) ?? 0;
        final count = t['count'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$type LOANS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                      ),
                    ),
                    Text(
                      '$count Total Loans',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _profitCol('Total Disbursed', Formatters.currency(disbursed), AppTheme.textDark)),
                    Expanded(child: _profitCol('Total Collected', Formatters.currency(collected), AppTheme.primaryColor)),
                    Expanded(child: _profitCol('Profit Earned', Formatters.currency(profit), AppTheme.successColor)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoansTab() {
    final filtered = _searchQuery.isEmpty
        ? _loans
        : _loans.where((l) {
            final name = (l['customerName'] ?? '').toString().toLowerCase();
            final loanNo = (l['loanNumber'] ?? '').toString().toLowerCase();
            final type = (l['type'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || loanNo.contains(_searchQuery) || type.contains(_searchQuery);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search customer name or loan number...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No loans found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final l = filtered[index];
                    final name = l['customerName'] ?? 'Unknown';
                    final loanNo = l['loanNumber'] ?? '-';
                    final type = l['type'] ?? '-';
                    final status = l['status'] ?? 'ACTIVE';
                    final disbursed = (l['disbursedAmount'] as num?) ?? 0;
                    final collected = (l['totalCollected'] as num?) ?? 0;
                    final profit = (l['interestProfit'] as num?) ?? 0;
                    final rate = l['interestRate'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: AppTheme.statusColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Loan #$loanNo • $type • $rate% Interest',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Disbursed: ${Formatters.currency(disbursed)}', style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                                Text('Collected: ${Formatters.currency(collected)}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
                                Text(
                                  'Profit: ${Formatters.currency(profit)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _profitCol(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
