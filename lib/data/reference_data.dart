class CategoryRef {
  final int id;
  final String name;
  const CategoryRef(this.id, this.name);
}

class TagRef {
  final int id;
  final String name;
  const TagRef(this.id, this.name);
}

const categories = <CategoryRef>[
  CategoryRef(1, 'Дети и образование'),
  CategoryRef(2, 'Медицина'),
  CategoryRef(3, 'Экология'),
  CategoryRef(4, 'Социальная помощь'),
  CategoryRef(5, 'Культура'),
];

const tags = <TagRef>[
  TagRef(1, 'Сбор средств'),
  TagRef(2, 'Волонтёрство'),
  TagRef(3, 'Срочная помощь'),
  TagRef(4, 'Долгосрочная программа'),
  TagRef(5, 'Региональный проект'),
];

String categoryName(int id) => categories
    .firstWhere((c) => c.id == id, orElse: () => const CategoryRef(0, '—'))
    .name;

String tagName(int id) =>
    tags.firstWhere((t) => t.id == id, orElse: () => const TagRef(0, '—')).name;
