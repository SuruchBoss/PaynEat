// เทมเพลตบูตของ Flutter Web ที่เขียนทับเอง
//
// เหตุผล: ค่าเริ่มต้นจะโหลด CanvasKit จาก CDN ของ Google (gstatic.com)
// ซึ่งอาจถูกบล็อกในบางเครือข่ายและทำให้แอปขาวทั้งจอ
// ชี้มาที่โฟลเดอร์ canvaskit/ ที่ถูก build มาพร้อมกันแทน — โหลดเร็วกว่าและใช้งานออฟไลน์ได้
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
