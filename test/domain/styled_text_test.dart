import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Оформление текста записи: хранится в самом тексте, чистый текст — для
/// поиска и уведомлений, правка не сдвигает оформление с его слов.
void main() {
  const bold = TextMark(bold: true);
  const red = TextMark(color: 0xE53935, size: TextSize.large, font: 'lora');

  StyledText styled() => StyledText.unstyled('Купить хлеб и молоко')
      .restyle(7, 11, (_) => bold)
      .restyle(14, 20, (_) => red);

  test('неоформленный текст хранится как был', () {
    expect(StyledText.unstyled('Купить хлеб').toStored(), 'Купить хлеб');
    expect(StyledText.parse('Купить <хлеб> & соль').plain, 'Купить <хлеб> & соль',
        reason: 'без метки в начале это просто текст, а не разметка');
  });

  test('хранение туда и обратно', () {
    final stored = styled().toStored();
    expect(stored, startsWith(StyledText.marker));
    expect(stored, contains('<f a="b">хлеб</f>'));
    expect(stored, contains('<f c="E53935" z="large" n="lora">молоко</f>'));
    final back = StyledText.parse(stored);
    expect(back.plain, 'Купить хлеб и молоко');
    expect(back.toStored(), stored);
    expect(StyledText.plainOf(stored), 'Купить хлеб и молоко');
  });

  test('знаки разметки внутри текста не ломают его', () {
    final text = StyledText.unstyled('a < b & c > d').restyle(0, 1, (_) => bold);
    expect(StyledText.parse(text.toStored()).plain, 'a < b & c > d');
  });

  test('правка: оформление остаётся на своих словах', () {
    final edited = styled().edited('Срочно купить хлеб и молоко');
    final runs = edited.runs();
    expect(edited.plain.substring(runs.first.start, runs.first.end), 'хлеб');
    expect(runs.first.mark, bold);
    final typed = styled().edited('Купить хлеба и молоко');
    expect(typed.plain.substring(typed.runs().first.start, typed.runs().first.end),
        'хлеба', reason: 'дописанное к жирному слову — тоже жирное');
  });

  test('края без пробелов, оформление на месте', () {
    final text = StyledText.unstyled('  важно  ').restyle(2, 7, (_) => bold);
    final trimmed = text.trimmed();
    expect(trimmed.plain, 'важно');
    expect(trimmed.runs().single.mark, bold);
  });

  test('запись отдаёт чистый текст для поиска и уведомлений', () {
    final item = MemoryItem(
      id: '1',
      type: MemoryType.note,
      title: 'Купить хлеб',
      body: styled().toStored(),
      memoryDate: DateTime(2026, 10, 11),
      createdAt: DateTime(2026, 10, 11),
      updatedAt: DateTime(2026, 10, 11),
    );
    expect(item.plainBody, 'Купить хлеб и молоко');
  });

  test('название в карточке — с оформлением текста', () {
    // Цвет поменяли в редакторе, а карточка показывала чёрное название.
    final body = StyledText.unstyled('Купить\nхлеб').restyle(7, 11, (_) => red);
    MemoryItem note(String title) => MemoryItem(
          id: '1',
          type: MemoryType.note,
          title: title,
          body: body.toStored(),
          memoryDate: DateTime(2026, 10, 11),
          createdAt: DateTime(2026, 10, 11),
          updatedAt: DateTime(2026, 10, 11),
        );
    final derived = memoryTitleFromRecord(body.plain, MemoryType.note, 'ru');
    final title = styledMemoryTitle(note(derived));
    expect(title.plain, 'Купить хлеб');
    final run = title.runs().single;
    expect(title.plain.substring(run.start, run.end), 'хлеб');
    expect(run.mark, red);
    expect(styledMemoryTitle(note('Своё название')).isPlain, isTrue,
        reason: 'название не из текста — показывается как есть');
  });
}
