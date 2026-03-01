import 'package:clickpix_ramon/domain/repositories/client_repository.dart';
import 'package:clickpix_ramon/domain/use_cases/create_client.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClientRepository implements ClientRepository {
  Map<String, String?>? lastCreated;

  @override
  Future<void> createClient({
    required String id,
    required String name,
    required String whatsapp,
    String? email,
  }) async {
    lastCreated = {
      'id': id,
      'name': name,
      'whatsapp': whatsapp,
      'email': email,
    };
  }
}

void main() {
  test('CreateClient delegates creation to repository', () async {
    final repository = FakeClientRepository();
    final useCase = CreateClient(repository);

    await useCase(
      id: 'client-1',
      name: 'Maria',
      whatsapp: '+5511999999999',
      email: 'maria@example.com',
    );

    expect(repository.lastCreated, isNotNull);
    expect(repository.lastCreated!['id'], 'client-1');
    expect(repository.lastCreated!['email'], 'maria@example.com');
  });
}
