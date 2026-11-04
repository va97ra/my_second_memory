/// Все картинки оформления приложения. Пути записаны только здесь, а темы и экраны
/// ссылаются на эти имена.
abstract final class AppTextures {
  static const blackLeather = 'assets/textures/black_leather.webp';
  static const silverLeather = 'assets/textures/silver_leather.webp';

  /// Зерно усилено от light_paper.webp: у исходной перепад всего в три уровня из
  /// 255, а этого глаз не видит, когда она лежит на кремовом в половину яркости.
  static const paperGrain = 'assets/textures/notebook_paper_grain.webp';

  /// Лист, на котором пишут в редакторе.
  static const writingSheet = paperGrain;

  static const lightWood = 'assets/textures/light_wood.webp';
  static const lightPaper = 'assets/textures/light_paper.webp';
  static const lightLeather = 'assets/textures/light_leather.webp';

  static const vacationRibbon = 'assets/textures/vacation_ribbon.webp';
}
