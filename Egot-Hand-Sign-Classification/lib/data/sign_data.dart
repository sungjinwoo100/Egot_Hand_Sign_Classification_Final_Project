class SignContent {
  final String title;
  final List<String> tags;
  final String accuracyTrend;
  final String contextDescription;
  final String? culturalNote;
  final List<InstructionStep> instructions;

  SignContent({
    required this.title,
    required this.tags,
    required this.accuracyTrend,
    required this.contextDescription,
    this.culturalNote,
    required this.instructions,
  });
}

class InstructionStep {
  final String step;
  final String title;
  final String desc;
  final bool isIcon;

  InstructionStep({
    required this.step,
    required this.title,
    required this.desc,
    this.isIcon = false,
  });
}

class SignRepository {
  static final Map<String, SignContent> _data = {
    // Letter A
    'A': SignContent(
      title: 'Letter A',
      tags: ['Alphabet', 'ASL', 'Static'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "A". It resembles a closed fist with the thumb resting against the side of the index finger.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Make a Fist',
          desc: 'Fold all four fingers into your palm.',
        ),
        InstructionStep(
          step: '2',
          title: 'Position Thumb',
          desc:
              'Place your thumb upright against the side of your index finger.',
          isIcon: true,
        ),
      ],
    ),
    // Letter B
    'B': SignContent(
      title: 'Letter B',
      tags: ['Alphabet', 'ASL', 'Static'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "B". An open palm with the thumb tucked across the palm.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Extend Fingers',
          desc: 'Hold your four fingers straight up and together.',
        ),
        InstructionStep(
          step: '2',
          title: 'Tuck Thumb',
          desc: 'Fold your thumb across your palm.',
          isIcon: true,
        ),
      ],
    ),
    // Letter C
    'C': SignContent(
      title: 'Letter C',
      tags: ['Alphabet', 'ASL', 'Shape'],
      accuracyTrend: 'Variable',
      contextDescription:
          'The manual alphabet sign for "C". The hand forms a C-shape, resembling the letter itself.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Curve Fingers',
          desc: 'Curve your fingers and thumb towards each other.',
        ),
        InstructionStep(
          step: '2',
          title: 'Form "C"',
          desc: 'Maintain the gap to look like the letter C.',
          isIcon: true,
        ),
      ],
    ),
    // Letter D
    'D': SignContent(
      title: 'Letter D',
      tags: ['Alphabet', 'ASL', 'Static'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "D". The index finger points up while the other fingers touch the thumb.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Point Index',
          desc: 'Extend your index finger straight up.',
        ),
        InstructionStep(
          step: '2',
          title: 'Loop Others',
          desc:
              'Touch the tips of your thumb, middle, ring, and pinky fingers together.',
          isIcon: true,
        ),
      ],
    ),
    // Letter E
    'E': SignContent(
      title: 'Letter E',
      tags: ['Alphabet', 'ASL', 'Static'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "E". The fingers curl down to touch the thumb, which is tucked in.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Curl Fingers',
          desc: 'Curl all four fingers down towards your palm.',
        ),
        InstructionStep(
          step: '2',
          title: 'Tuck Thumb',
          desc:
              'Fold your thumb in and rest your fingertips on it (or just above it).',
          isIcon: true,
        ),
      ],
    ),
    // Letter L
    'L': SignContent(
      title: 'Letter L',
      tags: ['Alphabet', 'ASL', 'Shape'],
      accuracyTrend: 'High',
      contextDescription:
          'The manual alphabet sign for "L". The thumb and index finger form an L shape.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Extend Thumb/Index',
          desc: 'Stick out your thumb and index finger.',
        ),
        InstructionStep(
          step: '2',
          title: 'Curl Others',
          desc: 'Curl the other three fingers into your palm.',
          isIcon: true,
        ),
      ],
    ),
    // Letter O
    'O': SignContent(
      title: 'Letter O',
      tags: ['Alphabet', 'ASL', 'Shape'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "O". All fingertips touch the thumb tip to form a circle.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Curve All',
          desc: 'Curve all fingers and thumb.',
        ),
        InstructionStep(
          step: '2',
          title: 'Touch Tips',
          desc:
              'Touch all fingertips to the tip of your thumb to make an O shape.',
          isIcon: true,
        ),
      ],
    ),
    // Letter S
    'S': SignContent(
      title: 'Letter S',
      tags: ['Alphabet', 'ASL', 'Static'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "S". A closed fist with the thumb wrapped across the front of the fingers.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Make a Fist',
          desc: 'Curl all fingers into a tight fist.',
        ),
        InstructionStep(
          step: '2',
          title: 'Wrap Thumb',
          desc:
              'Cross your thumb over your curled fingers (unlike A where it is on the side).',
          isIcon: true,
        ),
      ],
    ),
    // Letter U
    'U': SignContent(
      title: 'Letter U',
      tags: ['Alphabet', 'ASL', 'Static'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "U". Index and middle fingers are extended together.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Raise Two',
          desc: 'Extend your index and middle fingers upwards.',
        ),
        InstructionStep(
          step: '2',
          title: 'Join Them',
          desc: 'Keep them pressed together side -by-side.',
          isIcon: true,
        ),
      ],
    ),
    // Letter Y
    'Y': SignContent(
      title: 'Letter Y',
      tags: ['Alphabet', 'ASL', 'Shape'],
      accuracyTrend: 'Stable',
      contextDescription:
          'The manual alphabet sign for "Y". Thumb and pinky are extended, others curled.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Extend Ends',
          desc: 'Extend your thumb and pinky finger out.',
        ),
        InstructionStep(
          step: '2',
          title: 'Curl Middle',
          desc: 'Curl the three middle fingers into your palm.',
          isIcon: true,
        ),
      ],
    ),
  };

  static List<String> get supportedSigns => _data.keys.toList();

  static SignContent getContent(String label) {
    // Normalize label (e.g., "Letter A" -> "A" if needed, or handle direct matches)
    String cleanLabel = label.replaceAll('Letter ', '').trim();

    if (_data.containsKey(cleanLabel)) {
      return _data[cleanLabel]!;
    }

    // Check original label too just in case
    if (_data.containsKey(label)) {
      return _data[label]!;
    }

    // Fallback
    return SignContent(
      title: label,
      tags: ['Gesture'],
      accuracyTrend: '-',
      contextDescription: 'A detected hand gesture.',
      instructions: [
        InstructionStep(
          step: '1',
          title: 'Clear Background',
          desc: 'Ensure your hand is clearly visible against the background.',
        ),
      ],
    );
  }
}
