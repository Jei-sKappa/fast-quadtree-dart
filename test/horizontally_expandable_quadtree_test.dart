import 'package:collection/collection.dart';
import 'package:fast_quadtree/src/extensions/loose_overlaps_on_rect.dart';
import 'package:fast_quadtree/src/horizontally_expandable_quadtree.dart';
import 'package:test/test.dart';
import 'package:fast_quadtree/src/quadrant.dart';
import 'dart:ui';

void main() {
  group('HorizontallyExpandableQuadtree', () {
    final deepListEquality = const DeepCollectionEquality.unordered().equals;

    final quadrant = Quadrant(x: 0, y: 0, width: 100, height: 100);

    // NW subnode
    final nwRect = Rect.fromLTWH(10, 10, 1, 1);
    // SE -> SE subnode
    final seseRect = Rect.fromLTWH(90, 90, 1, 1);
    // SE -> NW subnode
    final senwRect = Rect.fromLTWH(60, 60, 1, 1);

    // New Root on left first root
    final newRootOnLeftRect = Rect.fromLTWH(-50, 0, 1, 1);

    Rect getBounds(Rect rect) => rect;
    Rect fromMapT(Map<String, dynamic> map) => Rect.fromLTWH(
          map['left'] as double,
          map['top'] as double,
          map['width'] as double,
          map['height'] as double,
        );

    Map<String, dynamic> toMapT(Rect rect) => {
          'left': rect.left,
          'top': rect.top,
          'width': rect.width,
          'height': rect.height,
        };

    late HorizontallyExpandableQuadtree<Rect> quadtree;

    setUp(() {
      quadtree = HorizontallyExpandableQuadtree<Rect>(
        quadrant,
        maxItems: 1,
        maxDepth: 5,
        getBounds: getBounds,
      );
    });

    test('constructor initializes correctly', () {
      expect(quadtree.maxItems, 1);
      expect(quadtree.maxDepth, 5);
      expect(quadtree.getBounds, getBounds);
      expect(quadtree.firstNode.quadrant, quadrant);
    });

    test('fromMap initializes correctly', () {
      final map = {
        '_type': 'HorizontallyExpandableQuadtree',
        'quadrant': quadrant.toMap(),
        'maxItems': 1,
        'maxDepth': 5,
        'items': [
          toMapT(nwRect),
          toMapT(newRootOnLeftRect),
        ]
      };

      final quadtree = HorizontallyExpandableQuadtree<Rect>.fromMap(
        map,
        getBounds,
        fromMapT,
      );

      expect(quadtree.maxItems, 1);
      expect(quadtree.maxDepth, 5);
      expect(quadtree.getBounds, getBounds);
      // First Node
      expect(quadtree.firstNode.quadrant.left, 0.0);
      expect(quadtree.firstNode.quadrant.top, 0.0);
      expect(quadtree.firstNode.quadrant.width, 100.0);
      expect(quadtree.firstNode.quadrant.height, 100.0);
      // Second Node on Left
      expect(quadtree.quadtreeNodes[-1], isNotNull);
      expect(quadtree.quadtreeNodes[-1]!.quadrant.left, -100);
      expect(quadtree.quadtreeNodes[-1]!.quadrant.top, 0);
      expect(quadtree.quadtreeNodes[-1]!.quadrant.width, 100);
      expect(quadtree.quadtreeNodes[-1]!.quadrant.height, 100);

      expect(
        deepListEquality(
          quadtree.getAllItems(),
          [nwRect, newRootOnLeftRect],
        ),
        isTrue,
      );
    });

    test('insert adds item correctly', () {
      expect(quadtree.insert(nwRect), isTrue);
      expect(quadtree.getAllItems(), [nwRect]);
    });

    test(
        'insert adds correctly when item is outside of the first quadrant but '
        'within the same horizontal bounds ', () {
      expect(quadtree.insert(newRootOnLeftRect), isTrue);
      expect(quadtree.getAllItems(), [newRootOnLeftRect]);
    });

    test(
        'insert fails when item is outside of the first quadrant but '
        'not within the same horizontal bounds ', () {
      final item = Rect.fromLTWH(0, -50, 1, 1);
      expect(quadtree.insert(item), isFalse);
      expect(quadtree.getAllItems(), []);
    });

    test('insertAll adds items correctly', () {
      final items = [
        nwRect,
        seseRect,
        senwRect,
        newRootOnLeftRect,
      ];

      expect(quadtree.insertAll(items), isTrue);
      expect(deepListEquality(quadtree.getAllItems(), items), isTrue);
    });

    test('remove removes item correctly', () {
      expect(quadtree.insert(nwRect), isTrue);
      quadtree.remove(nwRect);

      expect(quadtree.getAllItems(), []);
    });

    test('remove removes item in a root different from the first one correctly',
        () {
      expect(quadtree.insert(newRootOnLeftRect), isTrue);
      quadtree.remove(newRootOnLeftRect);

      expect(quadtree.getAllItems(), []);
    });

    test('removeAll removes items correctly', () {
      final items = [
        nwRect,
        seseRect,
        senwRect,
        newRootOnLeftRect,
      ];
      expect(quadtree.insertAll(items), isTrue);
      quadtree.removeAll(items);

      expect(quadtree.getAllItems(), []);
    });

    test('localizeRemove removes item correctly', () {
      expect(quadtree.insert(nwRect), isTrue);
      quadtree.localizedRemove(nwRect);

      expect(quadtree.getAllItems(), []);
    });

    test('localizeRemove removes item in a root different from the first one',
        () {
      expect(quadtree.insert(newRootOnLeftRect), isTrue);
      quadtree.localizedRemove(newRootOnLeftRect);

      expect(quadtree.getAllItems(), []);
    });

    test('localizeRemoveAll removes items correctly', () {
      final items = [
        nwRect,
        seseRect,
        senwRect,
        newRootOnLeftRect,
      ];
      expect(quadtree.insertAll(items), isTrue);
      quadtree.localizedRemoveAll(items);

      expect(quadtree.getAllItems(), []);
    });

    test("retrieve returns all items in node when passing firstNode's quadrant",
        () {
      final rects = [
        nwRect,
        seseRect,
        senwRect,
      ];
      quadtree.insertAll(rects);
      final items = quadtree.retrieve(quadtree.firstNode.quadrant);
      expect(deepListEquality(items, rects), isTrue);
    });

    test("retrieve returns all items in node when passing quadtree's quadrant",
        () {
      final rects = [
        nwRect,
        seseRect,
        senwRect,
        newRootOnLeftRect,
      ];
      quadtree.insertAll(rects);
      final items = quadtree.retrieve(
        Quadrant(
          x: quadtree.left,
          y: quadtree.top,
          width: quadtree.width,
          height: quadtree.height,
        ),
      );
      expect(deepListEquality(items, rects), isTrue);
    });

    test('retrieve returns all items that overlaps with given quadrant', () {
      for (int i = -10; i < 20; i++) {
        quadtree.insert(Rect.fromLTWH(i * 10.0, 50, 9.9, 9.9));
      }

      final otherQuadrant = Quadrant(
        x: -20,
        y: 40,
        width: 20 + 100 + 20,
        height: 20,
      );

      final items = quadtree.retrieve(otherQuadrant);

      expect(
        deepListEquality(items, [
          Rect.fromLTWH(-20, 50, 9.9, 9.9),
          Rect.fromLTWH(-10, 50, 9.9, 9.9),
          Rect.fromLTWH(0, 50, 9.9, 9.9),
          Rect.fromLTWH(10, 50, 9.9, 9.9),
          Rect.fromLTWH(20, 50, 9.9, 9.9),
          Rect.fromLTWH(30, 50, 9.9, 9.9),
          Rect.fromLTWH(40, 50, 9.9, 9.9),
          Rect.fromLTWH(50, 50, 9.9, 9.9),
          Rect.fromLTWH(60, 50, 9.9, 9.9),
          Rect.fromLTWH(70, 50, 9.9, 9.9),
          Rect.fromLTWH(80, 50, 9.9, 9.9),
          Rect.fromLTWH(90, 50, 9.9, 9.9),
          Rect.fromLTWH(100, 50, 9.9, 9.9),
          Rect.fromLTWH(110, 50, 9.9, 9.9),
          Rect.fromLTWH(120, 50, 9.9, 9.9),
        ]),
        isTrue,
      );
    });

    test(
        'retrieve returns 0 elements when the given quadrant does not collide'
        "with quadtrees's quadrant", () {
      for (int i = -10; i < 20; i++) {
        quadtree.insert(Rect.fromLTWH(i * 10.0, 50, 9.9, 9.9));
      }

      final otherQuadrant = Quadrant(x: 300, y: 300, width: 20, height: 20);
      expect(
        Quadrant(
          x: quadtree.left,
          y: quadtree.top,
          width: quadtree.width,
          height: quadtree.height,
        ).bounds.looseOverlaps(otherQuadrant.bounds),
        isFalse,
      );

      final items = quadtree.retrieve(otherQuadrant);
      expect(items.length, 0);
    });

    test(
        'getAllQuadrants returns all quadrants when includeNonLeafNodes is '
        'true', () {
      final quadrants = quadtree.getAllQuadrants();
      expect(quadrants.length, 1);
      expect(quadrants[0], quadtree.firstNode.quadrant);

      // Insert items to create subnodes
      expect(quadtree.insert(nwRect), isTrue);
      expect(quadtree.insert(seseRect), isTrue);
      expect(quadtree.insert(senwRect), isTrue);
      expect(quadtree.insert(newRootOnLeftRect), isTrue);

      final allQuadrants = quadtree.getAllQuadrants();
      expect(
        deepListEquality(allQuadrants, [
          // New Root on Left First' quadrant
          Quadrant(x: -100, y: 0, width: 100, height: 100),
          // Original quadrant
          quadrant,
          // Subnodes 1st level
          Quadrant(x: 0, y: 0, width: 50, height: 50),
          Quadrant(x: 50, y: 0, width: 50, height: 50),
          Quadrant(x: 0, y: 50, width: 50, height: 50),
          Quadrant(x: 50, y: 50, width: 50, height: 50),
          // Subnodes 2nd level
          Quadrant(x: 50, y: 50, width: 25, height: 25),
          Quadrant(x: 75, y: 50, width: 25, height: 25),
          Quadrant(x: 50, y: 75, width: 25, height: 25),
          Quadrant(x: 75, y: 75, width: 25, height: 25),
        ]),
        isTrue,
      );
    });

    test(
        'getAllQuadrants returns only leaf quadrands when includeNonLeafNodes'
        'is false', () {
      final quadrants = quadtree.getAllQuadrants(includeNonLeafNodes: false);
      expect(quadrants.length, 1);
      expect(quadrants[0], quadtree.firstNode.quadrant);

      // Insert items to create subnodes
      expect(quadtree.insert(nwRect), isTrue);
      expect(quadtree.insert(seseRect), isTrue);
      expect(quadtree.insert(senwRect), isTrue);
      expect(quadtree.insert(newRootOnLeftRect), isTrue);

      final nonLeadQuadrants =
          quadtree.getAllQuadrants(includeNonLeafNodes: false);
      expect(
        deepListEquality(nonLeadQuadrants, [
          // New Root on Left First' quadrant
          Quadrant(x: -100, y: 0, width: 100, height: 100),
          // Original quadrant
          // "quadrant" Not included
          // Subnodes 1st level
          Quadrant(x: 0, y: 0, width: 50, height: 50),
          Quadrant(x: 50, y: 0, width: 50, height: 50),
          Quadrant(x: 0, y: 50, width: 50, height: 50),
          // "Quadrant(x: 50, y: 50, width: 50, height: 50)" Not included
          // Subnodes 2nd level
          Quadrant(x: 50, y: 50, width: 25, height: 25),
          Quadrant(x: 75, y: 50, width: 25, height: 25),
          Quadrant(x: 50, y: 75, width: 25, height: 25),
          Quadrant(x: 75, y: 75, width: 25, height: 25),
        ]),
        isTrue,
      );
    });

    test('getAllItems returns all items in node and subnodes', () {
      final List<Rect> rects = [];
      for (int i = -10; i < 20; i++) {
        for (int j = 0; j < 10; j++) {
          rects.add(
            Rect.fromLTWH(
              i * 10.0 + j * 1,
              50,
              1,
              1,
            ),
          );
        }
      }

      expect(quadtree.insertAll(rects), isTrue);
      final allItems = quadtree.getAllItems();
      expect(
        deepListEquality(allItems, rects),
        isTrue,
      );
    });

    test(
        'getAllItems returns all items plus duplicates in node and subnodes'
        ' when removeDuplicates is false', () {
      final List<Rect> rects = [];
      for (int i = -10; i < 20; i++) {
        for (int j = 0; j < 10; j++) {
          rects.add(
            Rect.fromLTWH(
              i * 10.0 + j * 1,
              50,
              1,
              1,
            ),
          );
        }
      }

      expect(quadtree.insertAll(rects), isTrue);

      final allItemsWithDuplicas = quadtree.getAllItems();
      expect(allItemsWithDuplicas.length >= rects.length, isTrue);

      for (final item in allItemsWithDuplicas) {
        expect(rects.contains(item), isTrue);
      }
    });

    test('clear removes all items', () {
      final items = [
        nwRect,
        seseRect,
        senwRect,
        newRootOnLeftRect,
      ];
      quadtree.insertAll(items);
      quadtree.clear();

      expect(quadtree.getAllItems().isEmpty, isTrue);
    });

    test('toMap returns correct map representation', () {
      expect(quadtree.insert(nwRect), isTrue);
      expect(quadtree.insert(seseRect), isTrue);
      expect(quadtree.insert(senwRect), isTrue);
      expect(quadtree.insert(newRootOnLeftRect), isTrue);

      final map = quadtree.toMap(toMapT);

      expect(map['_type'], 'HorizontallyExpandableQuadtree');
      expect(map['quadrant'], quadrant.toMap());
      expect(map['maxItems'], 1);
      expect(map['maxDepth'], 5);
      expect(
        deepListEquality(
          map['items'],
          [
            toMapT(nwRect),
            toMapT(seseRect),
            toMapT(senwRect),
            toMapT(newRootOnLeftRect),
          ],
        ),
        isTrue,
      );
    });
  });
}
