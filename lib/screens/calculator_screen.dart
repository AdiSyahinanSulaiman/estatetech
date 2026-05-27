import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../widgets/global_user_dp.dart';

class CalculatorScreen extends StatefulWidget {
  final VoidCallback onDPClick;
  const CalculatorScreen({super.key, required this.onDPClick});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  int _currentStep = 0;
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _debtController = TextEditingController();
  double _budgetMode = 0.30;
  double _recommendedRent = 0;
  double _remainingBalance = 0;
  final Color navyBlue = const Color(0xFF1B263B);

  void _calculateResults() {
    double salary = double.tryParse(_salaryController.text) ?? 0;
    double debts = double.tryParse(_debtController.text) ?? 0;
    double netIncome = salary - debts;
    setState(() {
      _recommendedRent = netIncome * _budgetMode;
      _remainingBalance = netIncome - _recommendedRent;
      _currentStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: _currentStep > 0 ? IconButton(icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black, size: 20), onPressed: () => setState(() => _currentStep--)) : null,
        title: Text(_currentStep == 2 ? "Your Results" : "Calculator", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        actions: [Padding(padding: const EdgeInsets.only(right: 15), child: GlobalUserDP(radius: 16, onTap: widget.onDPClick))],
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildBody(isDark)),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_currentStep == 0) return _buildIntro(isDark);
    if (_currentStep == 1) return _buildInputs(isDark);
    return _buildResults(isDark);
  }

  Widget _buildIntro(bool isDark) {
    return Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(height: 250, child: Lottie.network('https://assets9.lottiefiles.com/packages/lf20_at6m8pnd.json', repeat: true, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => Icon(Icons.calculate_outlined, size: 100, color: isDark ? Colors.white24 : navyBlue.withOpacity(0.2)))),
      const SizedBox(height: 30),
      Text("Know your number", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
      const SizedBox(height: 15),
      const Text("Calculate your ideal budget based on your salary and commitments.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
      const Spacer(),
      ElevatedButton(onPressed: () => setState(() => _currentStep = 1), style: ElevatedButton.styleFrom(backgroundColor: navyBlue, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18))),
    ]));
  }

  Widget _buildInputs(bool isDark) {
    return SingleChildScrollView(padding: const EdgeInsets.all(25), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel("Monthly Salary (BND)", isDark),
      _textField(_salaryController, Icons.payments_outlined, "3500", isDark),
      const SizedBox(height: 25),
      _inputLabel("Monthly Debts", isDark),
      _textField(_debtController, Icons.credit_card_outlined, "500", isDark),
      const SizedBox(height: 35),
      _inputLabel("Budgeting Style", isDark),
      const SizedBox(height: 15),
      Row(children: [_modeCard("Conservative", "25%", 0.25, isDark), const SizedBox(width: 10), _modeCard("Balanced", "30%", 0.30, isDark), const SizedBox(width: 10), _modeCard("Maximum", "35%", 0.35, isDark)]),
      const SizedBox(height: 50),
      ElevatedButton(onPressed: _calculateResults, style: ElevatedButton.styleFrom(backgroundColor: navyBlue, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Calculate Budget", style: TextStyle(color: Colors.white, fontSize: 18))),
    ]));
  }

  Widget _buildResults(bool isDark) {
    return SingleChildScrollView(padding: const EdgeInsets.all(25), child: Column(children: [
      Container(padding: const EdgeInsets.all(30), width: double.infinity, decoration: BoxDecoration(color: navyBlue, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]), child: Column(children: [const Text("Recommended Monthly Rent", style: TextStyle(color: Colors.white70, fontSize: 14)), const SizedBox(height: 10), Text("BND \$${_recommendedRent.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold))])),
      const SizedBox(height: 30),
      _resultRow("Safe Range", "\$${(_recommendedRent - 150).toStringAsFixed(0)} - \$${(_recommendedRent + 150).toStringAsFixed(0)}", Icons.verified_user_outlined),
      _resultRow("Remaining Balance", "\$${_remainingBalance.toStringAsFixed(0)}", Icons.account_balance_wallet_outlined),
      const SizedBox(height: 40),
      OutlinedButton(onPressed: () => setState(() => _currentStep = 1), style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55), side: BorderSide(color: navyBlue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text("Edit Information", style: TextStyle(color: navyBlue))),
    ]));
  }

  Widget _inputLabel(String t, bool isDark) => Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87));
  Widget _textField(TextEditingController c, IconData i, String h, bool isDark) => Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(15)), child: TextField(controller: c, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(icon: Icon(i, color: navyBlue), hintText: h, hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey), border: InputBorder.none)));
  Widget _modeCard(String t, String p, double v, bool isDark) {
    bool isSel = _budgetMode == v;
    return Expanded(child: InkWell(onTap: () => setState(() => _budgetMode = v), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: isSel ? navyBlue : (isDark ? Colors.white10 : Colors.white), borderRadius: BorderRadius.circular(15), border: Border.all(color: isSel ? navyBlue : Colors.grey[300]!)), child: Column(children: [Text(p, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSel ? Colors.white : navyBlue)), const SizedBox(height: 5), Text(t, style: TextStyle(fontSize: 10, color: isSel ? Colors.white70 : Colors.grey))]))));
  }
  Widget _resultRow(String l, String v, IconData i) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [CircleAvatar(backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100], child: Icon(i, color: navyBlue, size: 20)), const SizedBox(width: 15), Text(l), const Spacer(), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]));
}