import '../models/fund_tag.dart';

List<FundTag> buildSeedTags() => const [
      FundTag(id: 1, name: 'Сбор средств', categoryId: 1),
      FundTag(id: 2, name: 'Волонтёрство', categoryId: 4),
      FundTag(id: 3, name: 'Срочная помощь', categoryId: 2),
      FundTag(id: 4, name: 'Долгосрочная программа', categoryId: 1),
      FundTag(id: 5, name: 'Региональный проект', categoryId: 3),
      FundTag(id: 6, name: 'Культурный обмен', categoryId: 5),
      FundTag(id: 7, name: 'Медоборудование', categoryId: 2),
      FundTag(id: 8, name: 'Экоакции', categoryId: 3),
    ];
