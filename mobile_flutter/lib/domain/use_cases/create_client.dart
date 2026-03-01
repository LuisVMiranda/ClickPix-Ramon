import 'package:clickpix_ramon/domain/repositories/client_repository.dart';

class CreateClient {
  final ClientRepository _clientRepository;

  CreateClient(this._clientRepository);

  Future<void> call({
    required String id,
    required String name,
    required String whatsapp,
    String? email,
  }) {
    return _clientRepository.createClient(
      id: id,
      name: name,
      whatsapp: whatsapp,
      email: email,
    );
  }
}
