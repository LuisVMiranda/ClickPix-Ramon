import 'dart:async';

import 'package:clickpix_ramon/domain/entities/order.dart';

typedef SnapshotSource = Stream<OrderStatus> Function(String orderId);
typedef PollSource = Future<OrderStatus?> Function(String orderId);

class WatchOrderPaymentStatus {
  const WatchOrderPaymentStatus({
    required SnapshotSource snapshotSource,
    required PollSource pollSource,
    Duration snapshotGracePeriod = const Duration(seconds: 5),
    Duration initialBackoff = const Duration(seconds: 2),
    Duration maxBackoff = const Duration(seconds: 30),
  }) : _snapshotSource = snapshotSource,
       _pollSource = pollSource,
       _snapshotGracePeriod = snapshotGracePeriod,
       _initialBackoff = initialBackoff,
       _maxBackoff = maxBackoff;

  final SnapshotSource _snapshotSource;
  final PollSource _pollSource;
  final Duration _snapshotGracePeriod;
  final Duration _initialBackoff;
  final Duration _maxBackoff;

  Stream<OrderStatus> call(String orderId) {
    final controller = StreamController<OrderStatus>();
    StreamSubscription<OrderStatus>? snapshotSubscription;
    Timer? graceTimer;
    bool firstSnapshotSeen = false;
    bool pollingStarted = false;
    OrderStatus? lastEmittedStatus;

    Future<void> emit(OrderStatus status) async {
      if (lastEmittedStatus == status || controller.isClosed) {
        return;
      }
      lastEmittedStatus = status;
      controller.add(status);
    }

    Future<void> startPolling() async {
      if (pollingStarted || controller.isClosed) {
        return;
      }
      pollingStarted = true;

      var delay = _initialBackoff;
      while (!controller.isClosed && !firstSnapshotSeen) {
        final polledStatus = await _pollSource(orderId);
        if (polledStatus != null) {
          await emit(polledStatus);
        }

        await Future<void>.delayed(delay);
        final nextDelayMs = delay.inMilliseconds * 2;
        final limitedMs = nextDelayMs.clamp(
          _initialBackoff.inMilliseconds,
          _maxBackoff.inMilliseconds,
        );
        delay = Duration(milliseconds: limitedMs);
      }
    }

    snapshotSubscription = _snapshotSource(orderId).listen(
      (status) async {
        firstSnapshotSeen = true;
        await emit(status);
      },
      onError: (_) {
        unawaited(startPolling());
      },
      onDone: () {
        if (!firstSnapshotSeen) {
          unawaited(startPolling());
        }
      },
    );

    graceTimer = Timer(_snapshotGracePeriod, () {
      if (!firstSnapshotSeen) {
        unawaited(startPolling());
      }
    });

    controller.onCancel = () async {
      graceTimer?.cancel();
      await snapshotSubscription?.cancel();
    };

    return controller.stream;
  }
}
