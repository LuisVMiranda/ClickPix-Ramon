import 'dart:convert';
import 'dart:io';

import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/value_objects/order_status_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final contractFile = File('../docs/contracts/order_status_transitions.v1.json');
  final contract = jsonDecode(contractFile.readAsStringSync()) as Map<String, dynamic>;

  test('mapeamento de enum para estados do contrato é 1:1', () {
    final states = (contract['states'] as List<dynamic>).cast<String>().toSet();
    final mappedStates = OrderStatusTransition.contractStateByStatus.values.toSet();

    expect(mappedStates, equals(states));
    expect(
      OrderStatusTransition.statusByContractState.keys.toSet(),
      equals(states),
    );
  });

  test('deve cobrir todas as transições permitidas e proibidas do contrato', () {
    final states = (contract['states'] as List<dynamic>).cast<String>();
    final transitions =
        (contract['transitions'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>().toSet()),
        );

    for (final fromState in states) {
      final from = OrderStatusTransition.statusByContractState[fromState]!;
      final allowed = transitions[fromState] ?? <String>{};

      for (final toState in states) {
        final to = OrderStatusTransition.statusByContractState[toState]!;
        final expected = allowed.contains(toState);

        expect(
          OrderStatusTransition.canTransition(from, to),
          expected,
          reason: 'Transição $fromState -> $toState deve ser $expected',
        );
      }
    }
  });
}
