/// Лёгкий типизированный HTTP/HTTPS API-клиент.
///
/// Запросы, интерсепторы, единая иерархия ошибок, аутентификация,
/// пагинация — и ничего лишнего (без WebSocket/SSE/кэша/security-слоя).
library;

// ─── Core ───────────────────────────────────────────────────────────────────
export 'src/api/api.dart';
export 'src/entities/entities.dart';
export 'src/pagination.dart';
export 'src/repositories/repositories.dart';
export 'src/cammands/cammands.dart';
