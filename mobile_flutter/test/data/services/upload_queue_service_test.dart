import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/services/upload_queue_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedOrder(String orderId) async {
    await database.into(database.clients).insert(
          const ClientsCompanion.insert(
            id: 'client-1',
            name: 'Client One',
            whatsapp: '+5511999999999',
          ),
        );

    await database.into(database.orders).insert(
          OrdersCompanion.insert(
            id: orderId,
            clientId: 'client-1',
            totalAmountCents: 1000,
            status: 'Created',
            paymentMethod: 'pix',
            externalReference: '$orderId-ref',
          ),
        );
  }

  test('enqueue order upload creates pending task', () async {
    await seedOrder('order-1');

    final service = UploadQueueService(
      database: database,
      settingsStore: AppSettingsStore(database),
      networkConstraint: _FakeNetworkConstraint(canSyncValue: true),
      syncGateway: _FakeUploadSyncGateway(),
    );

    await service.enqueueOrderUpload('order-1');

    final rows = await database.select(database.uploadTasks).get();
    expect(rows, hasLength(1));
    expect(rows.single.orderId, 'order-1');
    expect(rows.single.status, uploadTaskStatusPending);
  });

  test('process queue respects wifi-only setting', () async {
    await seedOrder('order-1');
    final settingsStore = AppSettingsStore(database);
    await settingsStore.saveDeliverySettings(
      const AppDeliverySettings(wifiOnly: true, accessCodeValidityDays: 7),
    );

    final service = UploadQueueService(
      database: database,
      settingsStore: settingsStore,
      networkConstraint: _FakeNetworkConstraint(canSyncValue: false),
      syncGateway: _FakeUploadSyncGateway(),
    );

    await service.enqueueOrderUpload('order-1');
    final result = await service.processQueue();

    expect(result.blockedByNetwork, isTrue);
    expect(result.processed, 0);

    final task = await database.select(database.uploadTasks).getSingle();
    expect(task.status, uploadTaskStatusPending);
  });

  test('process queue retries with backoff and marks failed after max attempts', () async {
    await seedOrder('order-1');

    final service = UploadQueueService(
      database: database,
      settingsStore: AppSettingsStore(database),
      networkConstraint: _FakeNetworkConstraint(canSyncValue: true),
      syncGateway: _FakeUploadSyncGateway(throwOnUpload: true),
      maxRetries: 2,
      baseDelay: const Duration(milliseconds: 1),
    );

    await service.enqueueOrderUpload('order-1');
    await service.processQueue();

    var task = await database.select(database.uploadTasks).getSingle();
    expect(task.status, uploadTaskStatusPending);
    expect(task.retryCount, 1);
    expect(task.lastError, contains('upload error'));

    await (database.update(database.uploadTasks)..where((tbl) => tbl.id.equals(task.id))).write(
      UploadTasksCompanion(nextAttemptAt: Value(DateTime.now().subtract(const Duration(seconds: 1)))),
    );

    await service.processQueue();

    task = await database.select(database.uploadTasks).getSingle();
    expect(task.status, uploadTaskStatusFailed);
    expect(task.retryCount, 2);
  });
}

class _FakeNetworkConstraint implements NetworkConstraint {
  _FakeNetworkConstraint({required this.canSyncValue});

  final bool canSyncValue;

  @override
  Future<bool> canSync({required bool wifiOnly}) async => canSyncValue;
}

class _FakeUploadSyncGateway implements UploadSyncGateway {
  _FakeUploadSyncGateway({this.throwOnUpload = false});

  final bool throwOnUpload;

  @override
  Future<void> startPaymentIfApplicable({required String orderId}) async {}

  @override
  Future<void> uploadOrder({required String orderId}) async {
    if (throwOnUpload) {
      throw StateError('upload error for $orderId');
    }
  }
}
