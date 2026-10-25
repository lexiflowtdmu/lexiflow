import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/cloudflare_service.dart';

// ── Models ─────────────────────────────────────────────────────

class FarmPlot extends Equatable {
  final String id;
  final int slotIndex;
  final String? cropType;
  final int wordsNeeded;
  final int wordsProgress;
  final int stage; // 0=empty 1=growing 2=ready

  const FarmPlot({
    required this.id,
    required this.slotIndex,
    this.cropType,
    required this.wordsNeeded,
    required this.wordsProgress,
    required this.stage,
  });

  factory FarmPlot.fromJson(Map<String, dynamic> j) => FarmPlot(
        id: j['id'] as String,
        slotIndex: (j['slot_index'] as num).toInt(),
        cropType: j['crop_type'] as String?,
        wordsNeeded: (j['words_needed'] as num).toInt(),
        wordsProgress: (j['words_progress'] as num).toInt(),
        stage: (j['stage'] as num).toInt(),
      );

  @override
  List<Object?> get props => [id, slotIndex, cropType, wordsNeeded, wordsProgress, stage];
}

class OrderItem extends Equatable {
  final String type;
  final int qty;
  const OrderItem({required this.type, required this.qty});
  factory OrderItem.fromJson(Map<String, dynamic> j) =>
      OrderItem(type: j['type'] as String, qty: (j['qty'] as num).toInt());
  @override
  List<Object?> get props => [type, qty];
}

class FarmOrder extends Equatable {
  final String id;
  final List<OrderItem> items;
  final int rewardCoins;
  final int rewardXp;
  final String expiresAt;

  const FarmOrder({
    required this.id,
    required this.items,
    required this.rewardCoins,
    required this.rewardXp,
    required this.expiresAt,
  });

  factory FarmOrder.fromJson(Map<String, dynamic> j) => FarmOrder(
        id: j['id'] as String,
        items: ((j['items'] as List?) ?? [])
            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        rewardCoins: (j['reward_coins'] as num).toInt(),
        rewardXp: (j['reward_xp'] as num).toInt(),
        expiresAt: j['expires_at'] as String,
      );

  @override
  List<Object?> get props => [id, items, rewardCoins, rewardXp, expiresAt];
}

// ── Events ─────────────────────────────────────────────────────

abstract class FarmEvent extends Equatable {
  const FarmEvent();
  @override
  List<Object?> get props => [];
}

class FarmLoadRequested extends FarmEvent {}

class FarmPlantCrop extends FarmEvent {
  final int slotIndex;
  final String cropType;
  const FarmPlantCrop(this.slotIndex, this.cropType);
  @override
  List<Object?> get props => [slotIndex, cropType];
}

class FarmHarvestPlot extends FarmEvent {
  final String plotId;
  const FarmHarvestPlot(this.plotId);
  @override
  List<Object?> get props => [plotId];
}

class FarmFulfillOrder extends FarmEvent {
  final String orderId;
  const FarmFulfillOrder(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class FarmSkipOrder extends FarmEvent {
  final String orderId;
  const FarmSkipOrder(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

// ── States ─────────────────────────────────────────────────────

abstract class FarmState extends Equatable {
  const FarmState();
  @override
  List<Object?> get props => [];
}

class FarmInitial extends FarmState {}
class FarmLoading extends FarmState {}

class FarmLoaded extends FarmState {
  final List<FarmPlot> plots;
  final Map<String, int> inventory;
  final List<FarmOrder> orders;
  final int coins;
  final Map<String, dynamic> cropCatalog;

  const FarmLoaded({
    required this.plots,
    required this.inventory,
    required this.orders,
    required this.coins,
    required this.cropCatalog,
  });

  @override
  List<Object?> get props => [plots, inventory, orders, coins, cropCatalog];
}

class FarmError extends FarmState {
  final String message;
  const FarmError(this.message);
  @override
  List<Object?> get props => [message];
}

class FarmActionSuccess extends FarmState {
  final String message;
  final FarmLoaded refreshed;
  const FarmActionSuccess(this.message, this.refreshed);
  @override
  List<Object?> get props => [message, refreshed];
}

// ── Bloc ───────────────────────────────────────────────────────

class FarmBloc extends Bloc<FarmEvent, FarmState> {
  final CloudflareService _service;

  FarmBloc({required CloudflareService service})
      : _service = service,
        super(FarmInitial()) {
    on<FarmLoadRequested>(_onLoad);
    on<FarmPlantCrop>(_onPlant);
    on<FarmHarvestPlot>(_onHarvest);
    on<FarmFulfillOrder>(_onFulfill);
    on<FarmSkipOrder>(_onSkip);
  }

  Future<void> _onLoad(FarmLoadRequested _, Emitter<FarmState> emit) async {
    emit(FarmLoading());
    try {
      emit(_parseLoaded(await _service.getFarmState()));
    } catch (e) {
      emit(FarmError(e.toString()));
    }
  }

  Future<void> _onPlant(FarmPlantCrop event, Emitter<FarmState> emit) async {
    try {
      await _service.farmPlant(event.slotIndex, event.cropType);
      emit(_parseLoaded(await _service.getFarmState()));
    } catch (e) {
      emit(FarmError(e.toString()));
    }
  }

  Future<void> _onHarvest(FarmHarvestPlot event, Emitter<FarmState> emit) async {
    try {
      await _service.farmHarvest(event.plotId);
      emit(_parseLoaded(await _service.getFarmState()));
    } catch (e) {
      emit(FarmError(e.toString()));
    }
  }

  Future<void> _onFulfill(FarmFulfillOrder event, Emitter<FarmState> emit) async {
    try {
      final result = await _service.farmFulfillOrder(event.orderId);
      final loaded = _parseLoaded(await _service.getFarmState());
      final earned = (result['coins_earned'] as num?)?.toInt() ?? 0;
      emit(FarmActionSuccess('+$earned 🪙 Đơn hàng hoàn thành!', loaded));
    } catch (e) {
      emit(FarmError(e.toString()));
    }
  }

  Future<void> _onSkip(FarmSkipOrder event, Emitter<FarmState> emit) async {
    try {
      await _service.farmSkipOrder(event.orderId);
      emit(_parseLoaded(await _service.getFarmState()));
    } catch (e) {
      emit(FarmError(e.toString()));
    }
  }

  FarmLoaded _parseLoaded(Map<String, dynamic> data) {
    final invRaw = (data['inventory'] as Map<String, dynamic>?) ?? {};
    return FarmLoaded(
      plots: ((data['plots'] as List?) ?? [])
          .map((p) => FarmPlot.fromJson(p as Map<String, dynamic>))
          .toList(),
      inventory: invRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
      orders: ((data['orders'] as List?) ?? [])
          .map((o) => FarmOrder.fromJson(o as Map<String, dynamic>))
          .toList(),
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      cropCatalog: (data['crop_catalog'] as Map<String, dynamic>?) ?? {},
    );
  }
}
