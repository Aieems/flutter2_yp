# Клиент благотворительного фонда (ПР2–ПР6)

## ПР4 — REST API

### 1. Сервер

```bash
cd api
node mock-server.js --port 8080 --origin http://localhost:5555
```

Проверка: [http://localhost:8080/api/__health](http://localhost:8080/api/__health)

### 2. Клиент (фиксированный порт для CORS)

```bash
flutter pub get
flutter run -d chrome --web-port=5555
```

Другой адрес API:

```bash
flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
```

Локальное хранилище без сервера:

```bash
flutter run -d chrome --web-port=5555 --dart-define=USE_API=false
```

### 3. Тесты репозитория

```bash
flutter test test/api_project_repository_test.dart
```

## ПР5 — вход, роли, защита маршрутов

Сервер (JWT-подобные токены, роли на эндпоинтах):

```bash
cd api
node mock-server.js --port 8080 --origin http://localhost:5555
# короткий access-токен для проверки refresh:
node mock-server.js --port 8080 --origin http://localhost:5555 --ttl 60
```

Клиент: `/login`, `/register`, redirect в `go_router`, `AuthNotifier` + `shared_preferences`, авто-refresh по 401, неактивность 3 мин (предупреждение за 30 с), макс. сессия 8 ч.

Учётки: `volunteer1` / `VolunteeR1!`, `coord1` / `Coordinat0r!`, `admin` / `Admin123!`.

Отчёт и демо п.17: [docs/PR5-otchet-kratko.md](docs/PR5-otchet-kratko.md).

Тесты: `flutter test test/role_access_test.dart`

## ПР6 — адаптив, сборка, GitHub Pages

Адаптив: `lib/core/breakpoints.dart`, `AdaptiveAppShell` (низ &lt;768, rail ≥768, таблицы ≥1280).

```bash
flutter build web --release --base-href /flutter2_yp/
cp build/web/index.html build/web/404.html
flutter build web --release --wasm
flutter test
flutter analyze
dart format lib test
```

CI: `.github/workflows/deploy-web.yml`. Краткий отчёт: [docs/PR6-otchet-kratko.md](docs/PR6-otchet-kratko.md).
