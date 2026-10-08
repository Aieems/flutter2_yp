# Supabase — первый запуск (SQL Editor)

## 1. SQL Editor (пошагово)

1. [Supabase Dashboard](https://supabase.com/dashboard) → ваш проект → **SQL Editor** → **New query**.
2. На компьютере откройте **`api/supabase/00_reset_fund_tables.sql`** → **Ctrl+A**, **Ctrl+C** (если база уже «ломалась» от прошлых Run).
3. Вставьте в Supabase → **Run** → в Results должно быть `reset_ok`.
4. **New query** снова.
5. Откройте **`api/supabase/01_schema_and_seed.sql`** → **Ctrl+A**, **Ctrl+C**.
6. В Supabase вставьте (**Ctrl+A** в редакторе, **Ctrl+V**). **Не выделяйте одну строку** — Run выполняет **выделенный** фрагмент, поэтому часто видна только одна строка `setval`.
7. **Run** (Ctrl+Enter).
8. В **Results** должна быть таблица **5 строк** `verify` / `projects` / `rows` = **5** (и categories = 5, partners = 8, …).

Отдельная проверка: файл **`api/supabase/02_verify_counts.sql`** → Run → та же таблица счётчиков.

Если в Results **1 row** и `setval` — вы запустили не весь скрипт. Снимите выделение, **Ctrl+A** в редакторе Supabase, Run ещё раз.

## 2. Проверка

**Table Editor** — должны появиться таблицы:

- `profiles`
- `categories`, `partners`, `tags`, `volunteers`, `projects`

В `projects` — 5 строк, в `categories` — 5 строк.

## 3. Ключи API (у вас уже скопированы)

**Project Settings → API**:

| Поле | Куда |
|------|------|
| Project URL | позже `--dart-define=SUPABASE_URL=...` |
| anon public | `--dart-define=SUPABASE_ANON_KEY=...` |

Пароль базы данных и **service_role** key в Flutter **не** вставляйте.

## 4. Пользователи и роли

Учётки `volunteer1` / `coord1` / `admin` из мока **сами не появятся** — их нужно создать в Supabase:

1. **Authentication → Users → Add user** (email + пароль),  
   или регистрация из приложения (когда подключите `supabase_flutter`).

2. После регистрации сработает триггер и строка появится в `profiles` с ролью `volunteer`.

3. Чтобы сделать координатора или админа: **Table Editor → profiles** → поле `role` → `coordinator` или `admin` (или SQL):

```sql
update public.profiles
set role = 'admin'
where username = 'ваш_логин';
```

## 5. Auth для Flutter (следующий шаг)

При регистрации через Supabase Auth передавайте metadata (когда будет код):

- `username`
- `display_name`

Email в Supabase обязателен: можно `логин@fund.local`.

## 6. Запуск Flutter с Supabase

В Supabase: **Authentication → Providers → Email** — для учебного проекта отключите **Confirm email**, иначе после регистрации вход не сработает до подтверждения.

**Authentication → URL configuration** — добавьте Site URL: `http://localhost:5555` и для Pages позже `https://aieems.github.io`.

```powershell
cd C:\Users\Admin\Desktop\technical\year4\flutter_yp\flutter_2
flutter pub get
flutter run -d chrome --web-port=5555 `
  --dart-define=USE_SUPABASE=true `
  --dart-define=SUPABASE_URL=https://ВАШ_ПРОЕКТ.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Логин в приложении — **логин** (не email): в Supabase уходит `логин@fund.local`.

Роль координатора/админа: **Table Editor → profiles → role**.

Ключи в репозиторий **не коммитьте**.

## 7. Сайт на GitHub Pages без консоли

1. **Supabase → Authentication → URL configuration**
   - **Site URL:** `https://aieems.github.io/flutter2_yp/` (или ваш Pages-URL)
   - **Redirect URLs:** добавьте  
     `https://aieems.github.io/flutter2_yp/**`  
     `https://aieems.github.io/**`

2. **GitHub → репозиторий `flutter2_yp` → Settings → Secrets and variables → Actions → New repository secret**
   - `SUPABASE_URL` = Project URL (например `https://xxxx.supabase.co`)
   - `SUPABASE_ANON_KEY` = anon public key (длинный `eyJ...`)

3. **Закоммитьте и push** в `main` (или **Actions → Build and deploy Flutter Web → Run workflow**).

4. Дождитесь зелёного job **build** и **deploy**.

5. Откройте в браузере: **https://aieems.github.io/flutter2_yp/login**  
   Регистрация/вход идут в Supabase; `flutter run` на ПК не нужен.

Если Secrets **не** добавлены, CI собирает старый режим `USE_API=false` (данные только в браузере). После добавления Secrets перезапустите workflow — следующая сборка уже с Supabase.
