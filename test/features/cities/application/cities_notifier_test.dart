import '../../../helpers/fixtures.dart';
import '../../../helpers/isar_test_helper.dart';
import '../../../helpers/test_bootstrap.dart';
import '../../../helpers/throwing_cities_repository.dart';
import '../../../helpers/widget_test_harness.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainy/core/di/provider_refs.dart';
import 'package:rainy/data/models/db.dart';
import 'package:rainy/data/repositories/cities_repository.dart';
import 'package:rainy/features/cities/application/cities_notifier.dart';

void main() {
  group('CitiesNotifier', () {
    late TestBootstrapContext ctx;

    setUp(() async {
      ctx = await createTestBootstrap();
      setTestConnectivity(true);
    });

    tearDown(() async {
      await ctx.dispose();
    });

    ProviderContainer createContainer({List overrides = const []}) {
      final container = createTestContainer(
        bootstrap: ctx.bootstrap,
        overrides: [
          weatherRemoteDatasourceProvider.overrideWithValue(
            createFakeWeatherRemoteDatasource(),
          ),
          ...overrides,
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'refresh shows cached cards while stale network update runs',
      () async {
        final card = completeWeatherCard(
          timestamp: DateTime.now().subtract(const Duration(hours: 24)),
        );
        await seedWeatherCard(ctx.isarContext.isar, card);

        final gate = Completer<void>();
        final delayedRepo = _DelayedCitiesRepository(
          ctx.isarContext.isar,
          createFakeWeatherRemoteDatasource(),
          gate,
        );

        final container = createContainer(
          overrides: [citiesRepositoryProvider.overrideWithValue(delayedRepo)],
        );

        final refreshFuture = container
            .read(citiesNotifierProvider.notifier)
            .refreshIfStale();

        await _pumpUntil(
          () => container.read(citiesNotifierProvider).isRefreshing,
        );

        final midState = container.read(citiesNotifierProvider);
        expect(midState.isLoading, isFalse);
        expect(midState.cards, hasLength(1));
        expect(midState.cards.first.city, 'Moscow');
        expect(midState.isRefreshing, isTrue);

        gate.complete();
        await refreshFuture;

        final finalState = container.read(citiesNotifierProvider);
        expect(finalState.isRefreshing, isFalse);
        expect(finalState.cards, hasLength(1));
      },
    );

    test('refreshIfStale skips network when cache is still fresh', () async {
      await seedWeatherCard(ctx.isarContext.isar, completeWeatherCard());

      final container = createContainer();

      await container.read(citiesNotifierProvider.notifier).refreshIfStale();

      final state = container.read(citiesNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.cards, hasLength(1));
      expect(state.isRefreshing, isFalse);
    });

    test('refresh loads cards from database', () async {
      await seedWeatherCard(ctx.isarContext.isar, completeWeatherCard());

      final container = createContainer();

      await container.read(citiesNotifierProvider.notifier).refresh(all: false);

      final state = container.read(citiesNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.cards, hasLength(1));
      expect(state.cards.first.city, 'Moscow');
    });

    test('deleteCard removes card from state', () async {
      final card = await seedWeatherCard(
        ctx.isarContext.isar,
        completeWeatherCard(),
      );

      final container = createContainer();

      await container.read(citiesNotifierProvider.notifier).deleteCard(card);

      final state = container.read(citiesNotifierProvider);
      expect(state.cards, isEmpty);
      expect(state.loadError, isFalse);
      expect(
        await container.read(citiesRepositoryProvider).getAllSorted(),
        isEmpty,
      );
    });

    test(
      'refresh sets loadError when database read fails with cards',
      () async {
        final card = await seedWeatherCard(
          ctx.isarContext.isar,
          completeWeatherCard(),
        );

        final throwingRepo = ThrowingCitiesRepository(
          ctx.isarContext.isar,
          createFakeWeatherRemoteDatasource(),
        );

        final container = createContainer(
          overrides: [citiesRepositoryProvider.overrideWithValue(throwingRepo)],
        );

        await container
            .read(citiesNotifierProvider.notifier)
            .refresh(all: false);

        expect(card.id, isNotNull);

        throwingRepo.throwOnGetAllSorted = true;
        await container
            .read(citiesNotifierProvider.notifier)
            .refresh(all: false);

        final state = container.read(citiesNotifierProvider);
        expect(state.loadError, isTrue);
        expect(state.cards, hasLength(1));
        expect(state.cards.first.city, 'Moscow');
      },
    );

    test(
      'deleteCard keeps loadError false when reload fails on empty list',
      () async {
        final card = await seedWeatherCard(
          ctx.isarContext.isar,
          completeWeatherCard(),
        );

        final throwingRepo = ThrowingCitiesRepository(
          ctx.isarContext.isar,
          createFakeWeatherRemoteDatasource(),
        );

        final container = createContainer(
          overrides: [citiesRepositoryProvider.overrideWithValue(throwingRepo)],
        );

        await container
            .read(citiesNotifierProvider.notifier)
            .refresh(all: false);

        throwingRepo.throwOnGetAllSorted = true;
        await container.read(citiesNotifierProvider.notifier).deleteCard(card);

        final state = container.read(citiesNotifierProvider);
        expect(state.cards, isEmpty);
        expect(state.loadError, isFalse);
      },
    );

    test(
      'deleteCard is not undone by a cache read that started first',
      () async {
        final card = await seedWeatherCard(
          ctx.isarContext.isar,
          completeWeatherCard(),
        );

        final gatedRepo = _GatedLoadCitiesRepository(
          ctx.isarContext.isar,
          createFakeWeatherRemoteDatasource(),
        );

        final container = createContainer(
          overrides: [citiesRepositoryProvider.overrideWithValue(gatedRepo)],
        );

        final notifier = container.read(citiesNotifierProvider.notifier);
        await notifier.refresh(all: false);
        expect(container.read(citiesNotifierProvider).cards, hasLength(1));

        final gate = Completer<void>();
        gatedRepo.gate = gate;
        final pendingLoad = notifier.loadFromCache();
        await _pumpUntil(() => gatedRepo.readStarted);

        final emittedCardCounts = <int>[];
        container.listen(
          citiesNotifierProvider,
          (_, next) => emittedCardCounts.add(next.cards.length),
        );

        final pendingDelete = notifier.deleteCard(card);
        gate.complete();
        await pendingLoad;
        await pendingDelete;

        expect(emittedCardCounts, isNotEmpty);
        expect(emittedCardCounts, everyElement(isZero));

        final state = container.read(citiesNotifierProvider);
        expect(state.cards, isEmpty);
        expect(state.loadError, isFalse);
        expect(await ctx.isarContext.isar.weatherCards.count(), 0);
      },
    );

    test('addCard requires internet', () async {
      setTestConnectivity(false);

      final container = createContainer();

      await container
          .read(citiesNotifierProvider.notifier)
          .addCard(55.75, 37.62, 'Moscow', 'Moscow Oblast');

      expect(container.read(citiesNotifierProvider).cards, isEmpty);
    });

    test('reorder updates card order in state', () async {
      await seedWeatherCard(
        ctx.isarContext.isar,
        completeWeatherCard(id: 1, index: 0),
      );
      await seedWeatherCard(
        ctx.isarContext.isar,
        completeWeatherCard(id: 2, index: 1)
          ..city = 'Berlin'
          ..district = 'Berlin',
      );

      final container = createContainer();

      final notifier = container.read(citiesNotifierProvider.notifier);
      await notifier.refresh(all: false);
      await notifier.reorder(0, 2);

      final cards = container.read(citiesNotifierProvider).cards;
      expect(cards, hasLength(2));
      expect(cards.first.city, 'Berlin');
      expect(cards.last.city, 'Moscow');
    });

    test('addCard online persists new city', () async {
      final container = createContainer();

      await container
          .read(citiesNotifierProvider.notifier)
          .addCard(52.52, 13.41, 'Berlin', 'Berlin');

      final cards = container.read(citiesNotifierProvider).cards;
      expect(cards, hasLength(1));
      expect(cards.first.city, 'Berlin');
    });

    test('updateCard refreshes card from remote', () async {
      final card = await seedWeatherCard(
        ctx.isarContext.isar,
        completeWeatherCard(),
      );

      final container = createContainer();
      await container.read(citiesNotifierProvider.notifier).refresh(all: false);

      await container.read(citiesNotifierProvider.notifier).updateCard(card);

      expect(container.read(citiesNotifierProvider).cards.first.city, 'Moscow');
    });
  });
}

class _GatedLoadCitiesRepository extends CitiesRepository {
  _GatedLoadCitiesRepository(super.isar, super.remote);

  Completer<void>? gate;
  var readStarted = false;

  @override
  Future<List<WeatherCard>> getAllSorted() async {
    final pending = gate;
    if (pending != null) {
      gate = null;
      readStarted = true;
      await pending.future;
    }
    return super.getAllSorted();
  }
}

Future<void> _pumpUntil(bool Function() condition, {int maxTurns = 200}) async {
  for (var turn = 0; turn < maxTurns; turn++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met within $maxTurns event loop turns');
}

class _DelayedCitiesRepository extends CitiesRepository {
  _DelayedCitiesRepository(super.isar, super.remote, this._gate);

  final Completer<void> _gate;

  @override
  Future<WeatherCard> fetchCard(
    double lat,
    double lon,
    String city,
    String district,
  ) async {
    await _gate.future;
    return super.fetchCard(lat, lon, city, district);
  }
}
