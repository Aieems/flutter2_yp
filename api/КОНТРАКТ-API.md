# Контракт учебного API — благотворительный фонд

Базовый URL: `http://localhost:8080/api` (параметр `--dart-define=API_BASE_URL=...`).

| Сущность | Путь API |
|----------|----------|
| Проект | `/projects` |
| Партнёр | `/partners` |
| Тег | `/tags` |
| Направление | `/categories` |
| Волонтёр | `/volunteers` |

## Проект

- **GET** `/projects` — `search`, `tagId`, `categoryId`, `yearFrom`, `yearTo`, `sort`, `page`, `size`, `includeDeleted`, `__delay`, `__fail=500`
- **POST/PUT** — тело: `title`, `code`, `year`, `goalAmount`, `categoryId`, `partnerIds`, `tagIds`, `volunteersTotal`, `volunteersActive`
- **422** — `{ "errors": { "code": "..." } }`
- Ответ чтения может содержать `category`, `partners`, `tags`

## Направление

- **DELETE** `/categories/:id` — **409**, если есть связанные проекты
- **422** — дубликат `name`

## Волонтёр

- Тело: `email`, `firstName`, `lastName`, `card` { `cardNumber`, `issuedAt`, `expiresAt` }
- **422** — дубликат `email`

## Общее

- **GET** `/__health` — `{ "ok": true }`
- Мягкое удаление: **DELETE**; жёсткое: `?hard=true`
- **POST** `/:id/restore`
- **POST** `/bulk-delete` — `{ "ids": [] }` → `{ "deleted": n }`

CORS: `node mock-server.js --port 8080 --origin http://localhost:5555`
