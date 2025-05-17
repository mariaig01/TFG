from flask import Flask
from routes.recomendaciones import bp as recomendaciones_bp

app = Flask(__name__)

# Registrar blueprints
app.register_blueprint(recomendaciones_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8010, debug=True)

