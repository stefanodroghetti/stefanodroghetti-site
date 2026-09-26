#!/bin/bash

# Percorsi
VENV_DIR="$HOME/venvs/stefanodroghetti-site"
PROJECT_DIR="$HOME/Script/stefanodroghetti-site"
PYTHON="$VENV_DIR/bin/python"
SERVER="$PROJECT_DIR/dashboard_server.py"
URL="http://localhost:5000"

# Verifica che il venv esista
if [ ! -f "$PYTHON" ]; then
    echo "❌ Virtual environment non trovato in $VENV_DIR"
    echo "Crea il venv con: python3 -m venv ~/venvs/stefanodroghetti-site"
    exit 1
fi

# Verifica che Flask sia installato
if ! $PYTHON -c "import flask" 2>/dev/null; then
    echo "❌ Flask non installato nel venv"
    echo "Installa con: $VENV_DIR/bin/pip install flask"
    exit 1
fi

echo "============================================================"
echo "🚀 Dashboard di stefanodroghetti.it"
echo "============================================================"
echo " Progetto: $PROJECT_DIR"
echo "🐍 Python:   $PYTHON"
echo "🌐 URL:      $URL"
echo "============================================================"
echo "⏹️  Premi Ctrl+C per fermare il server"
echo ""

# Apri il browser in background
xdg-open "$URL" &>/dev/null

# Avvia il server (foreground, così vedi i log e puoi fermarlo con Ctrl+C)
cd "$PROJECT_DIR"
exec "$PYTHON" "$SERVER"
