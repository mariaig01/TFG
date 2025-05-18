import cv2
import numpy as np
import mediapipe as mp
from sklearn.cluster import KMeans
from utils.hair_color import detect_hair_color
from utils.eye_color import detect_eye_color

# Inicializar MediaPipe solo una vez
mp_face_detection = mp.solutions.face_detection
mp_face_mesh = mp.solutions.face_mesh
detector = mp_face_detection.FaceDetection(model_selection=1, min_detection_confidence=0.5)
face_mesh = mp_face_mesh.FaceMesh(static_image_mode=True, max_num_faces=1, refine_landmarks=True)

def _extraer_color_dominante(region, k=1):
    if region.size == 0:
        return np.array([128, 128, 128])  # color neutro por defecto
    region = cv2.cvtColor(region, cv2.COLOR_BGR2RGB)
    reshaped = region.reshape((-1, 3))
    reshaped = reshaped[np.any(reshaped != [0, 0, 0], axis=1)]
    if len(reshaped) == 0:
        return np.array([128, 128, 128])
    if k == 1 or len(reshaped) < k:
        return np.mean(reshaped, axis=0)
    kmeans = KMeans(n_clusters=k, random_state=0).fit(reshaped)
    return kmeans.cluster_centers_[0]

def _clasificar_subtono(rgb_color):
    r, g, b = rgb_color
    if r > b and r > g:
        return 'cálido'
    elif b > r:
        return 'frío'
    else:
        return 'neutro'

def determinar_subestacion(tono_piel, color_pelo, color_ojos):
    pelo = color_pelo.lower()
    ojos = color_ojos.lower()

    if tono_piel == "claro":
        if pelo in ["blonde", "light brown"]:
            if ojos in ["blue", "green"]:
                return "Primavera Brillante"
            elif ojos in ["blue gray", "green gray"]:
                return "Primavera Suave"
        elif pelo in ["dark brown", "black"]:
            return "Verano Suave"

    elif tono_piel == "medio":
        if pelo in ["light brown", "dark brown"]:
            if ojos in ["brown", "brown gray"]:
                return "Otoño Verdadero"
            elif ojos in ["green", "green gray"]:
                return "Primavera Verdadera"
        elif pelo in ["black"]:
            return "Invierno Verdadero"

    elif tono_piel == "oscuro":
        if pelo in ["black", "brown black"]:
            if ojos in ["brown", "brown black", "blue gray"]:
                return "Invierno Oscuro"
            elif ojos in ["green gray", "blue"]:
                return "Invierno Brillante"
        elif pelo in ["dark brown"]:
            return "Otoño Oscuro"

    return "Verano Suave"

def colores_por_subestacion(subestacion):
    paletas = {
        "Primavera Verdadera": ["#F3E0BE", "#F5CDA0", "#F0D095", "#D8A760", "#D8BFA5",
        "#DAD3A4", "#D9CBA6", "#F6C289", "#C49E60", "#4E3B31",
        "#F6BE9A", "#F9CB73", "#F9C450", "#FCA94D", "#F47C7C",
        "#EC8E7D", "#EF6E5C", "#DA3D3D", "#E3496B", "#E23D6D",
        "#A7C6E3", "#80A1C1", "#487AA1", "#1C5E9C", "#1C6BA0",
        "#70C28D", "#34A853", "#36D3B1", "#4DBA87", "#00A28A",
        "#6EC07F", "#C2E076", "#A4D2D2", "#ADD9DE", "#007F7C"
        ],
        "Primavera Brillante": ["#F0ECE2", "#F6E2B3", "#EFCB8A", "#E3C7A5", "#D7CEC7",
        "#D2D3D5", "#5A5149", "#625D5D", "#2E3A66", "#2D4D6E",
        "#FFC845", "#FBBF75", "#E9A837", "#A9746E", "#B83A4B",
        "#D298A0", "#F69DAC", "#F760A7", "#FF86B3", "#D54C5C",
        "#E83F87", "#C53163", "#BA0C2F", "#2C4466", "#2B3E4C",
        "#48C6DC", "#008C72", "#009E6D", "#1E4956", "#005A70",
        "#A3C9A8", "#5FB548", "#BFD641", "#9DBFAF", "#86A293"
        ],
        "Primavera Suave": ["#F3E0C0", "#F5E3D0", "#E8D9C4", "#EAD1AE", "#D6C4B3",
        "#D6CDC4", "#B3AFA4", "#B7B1A9", "#7A6856", "#5E5045",
        "#F2E16D", "#F9DC6C", "#FCD25C", "#F8C85A", "#FDB66A",
        "#F4C7C3", "#F8C6C4", "#FBB9A3", "#F7A8A4", "#F79685",
        "#C2A3CF", "#C778A3", "#9F8FCE", "#C3A78F", "#A17B64",
        "#97D1E3", "#8BC8DE", "#5BC3D4", "#53C1D2", "#1FA9B3",
        "#C8E2B6", "#B6D7B1", "#A7CF87", "#A0D68C", "#A9D6C4"
        ],
        "Verano Suave": ["#EDEBE4", "#E8DED1", "#C6BEB4", "#B4B3B3", "#B9B1AB",
        "#C0B4AF", "#B5A8A4", "#927C7B", "#7C6664", "#8C6D7A",
        "#FA8072", "#D67C7C", "#FA6F65", "#E75464", "#B03A5B",
        "#F7C5CC", "#F3A6B0", "#F5B3BC", "#CE4176", "#A24D84",
        "#A9C8E2", "#A0B6D9", "#6D9DC5", "#4682B4", "#40788A",
        "#4BC1C5", "#3DC5E2", "#45D2C5", "#4AA3A2", "#38817A",
        "#C7EACB", "#A7D8B9", "#4CB7A5", "#1D9F8D", "#88BBA8"
        ],
        "Verano Verdadero": ["#E1DED3", "#EAE3DC", "#C5C5C5", "#9C9A9A", "#7C6F65",
        "#A5A8A6", "#B6A49A", "#8D848A", "#837F82", "#4C4E50",
        "#8DA3B1", "#7B8B94", "#84928C", "#6C7B7F", "#484C51",
        "#E6B3B3", "#D88A8A", "#EF7C8E", "#C75B76", "#8C3F4D",
        "#B4B1DA", "#A8A2D1", "#758AA8", "#4E517F", "#2C2D52",
        "#4EB3C9", "#3FA6B2", "#3AAE9A", "#3C6B5E", "#30575D",
        "#2F8477", "#4FBBA3", "#00594F", "#00756C", "#517B7F"
        ],
        "Verano Apagado": ["#E3E4DC", "#E8DFD7", "#BEB6AC", "#A69E98", "#786E67",
        "#B4B4B0", "#91928F", "#BCB6B0", "#8D8884", "#635A59",
        "#E8C1C5", "#F4C4C9", "#EF9A9E", "#B76B75", "#9D4E5B",
        "#E3B7C2", "#D28A87", "#B86D73", "#8A5B65", "#6D465B",
        "#9EB2CC", "#A299B6", "#A99ACD", "#7A7A93", "#5A5C81",
        "#78C1CA", "#A1D2CE", "#5AC1C3", "#4D9592", "#2A6262",
        "#91B796", "#B7D9C6", "#3E5E4D", "#507F70", "#7C8374"
        ],
        "Otoño Apagado": ["#F6E7C8", "#F3E9DA", "#D6CDBE", "#DAD5C2", "#CFCFB2",
        "#A3AE88", "#C0BFB1", "#4D4B39", "#C1BCA3", "#807E6A",
        "#855C52", "#944D3A", "#87503A", "#864B3A", "#73433E",
        "#E2A9A1", "#E48D81", "#C55C72", "#D16E5C", "#C8484E",
        "#F7CDD4", "#F2B5AF", "#D27A8A", "#B65F68", "#9C3E42",
        "#A6B9C6", "#6B8BAF", "#567BAE", "#1C4F5A", "#295468",
        "#A0D3CE", "#D1C0B4", "#1E6351", "#007163", "#2D5F5D"
        ],
        "Otoño Verdadero": ["#DDD6CB", "#E6D6C8", "#D8CDBE", "#F3E3C2", "#F2E3B0",
        "#BAB9A3", "#8A8C6D", "#948F7A", "#676053", "#3F4138",
        "#F5C1A6", "#E8A478", "#B86A55", "#984E45", "#583638",
        "#F6A666", "#F29C52", "#DF7A3F", "#A75344", "#944437",
        "#EBAF9B", "#F6C6C8", "#C94468", "#782C3F", "#6E263D",
        "#59C3CE", "#007C7A", "#84C5B1", "#5CA6A4", "#165C4C",
        "#7A785E", "#A8A77A", "#CBA852", "#48775E", "#43453E"
        ],
        "Otoño Oscuro": ["#E5D8CC", "#D6C7BA", "#E3CDBD", "#C6A78C", "#D1BEB0",
        "#D1BCA3", "#D4BAA3", "#4D4740", "#B59E89", "#4E4B4D",
        "#D2A24C", "#F0B323", "#B17A2B", "#E5A76D", "#CC8052",
        "#DB7B8E", "#E57967", "#BE5654", "#8D4E4B", "#792E38",
        "#DCB1D0", "#D36BC6", "#E65DA2", "#9C6B9C", "#42526C",
        "#56C1C2", "#3AA8A1", "#56766A", "#2E4E45", "#37473F",
        "#C0D4A4", "#8D9A7B", "#5C5F4E", "#6A5750", "#D3A950"
        ],
        "Invierno Oscuro": ["#F2F3F9", "#E8E3DC", "#D6D0C4", "#D4D7D9", "#A6A4A5",
        "#F1E3A1", "#F4D5DA", "#C4D9D5", "#F0C4D7", "#ADA0CA",
        "#F49AC1", "#EF95A4", "#E73D6D", "#E03C71", "#9B3259",
        "#C62345", "#D3274D", "#C62839", "#912F46", "#6A2C39",
        "#A385C1", "#9D85C1", "#7A5884", "#573B75", "#403F6F",
        "#A0D4EF", "#4A90B5", "#00587C", "#153D6F", "#304B87",
        "#00767A", "#7FC6B6", "#1B4F4A", "#3E3A39", "#574144"
        ],
        "Invierno Verdadero": ["#F2F4FC", "#F4F1EC", "#E2E1DA", "#D0CDD0", "#A09F9E",
        "#F1D5DA", "#F6ED9D", "#C1E1D2", "#CDEAF2", "#B4CCE4",
        "#E8C3D1", "#F8A8C1", "#F964A3", "#A9275D", "#91377C",
        "#E8C1E1", "#B95FA1", "#C77BAF", "#6B3F6B", "#843C74",
        "#7F8ED3", "#405BA8", "#003A70", "#1C3C85", "#1F2A52",
        "#00B4D5", "#317DA8", "#006E6B", "#006F7B", "#444D23",
        "#512E6F", "#1E2947", "#152E5F", "#3E2F2B", "#524B44"
        ],
        "Invierno Brillante": ["#F6F8FC", "#ECE8DF", "#DAD1C3", "#C1BEB8", "#B6B5B7",
        "#F6E79A", "#F5D3D0", "#B7E3E2", "#EDB5D6", "#C5B8DA",
        "#E67389", "#F78DA7", "#E73B8D", "#DB3C87", "#852F5B",
        "#E12B8C", "#DE2D81", "#D72875", "#C03A8D", "#82426E",
        "#918BC3", "#4C66B4", "#2D3E7F", "#24327C", "#3076B7",
        "#A87D6F", "#2BA68C", "#208BCB", "#1C85A6", "#1A9FB1",
        "#32244E", "#101820", "#161C1F", "#2E294E", "#313638"
        ],
    }
    return paletas.get(subestacion, ["colores neutros"])


def recomendaciones_maquillaje_por_subestacion(subestacion):
    maquillaje = {
        "Primavera Brillante": [
            "Base ligera con acabado luminoso",
            "Colorete en tonos melocotón o coral",
            "Sombras doradas, champagne o verdes menta",
            "Labiales en tonos coral, fresa o rosa vivo"
        ],
        "Primavera Cálida": [
            "Base con subtono cálido",
            "Colorete en tonos durazno o albaricoque",
            "Sombras en tonos tierra claros y dorados",
            "Labiales en tonos salmón o coral suave"
        ],
        "Primavera Clara": [
            "Base ligera con acabado natural",
            "Colorete en tonos rosa claro o melocotón",
            "Sombras en tonos pastel como rosa, lavanda o verde menta",
            "Labiales en tonos rosa claro o coral suave"
        ],
        "Verano Suave": [
            "Base satinada o semi-mate",
            "Colorete en tonos rosa empolvado o malva",
            "Sombras en tonos lavanda, rosa suave o gris topo",
            "Labiales en tonos nude rosados o frambuesa claro"
        ],
        "Verano Frío": [
            "Base con subtono rosa",
            "Colorete en tonos rosa frío o malva",
            "Sombras en tonos azul acero, gris o lavanda",
            "Labiales en tonos rosa frío o ciruela claro"
        ],
        "Verano Claro": [
            "Base ligera con acabado luminoso",
            "Colorete en tonos rosa claro o melocotón",
            "Sombras en tonos pastel como azul cielo o verde menta",
            "Labiales en tonos rosa claro o coral suave"
        ],
        "Otoño Verdadero": [
            "Base cálida mate o luminosa",
            "Colorete en tonos terracota o melocotón",
            "Sombras en tonos cobre, verde oliva o marrones cálidos",
            "Labiales en tonos teja, ladrillo o anaranjados"
        ],
        "Otoño Profundo": [
            "Base con subtono cálido y cobertura media",
            "Colorete en tonos ciruela o bronce",
            "Sombras en tonos chocolate, verde bosque o bronce",
            "Labiales en tonos vino, marrón rojizo o terracota"
        ],
        "Otoño Suave": [
            "Base con acabado natural y subtono cálido",
            "Colorete en tonos melocotón suave o rosa cálido",
            "Sombras en tonos beige, topo o verde oliva claro",
            "Labiales en tonos nude cálidos o coral suave"
        ],
        "Invierno Oscuro": [
            "Base mate de alta cobertura",
            "Colorete en tonos ciruela o burdeos",
            "Sombras en tonos esmeralda, granate o azul marino",
            "Labiales en tonos vino, rojo oscuro o fucsia profundo"
        ],
        "Invierno Brillante": [
            "Base con acabado luminoso y subtono frío",
            "Colorete en tonos rosa intenso o fucsia",
            "Sombras en tonos azul eléctrico, plata o morado vibrante",
            "Labiales en tonos rojo cereza, fucsia o rosa brillante"
        ],
        "Invierno Frío": [
            "Base con subtono rosado y acabado mate",
            "Colorete en tonos rosa frío o malva",
            "Sombras en tonos gris, azul acero o púrpura",
            "Labiales en tonos rojo frío, ciruela o rosa intenso"
        ]
    }
    return maquillaje.get(subestacion, ["Usa tonos neutros y adaptados a tu estilo."])


def recomendaciones_maquillaje_ojos(color_ojos):
    ojos = color_ojos.lower()

    if ojos in ["blue", "blue gray"]:
        return [
            "Sombras en tonos cálidos como cobre, bronce y dorado",
            "Evita sombras azules similares al iris",
            "Delineador marrón oscuro o negro para mayor contraste"
        ]

    elif ojos in ["green", "green gray"]:
        return [
            "Sombras en tonos ciruela, vino, rojizos o dorados",
            "Evita verdes similares al iris para evitar uniformidad",
            "Delineador negro o morado oscuro para resaltar"
        ]

    elif ojos in ["brown", "brown gray", "brown black"]:
        return [
            "Sombras en tonos azul marino, verde esmeralda, dorado o berenjena",
            "Puedes experimentar con una gran variedad de tonos",
            "Delineador negro intenso o violeta oscuro para mayor impacto"
        ]

    elif ojos == "other":
        return [
            "Sombras en tonos universales como bronce, gris topo o champán",
            "Evita contrastes extremos si el tono del ojo es muy claro",
            "Delineador gris oscuro o marrón suave"
        ]

    else:
        return ["Color de ojos no reconocido. Usa tonos neutros como marrón, bronce o gris."]


def analizar_imagen_completa(path_imagen):
    imagen_bgr = cv2.imread(path_imagen)
    if imagen_bgr is None:
        return {"error": "No se pudo leer la imagen"}

    imagen_rgb = cv2.cvtColor(imagen_bgr, cv2.COLOR_BGR2RGB)
    resultado = detector.process(imagen_rgb)
    if not resultado.detections:
        return {"error": "No se detectó rostro"}

    h, w, _ = imagen_bgr.shape

    face_result = face_mesh.process(imagen_rgb)
    if not face_result.multi_face_landmarks:
        return {"error": "No se detectaron landmarks"}

    puntos = face_result.multi_face_landmarks[0].landmark

    # PIEL
    puntos_mejilla_ids = [117, 346, 425, 205]
    puntos_mejilla = np.array([[int(puntos[pid].x * w), int(puntos[pid].y * h)] for pid in puntos_mejilla_ids])

    # Crear máscara para el polígono
    mask = np.zeros((h, w), dtype=np.uint8)
    cv2.fillConvexPoly(mask, puntos_mejilla, 255)

    # Extraer píxeles dentro del polígono
    region = imagen_bgr.copy()
    region_masked = cv2.bitwise_and(region, region, mask=mask)

    # Extraer color dominante
    color_piel = _extraer_color_dominante(region_masked)

    # Clasificar el tono
    tono_piel = "claro" if np.mean(color_piel) > 170 else "oscuro" if np.mean(color_piel) < 100 else "medio"

    # Dibujar polígono rojo sobre la imagen
    cv2.polylines(imagen_bgr, [puntos_mejilla], isClosed=True, color=(0, 0, 255), thickness=2)

    # PELO
    try:
        color_pelo_nombre = detect_hair_color(path_imagen, visualize=False)
    except Exception as e:
        return {"error": f"Error detectando color de pelo: {str(e)}"}

    try:
        color_ojos = detect_eye_color(path_imagen, visualize=False)
    except Exception as e:
        return {"error": f"Error detectando color de pelo: {str(e)}"}


    maquillaje_ojos = recomendaciones_maquillaje_ojos(color_ojos)
    subestacion = determinar_subestacion(tono_piel, color_pelo_nombre, color_ojos)
    maquillaje = recomendaciones_maquillaje_por_subestacion(subestacion)
    colores_recomendados = colores_por_subestacion(subestacion)

    return {
        "tono_piel": tono_piel,
        "color_pelo": color_pelo_nombre,
        "color_ojos": color_ojos,
        "subestacion": subestacion,
        "colores_recomendados": colores_recomendados,
        "maquillaje": maquillaje,
        "maquillaje_ojos": maquillaje_ojos
    }



