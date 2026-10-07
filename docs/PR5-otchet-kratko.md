# ПР5 — аутентификация, роли, защита маршрутов (фонд)

## Роли (аналог библиотеки)

| ПР5 | Фонд | Доступ |
|-----|------|--------|
| Читатель | **Волонтёр** (`volunteer`) | Просмотр проектов и партнёров |
| Библиотекарь | **Координатор** (`coordinator`) | CRUD проектов, партнёров, направлений, тегов, волонтёров |
| Администратор | **admin** | Пользователи, статистика, жёсткое удаление и восстановление |

## Учётные записи (mock-server)

- `volunteer1` / `VolunteeR1!`
- `coord1` / `Coordinat0r!`
- `admin` / `Admin123!`

## Запуск для проверки «5»

```bash
cd api
node mock-server.js --port 8080 --origin http://localhost:5555 --ttl 60
```

```bash
flutter run -d chrome --web-port=5555
```

Короткий TTL access-токена проверяет автообновление по 401.

## П.17 — клиент ≠ сервер

1. Войти как `volunteer1`.
2. DevTools → Application → Local Storage → ключ `auth_ui_profile`.
3. Заменить `"role":"volunteer"` на `"role":"admin"`.
4. Нажать **обновить профиль** (иконка ↻ в шапке) — появятся админ-кнопки и разделы.
5. Открыть «Пользователи» или выполнить POST `/api/projects` — в Network **403**, SnackBar «Недостаточно прав».

Токены (`auth_access_token`) не менялись: сервер читает роль из подписанного access-токена.

## Тесты ролей

```bash
flutter test test/role_access_test.dart
```
