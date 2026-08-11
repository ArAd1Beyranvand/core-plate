import 'package:bloc/bloc.dart';
import 'graph_event.dart';
import 'graph_state.dart';

class GraphBloc extends Bloc<GraphEvent, GraphState> {
  GraphBloc() : super(const GraphState(edges: {})) {
    on<RelationDirectionFlipped>(_onRelationDirectionFlipped);
  }

  void _onRelationDirectionFlipped(
    RelationDirectionFlipped event,
    Emitter<GraphState> emit,
  ) {
    final pairEdges = state.edges[event.pairKey];
    if (pairEdges == null) {
      assert(false, 'No edge for pairKey: ${event.pairKey}');
      return;
    }
    final relation = pairEdges[event.type];
    if (relation == null) {
      assert(
        false,
        'No relation of type ${event.type} for pairKey: ${event.pairKey}',
      );
      return;
    }
    if (event.type == RelationType.symmetric) {
      assert(false, 'Cannot flip symmetric relation');
      return;
    }

    final newEdges = Map<String, Map<RelationType, OrderedPair>>.from(
      state.edges,
    );
    final newPairEdges = Map<RelationType, OrderedPair>.from(pairEdges);
    newPairEdges[event.type] = relation.flip();
    newEdges[event.pairKey] = newPairEdges;
    emit(GraphState(edges: newEdges));
  }
}
