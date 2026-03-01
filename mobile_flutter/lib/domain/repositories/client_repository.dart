abstract class ClientRepository {
  Future<void> createClient({
    required String id,
    required String name,
    required String whatsapp,
    String? email,
  });
}
