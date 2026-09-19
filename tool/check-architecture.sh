#!/usr/bin/env bash
# ตรวจว่าทิศทาง dependency ยังเป็นไปตาม docs/CODING_STANDARDS.md §4.1 และ §4.2
#
# กฎพวกนี้เขียนไว้ใน CODING_STANDARDS.md ตั้งแต่แรกในรูปคำสั่ง grep ที่ "ต้องรันก่อน commit"
# แต่ไม่มีอะไรบังคับให้ใครรันจริง — ซึ่งเท่ากับเป็นกฎที่อยู่ในความจำของคน ไม่ใช่ในระบบ
# §4.4 บันทึกไว้เองแล้วว่าเคยผิดกฎจริง (payload class อยู่ผิดชั้น) และกว่าจะเจอก็ตอนไล่ตรวจด้วยมือ
#
# ไฟล์นี้คือคำสั่งชุดเดียวกันนั้น ย้ายมาอยู่ใน CI แทน — Clean Architecture ที่ตรวจได้
# ไม่ใช่แค่ชื่อโฟลเดอร์
#
# รันเองได้: bash tool/check-architecture.sh
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0

# รันหนึ่งกฎ: ถ้า grep เจออะไร = ผิดกฎ (ทุกคำสั่งต้องไม่มี output)
rule() {
  local name="$1"; shift
  local out
  out="$("$@" 2>/dev/null || true)"
  if [ -n "$out" ]; then
    echo "  ✗ $name"
    echo "$out" | sed 's/^/      /'
    fail=1
  else
    echo "  ok  $name"
  fi
}

echo "Flutter — domain ต้องไม่รู้จัก data/presentation (§4.1)"
rule "domain ไม่ import จาก data/"         grep -rn "import.*['\"].*/data/"         app/lib/features/*/domain/
rule "domain ไม่ import จาก presentation/" grep -rn "import.*['\"].*/presentation/" app/lib/features/*/domain/
# เทียบเฉพาะบรรทัด import/export ไม่ใช่ทุกที่ที่มีคำว่า package:get — เพราะเจตนาของกฎคือ
# "domain ต้องไม่ *พึ่ง* GetX" ส่วนคอมเมนต์ที่อธิบายว่าทำไมถึงห้าม ไม่ใช่ dependency
# (คำสั่งเดิมใน CODING_STANDARDS §4.3 เป็น `grep -rln "package:get"` ซึ่งสะดุดคอมเมนต์ของตัวเอง
#  ตอนเอามาแขวนใน CI ครั้งแรก — อัปเดตเอกสารให้ตรงกับที่นี่แล้ว)
rule "domain ไม่ import package:get"      grep -rnE "^\s*(import|export) .*package:get" app/lib/features/*/domain/

echo
echo "Backend — service ไม่รู้จัก HTTP, controller/routes ไม่ข้าม service (§4.2)"
# ตัดคอมเมนต์ // ออกก่อนเทียบ ด้วยเหตุผลเดียวกับกฎ package:get ด้านบน — เจตนาของกฎคือ
# "service ต้องไม่ *พึ่ง* HTTP layer" ส่วนคอมเมนต์ที่อ้างถึง req.user/req.branchId เพื่ออธิบายว่า
# ค่านั้นมาจากไหน (หรือว่าทำไม service ตัวนี้ถึงไม่มีให้ใช้) ไม่ใช่ dependency
# (เจอตอน ticket 17: public-order.service.js กับ user.service.js มีแต่คอมเมนต์ ไม่มีโค้ดแตะ req/res
#  แต่กฎเดิมจับทั้งไฟล์ ทำให้ CI แดงทั้งที่ไม่มีอะไรผิดจริง)
services_touching_http() {
  local f
  for f in backend/src/modules/*/*.service.js; do
    sed 's://.*::' "$f" | grep -q "req\.\|res\." && echo "$f"
  done
  return 0
}
rule "service ไม่แตะ req/res ของ Express"  services_touching_http
rule "controller/routes ไม่ import repository ตรงๆ" \
  grep -rn "require.*\.repository" backend/src/modules/*/*.routes.js backend/src/modules/*/*.controller.js

echo
if [ "$fail" -ne 0 ]; then
  echo "ผิดกฎ dependency — ดู docs/CODING_STANDARDS.md §4.1/§4.2 ว่าแต่ละชั้นถูกทำให้พึ่งอะไรได้บ้าง"
  echo "และ §4.4 เป็นตัวอย่างจริงว่าเคยผิดกฎแบบไหนแล้วย้ายไฟล์ไปไว้ตรงไหนถึงถูก"
  exit 1
fi
echo "ทิศทาง dependency ถูกต้องทั้ง 5 กฎ"
