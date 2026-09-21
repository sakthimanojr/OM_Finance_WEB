import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_buttons.dart';
import '../../providers/chit_fund_provider.dart';

class CreateChitFundScreen extends ConsumerStatefulWidget {
  const CreateChitFundScreen({super.key});

  @override
  ConsumerState<CreateChitFundScreen> createState() => _CreateChitFundScreenState();
}

class _CreateChitFundScreenState extends ConsumerState<CreateChitFundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _memberCountCtrl = TextEditingController(text: '30');
  final _contributionCtrl = TextEditingController(text: '6000');
  final _startingBidCtrl = TextEditingController(text: '1000');
  final _interestRateCtrl = TextEditingController(text: '3');
  DateTime _startDate = DateTime.now();
  int _paymentDueDay = 1;
  bool _loading = false;

  num get _regularAuctionAmount {
    final members = int.tryParse(_memberCountCtrl.text) ?? 0;
    final contribution = num.tryParse(_contributionCtrl.text) ?? 0;
    return members * contribution;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _memberCountCtrl.dispose();
    _contributionCtrl.dispose();
    _startingBidCtrl.dispose();
    _interestRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(chitFundServiceProvider).createChitFund(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            memberCount: int.parse(_memberCountCtrl.text),
            monthlyContribution: num.parse(_contributionCtrl.text),
            startingBid: num.parse(_startingBidCtrl.text),
            startDate: _startDate,
            interestRate: num.parse(_interestRateCtrl.text),
            paymentDueDay: _paymentDueDay,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Create Chit Fund',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Auto-calc banner
            ValueListenableBuilder(
              valueListenable: _memberCountCtrl,
              builder: (context, _, __) {
                return ValueListenableBuilder(
                  valueListenable: _contributionCtrl,
                  builder: (context, _, __) {
                    final amt = _regularAuctionAmount;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLime,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentLime.withOpacity(0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.buttonBlack.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.calculate_outlined,
                                color: AppTheme.buttonBlack, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Calculated Auction Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${amt.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Fund Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Chit Fund Name *', prefixIcon: Icon(Icons.savings_outlined)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.notes)),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _memberCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'No. of Members *', prefixIcon: Icon(Icons.people_outline)),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 2) return 'Min 2';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _contributionCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monthly ₹ *', prefixIcon: Icon(Icons.currency_rupee)),
                    validator: (v) {
                      final n = num.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Must be positive';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startingBidCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Min Bid ₹ *', prefixIcon: Icon(Icons.gavel)),
                    validator: (v) {
                      final n = num.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Must be positive';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _interestRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Loan Interest % *', prefixIcon: Icon(Icons.percent)),
                    validator: (v) {
                      final n = num.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Schedule card ────────────────────────────────────────
            Container(
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.primaryColor, size: 18),
                    ),
                    title: const Text('Start Date',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  ),
                  Divider(color: Colors.grey.shade100, height: 1, indent: 18),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event, color: AppTheme.warningColor, size: 18),
                    ),
                    title: const Text('Payment Due Day',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(
                      'Day $_paymentDueDay of each month',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    trailing: DropdownButton<int>(
                      value: _paymentDueDay,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      items: List.generate(28, (i) => i + 1)
                          .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                          .toList(),
                      onChanged: (v) => setState(() => _paymentDueDay = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AnimatedGradientButton(
              onPressed: _loading ? null : _submit,
              isLoading: _loading,
              icon: Icons.add_circle_outline,
              child: const Text('Create Chit Fund'),
            ),
          ],
        ),
      ),
    );
  }
}
