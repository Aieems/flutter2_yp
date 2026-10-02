# Клиент благотворительного фонда (ПР2–ПР4)

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

Контракт: [api/КОНТРАКТ-API.md](api/КОНТРАКТ-API.md)
