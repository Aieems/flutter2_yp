# ПР2 — благотворительный фонд (отчётные фрагменты)

## Ошибка в `deleteMany` (п. 7, оценка «4»)

В учебном фрагменте для книг было:

```dart
final i = _books.indexWhere((b) => b.id == id && !b[i].isDeleted);
```

Опечатка: вместо обращения к элементу списка `_books[i]` или к параметру лямбды `b.isDeleted` использовано `b[i]` — у модели `Book`/`Project` нет оператора `[]`, код не компилируется.

**Исправление:**

```dart
final i = _projects.indexWhere((p) => p.id == id && !p.isDeleted);
```

## Схема слоёв

```
screens  →  state (ChangeNotifier)  →  repositories (interface)
                ↓                              ↓
            widgets                      in_memory_* (данные)
                ↓
            models (Project, Partner, PageResult, *Query)
```

Экраны не вызывают репозиторий напрямую (кроме карточки детали — чтение одной записи). Списки работают через `ProjectListNotifier` / `PartnerListNotifier`.

## Зачем `EntityTable<T>`

Таблицы проектов и партнёров отличаются только набором колонок и действиями в строке. Обобщённый виджет принимает `TableColumnSpec<T>` и устраняет дублирование разметки `DataTable`, сортировки по заголовку и чекбоксов выбора.

## Соответствие предметной области

| Задание (библиотека) | Реализация (фонд) |
|---------------------|-------------------|
| Book | Project (проект сбора / программа) |
| Author | Partner (партнёр организации) |
| genreId | тег проекта (`genreId` в URL) |
| publisherId | направление фонда (`publisherId` в URL) |
| ISBN | код проекта `code` |
| pages | `goalAmount` (цель сбора) |

Пример адреса: `/projects?search=лес&genreId=2&publisherId=3&sort=year,desc&page=2&size=25`

Демонстрация ошибки загрузки: в поиске проектов введите `!!!error`.
