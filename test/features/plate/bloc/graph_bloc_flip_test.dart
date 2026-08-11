import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number/features/plate/bloc/graph_bloc.dart';
import 'package:plate_number/features/plate/bloc/graph_event.dart';
import 'package:plate_number/features/plate/bloc/graph_state.dart';

import 'graph_test_fixtures.dart';

void main() {
  group('RelationDirectionFlipped', () {
    blocTest<GraphBloc, GraphState>(
      'flips a directed relation (causes) — (from,to) becomes (to,from)',
      build: () => GraphBloc(),
      seed: () => singleRelationState(),
      act: (bloc) => bloc.add(
        const RelationDirectionFlipped(
          pairKey: pairA,
          type: RelationType.causes,
        ),
      ),
     expect: () => [
        const GraphState(
          edges: {
            pairA: {RelationType.causes: OrderedPair(from: 'b', to: 'a')},
          },
        ),
      ],
    );

    blocTest<GraphBloc, GraphState>(
      'flipping the same relation twice returns to original orientation',
      build: () => GraphBloc(),
      seed: () => singleRelationState(),
      act: (bloc) {
        bloc.add(
          const RelationDirectionFlipped(
            pairKey: pairA,
            type: RelationType.causes,
          ),
        );
        bloc.add(
          const RelationDirectionFlipped(
            pairKey: pairA,
            type: RelationType.causes,
          ),
        );
      },
     expect: () => [
        const GraphState(
          edges: {
            pairA: {RelationType.causes: OrderedPair(from: 'b', to: 'a')},
          },
        ),
        singleRelationState(),
      ],
    );

    blocTest<GraphBloc, GraphState>(
      'flip on a pair with several relations — only targeted type affected',
      build: () => GraphBloc(),
      seed: () => multiRelationState(),
      act: (bloc) => bloc.add(
        const RelationDirectionFlipped(
          pairKey: pairA,
          type: RelationType.causes,
        ),
      ),
     expect: () => [
        const GraphState(
          edges: {
            pairA: {
              RelationType.causes: OrderedPair(from: 'b', to: 'a'),
              RelationType.kindOf: directedKindOf,
            },
          },
        ),
      ],
    );

    blocTest<GraphBloc, GraphState>(
      'flip causes leaves kindOf direction untouched',
      build: () => GraphBloc(),
      seed: () => multiRelationState(),
      act: (bloc) => bloc.add(
        const RelationDirectionFlipped(
          pairKey: pairA,
          type: RelationType.causes,
        ),
      ),
      expect: () => [
        isA<GraphState>().having(
          (s) => s.edges[pairA]![RelationType.kindOf],
          'kindOf',
          directedKindOf,
        ),
      ],
    );

    blocTest<GraphBloc, GraphState>(
      'flip symmetric type asserts in debug mode',
      build: () => GraphBloc(),
      seed: () => symmetricRelationState(),
      act: (bloc) => bloc.add(
        const RelationDirectionFlipped(
          pairKey: pairA,
          type: RelationType.symmetric,
        ),
      ),
      errors: () => [isA<AssertionError>()],
    );

    blocTest<GraphBloc, GraphState>(
      'flip a type the pair does not have asserts in debug mode',
      build: () => GraphBloc(),
      seed: () => singleRelationState(),
      act: (bloc) => bloc.add(
        const RelationDirectionFlipped(
          pairKey: pairA,
          type: RelationType.kindOf,
        ),
      ),
      errors: () => [isA<AssertionError>()],
    );

    blocTest<GraphBloc, GraphState>(
      'flip on a pairKey with no edge asserts in debug mode',
      build: () => GraphBloc(),
      seed: () => singleRelationState(),
      act: (bloc) => bloc.add(
        const RelationDirectionFlipped(
          pairKey: pairB,
          type: RelationType.causes,
        ),
      ),
      errors: () => [isA<AssertionError>()],
    );
  });
}
