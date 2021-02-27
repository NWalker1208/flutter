// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../widgets/semantics_tester.dart';

Widget wrap({Widget? child}) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(child: child),
    ),
  );
}

void main() {
  testWidgets('RadioListTile should initialize according to groupValue',
      (WidgetTester tester) async {
    final List<int> values = <int>[0, 1, 2];
    int? selectedValue;
    // Constructor parameters are required for [RadioListTile], but they are
    // irrelevant when searching with [find.byType].
    final Type radioListTileType = const RadioListTile<int>(
      value: 0,
      groupValue: 0,
      onChanged: null,
    ).runtimeType;

    List<RadioListTile<int>> generatedRadioListTiles;
    List<RadioListTile<int>> findTiles() => find
        .byType(radioListTileType)
        .evaluate()
        .map<Widget>((Element element) => element.widget)
        .cast<RadioListTile<int>>()
        .toList();

    Widget buildFrame() {
      return wrap(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (BuildContext context, int index) => RadioListTile<int>(
                  onChanged: (int? value) {
                    setState(() {
                      selectedValue = value;
                    });
                  },
                  value: values[index],
                  groupValue: selectedValue,
                  title: Text(values[index].toString()),
                ),
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    generatedRadioListTiles = findTiles();

    expect(generatedRadioListTiles[0].checked, equals(false));
    expect(generatedRadioListTiles[1].checked, equals(false));
    expect(generatedRadioListTiles[2].checked, equals(false));

    selectedValue = 1;

    await tester.pumpWidget(buildFrame());
    generatedRadioListTiles = findTiles();

    expect(generatedRadioListTiles[0].checked, equals(false));
    expect(generatedRadioListTiles[1].checked, equals(true));
    expect(generatedRadioListTiles[2].checked, equals(false));
  });

  testWidgets('RadioListTile simple control test', (WidgetTester tester) async {
    final Key key = UniqueKey();
    final Key titleKey = UniqueKey();
    final List<int?> log = <int?>[];

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: log.add,
          title: Text('Title', key: titleKey),
        ),
      ),
    );

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
    log.clear();

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          key: key,
          value: 1,
          groupValue: 1,
          onChanged: log.add,
          activeColor: Colors.green[500],
          title: Text('Title', key: titleKey),
        ),
      ),
    );

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: null,
          title: Text('Title', key: titleKey),
        ),
      ),
    );

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: log.add,
          title: Text('Title', key: titleKey),
        ),
      ),
    );

    await tester.tap(find.byKey(titleKey));

    expect(log, equals(<int>[1]));
  });

  testWidgets('RadioListTile control tests', (WidgetTester tester) async {
    final List<int> values = <int>[0, 1, 2];
    int? selectedValue;
    // Constructor parameters are required for [Radio], but they are irrelevant
    // when searching with [find.byType].
    final Type radioType = const Radio<int>(
      value: 0,
      groupValue: 0,
      onChanged: null,
    ).runtimeType;
    final List<dynamic> log = <dynamic>[];

    Widget buildFrame() {
      return wrap(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (BuildContext context, int index) => RadioListTile<int>(
                  onChanged: (int? value) {
                    log.add(value);
                    setState(() {
                      selectedValue = value;
                    });
                  },
                  value: values[index],
                  groupValue: selectedValue,
                  title: Text(values[index].toString()),
                ),
              ),
            );
          },
        ),
      );
    }

    // Tests for tapping between [Radio] and [ListTile]
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.text('1'));
    log.add('-');
    await tester.tap(find.byType(radioType).at(2));
    expect(log, equals(<dynamic>[1, '-', 2]));
    log.add('-');
    await tester.tap(find.text('1'));

    log.clear();
    selectedValue = null;

    // Tests for tapping across [Radio]s exclusively
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.byType(radioType).at(1));
    log.add('-');
    await tester.tap(find.byType(radioType).at(2));
    expect(log, equals(<dynamic>[1, '-', 2]));

    log.clear();
    selectedValue = null;

    // Tests for tapping across [ListTile]s exclusively
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.text('1'));
    log.add('-');
    await tester.tap(find.text('2'));
    expect(log, equals(<dynamic>[1, '-', 2]));
  });

  testWidgets('Selected RadioListTile should not trigger onChanged', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/30311
    final List<int> values = <int>[0, 1, 2];
    int? selectedValue;
    // Constructor parameters are required for [Radio], but they are irrelevant
    // when searching with [find.byType].
    final Type radioType = const Radio<int>(
      value: 0,
      groupValue: 0,
      onChanged: null,
    ).runtimeType;
    final List<dynamic> log = <dynamic>[];

    Widget buildFrame() {
      return wrap(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (BuildContext context, int index) => RadioListTile<int>(
                  onChanged: (int? value) {
                    log.add(value);
                    setState(() {
                      selectedValue = value;
                    });
                  },
                  value: values[index],
                  groupValue: selectedValue,
                  title: Text(values[index].toString()),
                ),
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(log, equals(<int>[0]));

    await tester.tap(find.text('0'));
    await tester.pump();
    expect(log, equals(<int>[0]));

    await tester.tap(find.byType(radioType).at(0));
    await tester.pump();
    expect(log, equals(<int>[0]));
  });

  testWidgets('Selected RadioListTile should trigger onChanged when toggleable',
      (WidgetTester tester) async {
    final List<int> values = <int>[0, 1, 2];
    int? selectedValue;
    // Constructor parameters are required for [Radio], but they are irrelevant
    // when searching with [find.byType].
    final Type radioType = const Radio<int>(
      value: 0,
      groupValue: 0,
      onChanged: null,
    ).runtimeType;
    final List<dynamic> log = <dynamic>[];

    Widget buildFrame() {
      return wrap(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: ListView.builder(
                itemCount: values.length,
                itemBuilder: (BuildContext context, int index) {
                  return RadioListTile<int>(
                    onChanged: (int? value) {
                      log.add(value);
                      setState(() {
                        selectedValue = value;
                      });
                    },
                    toggleable: true,
                    value: values[index],
                    groupValue: selectedValue,
                    title: Text(values[index].toString()),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    await tester.tap(find.text('0'));
    await tester.pump();
    expect(log, equals(<int>[0]));

    await tester.tap(find.text('0'));
    await tester.pump();
    expect(log, equals(<int?>[0, null]));

    await tester.tap(find.byType(radioType).at(0));
    await tester.pump();
    expect(log, equals(<int?>[0, null, 0]));
  });

  testWidgets('RadioListTile can be toggled when toggleable is set', (WidgetTester tester) async {
    final Key key = UniqueKey();
    final List<int?> log = <int?>[];

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
    log.clear();

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
          key: key,
          value: 1,
          groupValue: 1,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int?>[null]));
    log.clear();

    await tester.pumpWidget(Material(
      child: Center(
        child: Radio<int>(
          key: key,
          value: 1,
          groupValue: null,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
  });

  testWidgets('RadioListTile semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          value: 1,
          groupValue: 2,
          onChanged: (int? i) {},
          title: const Text('Title'),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              flags: <SemanticsFlag>[
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isEnabled,
                SemanticsFlag.isInMutuallyExclusiveGroup,
                SemanticsFlag.isFocusable,
              ],
              actions: <SemanticsAction>[SemanticsAction.tap],
              label: 'Title',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          value: 2,
          groupValue: 2,
          onChanged: (int? i) {},
          title: const Text('Title'),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              flags: <SemanticsFlag>[
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isChecked,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isEnabled,
                SemanticsFlag.isInMutuallyExclusiveGroup,
                SemanticsFlag.isFocusable,
              ],
              actions: <SemanticsAction>[SemanticsAction.tap],
              label: 'Title',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    await tester.pumpWidget(
      wrap(
        child: const RadioListTile<int>(
          value: 1,
          groupValue: 2,
          onChanged: null,
          title: Text('Title'),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              flags: <SemanticsFlag>[
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isInMutuallyExclusiveGroup,
                SemanticsFlag.isFocusable,
              ],
              label: 'Title',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    await tester.pumpWidget(
      wrap(
        child: const RadioListTile<int>(
          value: 2,
          groupValue: 2,
          onChanged: null,
          title: Text('Title'),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              flags: <SemanticsFlag>[
                SemanticsFlag.hasCheckedState,
                SemanticsFlag.isChecked,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isInMutuallyExclusiveGroup,
              ],
              label: 'Title',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('RadioListTile has semantic events', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final Key key = UniqueKey();
    dynamic semanticEvent;
    int? radioValue = 2;
    SystemChannels.accessibility.setMockMessageHandler((dynamic message) async {
      semanticEvent = message;
    });

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          key: key,
          value: 1,
          groupValue: radioValue,
          onChanged: (int? i) {
            radioValue = i;
          },
          title: const Text('Title'),
        ),
      ),
    );

    await tester.tap(find.byKey(key));
    await tester.pump();
    final RenderObject object = tester.firstRenderObject(find.byKey(key));

    expect(radioValue, 1);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics!.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics!.getSemanticsData().hasAction(SemanticsAction.tap), true);

    semantics.dispose();
    SystemChannels.accessibility.setMockMessageHandler(null);
  });

  testWidgets('RadioListTile can autofocus unless disabled.', (WidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          value: 1,
          groupValue: 2,
          onChanged: (_) {},
          title: Text('Title', key: childKey),
          autofocus: true,
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      wrap(
        child: RadioListTile<int>(
          value: 1,
          groupValue: 2,
          onChanged: null,
          title: Text('Title', key: childKey),
          autofocus: true,
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

  testWidgets('RadioListTile contentPadding test', (WidgetTester tester) async {
    final Type radioType = const Radio<bool>(
      groupValue: true,
      value: true,
      onChanged: null,
    ).runtimeType;

    await tester.pumpWidget(
      wrap(
        child: Center(
          child: RadioListTile<bool>(
            groupValue: true,
            value: true,
            title: const Text('Title'),
            onChanged: (_){},
            contentPadding: const EdgeInsets.fromLTRB(8, 10, 15, 20),
          )
        )
      )
    );

    final Rect paddingRect = tester.getRect(find.byType(Padding));
    final Rect radioRect = tester.getRect(find.byType(radioType));
    final Rect titleRect = tester.getRect(find.text('Title'));

    // Get the taller Rect of the Radio and Text widgets
    final Rect tallerRect = radioRect.height > titleRect.height ? radioRect : titleRect;

    // Get the extra height between the tallerRect and ListTile height
    final double extraHeight = 56 - tallerRect.height;

    // Check for correct top and bottom padding
    expect(paddingRect.top, tallerRect.top - extraHeight / 2 - 10); //top padding
    expect(paddingRect.bottom, tallerRect.bottom + extraHeight / 2 + 20); //bottom padding

    // Check for correct left and right padding
    expect(paddingRect.left, radioRect.left - 8); //left padding
    expect(paddingRect.right, titleRect.right + 15); //right padding
  });

  testWidgets('RadioListTile respects shape', (WidgetTester tester) async {
    const ShapeBorder shapeBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(100)),
    );

    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: RadioListTile<bool>(
          value: true,
          groupValue: true,
          onChanged: null,
          title: Text('Title'),
          shape: shapeBorder,
        ),
      ),
    ));

    expect(tester.widget<InkWell>(find.byType(InkWell)).customBorder, shapeBorder);
  });

  testWidgets('RadioListTile respects tileColor', (WidgetTester tester) async {
    const Color tileColor = Colors.red;

    await tester.pumpWidget(
      wrap(
        child: const Center(
          child: RadioListTile<bool>(
            value: false,
            groupValue: true,
            onChanged: null,
            title: Text('Title'),
            tileColor: tileColor,
          ),
        ),
      ),
    );

    final ColoredBox coloredBox = tester.firstWidget(find.byType(ColoredBox));
    expect(coloredBox.color, tileColor);
  });

  testWidgets('RadioListTile respects selectedTileColor', (WidgetTester tester) async {
    const Color selectedTileColor = Colors.black;

    await tester.pumpWidget(
      wrap(
        child: const Center(
          child: RadioListTile<bool>(
            value: false,
            groupValue: true,
            onChanged: null,
            title: Text('Title'),
            selected: true,
            selectedTileColor: selectedTileColor,
          ),
        ),
      ),
    );

    final ColoredBox coloredBox = tester.firstWidget(find.byType(ColoredBox));
    expect(coloredBox.color, equals(selectedTileColor));
  });
}
