import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class ArithmeticTextField extends StatefulWidget {
  const ArithmeticTextField({super.key});

  @override
  _ArithmeticTextFieldState createState() => _ArithmeticTextFieldState();
}

class _ArithmeticTextFieldState extends State<ArithmeticTextField> {
  final TextEditingController _controller = TextEditingController();
  String _originalInput = '';  // To store the original user input
  bool _showResult = false;    // To control whether to show result or original input

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arithmetic TextField Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TextField to accept arithmetic input
            TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Enter arithmetic expression',
                border: OutlineInputBorder(),
              ),
              onTap: () {
                // When tapped, show the original input again
                if (_showResult) {
                  setState(() {
                    _controller.text = _originalInput;  // Show the original expression
                    _showResult = false;  // Reset to input mode
                  });
                }
              },
              onChanged: (value) {
                setState(() {
                  _originalInput = value;  // Update the original input
                });
              },
              onSubmitted: (value) {
                // When the user submits the expression, evaluate and show the result
                setState(() {
                  String result = _evaluateExpression(_originalInput);  // Evaluate the expression
                  _controller.text = result.isNotEmpty ? result : 'Invalid Expression';
                  _showResult = true;  // Switch to result display mode
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Function to evaluate arithmetic expression
  String _evaluateExpression(String expression) {
    try {
      Parser parser = Parser();
      Expression exp = parser.parse(expression);
      ContextModel contextModel = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, contextModel);
      return eval.toString();
    } catch (e) {
      return 'Invalid expression';
    }
  }
}

void main() => runApp(const MaterialApp(home: ArithmeticTextField()));
