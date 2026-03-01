import 'dart:io';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/services/upload_queue_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

const String uploadQueueWorkerTaskName = 'clickpix.upload.queue';

class ConnectivityNetworkConstraint implements NetworkConstraint {
  ConnectivityNetworkConstraint(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> canSync({required bool wifiOnly}) async {
    if (!wifiOnly) {
      return true;
    }

    final statuses = await _connectivity.checkConnectivity();
    return statuses.contains(ConnectivityResult.wifi);
  }
}

class NoopUploadSyncGateway implements UploadSyncGateway {
  const NoopUploadSyncGateway();

  @override
  Future<void> startPaymentIfApplicable({required String orderId}) async {}

  @override
  Future<void> uploadOrder({required String orderId}) async {}
}

class UploadWorkerScheduler {
  UploadWorkerScheduler(this._database);

  final AppDatabase _database;

  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }

    await Workmanager().initialize(_callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      'clickpix-upload-queue',
      uploadQueueWorkerTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      frequency: const Duration(minutes: 15),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
      initialDelay: const Duration(minutes: 1),
    );
  }

  Future<void> processNow() async {
    final service = UploadQueueService(
      database: _database,
      settingsStore: AppSettingsStore(_database),
      networkConstraint: ConnectivityNetworkConstraint(Connectivity()),
      syncGateway: const NoopUploadSyncGateway(),
    );
    await service.processQueue();
  }
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != uploadQueueWorkerTaskName) {
      return true;
    }

    final docsDirectory = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDirectory.path, 'clickpix.sqlite'));
    final database = AppDatabase(NativeDatabase(dbFile));
    final service = UploadQueueService(
      database: database,
      settingsStore: AppSettingsStore(database),
      networkConstraint: ConnectivityNetworkConstraint(Connectivity()),
      syncGateway: const NoopUploadSyncGateway(),
    );
    await service.processQueue();
    await database.close();

    return true;
  });
}
