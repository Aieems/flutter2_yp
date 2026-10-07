# ПР6 — адаптив, сборка, публикация, тесты

## Адаптив (360 / 768 / 1280 / 1920)

- `< 768`: нижняя `NavigationBar`, списки **карточками** (`AppBreakpoints.useTableOnLists`).
- `≥ 768`: боковая `NavigationRail` (подписи только у выбранного пункта).
- `≥ 1280`: **таблицы** вместо карточек, подписи у всех пунктов rail.
- `≥ 1920`: контент ограничен `1400px` (`ResponsiveContent`).

Формы: `ConstrainedBox` 720px, год — поле 160px. Диалоги — max 480px. Фильтры проектов — `Wrap`.

## Сборка

```bash
flutter build web --release
cd build/web && python -m http.server 8000
```

Подкаталог + API:

```bash
flutter build web --release --base-href /flutter_2/ \
  --dart-define=API_BASE_URL=http://localhost:8080/api
cp build/web/index.html build/web/404.html
```

Wasm:

```bash
flutter build web --release --wasm
```

Сравните размер `build/web` (папка целиком) и время первой загрузки в Network (Disable cache).

## Уменьшение сборки

Админ-экраны подключаются через **deferred import** (`admin_screens_deferred.dart`).

## Заглушка загрузки

`web/index.html` — splash до события `flutter-first-frame`.

## CI

`.github/workflows/deploy-web.yml` — analyze, test, build, `404.html`, GitHub Pages.

## Тесты

```bash
flutter test
flutter analyze
dart format --set-exit-if-changed lib test
```

Модульные: validators, Project.fromJson, password, role_access, api repo.  
Виджеты: AsyncListBody, LoginScreen, RoleGate.

## Доступность

Tooltips на иконках AppBar и действиях списков. Управление с клавиатуры — стандартные Material-виджеты.

## Офлайн

`AsyncListBody` — текст ошибки и «Повторить»; `ProjectListNotifier` сохраняет сообщение `NetworkException`.
