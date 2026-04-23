import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  int _step = 0; // 0 = Intro, 1 = Actual Calculator
  final TextEditingController _salaryController = TextEditingController();
  double _affordableRent = 0;

  @override
  Widget build(BuildContext context) {
    // We switch between widgets based on the current step
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_step == 0 ? "Financial Tools" : "Affordability Calculator",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: _step > 0 ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => setState(() => _step = 0),
        ) : null,
      ),
      body: _step == 0 ? _buildIntroPage() : _buildCalculatorPage(),
    );
  }

  // PAGE 1: The Zillow-style Intro
  Widget _buildIntroPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Illustrative Image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=1000',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 30),
          // 2. Headline
          const Text(
            "EstateTech Finance is here to help you get your next home",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 15),
          // 3. Sub-text
          const Text(
            "Start with us to see what you can afford, with no impact to your credit score.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          // 4. Action Button
          ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Get started", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          const SizedBox(height: 40),
          // 5. Why use this? (The Zillow details)
          const Divider(),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.calculate_outlined, "Know what's in your budget", "Shop with confidence knowing what you can afford."),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.speed, "Fast and Easy", "Get a realistic estimate in less than 1 minute."),
        ],
      ),
    );
  }

  // PAGE 2: The Interactive Tool
  Widget _buildCalculatorPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Affordability Calculator", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Enter your monthly income to determine how much to spend on a house."),
          const SizedBox(height: 30),
          const Text("Monthly Income", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _salaryController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              setState(() {
                double salary = double.tryParse(val) ?? 0;
                _affordableRent = salary * 0.35; // The 35% rule
              });
            },
            decoration: const InputDecoration(
              prefixText: "\$ ",
              border: OutlineInputBorder(),
              hintText: "e.g. 5000",
            ),
          ),
          const SizedBox(height: 40),
          // Result Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              children: [
                const Text("You can afford a house up to", style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
                const SizedBox(height: 10),
                Text(
                  "\$${_affordableRent.toStringAsFixed(0)}",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
                const SizedBox(height: 10),
                const Text("per month", style: TextStyle(color: Colors.blueGrey)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Based on the information you provided, a house at this price should fit comfortably within your budget.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Helper for the "Why use this" rows
  Widget _buildInfoRow(IconData icon, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue[800], size: 30),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(sub, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}