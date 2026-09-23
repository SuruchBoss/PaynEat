import net from 'node:net';

/**
 * ช่องทางอ่านข้อมูลจากตาชั่ง — ทุก driver ทำแค่ "ส่งข้อความทีละบรรทัด" ให้ scale.service.js ไม่รู้เรื่อง
 * รูปแบบน้ำหนัก (อยู่ที่ scale.parser.js) interface เดียวกันหมด:
 *
 *   driver.start({ onLine, onStatus })   onStatus({ connected, error })
 *   driver.write(text)                   ส่งคำสั่งถามน้ำหนัก (ตาชั่งแบบถาม-ตอบ)
 *   driver.stop()
 */

/** ตัดสตรีมเป็นบรรทัด — ตาชั่งแต่ละรุ่นจบบรรทัดด้วย CR, LF หรือ CRLF ไม่เหมือนกัน */
const lineSplitter = (onLine) => {
  let buffer = '';
  return (chunk) => {
    buffer += chunk.toString('latin1');
    const parts = buffer.split(/\r\n|\r|\n/);
    buffer = parts.pop() ?? '';
    // กันตาชั่งที่ไม่เคยส่งตัวจบบรรทัดทำ buffer โตไม่รู้จบ
    if (buffer.length > 256) buffer = buffer.slice(-256);
    for (const part of parts) if (part.trim()) onLine(part);
  };
};

/** ต่อซ้ำเมื่อหลุด: 1s, 2s, 4s ... สูงสุด 30s (สายหลุด/ตาชั่งปิด-เปิด เป็นเรื่องปกติหน้าร้าน) */
const backoff = (attempt) => Math.min(1000 * 2 ** attempt, 30_000);

export const tcpDriver = ({ host, port }) => {
  let socket = null;
  let stopped = false;
  let attempt = 0;
  let retryTimer = null;

  const connect = ({ onLine, onStatus }) => {
    if (stopped) return;
    socket = net.createConnection({ host, port });
    socket.setNoDelay(true);
    socket.on('connect', () => {
      attempt = 0;
      onStatus({ connected: true, error: null });
    });
    socket.on('data', lineSplitter(onLine));
    socket.on('error', (error) => onStatus({ connected: false, error: error.message }));
    socket.on('close', () => {
      onStatus({ connected: false });
      if (stopped) return;
      retryTimer = setTimeout(() => connect({ onLine, onStatus }), backoff(attempt));
      attempt += 1;
    });
  };

  return {
    start: (handlers) => connect(handlers),
    write: (text) => {
      if (socket?.writable) socket.write(text);
    },
    stop: () => {
      stopped = true;
      clearTimeout(retryTimer);
      socket?.destroy();
    },
  };
};

/**
 * USB/RS-232 ต่อเข้าเครื่องเซิร์ฟเวอร์ตรง — serialport เป็น native module (optionalDependencies)
 * import แบบ dynamic: ติดตั้งไม่ผ่านบนเครื่องไหนก็ไม่ทำให้ทั้งเซิร์ฟเวอร์ start ไม่ขึ้น แค่ตาชั่งใช้ไม่ได้
 */
export const serialDriver = ({ path, baudRate }) => {
  let port = null;
  let stopped = false;
  let attempt = 0;
  let retryTimer = null;

  const open = async ({ onLine, onStatus }) => {
    if (stopped) return;
    let SerialPort;
    try {
      ({ SerialPort } = await import('serialport'));
    } catch {
      onStatus({
        connected: false,
        error:
          'ไม่ได้ติดตั้งแพ็กเกจ serialport — รัน npm install ในเครื่องที่ต่อตาชั่ง หรือใช้ SCALE_DRIVER=tcp',
      });
      return;
    }
    if (!path) {
      onStatus({
        connected: false,
        error: 'ยังไม่ได้ตั้ง SCALE_SERIAL_PATH (เช่น /dev/ttyUSB0 หรือ COM3)',
      });
      return;
    }
    port = new SerialPort({ path, baudRate, autoOpen: false });
    port.on('data', lineSplitter(onLine));
    port.on('error', (error) => onStatus({ connected: false, error: error.message }));
    port.on('close', () => {
      onStatus({ connected: false });
      if (!stopped) retryTimer = setTimeout(() => open({ onLine, onStatus }), backoff(attempt++));
    });
    port.open((error) => {
      if (error) {
        onStatus({ connected: false, error: error.message });
        if (!stopped) retryTimer = setTimeout(() => open({ onLine, onStatus }), backoff(attempt++));
        return;
      }
      attempt = 0;
      onStatus({ connected: true, error: null });
    });
  };

  return {
    start: (handlers) => {
      open(handlers);
    },
    write: (text) => {
      if (port?.isOpen) port.write(text);
    },
    stop: () => {
      stopped = true;
      clearTimeout(retryTimer);
      if (port?.isOpen) port.close();
    },
  };
};

/**
 * ตาชั่งจำลอง — วนรอบ "วางของ → ตัวเลขแกว่ง → นิ่ง → ยกออก" ส่งข้อความรูปแบบ A&D จริงผ่าน parser
 * ตัวเดียวกับเครื่องจริง ใช้เดโมหน้าร้าน/ทดสอบ E2E โดยไม่ต้องมีตาชั่ง
 */
export const simulatorDriver = ({ intervalMs = 400 } = {}) => {
  let timer = null;
  let tick = 0;
  let target = 485;

  const frame = () => {
    const phase = tick % 20;
    tick += 1;
    if (phase === 0) target = 250 + Math.round(Math.random() * 1250);
    if (phase < 3) return 'ST,GS,+0000.000kg';
    if (phase < 6) {
      const wobble = Math.round(target * (0.7 + phase * 0.08));
      return `US,GS,+${(wobble / 1000).toFixed(3).padStart(8, '0')}kg`;
    }
    if (phase < 17) return `ST,GS,+${(target / 1000).toFixed(3).padStart(8, '0')}kg`;
    return 'US,GS,+0000.020kg';
  };

  return {
    start: ({ onLine, onStatus }) => {
      onStatus({ connected: true, error: null });
      onLine(frame());
      timer = setInterval(() => onLine(frame()), intervalMs);
    },
    write: () => {},
    stop: () => clearInterval(timer),
  };
};

export const createDriver = (config) => {
  switch (config.driver) {
    case 'tcp':
      return tcpDriver(config);
    case 'serial':
      return serialDriver({ path: config.serialPath, baudRate: config.baudRate });
    case 'simulator':
      return simulatorDriver(config);
    default:
      return null;
  }
};
