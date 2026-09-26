#!/bin/bash
echo "🔨 Building site from data.json..."

if [ ! -f "data.json" ]; then
    echo "❌ Errore: data.json non trovato!"
    exit 1
fi

python3 << 'PYTHON_SCRIPT'
import json
from datetime import datetime

with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Calcola età precisa
birth_date_str = data['site'].get('birth_date', '1970-01-01')
birth_date = datetime.strptime(birth_date_str, '%Y-%m-%d').date()
today = datetime.now().date()
age = today.year - birth_date.year
if (today.month, today.day) < (birth_date.month, birth_date.day):
    age -= 1

settings = data.get('section_settings', {})

# Funzione helper per generare liste con controllo visibilità
def render_list(items):
    html = ""
    for item in items:
        if item.get('visible', True) and item.get('url'):
            label = item.get('label', item.get('id', 'Link'))
            html += f'                <li><a href="{item["url"]}" target="_blank" rel="noopener">{label}</a></li>\n'
    return html

productions_html = render_list(data.get('productions', []))
social_html = render_list(data.get('social', []))
support_html = render_list(data.get('support', []))

prompts_html = "".join([f'                <div class="prompt-box"><code>{p}</code></div>\n' for p in data.get('ai_prompts', [])])

# Eventi
future_events_html = ""
past_events_html = ""
for event in data.get('events', []):
    event_date = datetime.strptime(event['date'], '%Y-%m-%d').date()
    css_class = "future" if event_date >= today else "past"
    html_event = f'                <div class="event {css_class}"><strong>{event["date"]}</strong> - {event["title"]}<br>{event["description"]}</div>\n'
    if event_date >= today:
        future_events_html += html_event
    else:
        past_events_html += html_event

recommended_html = ""
for link in data.get('recommended_links', []):
    recommended_html += f'                <li><a href="{link["url"]}" target="_blank" rel="noopener">{link["name"]}</a> - {link["description"]}</li>\n'

# Helper per generare sezioni con descrizione opzionale
def render_section(section_key, content_html):
    s = settings.get(section_key, {})
    if not s.get('visible', True):
        return ""
    title = s.get('title', section_key.capitalize())
    desc = s.get('description', '')
    desc_html = f'\n            <p class="section-desc">{desc}</p>' if desc else ''
    return f'''
        <section class="{section_key}">
            <h2>{title}</h2>{desc_html}
            {content_html}
        </section>'''

manifesto_section = render_section('manifesto', f'''
            <p>{data["manifesto"]["intro"]}</p>
            <p>{data["manifesto"]["linux"]}</p>
            <p>{data["manifesto"]["ai_note"]}</p>
            {prompts_html}''') if settings.get('manifesto', {}).get('visible', True) else ''

productions_section = render_section('productions', f'<ul>{productions_html}            </ul>')
social_section = render_section('social', f'<ul>{social_html}            </ul>')

# Sezione Support con layout a griglia
support_section = ""
if settings.get('support', {}).get('visible', True):
    s = settings['support']
    title = s.get('title', 'Supporta il mio lavoro')
    desc = s.get('description', '')
    desc_html = f'\n            <p class="section-desc">{desc}</p>' if desc else ''
    
    support_boxes = ""
    for item in data.get('support', []):
        if not item.get('visible', True):
            continue
        
        box_content = ""
        if item.get('type') == 'iframe' and item.get('iframe_code'):
            box_content = f'<div class="support-iframe">{item["iframe_code"]}</div>'
        else:
            logo_html = ""
            if item.get('logo_svg'):
                logo_html = f'<div class="support-logo">{item["logo_svg"]}</div>'
            link_url = item.get('url', '#')
            box_content = f'''
                {logo_html}
                <p class="support-desc">{item.get("description", "")}</p>
                <a href="{link_url}" target="_blank" rel="noopener" class="support-link">Vai a {item.get("label", "")} →</a>
            '''
        
        support_boxes += f'''
            <div class="support-box">
                <h3>{item.get("label", "")}</h3>
                {box_content}
            </div>
        '''
    
    support_section = f'''
        <section class="support">
            <h2>{title}</h2>{desc_html}
            <div class="support-grid">
                {support_boxes}
            </div>
        </section>'''

events_section = ""
if settings.get('events', {}).get('visible', True):
    events_title = settings['events'].get('title', 'Eventi')
    events_desc = settings['events'].get('description', '')
    events_desc_html = f'\n            <p class="section-desc">{events_desc}</p>' if events_desc else ''
    events_section = f'''
        <section class="events">
            <h2>{events_title}</h2>{events_desc_html}
            <h3>Prossimamente</h3>
            {future_events_html if future_events_html else '<p>Nessun evento programmato al momento.</p>'}
            <h3>Archivio</h3>
            {past_events_html if past_events_html else '<p>Nessun evento passato.</p>'}
        </section>'''

recommended_section = render_section('recommended', f'<ul>{recommended_html}            </ul>')

html = f'''<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{data["site"]["title"]} - Sito Ufficiale</title>
    <meta name="description" content="{data["site"]["tagline"]}">
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

        {manifesto_section}
        {productions_section}
        {social_section}
        {events_section}
        {recommended_section}
        {support_section}

        <footer>
            <p>{data["site"]["footer"]}</p>
        </footer>
    </main>
</body>
</html>'''

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("✅ index.html generato con successo!")
PYTHON_SCRIPT
echo "🎉 Build completata!"
