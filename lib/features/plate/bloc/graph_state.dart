enum RelationType { causes, kindOf, symmetric }

class OrderedPair {
  final String from;
  final String to;
  const OrderedPair({required this.from, required this.to});

  OrderedPair flip() => OrderedPair(from: to, to: from);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderedPair && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'OrderedPair($from, $to)';
}

class GraphState {
  final Map<String, Map<RelationType, OrderedPair>> edges;
  const GraphState({required this.edges});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GraphState) return false;
    if (edges.length != other.edges.length) return false;
    for (final entry in edges.entries) {
      final otherMap = other.edges[entry.key];
      if (otherMap == null) return false;
      if (entry.value.length != otherMap.length) return false;
      for (final inner in entry.value.entries) {
        final otherVal = otherMap[inner.key];
        if (otherVal == null) return false;
        if (inner.value != otherVal) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
    edges.entries.expand(
      (e) => [
        e.key,
        ...e.value.entries.expand((i) => [i.key, i.value]),
      ],
    ),
  );
}
