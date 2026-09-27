#!/bin/bash
echo "🔨 Building site from data.json..."

if [ ! -f "data.json" ]; then
    echo "❌ Errore: data.json non trovato!"
    exit 1
fi

python3 << 'PYTHON_SCRIPT'
import json
import os
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

manifesto_section = render_section('manifesto', prompts_html)
productions_section = render_section('productions', f'<ul>{productions_html}            </ul>')
social_section = render_section('social', f'<ul>{social_html}            </ul>')

support_section = ""
if settings.get('support', {}).get('visible', True):
    s = settings['support']
    title = s.get('title', 'Supporta questi progetti')
    desc = s.get('description', '')
    desc_html = f'\n            <p class="section-desc">{desc}</p>' if desc else ''
    support_boxes = ""
    for item in data.get('support', []):
        if not item.get('visible', True):
            continue
        box_content = ""
        if item.get('type') == 'qrcode':
            qr_image = item.get('qrcode_image', '')
            logo_html = f'<div class="support-logo">{item["logo_svg"]}</div>' if item.get('logo_svg') else ""
            box_content = f'''
                <div class="support-box-inner" data-modal="{item['id']}">
                    {logo_html}
                    <p class="support-desc">{item.get("description", "")}</p>
                    <span class="support-hint">Clicca per vedere il QR code</span>
                </div>
            '''
        else:
            logo_html = f'<div class="support-logo">{item["logo_svg"]}</div>' if item.get('logo_svg') else ""
            link_url = item.get('url', '#')
            box_content = f'''
                <a href="{link_url}" target="_blank" rel="noopener" class="support-box-inner">
                    {logo_html}
                    <p class="support-desc">{item.get("description", "")}</p>
                </a>
            '''
        support_boxes += f'''
            <div class="support-box">
                <h3>{item.get("label", "")}</h3>
                {box_content}
            </div>
        '''
    
    qrcode_modals = ""
    for item in data.get('support', []):
        if item.get('type') == 'qrcode' and item.get('visible', True):
            qr_image = item.get('qrcode_image', '')
            qrcode_modals += f'''
            <div id="modal-{item['id']}" class="qrcode-modal" onclick="closeModal('{item['id']}')">
                <div class="modal-content" onclick="event.stopPropagation()">
                    <button class="modal-close" onclick="closeModal('{item['id']}')">✕</button>
                    <h3>{item.get('label', '')}</h3>
                    <img src="{qr_image}" alt="QR Code {item.get('label')}" class="modal-qr-image">
                    <p class="modal-instructions">Scansiona con l'app {item.get('label')} per supportare il progetto.</p>
                    <p class="modal-mobile-hint">Sei su smartphone? Fai uno screenshot, poi apri l'app → Scansiona → Album → seleziona l'immagine.</p>
                </div>
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

function openModal(id) {
    const modal = document.getElementById('modal-' + id);
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}
function closeModal(id) {
    const modal = document.getElementById('modal-' + id);
    if (modal) {
        modal.classList.remove('active');
        document.body.style.overflow = '';
    }
}
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.support-box-inner[data-modal]').forEach(box => {
        box.addEventListener('click', function() {
            openModal(this.getAttribute('data-modal'));
        });
    });
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.qrcode-modal').forEach(modal => {
                modal.classList.remove('active');
            });
            document.body.style.overflow = '';
        }
    });
});
</script>
"""

html = f'''<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{data["site"]["title"]} - Sito Ufficiale</title>
    <meta name="description" content="{data["site"]["tagline"]}">
    <link rel="icon" type="image/png" href="/favicon.png">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://stefanodroghetti.it/">
    <meta property="og:title" content="{data["site"]["title"]}">
    <meta property="og:description" content="{data["site"]["tagline"]}">
    <meta property="og:image" content="https://stefanodroghetti-site.pages.dev/og-image.jpg">
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
        {qrcode_modals}
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
