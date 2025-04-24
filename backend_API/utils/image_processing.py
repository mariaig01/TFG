from rembg import remove
from PIL import Image

def remove_background_and_white_bg(input_path, output_path, eliminar_fondo=True):
    input_image = Image.open(input_path).convert("RGBA")

    if eliminar_fondo:
        output_image = remove(input_image)
        white_bg = Image.new("RGBA", output_image.size, (255, 255, 255, 255))
        white_bg.paste(output_image, mask=output_image.split()[3])
        white_bg.convert("RGB").save(output_path)
    else:
        input_image.convert("RGB").save(output_path)
