import os
from PIL import Image

src = os.path.join(os.path.dirname(__file__), 'assets', 'logo.png')
if not os.path.exists(src):
    print(f'ERROR: {src} not found! Place your logo at vibedeck-app/assets/logo.png')
    exit(1)

img = Image.open(src).convert('RGBA')

sizes = {
    'mipmap-mdpi': (48, 48),
    'mipmap-hdpi': (72, 72),
    'mipmap-xhdpi': (96, 96),
    'mipmap-xxhdpi': (144, 144),
    'mipmap-xxxhdpi': (192, 192),
}

res_dir = os.path.join(os.path.dirname(__file__), 'android', 'app', 'src', 'main', 'res')
for folder, size in sizes.items():
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'ic_launcher.png')
    resized = img.resize(size, Image.Resampling.LANCZOS)
    resized.save(out_path, 'PNG')
    print(f'Generated {folder}/ic_launcher.png ({size[0]}x{size[1]})')

print('\nSUCCESS: All Android launcher icons updated from assets/logo.png!')
