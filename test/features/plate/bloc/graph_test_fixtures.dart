import 'package:plate_number/features/plate/bloc/graph_state.dart';

const pairA = 'node1-node2';
const pairB = 'node3-node4';

const directedCauses = OrderedPair(from: 'a', to: 'b');
const directedKindOf = OrderedPair(from: 'x', to: 'y');
const symmetricRel = OrderedPair(from: 'u', to: 'v');

GraphState emptyState() {
  return const GraphState(edges: {});
}

GraphState singleRelationState() {
  return const GraphState(
    edges: {
      pairA: {RelationType.causes: directedCauses},
    },
  );
}

GraphState multiRelationState() {
  return const GraphState(
    edges: {
      pairA: {
        RelationType.causes: directedCauses,
        RelationType.kindOf: directedKindOf,
      },
    },
  );
}

GraphState symmetricRelationState() {
  return const GraphState(
    edges: {
      pairA: {RelationType.symmetric: symmetricRel},
    },
  );
}
