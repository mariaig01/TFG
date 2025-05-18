import requests
import pandas as pd

class SheinScraper:
    def __init__(self, keyword="camiseta mujer", limit=20, page=1):
        self.base_url = "https://www.shein.com/index.php"
        self.headers = {
            "User-Agent": "Mozilla/5.0",
            "Referer": "https://www.shein.com/"
        }
        self.params = {
            "app": "search_portal",
            "lang": "es",
            "currency": "EUR",
            "keyword": keyword,
            "page": page,
            "page_size": limit
        }

    def fetch_products(self):
        try:
            response = requests.get(self.base_url, headers=self.headers, params=self.params)
            if response.status_code != 200:
                print(f"Error {response.status_code} al obtener datos de SHEIN")
                print("Contenido devuelto:", response.text[:300])
                return []

            data = response.json()
            productos = []

            for item in data.get("goods_list", []):
                nombre = item.get("goods_name")
                precio = item.get("retail_price")
                imagen = item.get("goods_img")
                enlace = "https://es.shein.com/" + item.get("goods_url", "")

                productos.append({
                    "nombre": nombre,
                    "precio": f"{precio} €",
                    "imagen": imagen,
                    "enlace": enlace
                })

            return productos

        except Exception as e:
            print("Excepción:", str(e))
            return []

    def to_dataframe(self, productos):
        return pd.DataFrame(productos)

    def save_excel(self, productos, nombre_archivo="productos_shein.xlsx"):
        df = self.to_dataframe(productos)
        df.to_excel(nombre_archivo, index=False, engine="openpyxl")
        print(f"Guardado en {nombre_archivo}")


# ======================
# EJEMPLO DE USO
# ======================
if __name__ == "__main__":
    scraper = SheinScraper(keyword="negro casual mujer", limit=10)
    productos = scraper.fetch_products()

    for p in productos:
        print(p["nombre"], "-", p["precio"])
        print(p["enlace"])
        print()

    scraper.save_excel(productos)
