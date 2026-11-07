# -*- coding: utf-8 -*-
"""重新生成「摄影欣赏相册-分享包」ZIP。

用法：在 album-app/ 目录下运行  python make_share_zip.py
结果放在上一级目录，文件名带当天日期。
包内全部使用 ASCII 文件名 + 正斜杠路径，兼容所有解压工具。
"""
import datetime
import os
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
PARENT = os.path.dirname(HERE)

FILES = [
    'album.html',
    'config.js',
    'album-sw.js',
    'album-manifest.webmanifest',
    'album-icon.svg',
    'album-icon-192.png',
    'album-icon-512.png',
    'start-album.bat',
    'start-album-phone.bat',
    'start-album.ps1',
    'README-FIRST.txt',
    'README.md',
]


def main():
    missing = [f for f in FILES if not os.path.isfile(os.path.join(HERE, f))]
    if missing:
        raise SystemExit('缺少文件: ' + ', '.join(missing))

    day = datetime.date.today().strftime('%Y%m%d')
    out = os.path.join(PARENT, '摄影欣赏相册-分享包-%s.zip' % day)

    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for f in FILES:
            z.write(os.path.join(HERE, f), 'photo-album/' + f)

    with zipfile.ZipFile(out) as z:
        crc = 'OK' if z.testzip() is None else 'FAILED'
        count = len(z.infolist())

    print('已生成:', out)
    print('大小  :', os.path.getsize(out), 'bytes')
    print('条目  :', count)
    print('CRC   :', crc)


if __name__ == '__main__':
    main()
