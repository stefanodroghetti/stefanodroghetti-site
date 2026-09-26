#!/bin/bash

# Script di build per stefanodroghetti.it
# Legge data.json e genera index.html

echo " Building site from data.json..."

# Verifica che data.json esista
if [ ! -f "data.json" ]; then
    echo "❌ Errore: data.json non trovato!"
    exit 1
fi

# Usa Python per processare il JSON e generare l'HTML
python3 << 'PYTHON_SCRIPT'
import json
from datetime import datetime

# Leggi il file JSON
with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Calcola l'età precisa (considerando giorno e mese)
birth_date_str = data['site'].get('birth_date', '1970-01-01')
birth_date = datetime.strptime(birth_date_str, '%Y-%m-%d').date()
today = datetime.now().date()
age = today.year - birth_date.year
# Se il compleanno di quest'anno non è ancora passato, sottrai 1
if (today.month, today.day) < (birth_date.month, birth_date.day):
    age -= 1

# Genera i link delle produzioni
productions_html = ""
for key, value in data['productions'].items():
    if value['url']:  # Salta se URL vuoto
        productions_html += f'                <li><a href="{value["url"]}" target="_blank" rel="noopener">{value["label"]}</a></li>\n'

# Genera i link social
social_html = ""
for platform, url in data['social'].items():
    if url:
        social_html += f'                <li><a href="{url}" target="_blank" rel="noopener">{platform.capitalize()}</a></li>\n'

# Genera i link di supporto
support_html = ""
for platform, url in data['support'].items():
    if url:
        support_html += f'                <li><a href="{url}" target="_blank" rel="noopener">{platform.capitalize()}</a></li>\n'

# Genera i prompt AI
prompts_html = ""
for prompt in data['ai_prompts']:
    prompts_html += f'                <div class="prompt-box"><code>{prompt}</code></div>\n'

# Genera gli eventi (separati per futuro/passato)
future_events_html = ""
past_events_html = ""
today = datetime.now().date()

for event in data.get('events', []):
    event_date = datetime.strptime(event['date'], '%Y-%m-%d').date()
    if event_date >= today:
        future_events_html += f'                <div class="event future"><strong>{event["date"]}</strong> - {event["title"]}<br>{event["description"]}</div>\n'
    else:
        past_events_html += f'                <div class="event past"><strong>{event["date"]}</strong> - {event["title"]}<br>{event["description"]}</div>\n'

# Genera i link consigliati
recommended_html = ""
for link in data.get('recommended_links', []):
    recommended_html += f'                <li><a href="{link["url"]}" target="_blank" rel="noopener">{link["name"]}</a> - {link["description"]}</li>\n'

# Template HTML
html = f'''<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{data["site"]["title"]} - Sito Ufficiale</title>
    <meta name="description" content="{data["site"]["tagline"]}. {data["manifesto"]["intro"]}">
    <meta name="keywords" content="Stefano Droghetti, Linux, Open Source, Musica, Arte, Informatica">
    
    <meta property="og:title" content="{data["site"]["title"]}">
    <meta property="og:description" content="{data["site"]["tagline"]}">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://www.stefanodroghetti.it">
    
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <main>
        <header>
            <h1>{data["site"]["title"]}</h1>
            <p class="tagline">{data["site"]["tagline"]}</p>
        </header>

        <section class="bio">
            <p>{data["site"]["bio_placeholder"]}</p>
            <p class="age">Oggi ho {age} anni.</p>
        </section>

        <section class="manifesto">
            <h2>Il mio approccio</h2>
            <p>{data["manifesto"]["intro"]}</p>
            <p>{data["manifesto"]["linux"]}</p>
            <p>{data["manifesto"]["ai_note"]}</p>
            {prompts_html}
        </section>

        <section class="productions">
            <h2>Le mie produzioni</h2>
            <ul>
{productions_html}            </ul>
        </section>

        <section class="social">
            <h2>Social</h2>
            <ul>
{social_html}            </ul>
        </section>

        <section class="support">
            <h2>Supporta il mio lavoro</h2>
            <ul>
{support_html}            </ul>
        </section>

        <section class="events">
            <h2>Eventi</h2>
            <h3>Prossimamente</h3>
{future_events_html}            <h3>Archivio</h3>
{past_events_html}        </section>

        <section class="recommended">
            <h2>Link consigliati</h2>
            <ul>
{recommended_html}            </ul>
        </section>

        <footer>
            <p>{data["site"]["footer"]}</p>
        </footer>
    </main>
</body>
</html>'''

# Scrivi il file HTML
with open('index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("✅ index.html generato con successo!")
PYTHON_SCRIPT

echo "🎉 Build completata!"
