import 'package:flutter/material.dart';
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
  double _budgetMode = 0.30; // Default to Balanced (30%)
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
      _currentStep = 2; // Move to results
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0 ? IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => setState(() => _currentStep--),
        ) : null,
        title: Text(
          _currentStep == 2 ? "Your Results" : "Calculator",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentStep == 0) return _buildIntro();
    if (_currentStep == 1) return _buildInputs();
    return _buildResults();
  }

  // --- STEP 0: INTRO ---
  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1560518883-ce09059eeffa?q=80&w=1000'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text("Know your number", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          const Text(
            "Calculate your ideal rent budget based on your salary and commitments.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: navyBlue,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Get Started", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  // --- STEP 1: INPUTS ---
  Widget _buildInputs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel("Monthly Salary (BND)"),
          _textField(_salaryController, Icons.payments_outlined, "e.g. 3500"),
          const SizedBox(height: 25),
          _inputLabel("Monthly Debts / Commitments"),
          _textField(_debtController, Icons.credit_card_outlined, "e.g. 500"),
          const SizedBox(height: 35),
          _inputLabel("Budgeting Style"),
          const SizedBox(height: 15),
          Row(
            children: [
              _modeCard("Conservative", "25%", 0.25),
              const SizedBox(width: 10),
              _modeCard("Balanced", "30%", 0.30),
              const SizedBox(width: 10),
              _modeCard("Maximum", "35%", 0.35),
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

  // --- STEP 2: RESULTS ---
  Widget _buildResults() {
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
          _resultRow("Safe Range", "\$${(_recommendedRent - 150).toStringAsFixed(0)} - \$${(_recommendedRent + 150).toStringAsFixed(0)}", Icons.verified_user_outlined),
          _resultRow("Remaining Balance", "\$${_remainingBalance.toStringAsFixed(0)}", Icons.account_balance_wallet_outlined),
          _resultRow("Budget Utilization", "${(_budgetMode * 100).toInt()}% of Net", Icons.pie_chart_outline),
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

  // --- HELPER WIDGETS ---

  Widget _inputLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _textField(TextEditingController controller, IconData icon, String hint) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          icon: Icon(icon, color: navyBlue),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _modeCard(String title, String percent, double value) {
    bool isSelected = _budgetMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _budgetMode = value),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected ? navyBlue : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? navyBlue : Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Text(percent, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : navyBlue)),
              const SizedBox(height: 5),
              Text(title, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.grey[100], child: Icon(icon, color: navyBlue, size: 20)),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}