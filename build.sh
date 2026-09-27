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

birth_date_str = data['site'].get('birth_date', '1970-01-01')
birth_date = datetime.strptime(birth_date_str, '%Y-%m-%d').date()
today = datetime.now().date()
age = today.year - birth_date.year
if (today.month, today.day) < (birth_date.month, birth_date.day):
    age -= 1

settings = data.get('section_settings', {})

import os
embeds = {}
if os.path.exists('embeds.json'):
    with open('embeds.json', 'r', encoding='utf-8') as f:
        embeds = json.load(f)

def render_list(items):
    html = ""
    for item in items:
        if item.get('visible', True) and item.get('url'):
            label = item.get('label', item.get('id', 'Link'))
            desc = item.get('description', '')
            desc_html = f'<br><span class="link-desc">{desc}</span>' if desc else ''
            html += f'                <li><a href="{item["url"]}" target="_blank" rel="noopener">{label}</a>{desc_html}</li>\n'
    return html

productions_html = render_list(data.get('productions', []))
social_html = render_list(data.get('social', []))
support_html = render_list(data.get('support', []))

# Genera i prompt con titolo, descrizione e box
prompts_html = ""
for p in data.get('ai_prompts', []):
    title = p.get('title', 'Prompt') if isinstance(p, dict) else 'Prompt'
    desc = p.get('description', '') if isinstance(p, dict) else ''
    text = p.get('prompt', p) if isinstance(p, dict) else p
    desc_html = f'<p class="prompt-desc">{desc}</p>' if desc else ''
    prompts_html += f'''
    <div class="prompt-item">
        <h3>{title}</h3>
        {desc_html}
        <div class="prompt-box"><code>{text}</code></div>
    </div>
    '''

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
	if link.get('visible', True):
		recommended_html += f'                <li><a href="{link["url"]}" target="_blank" rel="noopener">{link["name"]}</a> - {link["description"]}</li>\n'

def render_section(section_key, content_html):
    s = settings.get(section_key, {})
    if not s.get('visible', True):
        return ""
    title = s.get('title', section_key.capitalize())
    desc = s.get('description', '')
    desc_html = f'\n            <p class="section-desc">{desc}</p>' if desc else ''
    return f'''
        <section class="{section_key}" id="{section_key}">
            <h2>{title}</h2>{desc_html}
            {content_html}
        </section>'''

# La sezione "manifesto" ora contiene solo i prompt
manifesto_section = render_section('manifesto', prompts_html)

productions_section = render_section('productions', f'<ul>{productions_html}            </ul>')
social_section = render_section('social', f'<ul>{social_html}            </ul>')

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
        if item.get('type') == 'iframe':
            code = embeds.get(item.get('id'), item.get('iframe_code', ''))
            if code:
                box_content = f'<div class="support-iframe">{code}</div>'
        else:
            logo_html = f'<div class="support-logo">{item["logo_svg"]}</div>' if item.get('logo_svg') else ""
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
        <section class="support" id="support">
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
        <section class="events" id="events">
            <h2>{events_title}</h2>{events_desc_html}
            <h3>Prossimamente</h3>
            {future_events_html if future_events_html else '<p>Nessun evento programmato al momento.</p>'}
            <h3>Archivio</h3>
            {past_events_html if past_events_html else '<p>Nessun evento passato.</p>'}
        </section>'''

recommended_section = render_section('recommended', f'<ul>{recommended_html}            </ul>')

nav_html = ""
nav_order = ['manifesto', 'productions', 'social', 'events', 'recommended', 'support']
for section_key in nav_order:
    s = settings.get(section_key, {})
    if s.get('visible', True):
        title = s.get('title', section_key.capitalize())
        nav_html += f'                <li><a href="#{section_key}">{title}</a></li>\n'

nav_html = f'''            <nav class="site-nav">
                <ul>
{nav_html}                </ul>
            </nav>
'''

js_code = """
<script>
const navLinks = document.querySelectorAll(".site-nav a");
const sections = document.querySelectorAll("section[id]");
window.addEventListener("scroll", () => {
    let current = "";
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        if (scrollY >= (sectionTop - 200)) {
            current = section.getAttribute("id");
        }
    });
    navLinks.forEach(link => {
        link.style.color = "";
        if (link.getAttribute("href") === "#" + current) {
            link.style.color = "#d90429";
        }
    });
});
function adjustBodyPadding() {
    const nav = document.querySelector(".site-nav");
    if (nav) {
        document.body.style.paddingBottom = (nav.offsetHeight + 20) + "px";
    }
}
window.addEventListener("resize", adjustBodyPadding);
window.addEventListener("load", adjustBodyPadding);
adjustBodyPadding();
</script>
"""

html = f'''<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Dosis:wght@400;500;600;700&family=Questrial&display=swap" rel="stylesheet">
    <title>{data["site"]["title"]} - Sito Ufficiale</title>
    <meta name="description" content="{data["site"]["tagline"]}">
    
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/favicon.png">
    
    <!-- Open Graph / Anteprima Social -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://stefanodroghetti.it/">
    <meta property="og:title" content="{data["site"]["title"]}">
    <meta property="og:description" content="{data["site"]["tagline"]}">
    <meta property="og:image" content="https://stefanodroghetti.it/og-image.jpg">
    
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
        
        {nav_html}

        {manifesto_section}
        {productions_section}
        {social_section}
        {events_section}
        {support_section}
        {recommended_section}

        <footer>
            <p>{data["site"]["footer"]}</p>
        </footer>
    </main>
{js_code}
</body>
</html>'''

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(html)

print("✅ index.html generato con successo!")
PYTHON_SCRIPT
echo "🎉 Build completata!"
