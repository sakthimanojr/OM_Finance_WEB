import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/report_json_service.dart';


import 'loan_detail_screen.dart';


class LoanPortfolioDetailScreen extends StatefulWidget {
  const LoanPortfolioDetailScreen({super.key});

  @override
  State<LoanPortfolioDetailScreen> createState() => _LoanPortfolioDetailScreenState();
}

class _LoanPortfolioDetailScreenState extends State<LoanPortfolioDetailScreen> {
  final ReportJsonService _service = ReportJsonService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _summary;
  List<dynamic> _loans = [];
  String _selectedStatus = 'ALL';
  String _searchQuery = '';
  bool _isDownloading = false;

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
      final res = await _service.loanPortfolio();
      setState(() {
        _summary = res['summary'] as Map<String, dynamic>?;
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

  Future<void> _downloadExcel() async {
    setState(() => _isDownloading = true);
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/loan-portfolio-report.xlsx';
      await ApiClient.instance.client.download(ApiConstants.reportsLoanPortfolio, savePath);
      await OpenFilex.open(savePath);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.message}'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Loan Portfolio Report'),
        actions: [
          IconButton(
            tooltip: 'Export Excel',
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined),
            onPressed: _isDownloading ? null : _downloadExcel,
          ),
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
              Text('Failed to load portfolio', style: Theme.of(context).textTheme.titleMedium),
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

    final filtered = _loans.where((loan) {
      final matchesStatus = _selectedStatus == 'ALL' || (loan['status'] == _selectedStatus);
      if (!matchesStatus) return false;

      if (_searchQuery.isEmpty) return true;
      final name = (loan['customerName'] ?? '').toString().toLowerCase();
      final phone = (loan['customerPhone'] ?? '').toString().toLowerCase();
      final loanNo = (loan['loanNumber'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || phone.contains(_searchQuery) || loanNo.contains(_searchQuery);
    }).toList();

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
                  // Top Summary Card
                  if (_summary != null) _buildSummaryGrid(),
                  const SizedBox(height: 16),
                  // Search Field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search customer name, phone, loan #...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusFilterChip('ALL', 'All (${_loans.length})'),
                        _statusFilterChip('ACTIVE', 'Active (${_summary?['activeLoans'] ?? 0})'),
                        _statusFilterChip('OVERDUE', 'Overdue (${_summary?['overdueLoans'] ?? 0})'),
                        _statusFilterChip('COMPLETED', 'Completed (${_summary?['completedLoans'] ?? 0})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No loans found matching your criteria.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildLoanCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final disbursed = _summary!['totalDisbursed'] ?? 0;
    final collected = _summary!['totalCollected'] ?? 0;
    final profit = _summary!['totalInterestProfit'] ?? 0;
    final pending = _summary!['totalPendingAmount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.heroCardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryStatItem('TOTAL DISBURSED', Formatters.currency(disbursed), Colors.white),
              ),
              Container(height: 40, width: 1, color: Colors.white24),
              Expanded(
                child: _summaryStatItem('TOTAL COLLECTED', Formatters.currency(collected), AppTheme.accentLime),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryStatItem('EST. INTEREST PROFIT', Formatters.currency(profit), Colors.greenAccent),
              ),
              Container(height: 40, width: 1, color: Colors.white24),
              Expanded(
                child: _summaryStatItem('PENDING DUES', Formatters.currency(pending), Colors.orangeAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStatItem(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _statusFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
        onSelected: (_) => setState(() => _selectedStatus = status),
      ),
    );
  }

  Widget _buildLoanCard(dynamic loan) {
    final id = loan['id'] ?? '';
    final loanNumber = loan['loanNumber'] ?? '-';
    final customerName = loan['customerName'] ?? 'Unknown';
    final phone = loan['customerPhone'] ?? '';
    final type = loan['type'] ?? '-';
    final status = loan['status'] ?? 'ACTIVE';
    final disbursed = (loan['disbursedAmount'] as num?) ?? 0;
    final collected = (loan['totalCollection'] as num?) ?? 0;
    final interestProfit = (loan['interestProfit'] as num?) ?? 0;
    final pendingAmount = (loan['pendingAmount'] as num?) ?? 0;
    final pendingDuesCount = loan['pendingDuesCount'] ?? 0;
    final interestRate = loan['interestRate'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: id)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Customer Name & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          maxLines: 2,
                          softWrap: true,
                        ),
                        if (phone.isNotEmpty)
                          Text(
                            phone,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(status: status, showIcon: true),

                ],
              ),
              const SizedBox(height: 10),
              // Loan details row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Loan #$loanNumber',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$type • $interestRate% Int',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                  ),
                  if (pendingDuesCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$pendingDuesCount Dues Left',
                        style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Financial Stats Row
              Row(
                children: [
                  Expanded(
                    child: _metricColumn('Disbursed', Formatters.currency(disbursed), AppTheme.textDark),
                  ),
                  Expanded(
                    child: _metricColumn('Collected', Formatters.currency(collected), AppTheme.successColor),
                  ),
                  Expanded(
                    child: _metricColumn('Profit', Formatters.currency(interestProfit), Colors.purple),
                  ),
                  Expanded(
                    child: _metricColumn('Pending', Formatters.currency(pendingAmount), pendingAmount > 0 ? AppTheme.errorColor : Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
