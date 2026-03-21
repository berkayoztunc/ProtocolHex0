import zipfile, os

zip_path = '/tmp/genihero_updated.zip'
dest_base = '/Users/berkay/Desktop/work/geni-hero/assets/characters/genihero_ui'

with zipfile.ZipFile(zip_path) as z:
    names = z.namelist()
    print(f'ZIP: {len(names)} files')

    anim_dirs = sorted(set('/'.join(n.split('/')[:3]) for n in names if 'animations' in n))
    print('Animation dirs in ZIP:')
    for d in anim_dirs:
        print(' ', d)

    wanted = [
        'animations/breathing-idle/east',
        'animations/breathing-idle/west',
        'animations/walk/east',
        'animations/walk/west',
    ]

    extracted = 0
    for member in names:
        if not member.endswith('.png'):
            continue
        for w in wanted:
            if w in member:
                parts = member.split('/')
                try:
                    ai = parts.index('animations')
                    rel = '/'.join(parts[ai:])
                    target = os.path.join(dest_base, rel)
                    os.makedirs(os.path.dirname(target), exist_ok=True)
                    with z.open(member) as src, open(target, 'wb') as dst:
                        dst.write(src.read())
                    extracted += 1
                    print(f'  -> {rel}')
                except ValueError:
                    pass
                break

    print(f'\nExtracted {extracted} frames total')
