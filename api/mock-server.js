

const http = require('http');
const url = require('url');

const args = process.argv.slice(2);
function arg(name, def) {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : def;
}

const PORT = Number(arg('--port', '8080'));
const ALLOWED_ORIGIN = arg('--origin', 'http://localhost:5555');

let nextId = { projects: 23, partners: 9, tags: 9, categories: 6, volunteers: 4 };

const categories = [
  { id: 1, name: 'Дети и образование', deletedAt: null },
  { id: 2, name: 'Медицина', deletedAt: null },
  { id: 3, name: 'Экология', deletedAt: null },
  { id: 4, name: 'Социальная помощь', deletedAt: null },
  { id: 5, name: 'Культура', deletedAt: null },
];

const tags = [
  { id: 1, name: 'Сбор средств', categoryId: 1, deletedAt: null },
  { id: 2, name: 'Волонтёрство', categoryId: 4, deletedAt: null },
  { id: 3, name: 'Срочная помощь', categoryId: 2, deletedAt: null },
  { id: 4, name: 'Долгосрочная программа', categoryId: 1, deletedAt: null },
  { id: 5, name: 'Региональный проект', categoryId: 3, deletedAt: null },
];

const partners = [
  { id: 1, lastName: 'Иванов', firstName: 'Пётр', country: 'Россия', birthYear: 1975, deletedAt: null },
  { id: 2, lastName: 'Smith', firstName: 'John', country: 'США', birthYear: 1980, deletedAt: null },
  { id: 3, lastName: 'Müller', firstName: 'Hans', country: 'Германия', birthYear: 1972, deletedAt: null },
];

const projects = [
  {
    id: 1,
    title: 'Школьные наборы',
    code: 'PRJ-001',
    year: 2022,
    goalAmount: 500000,
    categoryId: 1,
    partnerIds: [1, 2],
    tagIds: [1, 4],
    volunteersTotal: 40,
    volunteersActive: 32,
    deletedAt: null,
  },
  {
    id: 2,
    title: 'Лечение детей',
    code: 'PRJ-002',
    year: 2023,
    goalAmount: 1200000,
    categoryId: 2,
    partnerIds: [1],
    tagIds: [1, 3],
    volunteersTotal: 25,
    volunteersActive: 20,
    deletedAt: null,
  },
];

const volunteers = [
  {
    id: 1,
    lastName: 'Сидорова',
    firstName: 'Анна',
    email: 'anna@example.com',
    card: { cardNumber: 'V-001', issuedAt: '2024-01-15', expiresAt: '2026-01-15' },
    deletedAt: null,
  },
];

function expandProject(p) {
  const category = categories.find((c) => c.id === p.categoryId);
  const linkedPartners = p.partnerIds.map((id) => partners.find((x) => x.id === id)).filter(Boolean);
  const linkedTags = p.tagIds.map((id) => tags.find((x) => x.id === id)).filter(Boolean);
  return { ...p, category, partners: linkedPartners, tags: linkedTags };
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (c) => (data += c));
    req.on('end', () => {
      if (!data) return resolve(null);
      try {
        resolve(JSON.parse(data));
      } catch (e) {
        reject(e);
      }
    });
  });
}

function send(res, status, body, origin) {
  const json = body === undefined ? '' : JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(json);
}

function parseQuery(q) {
  const out = {};
  for (const [k, v] of Object.entries(q)) {
    if (v === 'true') out[k] = true;
    else if (v === 'false') out[k] = false;
    else if (/^\d+$/.test(v)) out[k] = Number(v);
    else out[k] = v;
  }
  return out;
}

function paginate(items, page, size) {
  const p = Math.max(1, page || 1);
  const s = Math.max(1, Math.min(500, size || 10));
  const total = items.length;
  const from = (p - 1) * s;
  return { items: items.slice(from, from + s), page: p, size: s, total };
}

function sortItems(items, sort, getters) {
  if (!sort) return items;
  const [field, dir] = sort.split(',');
  const asc = (dir || 'asc') === 'asc';
  const g = getters[field] || getters.title;
  return [...items].sort((a, b) => {
    const va = g(a);
    const vb = g(b);
    const r =
      typeof va === 'number' && typeof vb === 'number'
        ? va - vb
        : String(va).localeCompare(String(vb), 'ru');
    return asc ? r : -r;
  });
}

async function applyDelayFail(q) {
  if (q.__fail === 500 || q.__fail === '500') {
    throw { status: 500, body: { message: 'Принудительная ошибка __fail=500' } };
  }
  const d = Number(q.__delay);
  if (d > 0) await new Promise((r) => setTimeout(r, Math.min(d, 10000)));
}

function filterProjects(all, q) {
  let rows = all.filter((p) => q.includeDeleted || !p.deletedAt);
  if (q.search === '!!!error') throw { status: 500, body: { message: 'Демонстрация ошибки' } };
  if (q.search) {
    const n = String(q.search).toLowerCase();
    rows = rows.filter(
      (p) => p.title.toLowerCase().includes(n) || p.code.toLowerCase().includes(n),
    );
  }
  if (q.tagId) rows = rows.filter((p) => p.tagIds.includes(Number(q.tagId)));
  if (q.categoryId) rows = rows.filter((p) => p.categoryId === Number(q.categoryId));
  if (q.yearFrom) rows = rows.filter((p) => p.year >= Number(q.yearFrom));
  if (q.yearTo) rows = rows.filter((p) => p.year <= Number(q.yearTo));
  rows = sortItems(rows, q.sort, {
    title: (p) => p.title,
    year: (p) => p.year,
    goalAmount: (p) => p.goalAmount,
  });
  return paginate(rows.map(expandProject), q.page, q.size);
}

function crudList(collection, q, searchFn, sortGetters) {
  let rows = collection.filter((x) => q.includeDeleted || !x.deletedAt);
  if (q.search) {
    const n = String(q.search).toLowerCase();
    rows = rows.filter(searchFn(n));
  }
  rows = sortItems(rows, q.sort, sortGetters);
  return paginate(rows, q.page, q.size);
}

const server = http.createServer(async (req, res) => {
  const origin = ALLOWED_ORIGIN;
  if (req.method === 'OPTIONS') {
    return send(res, 204, undefined, origin);
  }

  const parsed = url.parse(req.url, true);
  const path = parsed.pathname.replace(/\/$/, '') || '/';
  const q = parseQuery(parsed.query);

  try {
    await applyDelayFail(q);

    if (path === '/api/__health') {
      return send(res, 200, { ok: true }, origin);
    }

    // --- projects ---
    if (path === '/api/projects' && req.method === 'GET') {
      return send(res, 200, filterProjects(projects, q), origin);
    }
    if (path === '/api/projects' && req.method === 'POST') {
      const body = await readBody(req);
      const code = (body.code || '').trim();
      if (projects.some((p) => !p.deletedAt && p.code.toLowerCase() === code.toLowerCase())) {
        return send(
          res,
          422,
          { message: 'Ошибка валидации', errors: { code: 'Код проекта (ISBN) уже используется' } },
          origin,
        );
      }
      const id = nextId.projects++;
      const created = {
        id,
        title: body.title,
        code,
        year: body.year,
        goalAmount: body.goalAmount,
        categoryId: body.categoryId,
        partnerIds: body.partnerIds || [],
        tagIds: body.tagIds || [],
        volunteersTotal: body.volunteersTotal ?? 0,
        volunteersActive: body.volunteersActive ?? 0,
        deletedAt: null,
      };
      projects.push(created);
      return send(res, 201, expandProject(created), origin);
    }
    const projectMatch = path.match(/^\/api\/projects\/(\d+)(\/restore)?$/);
    if (projectMatch) {
      const id = Number(projectMatch[1]);
      const idx = projects.findIndex((p) => p.id === id);
      if (idx === -1) return send(res, 404, { message: 'Не найдено' }, origin);
      if (projectMatch[2] === '/restore' && req.method === 'POST') {
        projects[idx].deletedAt = null;
        return send(res, 200, expandProject(projects[idx]), origin);
      }
      if (req.method === 'GET') return send(res, 200, expandProject(projects[idx]), origin);
      if (req.method === 'PUT') {
        const body = await readBody(req);
        const code = (body.code || '').trim();
        if (
          projects.some(
            (p) => p.id !== id && !p.deletedAt && p.code.toLowerCase() === code.toLowerCase(),
          )
        ) {
          return send(
            res,
            422,
            { message: 'Ошибка валидации', errors: { code: 'Код проекта (ISBN) уже используется' } },
            origin,
          );
        }
        projects[idx] = { ...projects[idx], ...body, code, id };
        return send(res, 200, expandProject(projects[idx]), origin);
      }
      if (req.method === 'DELETE') {
        if (q.hard) projects.splice(idx, 1);
        else projects[idx].deletedAt = new Date().toISOString();
        return send(res, 204, undefined, origin);
      }
    }
    if (path === '/api/projects/bulk-delete' && req.method === 'POST') {
      const body = await readBody(req);
      let deleted = 0;
      for (const id of body.ids || []) {
        const p = projects.find((x) => x.id === id && !x.deletedAt);
        if (p) {
          p.deletedAt = new Date().toISOString();
          deleted++;
        }
      }
      return send(res, 200, { deleted }, origin);
    }

    // --- categories (направления) ---
    if (path === '/api/categories' && req.method === 'GET') {
      return send(
        res,
        200,
        crudList(categories, q, (n) => (c) => c.name.toLowerCase().includes(n), {
          name: (c) => c.name,
        }),
        origin,
      );
    }
    if (path === '/api/categories' && req.method === 'POST') {
      const body = await readBody(req);
      const name = (body.name || '').trim();
      if (categories.some((c) => !c.deletedAt && c.name.toLowerCase() === name.toLowerCase())) {
        return send(res, 422, { message: 'Ошибка валидации', errors: { name: 'Название уже существует' } }, origin);
      }
      const created = { id: nextId.categories++, name, deletedAt: null };
      categories.push(created);
      return send(res, 201, created, origin);
    }
    const catMatch = path.match(/^\/api\/categories\/(\d+)(\/restore)?$/);
    if (catMatch) {
      const id = Number(catMatch[1]);
      const idx = categories.findIndex((c) => c.id === id);
      if (idx === -1) return send(res, 404, { message: 'Не найдено' }, origin);
      if (catMatch[2] && req.method === 'POST') {
        categories[idx].deletedAt = null;
        return send(res, 200, categories[idx], origin);
      }
      if (req.method === 'GET') return send(res, 200, categories[idx], origin);
      if (req.method === 'PUT') {
        const body = await readBody(req);
        categories[idx].name = body.name;
        return send(res, 200, categories[idx], origin);
      }
      if (req.method === 'DELETE') {
        const linked = projects.filter((p) => p.categoryId === id && !p.deletedAt).length;
        if (!q.hard && linked > 0) {
          return send(res, 409, { message: `Нельзя удалить: привязано проектов: ${linked}` }, origin);
        }
        if (q.hard) categories.splice(idx, 1);
        else categories[idx].deletedAt = new Date().toISOString();
        return send(res, 204, undefined, origin);
      }
    }
    if (path === '/api/categories/bulk-delete' && req.method === 'POST') {
      const body = await readBody(req);
      let deleted = 0;
      for (const id of body.ids || []) {
        try {
          const linked = projects.filter((p) => p.categoryId === id && !p.deletedAt).length;
          if (linked > 0) continue;
          const c = categories.find((x) => x.id === id && !x.deletedAt);
          if (c) {
            c.deletedAt = new Date().toISOString();
            deleted++;
          }
        } catch (_) {}
      }
      return send(res, 200, { deleted }, origin);
    }

    const simpleRoutes = [
      {
        path: '/api/tags',
        arr: tags,
        key: 'tags',
        search: (n) => (t) => t.name.toLowerCase().includes(n),
      },
      {
        path: '/api/partners',
        arr: partners,
        key: 'partners',
        search: (n) => (p) =>
          p.lastName.toLowerCase().includes(n) || p.country.toLowerCase().includes(n),
      },
      {
        path: '/api/volunteers',
        arr: volunteers,
        key: 'volunteers',
        search: (n) => (v) =>
          v.email.toLowerCase().includes(n) || v.lastName.toLowerCase().includes(n),
      },
    ];

    for (const route of simpleRoutes) {
      if (path === route.path && req.method === 'GET') {
        const sort =
          route.key === 'partners'
            ? {
                lastName: (p) => p.lastName,
                country: (p) => p.country,
                birthYear: (p) => p.birthYear,
              }
            : { name: (x) => x.name || x.lastName };
        return send(res, 200, crudList(route.arr, q, route.search, sort), origin);
      }
      if (path === route.path && req.method === 'POST') {
        const body = await readBody(req);
        if (route.key === 'volunteers') {
          const email = (body.email || '').trim().toLowerCase();
          if (volunteers.some((v) => !v.deletedAt && v.email.toLowerCase() === email)) {
            return send(res, 422, { message: 'Ошибка валидации', errors: { email: 'Email уже зарегистрирован' } }, origin);
          }
        }
        const id = nextId[route.key]++;
        const created = { id, ...body, deletedAt: null };
        if (route.key === 'volunteers' && body.card) created.card = body.card;
        if (route.key === 'tags' && body.categoryId) created.categoryId = body.categoryId;
        route.arr.push(created);
        return send(res, 201, created, origin);
      }
      const m = path.match(new RegExp(`^${route.path.replace(/\//g, '\\/')}/(\\d+)(\\/restore)?$`));
      if (m) {
        const id = Number(m[1]);
        const idx = route.arr.findIndex((x) => x.id === id);
        if (idx === -1) return send(res, 404, { message: 'Не найдено' }, origin);
        if (m[2] && req.method === 'POST') {
          route.arr[idx].deletedAt = null;
          return send(res, 200, route.arr[idx], origin);
        }
        if (req.method === 'GET') return send(res, 200, route.arr[idx], origin);
        if (req.method === 'PUT') {
          const body = await readBody(req);
          route.arr[idx] = { ...route.arr[idx], ...body, id };
          return send(res, 200, route.arr[idx], origin);
        }
        if (req.method === 'DELETE') {
          if (q.hard) route.arr.splice(idx, 1);
          else route.arr[idx].deletedAt = new Date().toISOString();
          return send(res, 204, undefined, origin);
        }
      }
      if (path === `${route.path}/bulk-delete` && req.method === 'POST') {
        const body = await readBody(req);
        let deleted = 0;
        for (const id of body.ids || []) {
          const row = route.arr.find((x) => x.id === id && !x.deletedAt);
          if (row) {
            row.deletedAt = new Date().toISOString();
            deleted++;
          }
        }
        return send(res, 200, { deleted }, origin);
      }
    }

    send(res, 404, { message: 'Маршрут не найден' }, origin);
  } catch (e) {
    if (e.status) return send(res, e.status, e.body, origin);
    console.error(e);
    send(res, 500, { message: 'Внутренняя ошибка сервера' }, origin);
  }
});

server.listen(PORT, () => {
  console.log(`Mock API (фонд): http://localhost:${PORT}/api/__health`);
  console.log(`CORS origin: ${ALLOWED_ORIGIN}`);
});
