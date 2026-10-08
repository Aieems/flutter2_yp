-- Проверка после установки. Ожидается: categories=5, projects=5, partners=8, tags=8, volunteers=3
select 'categories' as table_name, count(*)::bigint as rows from public.categories
union all select 'partners', count(*) from public.partners
union all select 'tags', count(*) from public.tags
union all select 'volunteers', count(*) from public.volunteers
union all select 'projects', count(*) from public.projects
order by 1;
