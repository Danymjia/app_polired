import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test grid cell aspect ratio with SliverMainAxisGroup', (WidgetTester tester) async {
    final scrollController = ScrollController();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverMainAxisGroup(
                slivers: [
                  SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.crossAxisExtent;
                      const spacing = 1.5;
                      const columns = 3;
                      final cellSize = (totalWidth - spacing * (columns - 1)) / columns;
                      
                      debugPrint('Grid constraints crossAxisExtent: $totalWidth');
                      debugPrint('Calculated cellSize: $cellSize');

                      return SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          mainAxisExtent: cellSize,
                        ),
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return LayoutBuilder(
                            builder: (context, boxConstraints) {
                              debugPrint('Cell $index constraints: $boxConstraints');
                              return Container(color: Colors.red);
                            }
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  });
}
