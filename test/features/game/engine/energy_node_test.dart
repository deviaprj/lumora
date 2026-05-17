import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumora_mobile/features/game/engine/energy_node.dart';

void main() {
  group('EnergyNode', () {
    late EnergyNode node;

    setUp(() {
      node = EnergyNode(
        nodeIndex: 0,
        position: Vector2(100, 200),
        radius: 18.0,
      );
    });

    test('initial state is dormant', () {
      expect(node.state, NodeState.dormant);
      expect(node.nodeIndex, 0);
      expect(node.radius, 18.0);
    });

    test('activate changes state to activated', () {
      node.activate();
      expect(node.state, NodeState.activated);
    });

    test('markConnected changes state to connected', () {
      node.markConnected();
      expect(node.state, NodeState.connected);
    });

    test('markTarget changes state to target', () {
      node.markTarget();
      expect(node.state, NodeState.target);
    });

    test('reset restores dormant state', () {
      node.activate();
      expect(node.state, NodeState.activated);
      node.reset();
      expect(node.state, NodeState.dormant);
    });

    test('containsPoint works within hit radius', () {
      // Centre du nœud : (100, 200), rayon : 18
      // containsPoint utilise radius * 3 comme zone de détection = 54
      // Mais après le fix, LumoraGame utilise radius * 5
      // Le containsPoint du nœud garde radius * 3 pour les taps directs

      // Point au centre — doit être contenu
      expect(node.containsPoint(Vector2(100, 200)), true);

      // Point à 30px du centre — dans la zone (radius*3 = 54)
      expect(node.containsPoint(Vector2(130, 200)), true);

      // Point à 50px du centre — dans la zone
      expect(node.containsPoint(Vector2(150, 200)), true);

      // Point à 60px du centre — hors zone (radius*3 = 54)
      expect(node.containsPoint(Vector2(160, 200)), false);

      // Point très loin — hors zone
      expect(node.containsPoint(Vector2(500, 500)), false);
    });

    test('containsPoint works with diagonal distances', () {
      // Distance diagonale : sqrt(30² + 30²) ≈ 42.4 — dans la zone
      expect(node.containsPoint(Vector2(130, 230)), true);

      // Distance diagonale : sqrt(40² + 40²) ≈ 56.6 — hors zone
      expect(node.containsPoint(Vector2(140, 240)), false);
    });

    test('state transitions follow expected flow', () {
      // dormant → target → activated → connected
      expect(node.state, NodeState.dormant);

      node.markTarget();
      expect(node.state, NodeState.target);

      node.activate();
      expect(node.state, NodeState.activated);

      node.markConnected();
      expect(node.state, NodeState.connected);

      // Reset → dormant
      node.reset();
      expect(node.state, NodeState.dormant);
    });

    test('activate can be called from target state', () {
      node.markTarget();
      node.activate();
      expect(node.state, NodeState.activated);
    });

    test('multiple nodes have correct positions', () {
      final node2 = EnergyNode(
        nodeIndex: 1,
        position: Vector2(200, 300),
        radius: 18.0,
      );

      // Les deux nœuds ont des positions différentes
      expect(node.position.x, 100);
      expect(node.position.y, 200);
      expect(node2.position.x, 200);
      expect(node2.position.y, 300);

      // Un point plus proche de node2 que de node
      final testPoint = Vector2(180, 280);
      final dist0 = testPoint.distanceTo(node.position);
      final dist1 = testPoint.distanceTo(node2.position);
      expect(dist1, lessThan(dist0));
    });

    test('node radius affects hit area', () {
      final smallNode = EnergyNode(
        nodeIndex: 0,
        position: Vector2(100, 200),
        radius: 10.0,
      );
      final largeNode = EnergyNode(
        nodeIndex: 0,
        position: Vector2(100, 200),
        radius: 30.0,
      );

      // smallNode : radius*3 = 30, largeNode : radius*3 = 90
      // Un point à 50px du centre
      final point = Vector2(150, 200); // 50px du centre
      expect(smallNode.containsPoint(point), false); // 50 > 30
      expect(largeNode.containsPoint(point), true);  // 50 < 90
    });
  });

  group('NodeState', () {
    test('all states exist and are distinct', () {
      expect(NodeState.values, containsAll([
        NodeState.dormant,
        NodeState.activated,
        NodeState.connected,
        NodeState.target,
      ]));
      expect(NodeState.values.length, 4);
    });

    test('state transitions are valid for gameplay', () {
      // Le flow normal: dormant → activated → connected
      // Ou: dormant → target → activated → connected
      // Ces transitions doivent toujours être possibles
      final node = EnergyNode(nodeIndex: 0, position: Vector2.zero());

      // dormant → activated
      node.activate();
      expect(node.state, NodeState.activated);

      node.reset();

      // dormant → target
      node.markTarget();
      expect(node.state, NodeState.target);

      // target → activated
      node.activate();
      expect(node.state, NodeState.activated);

      // activated → connected
      node.markConnected();
      expect(node.state, NodeState.connected);
    });
  });
}