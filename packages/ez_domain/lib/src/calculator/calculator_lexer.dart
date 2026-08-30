enum CalculatorTokenKind {
  number,
  identifier,
  plus,
  minus,
  multiply,
  divide,
  power,
  percent,
  factorial,
  left,
  right,
  comma,
  end,
}

class CalculatorToken {
  const CalculatorToken(this.kind, [this.text = '']);

  final CalculatorTokenKind kind;
  final String text;
}

class CalculatorLexer {
  CalculatorLexer(this.source);

  final String source;

  List<CalculatorToken> tokens() {
    final result = <CalculatorToken>[];
    var index = 0;
    while (index < source.length) {
      final char = source[index];
      if (char.trim().isEmpty) {
        index++;
        continue;
      }
      if (_isDigit(char) || char == '.') {
        final start = index;
        var hasDot = char == '.';
        index++;
        while (index < source.length) {
          final next = source[index];
          if (_isDigit(next)) {
            index++;
          } else if (next == '.' && !hasDot) {
            hasDot = true;
            index++;
          } else {
            break;
          }
        }
        if (index < source.length &&
            (source[index] == 'e' || source[index] == 'E')) {
          index++;
          if (index < source.length &&
              (source[index] == '+' || source[index] == '-')) {
            index++;
          }
          final digitStart = index;
          while (index < source.length && _isDigit(source[index])) {
            index++;
          }
          if (digitStart == index) {
            throw const CalculatorIncompleteInput();
          }
        }
        final number = source.substring(start, index);
        if (number == '.') throw const FormatException();
        result.add(CalculatorToken(CalculatorTokenKind.number, number));
        continue;
      }
      if (_isLetter(char) || char == 'π') {
        final start = index++;
        while (index < source.length && _isLetter(source[index])) {
          index++;
        }
        final word = source.substring(start, index).toLowerCase();
        result.add(CalculatorToken(
          word == 'mod'
              ? CalculatorTokenKind.percent
              : CalculatorTokenKind.identifier,
          word,
        ));
        continue;
      }
      result.add(CalculatorToken(
        switch (char) {
          '+' => CalculatorTokenKind.plus,
          '-' => CalculatorTokenKind.minus,
          '*' => CalculatorTokenKind.multiply,
          '/' => CalculatorTokenKind.divide,
          '^' => CalculatorTokenKind.power,
          '%' => CalculatorTokenKind.percent,
          '!' => CalculatorTokenKind.factorial,
          '(' => CalculatorTokenKind.left,
          ')' => CalculatorTokenKind.right,
          ';' => CalculatorTokenKind.comma,
          _ => throw const FormatException(),
        },
        char,
      ));
      index++;
    }
    return [...result, const CalculatorToken(CalculatorTokenKind.end)];
  }

  bool _isDigit(String value) => RegExp(r'\d').hasMatch(value);
  bool _isLetter(String value) => RegExp(r'[A-Za-z]').hasMatch(value);
}

class CalculatorIncompleteInput implements Exception {
  const CalculatorIncompleteInput();
}
