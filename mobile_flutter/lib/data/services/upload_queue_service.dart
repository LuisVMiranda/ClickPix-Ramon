import 'dart:math';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/drift.dart';

const String uploadTaskStatusPending = 'pending';
const String uploadTaskStatusProcessing = 'processing';
const String uploadTaskStatusCompleted = 'completed';
const String uploadTaskStatusFailed = 'failed';

abstract class NetworkConstraint {
  Future<bool> canSync({required bool wifiOnly});
}

abstract class UploadSyncGateway {
  Future<void> uploadOrder({required String orderId});

  Future<void> startPaymentIfApplicable({required String orderId});
}

class UploadQueueService {
  UploadQueueService({
    required AppDatabase database,
    required AppSettingsStore settingsStore,
    required NetworkConstraint networkConstraint,
    required UploadSyncGateway syncGateway,
    this.maxRetries = 5,
    this.baseDelay = const Duration(seconds: 30),
  })  : _database = database,
        _settingsStore = settingsStore,
        _networkConstraint = networkConstraint,
        _syncGateway = syncGateway;

  final AppDatabase _database;
  final AppSettingsStore _settingsStore;
  final NetworkConstraint _networkConstraint;
  final UploadSyncGateway _syncGateway;
  final int maxRetries;
  final Duration baseDelay;

  Future<void> enqueueOrderUpload(String orderId) async {
    final now = DateTime.now();
    final current = await (_database.select(_database.uploadTasks)
          ..where((tbl) => tbl.orderId.equals(orderId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    if (current != null &&
        (current.status == uploadTaskStatusPending || current.status == uploadTaskStatusProcessing)) {
      return;
    }

    await _database.into(_database.uploadTasks).insert(
          UploadTasksCompanion.insert(
            id: 'task_${now.microsecondsSinceEpoch}_$orderId',
            orderId: orderId,
            status: uploadTaskStatusPending,
            retryCount: const Value(0),
            nextAttemptAt: Value(now),
            lastError: const Value.absent(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<UploadQueueProcessResult> processQueue() async {
    final settings = await _settingsStore.loadDeliverySettings();
    final canSync = await _networkConstraint.canSync(wifiOnly: settings.wifiOnly);
    if (!canSync) {
      return const UploadQueueProcessResult(processed: 0, blockedByNetwork: true);
    }

    final now = DateTime.now();
    final tasks = await (_database.select(_database.uploadTasks)
          ..where((tbl) => tbl.status.equals(uploadTaskStatusPending) & tbl.nextAttemptAt.isSmallerOrEqualValue(now))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.nextAttemptAt),
            (tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .get();

    var processed = 0;
    for (final task in tasks) {
      processed += 1;
      await _database.transaction(() async {
        await (_database.update(_database.uploadTasks)..where((tbl) => tbl.id.equals(task.id))).write(
          const UploadTasksCompanion(status: Value(uploadTaskStatusProcessing)),
        );
      });

      try {
        await _syncGateway.uploadOrder(orderId: task.orderId);
        await _syncGateway.startPaymentIfApplicable(orderId: task.orderId);

        await (_database.update(_database.uploadTasks)..where((tbl) => tbl.id.equals(task.id))).write(
          const UploadTasksCompanion(
            status: Value(uploadTaskStatusCompleted),
            lastError: Value.absent(),
          ),
        );
      } catch (error) {
        final nextRetryCount = task.retryCount + 1;
        final hasExceeded = nextRetryCount >= maxRetries;
        await (_database.update(_database.uploadTasks)..where((tbl) => tbl.id.equals(task.id))).write(
          UploadTasksCompanion(
            status: Value(hasExceeded ? uploadTaskStatusFailed : uploadTaskStatusPending),
            retryCount: Value(nextRetryCount),
            nextAttemptAt: Value(_nextAttemptAt(now, nextRetryCount)),
            lastError: Value(error.toString()),
          ),
        );
      }
    }

    return UploadQueueProcessResult(processed: processed, blockedByNetwork: false);
  }

  DateTime _nextAttemptAt(DateTime now, int retryCount) {
    final exponential = pow(2, max(0, retryCount - 1)).toInt();
    return now.add(baseDelay * exponential);
  }
}

class UploadQueueProcessResult {
  const UploadQueueProcessResult({
    required this.processed,
    required this.blockedByNetwork,
  });

  final int processed;
  final bool blockedByNetwork;
}
