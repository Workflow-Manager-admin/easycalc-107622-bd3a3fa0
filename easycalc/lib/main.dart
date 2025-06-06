import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Build Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'easycalc'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _expression = '';
  String _result = '0';

  final Color _primaryColor = const Color(0xFF2196F3);  // #2196F3
  final Color _secondaryColor = const Color(0xFFFFFFFF); // #FFFFFF
  final Color _accentColor = const Color(0xFFFF9800); // #FF9800

  // Calculator button labels
  final List<List<String>> _buttons = const [
    ['7', '8', '9', '÷'],
    ['4', '5', '6', '×'],
    ['1', '2', '3', '−'],
    ['0', '.', 'C', '+'],
    ['=']
  ];

  // PUBLIC_INTERFACE
  /// Handles button tap logic
  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
      } else if (value == '=') {
        _calculateResult();
      } else {
        // Prevent more than one decimal in a number
        if (value == '.') {
          final expParts = _expression.split(RegExp(r'[+\-\×÷]'));
          if (expParts.isNotEmpty && expParts.last.contains('.')) {
            return;
          }
        }
        _expression += value;
      }
    });
  }

  // PUBLIC_INTERFACE
  /// Evaluates the current expression and sets result.
  void _calculateResult() {
    try {
      String exp = _expression.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-');
      // Prevents invalid expressions at the end
      if (RegExp(r'[+\-*/.]$').hasMatch(exp)) {
        exp = exp.substring(0, exp.length - 1);
      }
      // Use Dart's Expression evaluation (simple implementation)
      _result = _evaluateExpression(exp);
    } catch (_) {
      _result = 'Err';
    }
  }

  /// Simple expression evaluator (handles + - * / and decimals)
  String _evaluateExpression(String expression) {
    // Only basic arithmetic supported
    if (expression.isEmpty) return '0';
    try {
      // Parse into tokens using regular expressions
      final tokens = <String>[];
      final tokenRegExp = RegExp(r'(\d+\.\d+|\d+|[+\-*/])');
      for (final match in tokenRegExp.allMatches(expression)) {
        tokens.add(match.group(0)!);
      }

      // Convert infix to postfix (shunting yard) for left-to-right eval
      final List<String> output = [];
      final List<String> operators = [];
      final precedence = {'+': 1, '-': 1, '*': 2, '/': 2};
      for (final token in tokens) {
        if (RegExp(r'\d+(\.\d+)?').hasMatch(token)) {
          output.add(token);
        } else if (precedence.containsKey(token)) {
          while (operators.isNotEmpty &&
              precedence.containsKey(operators.last) &&
              precedence[operators.last]! >= precedence[token]!) {
            output.add(operators.removeLast());
          }
          operators.add(token);
        }
      }
      while (operators.isNotEmpty) {
        output.add(operators.removeLast());
      }

      // Evaluate postfix
      final List<double> stack = [];
      for (final token in output) {
        if (RegExp(r'\d+(\.\d+)?').hasMatch(token)) {
          stack.add(double.parse(token));
        } else {
          final b = stack.removeLast();
          final a = stack.removeLast();
          switch (token) {
            case '+':
              stack.add(a + b);
              break;
            case '-':
              stack.add(a - b);
              break;
            case '*':
              stack.add(a * b);
              break;
            case '/':
              if (b == 0) return 'Err';
              stack.add(a / b);
              break;
          }
        }
      }
      double value = stack.isEmpty ? 0 : stack.first;
      // Format result (no .0 for integer results)
      if (value % 1 == 0) {
        return value.toInt().toString();
      } else {
        return value.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
      }
    } catch (e) {
      return 'Err';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double displayHeight = constraints.maxHeight * 0.26;
            double buttonGridHeight = constraints.maxHeight - displayHeight;

            return Column(
              children: [
                // Display area (result & expression)
                Container(
                  height: displayHeight,
                  width: double.infinity,
                  color: _primaryColor.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  alignment: Alignment.bottomRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _expression.isEmpty ? '0' : _expression,
                        style: TextStyle(
                          fontSize: 32,
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _result,
                        style: TextStyle(
                          fontSize: 52,
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Buttons area - Responsive Grid
                SizedBox(
                  height: buttonGridHeight,
                  child: _buildButtonGrid(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtonGrid(BuildContext context) {
    // Allow for responsive grid
    return Column(
      children: [
        for (var row = 0; row < _buttons.length; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < _buttons[row].length; col++)
                  _buildCalcButton(_buttons[row][col], isWide: _buttons[row][col] == '=')
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalcButton(String label, {bool isWide = false}) {
    Color bgColor;
    Color fgColor;
    switch (label) {
      case 'C':
        bgColor = _accentColor;
        fgColor = Colors.white;
        break;
      case '+':
      case '−':
      case '×':
      case '÷':
        bgColor = _primaryColor;
        fgColor = Colors.white;
        break;
      case '=':
        bgColor = _accentColor;
        fgColor = Colors.white;
        break;
      default:
        bgColor = _secondaryColor;
        fgColor = Colors.black87;
    }
    return Expanded(
      flex: isWide ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          height: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              textStyle: TextStyle(
                  fontSize: isWide ? 34 : 26,
                  fontWeight: isWide ? FontWeight.bold : FontWeight.w500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.zero,
              elevation: fgColor == Colors.white ? 4 : 1,
            ),
            onPressed: () => _onButtonPressed(label),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: isWide ? FontWeight.bold : FontWeight.normal,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
