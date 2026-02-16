from PIL import Image
import os

files = ["/home/lamsak/Videojuego/assests/items/iron_sword.png"]

def clean_only(path):
    if not os.path.exists(path): return
    img = Image.open(path).convert("RGBA")
    
    # 1. Resize to 32x96 (KEEPING this as user liked the size, just not the rotation)
    # The artifact is 640x640. Original resize logic:
    bbox = img.getbbox()
    if bbox: img = img.crop(bbox)
    
    tg_w, tg_h = 32, 96
    img.thumbnail((tg_w, tg_h), Image.Resampling.LANCZOS)
    
    final_img = Image.new("RGBA", (tg_w, tg_h), (0, 0, 0, 0))
    offset_x = (tg_w - img.width) // 2
    offset_y = (tg_h - img.height) // 2
    final_img.paste(img, (offset_x, offset_y))
    
    # 2. Remove background (Simple tolerance)
    datas = final_img.getdata()
    new_data = []
    # Identify background from corner? Since we centered, corners are transparent (0,0,0,0).
    # Wait, if we pasted onto transparent, the original background is still inside the pasted image.
    # We should have removed background FIRST.
    
    # Redo:
    img = Image.open(path).convert("RGBA")
    datas = img.getdata()
    bg = datas[0] # Sample top-left
    
    new_data_raw = []
    threshold = 60
    for item in datas:
        diff = abs(item[0] - bg[0]) + abs(item[1] - bg[1]) + abs(item[2] - bg[2])
        if diff < threshold:
            new_data_raw.append((0, 0, 0, 0))
        else:
            new_data_raw.append(item)
            
    img.putdata(new_data_raw)
    
    # NOW Resize
    bbox = img.getbbox()
    if bbox: img = img.crop(bbox)
    img.thumbnail((32, 96), Image.Resampling.LANCZOS)
    
    final_img = Image.new("RGBA", (32, 96), (0, 0, 0, 0))
    offset_x = (32 - img.width) // 2
    offset_y = (96 - img.height) // 2
    final_img.paste(img, (offset_x, offset_y))
    
    final_img.save(path)
    print("Sword reverted and cleaned.")

for f in files: clean_only(f)
