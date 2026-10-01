#!/usr/bin/env python3
"""
Server locale per la dashboard di stefanodroghetti.it
Avvia con: python3 dashboard_server.py
Poi apri: http://localhost:5000
"""

from flask import Flask, jsonify, request, send_from_directory, render_template_string
import json
import subprocess
import os
from datetime import datetime

app = Flask(__name__)

# Percorsi
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(BASE_DIR, 'data.json')
BUILD_SCRIPT = os.path.join(BASE_DIR, 'build.sh')
SITE_DIR = BASE_DIR  # dove si trova index.html generato

@app.route('/')
def dashboard():
    """Serve la dashboard HTML"""
    with open(os.path.join(BASE_DIR, 'dashboard.html'), 'r', encoding='utf-8') as f:
        return f.read()

@app.route('/api/data', methods=['GET'])
def get_data():
    """Restituisce il contenuto di data.json"""
    try:
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return jsonify(data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/data', methods=['POST'])
def save_data():
    """Salva i dati in data.json"""
    try:
        data = request.json
        with open(DATA_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        return jsonify({'success': True, 'message': 'File salvato con successo!'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/build', methods=['POST'])
def build():
    """Lancia lo script di build"""
    try:
        result = subprocess.run(
            ['bash', BUILD_SCRIPT],
            capture_output=True,
            text=True,
            cwd=BASE_DIR
        )
        if result.returncode == 0:
            return jsonify({
                'success': True, 
                'message': 'Build completata!',
                'output': result.stdout
            })
        else:
            return jsonify({
                'success': False,
                'message': 'Errore nella build',
                'output': result.stderr
            }), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/preview')
def preview():
    """Mostra l'anteprima del sito"""
    return send_from_directory(SITE_DIR, 'index.html')

@app.route('/style.css')
def css():
    """Serve il CSS per l'anteprima"""
    return send_from_directory(SITE_DIR, 'style.css')
    
@app.route('/fonts/<path:filename>')
def fonts(filename):
    """Serve i font locali (.ttf)"""
    return send_from_directory(os.path.join(SITE_DIR, 'fonts'), filename)

@app.route('/pdf/<path:filename>')
def serve_pdf(filename):
    """Serve i file PDF delle guide storiche"""
    pdf_dir = os.path.join(SITE_DIR, 'pdf')
    return send_from_directory(pdf_dir, filename)

@app.route('/favicon.png')
def favicon():
    """Serve la favicon per l'anteprima"""
    return send_from_directory(SITE_DIR, 'favicon.png')

@app.route('/og-image.jpg')
def og_image():
    """Serve l'immagine Open Graph per l'anteprima"""
    return send_from_directory(SITE_DIR, 'og-image.jpg')

@app.route('/<path:filename>')
def serve_static(filename):
    """Serve tutti gli altri file del sito (immagini, cartelle, ecc.)"""
    target = os.path.join(SITE_DIR, filename)
    # Se la richiesta punta a una cartella, servi il suo index.html
    if os.path.isdir(target):
        return send_from_directory(target, 'index.html')
    return send_from_directory(SITE_DIR, filename)
  
if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Dashboard di stefanodroghetti.it")
    print("=" * 60)
    print(f"📁 Directory: {BASE_DIR}")
    print(f" Data file: {DATA_FILE}")
    print("=" * 60)
    print("🌐 Apri nel browser: http://localhost:5000")
    print("=" * 60)
    app.run(host='localhost', port=5000, debug=False)
