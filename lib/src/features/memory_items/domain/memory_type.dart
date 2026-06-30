enum MemoryType {
  task,
  note,
  voiceNote,
  event,
  person,
  habit,
  goal,
  project,
  purchase,
  document,
  place;

  String label(String languageCode) {
    final ru = languageCode == 'ru';
    return switch (this) {
      MemoryType.task => ru ? 'Задача' : 'Task',
      MemoryType.note => ru ? 'Заметка' : 'Note',
      MemoryType.voiceNote => ru ? 'Голос' : 'Voice',
      MemoryType.event => ru ? 'Событие' : 'Event',
      MemoryType.person => ru ? 'Человек' : 'Person',
      MemoryType.habit => ru ? 'Привычка' : 'Habit',
      MemoryType.goal => ru ? 'Цель' : 'Goal',
      MemoryType.project => ru ? 'Проект' : 'Project',
      MemoryType.purchase => ru ? 'Покупка' : 'Purchase',
      MemoryType.document => ru ? 'Документ' : 'Document',
      MemoryType.place => ru ? 'Место' : 'Place',
    };
  }
}
