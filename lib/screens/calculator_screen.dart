import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  int step = 0;
  final TextEditingController _salary = TextEditingController();
  double _result = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(step == 0 ? "Financing" : "Calculator"), backgroundColor: Colors.white, elevation: 0),
      body: step == 0 ? _buildIntro() : _buildCalc(),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(children: [
        Image.network('https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?q=80&w=1000', height: 200, fit: BoxFit.cover),
        const SizedBox(height: 30),
        const Text("See what you can afford", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text("Get a clearer picture of your finances before you start house hunting.", textAlign: TextAlign.center),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => step = 1),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], minimumSize: const Size(double.infinity, 55)),
          child: const Text("Get started", style: TextStyle(color: Colors.white)),
        )
      ]),
    );
  }

  Widget _buildCalc() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Monthly Income", style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(controller: _salary, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: "\$ "),
            onChanged: (v) => setState(() => _result = (double.tryParse(v) ?? 0) * 0.35)),
        const SizedBox(height: 40),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
          child: Column(children: [
            const Text("Estimated Monthly Rent:"),
            Text("\$${_result.toStringAsFixed(0)}", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue)),
          ]),
        ),
        const Spacer(),
        TextButton(onPressed: () => setState(() => step = 0), child: const Center(child: Text("Back to info")))
      ]),
    );
  }
}