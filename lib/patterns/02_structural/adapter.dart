/// ============================================================================
/// ПАТТЕРН: ADAPTER (Адаптер)
/// Категория: Структурный (Structural) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Преобразует интерфейс одного класса в интерфейс, ожидаемый клиентом,
/// позволяя работать вместе классам с несовместимыми интерфейсами.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Интеграция стороннего SDK/legacy-кода, интерфейс которого нельзя
///   изменить, с вашей кодовой базой, ожидающей другой контракт.
/// - Миграция между версиями API, когда старый и новый код должны
///   сосуществовать.
/// - Продакшен-кейс: у вас есть собственный интерфейс `AnalyticsService`,
///   а сторонние SDK (Firebase, Amplitude, Mixpanel) имеют разные API —
///   адаптеры приводят их к единому контракту.
library;

import 'package:meta/meta.dart';

/// ЦЕЛЕВОЙ ИНТЕРФЕЙС (Target) — то, что ожидает наше приложение.
abstract class const AnalyticsService() {
  void logEvent(String name, Map<String, Object?> params);
  void setUserId(String userId);
}

// --- АДАПТИРУЕМЫЕ (Adaptee) сторонние SDK с чужими, несовместимыми API ---

/// Пример стороннего SDK Firebase Analytics с собственным API.
@immutable
class const FirebaseAnalyticsSdk() {
  void logFirebaseEvent(String eventName, Map<String, dynamic> parameters) {
    print('[Firebase] event="$eventName" params=$parameters');
  }

  void setFirebaseUserProperty(String key, String value) {
    print('[Firebase] user property $key=$value');
  }
}

/// Пример другого стороннего SDK Mixpanel с ещё одним, другим API.
@immutable
class const MixpanelSdk() {
  void track(String event, {Map<String, dynamic>? properties}) {
    print('[Mixpanel] track "$event" props=${properties ?? {}}');
  }

  void identify(String distinctId) {
    print('[Mixpanel] identify $distinctId');
  }
}

/// АДАПТЕР для Firebase: приводит FirebaseAnalyticsSdk к интерфейсу
/// AnalyticsService, ожидаемому приложением.
@immutable
class const FirebaseAnalyticsAdapter(final FirebaseAnalyticsSdk _sdk)
    implements AnalyticsService {
  @override
  void logEvent(String name, Map<String, Object?> params) {
    _sdk.logFirebaseEvent(name, params);
  }

  @override
  void setUserId(String userId) {
    _sdk.setFirebaseUserProperty('user_id', userId);
  }
}

/// АДАПТЕР для Mixpanel: та же роль, другой Adaptee.
@immutable
class const MixpanelAdapter(final MixpanelSdk _sdk)
    implements AnalyticsService {
  @override
  void logEvent(String name, Map<String, Object?> params) {
    _sdk.track(name, properties: params);
  }

  @override
  void setUserId(String userId) {
    _sdk.identify(userId);
  }
}

/// Композитный сервис: рассылает события во все подключённые аналитики
/// одновременно через единый интерфейс — приложению не важно, сколько
/// и какие именно SDK подключены "под капотом".
@immutable
class const CompositeAnalyticsService(final List<AnalyticsService> _services)
    implements AnalyticsService {
  @override
  void logEvent(String name, Map<String, Object?> params) {
    /// Каждый адаптер вызовет свой logEvent()
    for (final s in _services) {
      s.logEvent(name, params);
    }
  }

  @override
  void setUserId(String userId) {
    /// Каждый адаптер вызовет свой setUserId()
    for (final s in _services) {
      s.setUserId(userId);
    }
  }
}

void main() {
  final analytics = CompositeAnalyticsService(
    /// Даем список адаптеров
    [
      const FirebaseAnalyticsAdapter(FirebaseAnalyticsSdk()),
      const MixpanelAdapter(MixpanelSdk()),
    ],
  );

  /// Рассылаем сообщения всем Sdk которые мы зарегистрировали
  analytics.setUserId('user_123');
  analytics.logEvent('purchase_completed', {
    'amount': 49.99,
    'currency': 'USD',
  });
}
