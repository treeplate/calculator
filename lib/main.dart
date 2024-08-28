import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Operation { add, subtract }

class _MyHomePageState extends State<MyHomePage> {
  double? _lhs;
  double _display = 0;
  Operation? _selectedOperation;
  bool _afterDotInput = false;
  int _fractionalDecimalPlace = 1;

  bool _negative = false;

  @override
  Widget build(BuildContext context) {
    String realDisplay = displayToString(_display, _afterDotInput, _negative);
    return Focus(
      autofocus: true,
      onKeyEvent: onKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                  _lhs != null
                      ? displayToString(_lhs!, _lhs! % 1 != 0, _negative)
                      : '',
                  style: Theme.of(context).textTheme.bodyLarge!),
              Text(
                realDisplay,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _selectedOperation != null
                        ? null
                        : () {
                            setState(() {
                              selectOperation(Operation.add);
                            });
                          },
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    onPressed: _selectedOperation != null
                        ? null
                        : () {
                            setState(() {
                              selectOperation(Operation.subtract);
                            });
                          },
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedOperation = null;
                        _lhs = null;
                        _display = 0;
                        _afterDotInput = false;
                      });
                    },
                    icon: const Icon(Icons.exposure_zero),
                  ),
                  IconButton(
                    onPressed: _selectedOperation == null
                        ? null
                        : () {
                            setState(() {
                              outerCalculate();
                            });
                          },
                    icon: const Icon(Icons.arrow_right_alt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void outerCalculate() {
    _display = calculate(_display, _lhs!, _selectedOperation!);
    _selectedOperation = null;
    _lhs = null;
    _afterDotInput = _display % 1 != 0;
    _fractionalDecimalPlace =
        _display.toString().length - (1 + _display.toInt().toString().length);
    _negative = _display.isNegative;
  }

  double calculate(double rhs, double lhs, Operation operation) {
    switch (operation) {
      case Operation.add:
        double fractionalConcat = rhs.isNegative
            ? (lhs % 1) - (rhs % 1).abs()
            : double.parse(
                '.${(lhs % 1).toString().substring(2)}${(rhs % 1).toString().substring(2)}');
        double realFracResult = (lhs % 1) + (rhs % 1);
        int fracConcatDecimalPlace = fractionalConcat.toString().length - 2;
        double fractionalResult = fractionalConcat - realFracResult;
        String string = fractionalResult.toString();
        var digits = min(
            (fractionalResult.isNegative ? 1 : 0) + 2 + fracConcatDecimalPlace,
            string.length);
        if (digits != string.length && string[digits] == '9') {
          if (fractionalResult.isNegative) {
            fractionalResult += 1 / pow(-10, digits - (2));
            fractionalResult -= 1 / pow(10, digits - (3));
          } else {
            fractionalResult += 1 / pow(10, digits - (1));
            fractionalResult += 1 / pow(10, digits - (2));
          }
        }
        fractionalResult =
            double.tryParse(fractionalResult.toString().substring(0, digits)) ??
                -5;
        int integerConcat = rhs.isNegative
            ? lhs.truncate() - rhs.truncate().abs()
            : int.parse(lhs.truncate().toString() + rhs.truncate().toString());
        int realIntResult = lhs.truncate() + rhs.truncate();
        int integerResult = integerConcat - realIntResult;
        return fractionalResult *
                (integerResult == 0 ? 1 : integerResult.sign) +
            integerResult;
      case Operation.subtract:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String displayToString(double display, bool afterDotInput, bool negative) {
    if (display % 1 == 0) {
      if (afterDotInput) {
        // no actual fractional component but pad with zeros
        // examples: 1. 1.0 2.00 -3.000
        return '${negative && _display == 0 ? '-' : ''}${display.toInt()}.'
            .padRight(
                display.toInt().toString().length + _fractionalDecimalPlace,
                '0');
      } else {
        // no fractional component, nor should there be
        // examples: 1 4 -3 2
        return (negative && _display == 0 ? '-' : '') +
            display.toInt().toString();
      }
    } else {
      if (afterDotInput) {
        // regular tostring should work, EXCEPT there might be extra zeros that we add
        return (negative && _display == 0 ? '-' : '') +
            display.toString().padRight(
                  display.toInt().toString().length + _fractionalDecimalPlace,
                  '0',
                );
      } else {
        throw StateError('not in afterDotInput mode but not an integer');
      }
    }
  }

  void selectOperation(Operation operation) {
    if (_lhs != null) {
      assert(_selectedOperation != null);
      return;
    }
    assert(_selectedOperation == null);
    _selectedOperation = Operation.add;
    _lhs = _display;
    _display = 0;
    _afterDotInput = false;
    _negative = false;
  }

  KeyEventResult onKey(focusnode, key) {
    if (key is! KeyDownEvent) {
      return key is KeyRepeatEvent
          ? KeyEventResult.ignored
          : KeyEventResult.handled;
    }
    if (key.logicalKey == LogicalKeyboardKey.add) {
      setState(() {
        selectOperation(Operation.add);
      });
      return KeyEventResult.handled;
    }
    if (key.logicalKey == LogicalKeyboardKey.minus) {
      if (_afterDotInput || _display ~/ 1 != 0 || _negative) {
        print('hi');
        setState(() {
          selectOperation(Operation.subtract);
        });
      } else {
        print('ho');
        setState(() {
          _negative = true;
          _display = -_display;
        });
      }
      return KeyEventResult.handled;
    }
    if (key.logicalKey == LogicalKeyboardKey.period) {
      if (!_afterDotInput) {
        setState(() {
          _afterDotInput = true;
          _fractionalDecimalPlace = 1;
        });
        return KeyEventResult.handled;
      }
    }
    if (key.logicalKey == LogicalKeyboardKey.equal) {
      setState(() {
        outerCalculate();
      });
      return KeyEventResult.handled;
    }
    if (key.logicalKey == LogicalKeyboardKey.delete ||
        key.logicalKey == LogicalKeyboardKey.backspace) {
      setState(() {
        String realDisplay =
            displayToString(_display, _afterDotInput, _negative);
        if (_afterDotInput) {
          _fractionalDecimalPlace--;
          if (_fractionalDecimalPlace == 0) {
            _afterDotInput = false;
          }
        }
        _display =
            double.tryParse(realDisplay.substring(0, realDisplay.length - 1)) ??
                0;
      });
      return KeyEventResult.handled;
    }
    int? i = int.tryParse(key.character ?? '');
    if (i != null) {
      setState(() {
        _display = double.parse(
            displayToString(_display, _afterDotInput, _negative) +
                i.toString());
        if (!_display.isNegative && _negative) {
          _display = -_display;
        }
        if (_afterDotInput) {
          _fractionalDecimalPlace++;
        }
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
