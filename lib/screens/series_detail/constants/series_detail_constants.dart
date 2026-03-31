class SeriesDetailConstants {
  // Scroll and animation
  static const double estimatedItemHeight = 125.0;
  static const double estimatedMoveItemHeight = 110.0;
  static const int scrollAnimationMs = 300;
  static const int comboAnimationMs = 400;
  static const int removeAnimationMs = 350;

  // Widget dimensions
  static const double comboCardWidth = 160.0;
  static const double comboScrollOffset = 168.0;
  static const double comboPreviewMinHeight = 170.0;
  static const double comboPreviewMaxHeightWithMove = 198.0;
  static const double comboPreviewMaxHeight = 190.0;

  // Delays
  static const int scrollDelayMs = 100;
  static const int successDialogSeconds = 1;

  // Icon sizes
  static const double categoryIconSize = 32.0;
  static const double categoryIconSizeSmall = 28.0;
  static const double categoryIconSizeMini = 24.0;
  static const double levelIconSize = 14.0;
  static const double levelIconSizeMini = 10.0;
  static const double levelIconSizeSmaller = 12.0;

  // Padding and spacing
  static const double cardPadding = 8.0;
  static const double moveLeftPadding = 15.0;
  static const double moveBottomPadding = 8.0;

  // Circle avatar
  static const double numberCircleRadius = 15.0;
  static const double numberCircleLeftOffset = -15.0;

  // Method definitions
  static const Map<String, String> methodDefinitions = {
    'SDA':
        'Simple Direct Attack: A single, direct strike without preceding feints.',
    'PIA':
        'Progressive Indirect Attack: Begins with a feint to misdirect and progresses to an open line.',
    'SIA':
        'Single Indirect Attack: A single motion that changes direction mid-flight.',
    'BTAA':
        'Broken Timing Angle Attack: Varying speed and timing to disrupt defensive rhythm.',
    'ABD':
        'Attack By Drawing: Deliberately baiting the opponent into attacking to create a counter opportunity.',
    'ABC':
        'Attack By Combination: A rapid sequence of multiple strikes to overwhelm the guard.',
  };
}
