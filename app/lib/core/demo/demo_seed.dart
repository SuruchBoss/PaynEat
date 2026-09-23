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
      'nameEn': 'System Admin',
      'nameKo': '관리자',
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'สมชาย (ผู้จัดการ)',
      'nameEn': 'Somchai (Manager)',
      'nameKo': '김민수 (매니저)',
      'username': 'manager',
      'password': 'manager123',
      'role': 'manager',
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'น้องฝน (พนักงานเสิร์ฟ)',
      'nameEn': 'Fon (Server)',
      'nameKo': '박지은 (홀)',
      'username': 'waiter1',
      'password': 'waiter123',
      'role': 'waiter',
      'isActive': true,
    },
    {
      'id': 4,
      'name': 'น้องมิ้น (พนักงานเสิร์ฟ)',
      'nameEn': 'Mint (Server)',
      'nameKo': '이수빈 (홀)',
      'username': 'waiter2',
      'password': 'waiter123',
      'role': 'waiter',
      'isActive': true,
    },
    {
      'id': 5,
      'name': 'เชฟต้น (ครัว)',
      'nameEn': 'Chef Ton (Kitchen)',
      'nameKo': '최현우 (주방)',
      'username': 'kitchen',
      'password': 'kitchen123',
      'role': 'kitchen',
      'isActive': true,
    },
    {
      'id': 6,
      'name': 'พี่แอน (แคชเชียร์)',
      'nameEn': 'Ann (Cashier)',
      'nameKo': '한소영 (캐셔)',
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
      'nameKo': '추천',
      'icon': '⭐',
      'sortOrder': 1,
      'isActive': true,
    },
    {
      'id': 2,
      'name': 'อาหารจานเดียว',
      'nameEn': 'Rice & Noodles',
      'nameKo': '밥 · 면',
      'icon': '🍛',
      'sortOrder': 2,
      'isActive': true,
    },
    {
      'id': 3,
      'name': 'กับข้าว',
      'nameEn': 'Main Dishes',
      'nameKo': '메인 요리',
      'icon': '🍲',
      'sortOrder': 3,
      'isActive': true,
    },
    {
      'id': 4,
      'name': 'ยำ / สลัด',
      'nameEn': 'Salads',
      'nameKo': '샐러드',
      'icon': '🥗',
      'sortOrder': 4,
      'isActive': true,
    },
    {
      'id': 5,
      'name': 'ของทานเล่น',
      'nameEn': 'Appetizers',
      'nameKo': '애피타이저',
      'icon': '🍤',
      'sortOrder': 5,
      'isActive': true,
    },
    {
      'id': 6,
      'name': 'เครื่องดื่ม',
      'nameEn': 'Drinks',
      'nameKo': '음료',
      'icon': '🥤',
      'sortOrder': 6,
      'isActive': true,
    },
    {
      'id': 7,
      'name': 'ของหวาน',
      'nameEn': 'Desserts',
      'nameKo': '디저트',
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
      'nameEn': 'Spice level',
      'nameKo': '맵기',
      'minSelect': 1,
      'maxSelect': 1,
      'isRequired': true,
      'options': [
        {
          'id': baseId * 10 + 1,
          'name': 'ไม่เผ็ด',
          'nameEn': 'Not spicy',
          'nameKo': '안 맵게',
          'priceDelta': 0,
          'isDefault': true,
        },
        {
          'id': baseId * 10 + 2,
          'name': 'เผ็ดน้อย',
          'nameEn': 'Mild',
          'nameKo': '약간 맵게',
          'priceDelta': 0,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 3,
          'name': 'เผ็ดปกติ',
          'nameEn': 'Medium',
          'nameKo': '보통',
          'priceDelta': 0,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 4,
          'name': 'เผ็ดมาก',
          'nameEn': 'Extra spicy',
          'nameKo': '아주 맵게',
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
      'nameEn': 'Add-ons',
      'nameKo': '추가 선택',
      'minSelect': 0,
      'maxSelect': 3,
      'isRequired': false,
      'options': [
        {
          'id': baseId * 10 + 1,
          'name': 'ไข่ดาว',
          'nameEn': 'Fried egg',
          'nameKo': '계란 프라이',
          'priceDelta': 15,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 2,
          'name': 'เพิ่มข้าว',
          'nameEn': 'Extra rice',
          'nameKo': '밥 추가',
          'priceDelta': 10,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 3,
          'name': 'พิเศษ (เพิ่มปริมาณ)',
          'nameEn': 'Large portion',
          'nameKo': '곱빼기',
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
      'nameEn': 'Sweetness',
      'nameKo': '당도',
      'minSelect': 1,
      'maxSelect': 1,
      'isRequired': true,
      'options': [
        {
          'id': baseId * 10 + 1,
          'name': 'หวานปกติ',
          'nameEn': 'Regular sweet',
          'nameKo': '보통',
          'priceDelta': 0,
          'isDefault': true,
        },
        {
          'id': baseId * 10 + 2,
          'name': 'หวานน้อย',
          'nameEn': 'Less sweet',
          'nameKo': '덜 달게',
          'priceDelta': 0,
          'isDefault': false,
        },
        {
          'id': baseId * 10 + 3,
          'name': 'ไม่หวาน',
          'nameEn': 'No sugar',
          'nameKo': '무가당',
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
        '새우 볶음밥',
        90,
        recommended: true,
        description: 'ข้าวผัดหอมกระทะ กุ้งสดตัวโต',
        groups: _extra(101),
        ingredients: [_ingredientUsage(1, 80), _ingredientUsage(3, 1)],
      ),
      _menu(
        2,
        2,
        'ผัดกะเพราหมูสับ',
        'Basil Pork with Rice',
        '바질 돼지고기 덮밥',
        75,
        recommended: true,
        description: 'เผ็ดร้อนแบบต้นตำรับ ราดข้าวสวยร้อน ๆ',
        groups: [..._spicy(102), ..._extra(103)],
        ingredients: [_ingredientUsage(2, 100), _ingredientUsage(3, 1)],
      ),
      _menu(
        3,
        2,
        'ผัดไทยกุ้งสด',
        'Pad Thai with Shrimp',
        '새우 팟타이',
        95,
        description: 'เส้นจันท์ผัดซอสมะขาม',
        groups: [..._spicy(104), ..._extra(105)],
      ),
      _menu(4, 2, 'ข้าวหมูกรอบ', 'Crispy Pork with Rice', '바삭 돼지고기 덮밥', 85),
      _menu(5, 2, 'ราดหน้าหมูหมัก', 'Pork Noodles in Gravy', '돼지고기 랏나', 80),
      _menu(
        6,
        3,
        'ต้มยำกุ้งน้ำข้น',
        'Tom Yum Goong',
        '똠얌꿍',
        220,
        recommended: true,
        description: 'กุ้งแม่น้ำ น้ำข้นเข้มข้น',
        groups: _spicy(106),
      ),
      _menu(7, 3, 'แกงเขียวหวานไก่', 'Green Curry Chicken', '치킨 그린커리', 160),
      _menu(
        8,
        3,
        'ปลาทับทิมนึ่งมะนาว',
        'Steamed Fish with Lime',
        '라임 찜생선',
        320,
        ingredients: [_ingredientUsage(6, 1)],
      ),
      _menu(
        9,
        3,
        'ผัดผักรวมมิตร',
        'Stir-fried Mixed Vegetables',
        '모둠 채소 볶음',
        120,
      ),
      _menu(
        10,
        3,
        'ไข่เจียวปู',
        'Crab Omelette',
        '게살 오믈렛',
        180,
        ingredients: [_ingredientUsage(4, 2), _ingredientUsage(5, 50)],
      ),
      _menu(
        11,
        4,
        'ส้มตำไทย',
        'Papaya Salad',
        '쏨땀',
        80,
        recommended: true,
        groups: _spicy(107),
      ),
      _menu(
        12,
        4,
        'ยำวุ้นเส้นทะเล',
        'Seafood Glass Noodle Salad',
        '해산물 당면 샐러드',
        150,
        groups: _spicy(108),
      ),
      _menu(
        13,
        4,
        'ลาบหมู',
        'Spicy Minced Pork Salad',
        '돼지고기 라브',
        110,
        groups: _spicy(109),
      ),
      _menu(14, 5, 'ปีกไก่ทอดน้ำปลา', 'Fried Chicken Wings', '닭날개 튀김', 120),
      _menu(15, 5, 'กุ้งชุบแป้งทอด', 'Deep-fried Shrimp', '새우 튀김', 160),
      _menu(16, 5, 'ปอเปี๊ยะทอด', 'Spring Rolls', '스프링롤', 90),
      _menu(
        17,
        6,
        'ชาไทยเย็น',
        'Thai Iced Tea',
        '타이 아이스티',
        55,
        recommended: true,
        groups: _sweetIce(110),
      ),
      _menu(
        18,
        6,
        'น้ำมะนาวโซดา',
        'Lime Soda',
        '라임 소다',
        60,
        groups: _sweetIce(111),
      ),
      _menu(19, 6, 'น้ำเปล่า', 'Drinking Water', '생수', 20),
      _menu(20, 6, 'โค้ก', 'Coke', '콜라', 30),
      _menu(21, 6, 'เบียร์สิงห์', 'Singha Beer', '싱하 맥주', 90),
      _menu(
        22,
        7,
        'ข้าวเหนียวมะม่วง',
        'Mango Sticky Rice',
        '망고 찰밥',
        120,
        recommended: true,
      ),
      _menu(23, 7, 'บัวลอยไข่หวาน', 'Bua Loy', '부아로이', 70),
      _menu(24, 7, 'ไอศกรีมกะทิ', 'Coconut Ice Cream', '코코넛 아이스크림', 65),
    ];
    return items;
  }

  static Map<String, dynamic> _menu(
    int id,
    int categoryId,
    String name,
    String nameEn,
    String nameKo,
    double price, {
    bool recommended = false,
    String? description,
    List<Map<String, dynamic>> groups = const [],
    List<Map<String, dynamic>> ingredients = const [],
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
      'nameKo': nameKo,
      'description': description,
      'price': price,
      'imageUrl': null,
      'isAvailable': true,
      'isRecommended': recommended,
      'prepMinutes': 10,
      'sortOrder': id,
      'optionGroups': groups,
      'ingredients': ingredients,
      // เก็บไว้ใช้ภายใน demo store เท่านั้น (ไม่ใช่ฟิลด์ที่ API จริงส่งกลับ) — ดู
      // demo_store_ingredients.dart: แยก "ระบบปิดขายเพราะสต๊อกหมด" ออกจาก "พนักงานปิดขายเอง"
      'autoDisabledByStock': false,
    };
  }

  /// วัตถุดิบตัวอย่าง (ดู docs/tickets/06-inventory-stock.md) — หน่วยอิสระที่ร้านตั้งเอง ไม่ใช่เงิน
  /// "ปลาทับทิม" ตั้งใจให้ currentStock ต่ำกว่า lowStockThreshold ตั้งแต่ seed เพื่อให้เห็นตัวอย่าง
  /// การแจ้งเตือนของใกล้หมดได้ทันทีโดยไม่ต้องสั่งอาหารก่อน
  static List<Map<String, dynamic>> ingredients() => [
    {
      'id': 1,
      'name': 'กุ้งสด',
      'unit': 'กรัม',
      'currentStock': 3000.0,
      'lowStockThreshold': 500.0,
    },
    {
      'id': 2,
      'name': 'หมูสับ',
      'unit': 'กรัม',
      'currentStock': 4000.0,
      'lowStockThreshold': 800.0,
    },
    {
      'id': 3,
      'name': 'ข้าวสวย',
      'unit': 'จาน',
      'currentStock': 100.0,
      'lowStockThreshold': 20.0,
    },
    {
      'id': 4,
      'name': 'ไข่ไก่',
      'unit': 'ฟอง',
      'currentStock': 60.0,
      'lowStockThreshold': 12.0,
    },
    {
      'id': 5,
      'name': 'เนื้อปู',
      'unit': 'กรัม',
      'currentStock': 500.0,
      'lowStockThreshold': 300.0,
    },
    {
      'id': 6,
      'name': 'ปลาทับทิม',
      'unit': 'ตัว',
      'currentStock': 3.0,
      'lowStockThreshold': 5.0,
    },
  ];

  /// ผูกเมนู → วัตถุดิบที่ใช้ + ปริมาณต่อ 1 ที่ (denormalize ชื่อ/หน่วยไว้ตรง ๆ เหมือน categoryName)
  static Map<String, dynamic> _ingredientUsage(
    int ingredientId,
    double qtyPerUnit,
  ) {
    final ingredient = ingredients().firstWhere((i) => i['id'] == ingredientId);
    return {
      'ingredientId': ingredientId,
      'ingredientName': ingredient['name'],
      'unit': ingredient['unit'],
      'qtyPerUnit': qtyPerUnit,
    };
  }

  static List<Map<String, dynamic>> tables() {
    final result = <Map<String, dynamic>>[];
    var id = 1;
    for (var i = 1; i <= 8; i++) {
      result.add(
        _table(id++, 'A$i', 'โซนในร้าน', 'Indoor', '실내', i <= 4 ? 2 : 4),
      );
    }
    for (var i = 1; i <= 6; i++) {
      result.add(_table(id++, 'B$i', 'โซนริมหน้าต่าง', 'Window', '창가', 4));
    }
    for (var i = 1; i <= 4; i++) {
      result.add(_table(id++, 'C$i', 'โซนสวน', 'Garden', '정원', 6));
    }
    result.add(_table(id++, 'VIP1', 'ห้องส่วนตัว', 'Private Room', '룸', 10));
    result.add(_table(id++, 'VIP2', 'ห้องส่วนตัว', 'Private Room', '룸', 12));
    return result;
  }

  static Map<String, dynamic> _table(
    int id,
    String name,
    String zone,
    String zoneEn,
    String zoneKo,
    int seats,
  ) => {
    'id': id,
    'name': name,
    'zone': zone,
    'zoneEn': zoneEn,
    'zoneKo': zoneKo,
    'seats': seats,
    'status': 'available',
    'isActive': true,
    'currentOrder': null,
    // ใช้แทนของจริงที่ backend สุ่มด้วย randomUUID() — โหมดสาธิตกำหนดตายตัวได้เลยเพราะข้อมูลไม่
    // เปลี่ยนข้ามเซสชัน ไม่ต้องสุ่มจริงจัง (ดู docs/tickets/17-qr-self-order.md)
    'qrToken': 'demo-table-$id',
  };

  static Map<String, dynamic> settings() => {
    'storeName': 'ครัวคุณย่า (เดโม)',
    'storeNameEn': "Grandma's Kitchen (Demo)",
    'storeNameKo': '할머니 부엌 (데모)',
    'currency': 'THB',
    'vatRate': 0.07,
    'serviceChargeRate': 0.1,
    'vatIncluded': false,
    // ข้อมูลผู้เสียภาษีของร้านตัวอย่าง (ดู docs/tickets/07-tax-invoice.md) — seed ไว้ให้ลอง
    // ออกใบกำกับภาษีได้ทันทีโดยไม่ต้องตั้งค่าเองก่อน
    'storeTaxId': '0105558000012',
    // ที่อยู่และชื่อสาขา **จงใจไม่แปล** ทุกภาษา — ใบกำกับภาษีของไทยต้องแสดง
    // ที่อยู่ตามที่จดทะเบียนไว้เป็นภาษาไทย ต่อให้หน้าจอเป็นเกาหลีก็ตาม
    // (ร้านเกาหลีในกรุงเทพฯ ก็ยังต้องออกใบกำกับภาษีตามรูปแบบของไทย)
    'storeAddress':
        '123/45 ถนนสุขุมวิท แขวงคลองตัน เขตคลองเตย กรุงเทพมหานคร 10110',
    'storeBranch': 'สำนักงานใหญ่',
    // แต้มสะสม (ดู docs/tickets/09-customer-loyalty.md) — ค่าเริ่มต้นตรงกับ backend
    'pointsEarnRateBaht': 25.0,
    'pointsRedeemValueBaht': 1.0,
    // เลขพร้อมเพย์ของร้านตัวอย่าง (ดู docs/tickets/16-promptpay-qr.md) — seed ไว้ให้เห็น QR
    // จริงได้ทันทีตอนเลือกช่องทางจ่าย "qr" โดยไม่ต้องตั้งค่าเอง
    'promptPayId': '0812345678',
  };
}
