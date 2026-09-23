/// คำแปลของตาชั่งต่อสาย + สแกนด้วยกล้อง (ดู docs/tickets/22-live-scale-camera-scan.md)
const Map<String, String> scaleTranslationsTh = {
  'scale_live_title': 'ตาชั่ง (อ่านสด)',
  'scale_live_title_demo':
      'ตาชั่งจำลอง (เดโม) — น้ำหนักเปลี่ยนเองทุกไม่กี่วินาที',
  'scale_live_waiting': 'รอน้ำหนักจากตาชั่ง…',
  'scale_live_unstable': 'กำลังชั่ง… รอตัวเลขนิ่งก่อน',
  'scale_live_overload': 'เกินพิกัดตาชั่ง',
  'scale_live_empty': 'วางสินค้าบนตาชั่ง',
  'scale_live_stable': 'นิ่งแล้ว = @price',
  'scale_live_disconnected':
      'ตาชั่งไม่ได้เชื่อมต่อ — กรอกน้ำหนักเองด้านล่างได้',
  'scale_live_use': 'ใช้น้ำหนักนี้',
  'scan_camera_title': 'สแกนด้วยกล้อง',
  'scan_camera_hint': 'เล็งบาร์โค้ดหรือฉลากตาชั่งให้อยู่ในกรอบ',
  'scan_camera_torch': 'เปิด/ปิดไฟฉาย',
  'scan_camera_denied':
      'ไม่ได้รับสิทธิ์ใช้กล้อง — เปิดสิทธิ์กล้องให้แอป/เบราว์เซอร์ในการตั้งค่าเครื่อง',
  'scan_camera_unavailable':
      'เปิดกล้องไม่ได้ — ใช้เครื่องสแกนหรือพิมพ์รหัสในช่องแทน',
  'order_scan_camera_tooltip': 'สแกนด้วยกล้อง',
};

const Map<String, String> scaleTranslationsEn = {
  'scale_live_title': 'Scale (live)',
  'scale_live_title_demo':
      'Simulated scale (demo) — weight changes every few seconds',
  'scale_live_waiting': 'Waiting for the scale…',
  'scale_live_unstable': 'Weighing… wait until it settles',
  'scale_live_overload': 'Scale overloaded',
  'scale_live_empty': 'Place the item on the scale',
  'scale_live_stable': 'Stable = @price',
  'scale_live_disconnected':
      'Scale not connected — you can type the weight below',
  'scale_live_use': 'Use this weight',
  'scan_camera_title': 'Scan with camera',
  'scan_camera_hint': 'Point at the barcode or scale label inside the frame',
  'scan_camera_torch': 'Toggle flashlight',
  'scan_camera_denied':
      'Camera permission denied — allow camera access for this app/browser in device settings',
  'scan_camera_unavailable':
      'Camera unavailable — use a scanner or type the code instead',
  'order_scan_camera_tooltip': 'Scan with camera',
};

const Map<String, String> scaleTranslationsKo = {
  'scale_live_title': '저울 (실시간)',
  'scale_live_title_demo': '가상 저울 (데모) — 몇 초마다 무게가 바뀝니다',
  'scale_live_waiting': '저울 값을 기다리는 중…',
  'scale_live_unstable': '계량 중… 값이 안정될 때까지 기다리세요',
  'scale_live_overload': '저울 최대 하중 초과',
  'scale_live_empty': '상품을 저울에 올려 주세요',
  'scale_live_stable': '안정됨 = @price',
  'scale_live_disconnected': '저울이 연결되지 않았습니다 — 아래에 무게를 직접 입력하세요',
  'scale_live_use': '이 무게 사용',
  'scan_camera_title': '카메라로 스캔',
  'scan_camera_hint': '바코드나 저울 라벨을 프레임 안에 맞추세요',
  'scan_camera_torch': '손전등 켜기/끄기',
  'scan_camera_denied': '카메라 권한이 거부되었습니다 — 기기 설정에서 앱/브라우저의 카메라 접근을 허용하세요',
  'scan_camera_unavailable': '카메라를 사용할 수 없습니다 — 스캐너를 쓰거나 코드를 직접 입력하세요',
  'order_scan_camera_tooltip': '카메라로 스캔',
};
