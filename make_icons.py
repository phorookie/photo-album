import zlib, struct, math, os

S = 2  # supersample

def in_round(px, py, x0, y0, x1, y1, r):
    if px < x0 or px > x1 or py < y0 or py > y1:
        return False
    cx = x0 + r if px < x0 + r else (x1 - r if px > x1 - r else px)
    cy = y0 + r if py < y0 + r else (y1 - r if py > y1 - r else py)
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r

def in_circle(px, py, cx, cy, r):
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r

class Buf:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.b = bytearray(w * h * 4)
    def blend(self, x, y, r, g, bl, a):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 4
            da = self.b[i + 3] / 255.0
            sa = a / 255.0
            oa = sa + da * (1 - sa)
            if oa <= 0:
                return
            self.b[i] = int((r * sa + self.b[i] * da * (1 - sa)) / oa)
            self.b[i + 1] = int((g * sa + self.b[i + 1] * da * (1 - sa)) / oa)
            self.b[i + 2] = int((bl * sa + self.b[i + 2] * da * (1 - sa)) / oa)
            self.b[i + 3] = int(oa * 255)

def fill_round(buf, x0, y0, x1, y1, r, col):
    R, G, B, A = col
    for y in range(int(y0 * S), int(y1 * S) + 1):
        for x in range(int(x0 * S), int(x1 * S) + 1):
            px, py = (x + 0.5) / S, (y + 0.5) / S
            if in_round(px, py, x0, y0, x1, y1, r):
                buf.blend(x, y, R, G, B, A)

def fill_circle(buf, cx, cy, r, col):
    R, G, B, A = col
    for y in range(int((cy - r) * S), int((cy + r) * S) + 1):
        for x in range(int((cx - r) * S), int((cx + r) * S) + 1):
            px, py = (x + 0.5) / S, (y + 0.5) / S
            if in_circle(px, py, cx, cy, r):
                buf.blend(x, y, R, G, B, A)

def fill_tri(buf, ax, ay, bx, by, cx, cy, col):
    R, G, B, A = col
    minx, maxx = int(min(ax, bx, cx) * S), int(max(ax, bx, cx) * S) + 1
    miny, maxy = int(min(ay, by, cy) * S), int(max(ay, by, cy) * S) + 1
    for y in range(miny, maxy):
        for x in range(minx, maxx):
            px, py = (x + 0.5) / S, (y + 0.5) / S
            d1 = (px - bx) * (ay - by) - (ax - bx) * (py - by)
            d2 = (px - cx) * (by - cy) - (bx - cx) * (py - cy)
            d3 = (px - ax) * (cy - ay) - (cx - ax) * (py - ay)
            neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
            pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
            if not (neg and pos):
                buf.blend(x, y, R, G, B, A)

def draw(N, out):
    fw, fh = N * S, N * S
    buf = Buf(fw, fh)
    k = N / 512.0
    BLUE = (47, 111, 237, 255)
    WHITE = (255, 255, 255, 255)
    # 圆角方底
    fill_round(buf, 64 * k, 64 * k, 448 * k, 448 * k, 96 * k, BLUE)
    # 相框（白底 + 内部镂空回蓝色）
    fill_round(buf, 152 * k, 160 * k, 360 * k, 352 * k, 28 * k, WHITE)
    fill_round(buf, 176 * k, 184 * k, 336 * k, 328 * k, 14 * k, BLUE)
    # 山
    fill_tri(buf, 192 * k, 300 * k, 256 * k, 224 * k, 320 * k, 300 * k, WHITE)
    # 太阳
    fill_circle(buf, 296 * k, 206 * k, 16 * k, WHITE)
    # 降采样
    data = bytearray(N * N * 4)
    for y in range(N):
        for x in range(N):
            rs = gs = bs = as_ = 0
            for dy in range(S):
                for dx in range(S):
                    i = (((y * S + dy) * fw) + (x * S + dx)) * 4
                    rs += buf.b[i]; gs += buf.b[i + 1]; bs += buf.b[i + 2]; as_ += buf.b[i + 3]
            n = S * S
            j = (y * N + x) * 4
            data[j] = rs // n; data[j + 1] = gs // n; data[j + 2] = bs // n; data[j + 3] = as_ // n
    write_png(out, data, N, N)
    print('written', out, N, 'x', N, os.path.getsize(out), 'bytes')

def write_png(path, data, w, h):
    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    raw = b''.join(b'\x00' + bytes(data[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    png = b'\x89PNG\r\n\x1a\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', zlib.compress(raw, 9))
    png += chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(png)

here = os.path.dirname(os.path.abspath(__file__))
draw(192, os.path.join(here, 'album-icon-192.png'))
draw(512, os.path.join(here, 'album-icon-512.png'))
