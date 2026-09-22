import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/report_json_service.dart';

class MonthlyCollectionsDetailScreen extends StatefulWidget {
  const MonthlyCollectionsDetailScreen({super.key});

  @override
  State<MonthlyCollectionsDetailScreen> createState() => _MonthlyCollectionsDetailScreenState();
}

class _MonthlyCollectionsDetailScreenState extends State<MonthlyCollectionsDetailScreen> {
  final ReportJsonService _service = ReportJsonService();
  bool _isLoading = true;
  String? _error;
  num _grandTotal = 0;
  List<dynamic> _months = [];
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
      final res = await _service.monthlyCollections();
      setState(() {
        _grandTotal = res['grandTotal'] ?? 0;
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

  Future<void> _downloadExcel() async {
    setState(() => _isDownloading = true);
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/collections-report.xlsx';
      await ApiClient.instance.client.download(ApiConstants.reportsCollections, savePath);
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
        title: const Text('Monthly Collections'),
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
              Text('Failed to load collections', style: Theme.of(context).textTheme.titleMedium),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Total Card
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
                              'TOTAL COLLECTIONS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_months.length} Months',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Formatters.currency(_grandTotal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Verified payments across all active & past loans',
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ],
              ),
            ),
          ),
          if (_months.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No collection records found.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final m = _months[index];
                    final monthKey = m['month'] as String? ?? '-';
                    final total = (m['total'] as num?) ?? 0;
                    final payments = (m['payments'] as List<dynamic>?) ?? [];

                    final filteredPayments = _searchQuery.isEmpty
                        ? payments
                        : payments.where((p) {
                            final name = (p['customerName'] ?? '').toString().toLowerCase();
                            final phone = (p['customerPhone'] ?? '').toString().toLowerCase();
                            final loanNo = (p['loanNumber'] ?? '').toString().toLowerCase();
                            return name.contains(_searchQuery) || phone.contains(_searchQuery) || loanNo.contains(_searchQuery);
                          }).toList();

                    if (_searchQuery.isNotEmpty && filteredPayments.isEmpty) {
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
                            child: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                          ),
                          title: Text(
                            monthKey,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${filteredPayments.length} payment${filteredPayments.length == 1 ? '' : 's'}',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.currency(total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                  fontSize: 15,
                                ),
                              ),
                              const Icon(Icons.expand_more, size: 18, color: Colors.grey),
                            ],
                          ),
                          children: [
                            const Divider(height: 1),
                            ...filteredPayments.map((p) => _buildPaymentRow(p)),
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

  Widget _buildPaymentRow(dynamic p) {
    final name = p['customerName'] ?? 'Unknown Customer';
    final phone = p['customerPhone'] ?? '';
    final loanNo = p['loanNumber'] ?? '-';
    final loanType = p['loanType'] ?? '-';
    final dueNo = p['dueNumber'] ?? '-';
    final amount = (p['amount'] as num?) ?? 0;
    final method = p['method'] ?? 'CASH';
    final upiRef = p['upiRef'];
    final dateStr = p['date'];
    final parsedDate = Formatters.tryParse(dateStr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: AppTheme.successColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.currency(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Loan #$loanNo',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textDark),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loanType,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due #$dueNo',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Method: $method ${upiRef != null ? '($upiRef)' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    Text(
                      parsedDate != null ? Formatters.date(parsedDate) : '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Phone: $phone',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
