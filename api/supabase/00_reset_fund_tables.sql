-- Сброс таблиц фонда (profiles и auth.users не удаляются).
-- SQL Editor: вставить весь файл → Ctrl+A → Run

drop table if exists public.projects cascade;
drop table if exists public.tags cascade;
drop table if exists public.volunteers cascade;
drop table if exists public.partners cascade;
drop table if exists public.categories cascade;

select 'reset_ok' as status;
