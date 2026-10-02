# ПР4 — кратко для отчёта

- Адрес API: `lib/core/config.dart`, `--dart-define=API_BASE_URL=...`
- Dio: `lib/core/api_client.dart` (интерсептор 4xx → `ApiException`, лог в debug, retry GET до 3 раз)
- Репозитории: `lib/repositories/api/*`, интерфейсы ПР2 без изменений
- `CancelToken` в `ProjectListNotifier` / `PartnerListNotifier` при каждой загрузке
- Кэш справочников: `listForSelect` в API-репозиториях категорий, тегов, партнёров
- API: `/projects`, `/partners`, `/tags`, `/categories`, `/volunteers`
- 422 в формах проекта (`code` → поле ISBN), направления (`name`), волонтёра (`email`)
- 409 при удалении направления с проектами
- CORS: сервер `--origin http://localhost:5555`, клиент `--web-port=5555`
- Демо: `?__delay=1500`, `?__fail=500`, остановленный сервер → `NetworkException`
