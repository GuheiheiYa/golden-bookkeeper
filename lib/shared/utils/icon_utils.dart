import 'package:flutter/material.dart';

/// 图标分类
enum IconCategory {
  food,       // 餐饮
  transport,  // 交通
  shopping,   // 购物
  entertainment, // 娱乐
  living,     // 居住
  health,     // 医疗
  education,  // 教育
  work,       // 工作
  finance,    // 金融
  travel,     // 旅行
  pets,       // 宠物
  other,      // 其他
}

/// 图标信息
class IconInfo {
  final String name;
  final IconData icon;
  final String label;
  final IconCategory category;

  const IconInfo({
    required this.name,
    required this.icon,
    required this.label,
    required this.category,
  });
}

/// 图标名称到 IconData 的映射工具类
/// 用于数据库中存储的图标名称与 Flutter 图标之间的转换
class IconUtils {
  /// 所有可用的图标列表（带分类）
  static const List<IconInfo> icons = [
    // 餐饮
    IconInfo(name: 'restaurant', icon: Icons.restaurant, label: '餐饮', category: IconCategory.food),
    IconInfo(name: 'local_cafe', icon: Icons.local_cafe, label: '咖啡', category: IconCategory.food),
    IconInfo(name: 'local_bar', icon: Icons.local_bar, label: '酒吧', category: IconCategory.food),
    IconInfo(name: 'local_pizza', icon: Icons.local_pizza, label: '披萨', category: IconCategory.food),
    IconInfo(name: 'cake', icon: Icons.cake, label: '蛋糕', category: IconCategory.food),
    IconInfo(name: 'local_dining', icon: Icons.local_dining, label: '用餐', category: IconCategory.food),
    IconInfo(name: 'fastfood', icon: Icons.fastfood, label: '快餐', category: IconCategory.food),
    IconInfo(name: 'emoji_food_beverage', icon: Icons.emoji_food_beverage, label: '饮品', category: IconCategory.food),

    // 交通
    IconInfo(name: 'directions_car', icon: Icons.directions_car, label: '汽车', category: IconCategory.transport),
    IconInfo(name: 'directions_bus', icon: Icons.directions_bus, label: '公交', category: IconCategory.transport),
    IconInfo(name: 'directions_bike', icon: Icons.directions_bike, label: '自行车', category: IconCategory.transport),
    IconInfo(name: 'directions_walk', icon: Icons.directions_walk, label: '步行', category: IconCategory.transport),
    IconInfo(name: 'local_taxi', icon: Icons.local_taxi, label: '出租车', category: IconCategory.transport),
    IconInfo(name: 'train', icon: Icons.train, label: '地铁', category: IconCategory.transport),
    IconInfo(name: 'flight', icon: Icons.flight, label: '飞机', category: IconCategory.transport),
    IconInfo(name: 'directions_boat', icon: Icons.directions_boat, label: '轮船', category: IconCategory.transport),
    IconInfo(name: 'local_gas_station', icon: Icons.local_gas_station, label: '加油', category: IconCategory.transport),
    IconInfo(name: 'electric_car', icon: Icons.electric_car, label: '电动车', category: IconCategory.transport),

    // 购物
    IconInfo(name: 'shopping_bag', icon: Icons.shopping_bag, label: '购物袋', category: IconCategory.shopping),
    IconInfo(name: 'shopping_cart', icon: Icons.shopping_cart, label: '购物车', category: IconCategory.shopping),
    IconInfo(name: 'local_mall', icon: Icons.local_mall, label: '商场', category: IconCategory.shopping),
    IconInfo(name: 'store', icon: Icons.store, label: '商店', category: IconCategory.shopping),
    IconInfo(name: 'checkroom', icon: Icons.checkroom, label: '服装', category: IconCategory.shopping),
    IconInfo(name: 'diamond', icon: Icons.diamond, label: '珠宝', category: IconCategory.shopping),
    IconInfo(name: 'redeem', icon: Icons.redeem, label: '礼物', category: IconCategory.shopping),
    IconInfo(name: 'loyalty', icon: Icons.loyalty, label: '标签', category: IconCategory.shopping),

    // 娱乐
    IconInfo(name: 'sports_esports', icon: Icons.sports_esports, label: '游戏', category: IconCategory.entertainment),
    IconInfo(name: 'movie', icon: Icons.movie, label: '电影', category: IconCategory.entertainment),
    IconInfo(name: 'music_note', icon: Icons.music_note, label: '音乐', category: IconCategory.entertainment),
    IconInfo(name: 'sports_basketball', icon: Icons.sports_basketball, label: '篮球', category: IconCategory.entertainment),
    IconInfo(name: 'sports_soccer', icon: Icons.sports_soccer, label: '足球', category: IconCategory.entertainment),
    IconInfo(name: 'sports_tennis', icon: Icons.sports_tennis, label: '网球', category: IconCategory.entertainment),
    IconInfo(name: 'pool', icon: Icons.pool, label: '游泳', category: IconCategory.entertainment),
    IconInfo(name: 'fitness_center', icon: Icons.fitness_center, label: '健身', category: IconCategory.entertainment),
    IconInfo(name: 'spa', icon: Icons.spa, label: '水疗', category: IconCategory.entertainment),
    IconInfo(name: 'photo_camera', icon: Icons.photo_camera, label: '摄影', category: IconCategory.entertainment),

    // 居住
    IconInfo(name: 'home', icon: Icons.home, label: '住房', category: IconCategory.living),
    IconInfo(name: 'apartment', icon: Icons.apartment, label: '公寓', category: IconCategory.living),
    IconInfo(name: 'hotel', icon: Icons.hotel, label: '酒店', category: IconCategory.living),
    IconInfo(name: 'bed', icon: Icons.bed, label: '卧室', category: IconCategory.living),
    IconInfo(name: 'kitchen', icon: Icons.kitchen, label: '厨房', category: IconCategory.living),
    IconInfo(name: 'bathroom', icon: Icons.bathroom, label: '浴室', category: IconCategory.living),
    IconInfo(name: 'lightbulb', icon: Icons.lightbulb, label: '电费', category: IconCategory.living),
    IconInfo(name: 'wifi', icon: Icons.wifi, label: '网络', category: IconCategory.living),
    IconInfo(name: 'phone_android', icon: Icons.phone_android, label: '话费', category: IconCategory.living),
    IconInfo(name: 'build', icon: Icons.build, label: '维修', category: IconCategory.living),

    // 医疗
    IconInfo(name: 'local_hospital', icon: Icons.local_hospital, label: '医院', category: IconCategory.health),
    IconInfo(name: 'local_pharmacy', icon: Icons.local_pharmacy, label: '药店', category: IconCategory.health),
    IconInfo(name: 'medical_services', icon: Icons.medical_services, label: '医疗', category: IconCategory.health),
    IconInfo(name: 'healing', icon: Icons.healing, label: '治疗', category: IconCategory.health),
    IconInfo(name: 'favorite', icon: Icons.favorite, label: '健康', category: IconCategory.health),

    // 教育
    IconInfo(name: 'school', icon: Icons.school, label: '学校', category: IconCategory.education),
    IconInfo(name: 'menu_book', icon: Icons.menu_book, label: '书籍', category: IconCategory.education),
    IconInfo(name: 'auto_stories', icon: Icons.auto_stories, label: '阅读', category: IconCategory.education),
    IconInfo(name: 'science', icon: Icons.science, label: '科学', category: IconCategory.education),
    IconInfo(name: 'psychology', icon: Icons.psychology, label: '心理学', category: IconCategory.education),
    IconInfo(name: 'brush', icon: Icons.brush, label: '艺术', category: IconCategory.education),

    // 工作
    IconInfo(name: 'work', icon: Icons.work, label: '工作', category: IconCategory.work),
    IconInfo(name: 'business', icon: Icons.business, label: '商务', category: IconCategory.work),
    IconInfo(name: 'emoji_events', icon: Icons.emoji_events, label: '奖金', category: IconCategory.work),
    IconInfo(name: 'trending_up', icon: Icons.trending_up, label: '投资', category: IconCategory.work),
    IconInfo(name: 'account_balance', icon: Icons.account_balance, label: '银行', category: IconCategory.work),
    IconInfo(name: 'savings', icon: Icons.savings, label: '储蓄', category: IconCategory.work),

    // 金融
    IconInfo(name: 'payments', icon: Icons.payments, label: '现金', category: IconCategory.finance),
    IconInfo(name: 'account_balance_wallet', icon: Icons.account_balance_wallet, label: '钱包', category: IconCategory.finance),
    IconInfo(name: 'credit_card', icon: Icons.credit_card, label: '信用卡', category: IconCategory.finance),
    IconInfo(name: 'attach_money', icon: Icons.attach_money, label: '美元', category: IconCategory.finance),
    IconInfo(name: 'money_off', icon: Icons.money_off, label: '支出', category: IconCategory.finance),
    IconInfo(name: 'currency_exchange', icon: Icons.currency_exchange, label: '换汇', category: IconCategory.finance),
    IconInfo(name: 'receipt_long', icon: Icons.receipt_long, label: '收据', category: IconCategory.finance),
    IconInfo(name: 'volunteer_activism', icon: Icons.volunteer_activism, label: '捐赠', category: IconCategory.finance),

    // 旅行
    IconInfo(name: 'luggage', icon: Icons.luggage, label: '行李', category: IconCategory.travel),
    IconInfo(name: 'map', icon: Icons.map, label: '地图', category: IconCategory.travel),
    IconInfo(name: 'explore', icon: Icons.explore, label: '探索', category: IconCategory.travel),
    IconInfo(name: 'camera_alt', icon: Icons.camera_alt, label: '拍照', category: IconCategory.travel),

    // 宠物
    IconInfo(name: 'pets', icon: Icons.pets, label: '宠物', category: IconCategory.pets),

    // 其他
    IconInfo(name: 'category', icon: Icons.category, label: '分类', category: IconCategory.other),
    IconInfo(name: 'label', icon: Icons.label, label: '标签', category: IconCategory.other),
    IconInfo(name: 'more_horiz', icon: Icons.more_horiz, label: '更多', category: IconCategory.other),
    IconInfo(name: 'repeat', icon: Icons.repeat, label: '周期', category: IconCategory.other),
    IconInfo(name: 'card_giftcard', icon: Icons.card_giftcard, label: '礼品卡', category: IconCategory.other),
    IconInfo(name: 'subscriptions', icon: Icons.subscriptions, label: '订阅', category: IconCategory.other),
    IconInfo(name: 'child_care', icon: Icons.child_care, label: '育儿', category: IconCategory.other),
    IconInfo(name: 'notifications', icon: Icons.notifications, label: '通知', category: IconCategory.other),
    IconInfo(name: 'star', icon: Icons.star, label: '收藏', category: IconCategory.other),
  ];

  /// 图标名称到 IconData 的映射表（快速查找）
  static final Map<String, IconData> iconMap = {
    for (var info in icons) info.name: info.icon,
  };

  /// 按分类分组的图标
  static Map<IconCategory, List<IconInfo>> get iconsByCategory {
    final map = <IconCategory, List<IconInfo>>{};
    for (var info in icons) {
      map.putIfAbsent(info.category, () => []).add(info);
    }
    return map;
  }

  /// 分类名称
  static String getCategoryName(IconCategory category) {
    switch (category) {
      case IconCategory.food:
        return '餐饮';
      case IconCategory.transport:
        return '交通';
      case IconCategory.shopping:
        return '购物';
      case IconCategory.entertainment:
        return '娱乐';
      case IconCategory.living:
        return '居住';
      case IconCategory.health:
        return '医疗';
      case IconCategory.education:
        return '教育';
      case IconCategory.work:
        return '工作';
      case IconCategory.finance:
        return '金融';
      case IconCategory.travel:
        return '旅行';
      case IconCategory.pets:
        return '宠物';
      case IconCategory.other:
        return '其他';
    }
  }

  /// 所有可用的图标名称列表（用于选择器）
  static List<String> get availableIconNames => iconMap.keys.toList();

  /// 根据名称获取图标，如果不存在则返回默认图标
  static IconData fromName(String? name) {
    if (name == null) return Icons.category;
    return iconMap[name] ?? Icons.category;
  }

  /// 根据名称获取图标信息
  static IconInfo? getInfo(String name) {
    try {
      return icons.firstWhere((info) => info.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 根据 IconData 获取名称
  static String toName(IconData icon) {
    final entry = iconMap.entries.where((e) => e.value == icon).firstOrNull;
    return entry?.key ?? 'category';
  }
}
