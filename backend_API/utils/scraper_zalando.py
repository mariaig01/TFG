import requests
import pandas as pd


class ZalandoScraper:
    def __init__(self, category="clothing-men", keyword=None, limit=20, offset=0):
        self.base_url = "https://www.zalando.es/api/catalog/articles"
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0",
            "Accept": "application/json",
            "Accept-Language": "es-ES,es;q=0.9",
            "Referer": "https://www.zalando.es/hombre-home/"
        }

        self.params = {
            "categories": category,
            "limit": limit,
            "offset": offset,
            "sort": "popularity"
        }
        if keyword:
            self.params["q"] = keyword


    def fetch_products(self):
        try:
            response = requests.get(self.base_url, headers=self.headers, params=self.params)
            if response.status_code != 200:
                print(f"Error {response.status_code} al obtener datos de Zalando")
                print("Contenido devuelto:", response.text[:300])
                return []

            data = response.json()
            productos = []

            for item in data.get("articles", []):
                nombre = item.get("name")
                precio = item.get("price", {}).get("formatted")
                imagen = item.get("media", {}).get("images", [{}])[0].get("smallUrl")
                link = f"https://www.zalando.es{item.get('url')}"

                productos.append({
                    "nombre": nombre,
                    "precio": precio,
                    "imagen": imagen,
                    "enlace": link
                })

            return productos

        except Exception as e:
            print("Excepción capturada:", str(e))
            return []

    def to_dataframe(self, productos):
        return pd.DataFrame(productos)

    def save_excel(self, productos, nombre_archivo="productos_zalando.xlsx"):
        df = self.to_dataframe(productos)
        df.to_excel(nombre_archivo, index=False, engine="openpyxl")
        print(f"Guardado en {nombre_archivo}")



# ======================
# EJEMPLO DE USO
# ======================
if __name__ == "__main__":
    # Ejemplo: ropa casual negra de hombre
    scraper = ZalandoScraper(category="clothing-men", keyword="negro casual", limit=20)
    productos = scraper.fetch_products()

    for producto in productos:
        print(f"{producto['nombre']} - {producto['precio']}")
        print(f"Link: {producto['enlace']}")
        print(f"Imagen: {producto['imagen']}")
        print("-" * 60)

    # Guardar como CSV si quieres
    scraper.save_csv(productos)
