/// 分类关键词匹配工具
///
/// 根据文本描述（如商品名、商户名），通过关键词映射自动匹配分类。
/// 与 [ImportScreen] 的账单导入分类匹配逻辑保持一致。
///
/// ## 使用场景
/// - 支付通知确认弹窗：用解析器提取的 goods 自动匹配分类
/// - 全部确认：批量自动匹配分类

/// 关键词 → 分类名称映射表
///
/// 与账单导入模块 `_matchCategoryByDescription` 的方法保持同步。
/// 映射按优先级排列，同一关键词只会匹配到最先命中的分类。
const Map<String, List<String>> categoryKeywordMap = {
  '餐饮': [
    '美团', '饿了么', '麦当劳', '肯德基', '星巴克', '瑞幸',
    '库迪', '海底捞', '蜜雪冰城', '汉堡王', '必胜客',
    '喜茶', '奈雪', '茶百道', 'CoCo', '一点点',
    '咖啡', '奶茶', '火锅', '烧烤', '快餐', '小吃',
    '面包', '糕点', '甜品', '饮品', '果汁',
    '超市', '便利店', '水果', '生鲜', '食堂',
    '餐厅', '饭店', '面馆', '饺子', '包子',
    '蛋糕', '烘焙', '外卖',
    'cotti', 'coffee', 'luckin', 'starbucks', 'kfc',
    'mcdonald', 'pizzahut', 'heytea', 'mixue',
    'tea', 'bubble', 'latte', 'mocha',
  ],
  '交通': [
    '滴滴', '打车', '地铁', '公交', '出租', '加油', '停车',
    '高铁', '飞机', '机票', 'ETC',
    '哈啰', '青桔', 'T3出行', '曹操出行',
    '共享单车', '客运', '洗车', '保养', '过路费',
  ],
  '购物': [
    '淘宝', '京东', '拼多多', '天猫', '苏宁', '唯品会',
    '闲鱼', '得物', '抖音',
    '商场', '百货', '服装', '化妆品', '数码',
  ],
  '娱乐': [
    '电影', '游戏', 'KTV', '景区', '门票', '酒店', '民宿',
    '爱奇艺', '优酷', '腾讯视频', '网易云',
    'Steam', 'Apple',
  ],
  '居住': [
    '房租', '水电', '物业', '燃气', '宽带', '家具', '装修',
    '保洁', '搬家', '房贷',
  ],
  '医疗': [
    '医院', '药房', '药店', '诊所', '体检', '挂号',
    '牙科', '中医', '保健',
  ],
  '教育': [
    '书店', '图书', '培训', '课程', '学费', '网课', '驾校',
    '考试', '辅导',
  ],
  '通讯': ['话费', '流量', '中国移动', '中国联通', '中国电信', '手机充值'],
  '转账': ['转账', '转出', '转入'],
};

/// 根据文本描述自动匹配分类 ID
///
/// [text]        要匹配的文本（如商品名、商户名）
/// [categories]  可选分类列表（每个元素需包含 'name' 和 'id' 字段）
/// 返回匹配到的分类 ID，未匹配返回 null
int? matchCategoryByKeywords(
  String text,
  List<Map<String, dynamic>> categories,
) {
  final lower = text.toLowerCase();

  // 策略 1：关键词映射匹配（精确命中常见商户名）
  for (final entry in categoryKeywordMap.entries) {
    for (final keyword in entry.value) {
      if (lower.contains(keyword.toLowerCase())) {
        for (final cat in categories) {
          if (cat['name'] == entry.key) {
            return cat['id'] as int;
          }
        }
      }
    }
  }

  // 策略 2：分类名直接匹配（用户自定义分类也能自动对上）
  // 检查文本中是否包含某个分类的名称，如"基金"、"旅行"、"宠物"等
  for (final cat in categories) {
    final catName = (cat['name'] as String).toLowerCase();
    if (catName.isNotEmpty && lower.contains(catName)) {
      return cat['id'] as int;
    }
  }

  return null;
}
