/// ข้อมูลตัวอย่างสำหรับ Demo Mode
///
/// รูปร่างของข้อมูลตรงกับ JSON ที่ backend ส่งกลับมาทุกฟิลด์
/// จึงนำไปแปลงด้วย Model.fromJson ตัวเดียวกับของจริงได้เลย
class DemoSeed {
  const DemoSeed._();

  static List<Map<String, dynamic>> users() => [
    {
      'id': 1,
      'name': 'ผู้ดูแลระบบ',
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'สมชาย (ผู้จัดการ)',
      'username': 'manager',
      'password': 'manager123',
      'role': 'manager',
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'น้องฝน (พนักงานเสิร์ฟ)',
      'username': 'waiter1',
      'password': 'waiter123',
      'role': 'waiter',
      'isActive': true,
    },
    {
      'id': 4,
      'name': 'น้องมิ้น (พนักงานเสิร์ฟ)',
      'username': 'waiter2',
      'password': 'waiter123',
      'role': 'waiter',
      'isActive': true,
    },
    {
      'id': 5,
      'name': 'เชฟต้น (ครัว)',
      'username': 'kitchen',
      'password': 'kitchen123',
      'role': 'kitchen',
      'isActive': true,
    },
    {
      'id': 6,
      'name': 'พี่แอน (แคชเชียร์)',
      'username': 'cashier',
      'password': 'cashier123',
      'role': 'cashier',
      'isActive': true,
    },
  ];

  static List<Map<String, dynamic>> categories() => [
    {
      'id': 1,
      'name': 'แนะนำ',
      'nameEn': 'Recommended',
      'icon': '⭐',
      'sortOrder': 1,
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'อาหารจานเดียว',
      'nameEn': 'Rice & Noodles',
      'icon': '🍛',
      'sortOrder': 2,
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'กับข้าว',
      'nameEn': 'Main Dishes',
      'icon': '🍲',
      'sortOrder': 3,
      'isActive': true,
    },
    {
      'id': 4,
      'name': 'ยำ / สลัด',
      'nameEn': 'Salads',
      'icon': '🥗',
      'sortOrder': 4,
      'isActive': true,
    },
    {
      'id': 5,
      'name': 'ของทานเล่น',
      'nameEn': 'Appetizers',
      'icon': '🍤',
      'sortOrder': 5,
      'isActive': true,
    },
    {
      'id': 6,
      'name': 'เครื่องดื่ม',
      'nameEn': 'Drinks',
      'icon': '🥤',
      'sortOrder': 6,
      'isActive': true,
    },
    {
      'id': 7,
      'name': 'ของหวาน',
      'nameEn': 'Desserts',
      'icon': '🍨',
      'sortOrder': 7,
      'isActive': true,
    },
  ];

  /// กลุ่มตัวเลือกมาตรฐานที่ใช้ซ้ำหลายเมนู
  static List<Map<String, dynamic>> _spicy(int baseId) => [
    {
      'id': baseId,
      'name': 'ระดับความเผ็ด',
      'minSelect': 1,
      'maxSelect': 1,
      'isRequired': true,
      'options': [
        {
          'id': baseId * 10 + 1,
          'name': 'ไม่เผ็ด',
          'priceDelta': 0,
          'isDefault': true,
        },
        {
          'id': baseId * 10 + 2,
          'name': 'เผ็ดน้อย',
          'priceDelta': 0,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 3,
          'name': 'เผ็ดปกติ',
          'priceDelta': 0,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 4,
          'name': 'เผ็ดมาก',
          'priceDelta': 0,
          'isDefault': false,
        },
      ],
    },
  ];

  static List<Map<String, dynamic>> _extra(int baseId) => [
    {
      'id': baseId,
      'name': 'เพิ่มพิเศษ',
      'minSelect': 0,
      'maxSelect': 3,
      'isRequired': false,
      'options': [
        {
          'id': baseId * 10 + 1,
          'name': 'ไข่ดาว',
          'priceDelta': 15,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 2,
          'name': 'เพิ่มข้าว',
          'priceDelta': 10,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 3,
          'name': 'พิเศษ (เพิ่มปริมาณ)',
          'priceDelta': 20,
          'isDefault': false,
        },
      ],
    },
  ];

  static List<Map<String, dynamic>> _sweetIce(int baseId) => [
    {
      'id': baseId,
      'name': 'ระดับความหวาน',
      'minSelect': 1,
      'maxSelect': 1,
      'isRequired': true,
      'options': [
        {
          'id': baseId * 10 + 1,
          'name': 'หวานปกติ',
          'priceDelta': 0,
          'isDefault': true,
        },
        {
          'id': baseId * 10 + 2,
          'name': 'หวานน้อย',
          'priceDelta': 0,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 3,
          'name': 'ไม่หวาน',
          'priceDelta': 0,
          'isDefault': false,
        },
      ],
    },
  ];

  static List<Map<String, dynamic>> menuItems() {
    final items = <Map<String, dynamic>>[
      _menu(
        1,
        2,
        'ข้าวผัดกุ้ง',
        'Shrimp Fried Rice',
        90,
        recommended: true,
        description: 'ข้าวผัดหอมกระทะ กุ้งสดตัวโต',
        groups: _extra(101),
      ),
      _menu(
        2,
        2,
        'ผัดกะเพราหมูสับ',
        'Basil Pork with Rice',
        75,
        recommended: true,
        description: 'เผ็ดร้อนแบบต้นตำรับ ราดข้าวสวยร้อน ๆ',
        groups: [..._spicy(102), ..._extra(103)],
      ),
      _menu(
        3,
        2,
        'ผัดไทยกุ้งสด',
        'Pad Thai with Shrimp',
        95,
        description: 'เส้นจันท์ผัดซอสมะขาม',
        groups: [..._spicy(104), ..._extra(105)],
      ),
      _menu(4, 2, 'ข้าวหมูกรอบ', 'Crispy Pork with Rice', 85),
      _menu(5, 2, 'ราดหน้าหมูหมัก', 'Pork Noodles in Gravy', 80),
      _menu(
        6,
        3,
        'ต้มยำกุ้งน้ำข้น',
        'Tom Yum Goong',
        220,
        recommended: true,
        description: 'กุ้งแม่น้ำ น้ำข้นเข้มข้น',
        groups: _spicy(106),
      ),
      _menu(7, 3, 'แกงเขียวหวานไก่', 'Green Curry Chicken', 160),
      _menu(8, 3, 'ปลาทับทิมนึ่งมะนาว', 'Steamed Fish with Lime', 320),
      _menu(9, 3, 'ผัดผักรวมมิตร', 'Stir-fried Mixed Vegetables', 120),
      _menu(10, 3, 'ไข่เจียวปู', 'Crab Omelette', 180),
      _menu(
        11,
        4,
        'ส้มตำไทย',
        'Papaya Salad',
        80,
        recommended: true,
        groups: _spicy(107),
      ),
      _menu(
        12,
        4,
        'ยำวุ้นเส้นทะเล',
        'Seafood Glass Noodle Salad',
        150,
        groups: _spicy(108),
      ),
      _menu(
        13,
        4,
        'ลาบหมู',
        'Spicy Minced Pork Salad',
        110,
        groups: _spicy(109),
      ),
      _menu(14, 5, 'ปีกไก่ทอดน้ำปลา', 'Fried Chicken Wings', 120),
      _menu(15, 5, 'กุ้งชุบแป้งทอด', 'Deep-fried Shrimp', 160),
      _menu(16, 5, 'ปอเปี๊ยะทอด', 'Spring Rolls', 90),
      _menu(
        17,
        6,
        'ชาไทยเย็น',
        'Thai Iced Tea',
        55,
        recommended: true,
        groups: _sweetIce(110),
      ),
      _menu(18, 6, 'น้ำมะนาวโซดา', 'Lime Soda', 60, groups: _sweetIce(111)),
      _menu(19, 6, 'น้ำเปล่า', 'Drinking Water', 20),
      _menu(20, 6, 'โค้ก', 'Coke', 30),
      _menu(21, 6, 'เบียร์สิงห์', 'Singha Beer', 90),
      _menu(
        22,
        7,
        'ข้าวเหนียวมะม่วง',
        'Mango Sticky Rice',
        120,
        recommended: true,
      ),
      _menu(23, 7, 'บัวลอยไข่หวาน', 'Bua Loy', 70),
      _menu(24, 7, 'ไอศกรีมกะทิ', 'Coconut Ice Cream', 65),
    ];
    return items;
  }

  static Map<String, dynamic> _menu(
    int id,
    int categoryId,
    String name,
    String nameEn,
    double price, {
    bool recommended = false,
    String? description,
    List<Map<String, dynamic>> groups = const [],
  }) {
    final categoryName = categories().firstWhere(
      (c) => c['id'] == categoryId,
    )['name'];
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'price': price,
      'imageUrl': null,
      'isAvailable': true,
      'isRecommended': recommended,
      'prepMinutes': 10,
      'sortOrder': id,
      'optionGroups': groups,
    };
  }

  static List<Map<String, dynamic>> tables() {
    final result = <Map<String, dynamic>>[];
    var id = 1;
    for (var i = 1; i <= 8; i++) {
      result.add(_table(id++, 'A$i', 'โซนในร้าน', i <= 4 ? 2 : 4));
    }
    for (var i = 1; i <= 6; i++) {
      result.add(_table(id++, 'B$i', 'โซนริมหน้าต่าง', 4));
    }
    for (var i = 1; i <= 4; i++) {
      result.add(_table(id++, 'C$i', 'โซนสวน', 6));
    }
    result.add(_table(id++, 'VIP1', 'ห้องส่วนตัว', 10));
    result.add(_table(id++, 'VIP2', 'ห้องส่วนตัว', 12));
    return result;
  }

  static Map<String, dynamic> _table(
    int id,
    String name,
    String zone,
    int seats,
  ) => {
    'id': id,
    'name': name,
    'zone': zone,
    'seats': seats,
    'status': 'available',
    'isActive': true,
    'currentOrder': null,
  };

  static Map<String, dynamic> settings() => {
    'storeName': 'ครัวคุณย่า (เดโม)',
    'currency': 'THB',
    'vatRate': 0.07,
    'serviceChargeRate': 0.1,
    'vatIncluded': false,
  };
}
