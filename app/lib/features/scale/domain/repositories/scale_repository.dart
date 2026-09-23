import '../../../../core/usecases/result.dart';
import '../entities/scale_status.dart';

abstract class ScaleRepository {
  /// สถานะล่าสุด — เรียกครั้งแรกตอนเปิดกล่องชั่งน้ำหนัก
  Future<Result<ScaleStatus>> status();

  /// น้ำหนักสดที่เซิร์ฟเวอร์กระจายมา (socket event `scale:reading`) — ยกเลิกด้วย cancel()
  Stream<ScaleStatus> watch();
}
