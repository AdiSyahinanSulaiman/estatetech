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

  // Controllers
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _debtController = TextEditingController();

  // State
  double _budgetMode = 0.30;
  double _recommendedRent = 0;
  double _remainingBalance = 0;
  final Color navyBlue = const Color(0xFF1B263B);

  void _applyToAI() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'calculatedBudget': _recommendedRent,
        'budgetModeActive': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("AI Feed successfully updated!")),
        );
      }
    }
  }

  void _showAIBridgeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Optimize your Feed?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Would you like EstateTech AI to prioritize properties within your BND \$${_recommendedRent.toStringAsFixed(0)} budget?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe Later")),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _applyToAI(); },
            style: ElevatedButton.styleFrom(backgroundColor: navyBlue),
            child: const Text("Yes, Personalize", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _calculateResults() {
    double salary = double.tryParse(_salaryController.text) ?? 0;
    double debts = double.tryParse(_debtController.text) ?? 0;
    double netIncome = salary - debts;
    setState(() {
      _recommendedRent = netIncome * _budgetMode;
      _remainingBalance = netIncome - _recommendedRent;
      _currentStep = 2;
    });
    Future.delayed(const Duration(milliseconds: 600), () => _showAIBridgeDialog());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // THEME FIX
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // THEME FIX
        elevation: 0,
        leading: _currentStep > 0 ? IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => setState(() => _currentStep--),
        ) : null,
        title: Text(
          _currentStep == 2 ? "Your Results" : "Calculator",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GlobalUserDP(radius: 16, onTap: widget.onDPClick),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_currentStep == 0) return _buildIntro(isDark);
    if (_currentStep == 1) return _buildInputs(isDark);
    return _buildResults(isDark);
  }

  Widget _buildIntro(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            child: Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_at6m8pnd.json',
              repeat: true,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.calculate_outlined, size: 100, color: navyBlue.withOpacity(0.2));
              },
            ),
          ),
          const SizedBox(height: 30),
          Text("Know your number", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 15),
          const Text(
            "Calculate your ideal rent budget based on your salary and commitments.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: navyBlue,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputs(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel("Monthly Salary (BND)", isDark),
          _textField(_salaryController, Icons.payments_outlined, "e.g. 3500", isDark),
          const SizedBox(height: 25),
          _inputLabel("Monthly Debts / Commitments", isDark),
          _textField(_debtController, Icons.credit_card_outlined, "e.g. 500", isDark),
          const SizedBox(height: 35),
          _inputLabel("Budgeting Style", isDark),
          const SizedBox(height: 15),
          Row(
            children: [
              _modeCard("Conservative", "25%", 0.25, isDark),
              const SizedBox(width: 10),
              _modeCard("Balanced", "30%", 0.30, isDark),
              const SizedBox(width: 10),
              _modeCard("Maximum", "35%", 0.35, isDark),
            ],
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _calculateResults,
            style: ElevatedButton.styleFrom(
              backgroundColor: navyBlue,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Calculate Budget", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: navyBlue,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                const Text("Recommended Monthly Rent", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                Text(
                  "BND \$${_recommendedRent.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _resultRow("Safe Range", "\$${(_recommendedRent - 150).toStringAsFixed(0)} - \$${(_recommendedRent + 150).toStringAsFixed(0)}", Icons.verified_user_outlined, isDark),
          _resultRow("Remaining Balance", "\$${_remainingBalance.toStringAsFixed(0)}", Icons.account_balance_wallet_outlined, isDark),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              side: BorderSide(color: navyBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Text("Edit Information", style: TextStyle(color: navyBlue)),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String text, bool isDark) {
    return Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87));
  }

  Widget _textField(TextEditingController controller, IconData icon, String hint, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(15)
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          icon: Icon(icon, color: isDark ? Colors.white54 : navyBlue),
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _modeCard(String title, String percent, double value, bool isDark) {
    bool isSelected = _budgetMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _budgetMode = value),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected ? navyBlue : (isDark ? Colors.white10 : Colors.white),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? navyBlue : (isDark ? Colors.white10 : Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              Text(percent, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : navyBlue))),
              Text(title, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
              child: Icon(icon, color: isDark ? Colors.white70 : navyBlue, size: 20)
          ),
          const SizedBox(width: 15),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}