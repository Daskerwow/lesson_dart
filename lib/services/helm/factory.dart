import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider.dart';

/// Провайдер синхронного стора: состояние меняется только через
/// [SyncCommand] / [SyncSideEffect], без IO.
///
/// ```dart
/// final counterProvider = helmSyncProvider<int, CounterEffect>(
///   initial: 0,
///   name: 'counter',
/// );
/// ```
NotifierProvider<HelmSyncNotifier<S, E>, S> helmSyncProvider<S, E>({
  required S initial,
  required String name,
  bool isAutoDispose = true,
}) => NotifierProvider<HelmSyncNotifier<S, E>, S>(
  () => HelmSyncNotifier<S, E>(initial),
  isAutoDispose: isAutoDispose,
  name: name,
);

/// Провайдер асинхронного стора: начальное состояние грузится через [load]
/// (с доступом к DI через [Ref]), дальнейшие мутации — через [AsyncCommand] /
/// [AsyncSideEffect].
///
/// ```dart
/// final themeProvider = helmAsyncProvider<ThemeState, ThemeEffect>(
///   load: (ref) => ref.read(themeLocalStoreDI).getData(),
///   name: 'theme',
/// );
/// ```
AsyncNotifierProvider<HelmAsyncNotifier<S, E>, S> helmAsyncProvider<S, E>({
  required Future<S> Function(Ref ref) load,
  required String name,
  bool isAutoDispose = true,
}) => AsyncNotifierProvider<HelmAsyncNotifier<S, E>, S>(
  () => HelmAsyncNotifier<S, E>(load),
  isAutoDispose: isAutoDispose,
  name: name,
);

/// Провайдер потокового стора: тонкая обёртка над [source]. Если нужны свои
/// методы (`sendFilter`, `startCalculate` и т.п.) — наследуйтесь от
/// [HelmStreamNotifier] напрямую, см. его докстринг.
///
/// ```dart
/// final industrialProvider = helmStreamProvider<Dashboard, void>(
///   source: (ref) => ref.watch(getIndustrialDataUse).execute(),
///   name: 'industrial',
/// );
/// ```
StreamNotifierProvider<HelmStreamNotifier<S, E>, S> helmStreamProvider<S, E>({
  required Stream<S> Function(Ref ref) source,
  required String name,
  bool isAutoDispose = true,
}) => StreamNotifierProvider<HelmStreamNotifier<S, E>, S>(
  () => HelmStreamNotifier<S, E>(source),
  isAutoDispose: isAutoDispose,
  name: name,
);
