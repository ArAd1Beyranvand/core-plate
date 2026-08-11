import 'graph_state.dart';

sealed class GraphEvent {
  const GraphEvent();
}

class RelationDirectionFlipped extends GraphEvent {
  final String pairKey;
  final RelationType type;
  const RelationDirectionFlipped({required this.pairKey, required this.type});
}
