# CONTESTO_PROGETTO.md — stefanodroghetti.it ("Divagazioni")

Documento master condiviso da tutte le chat del progetto.
Autore/proprietario: **Stefano Droghetti**. Lingua di lavoro: **italiano**.
Ogni chat specializzata (SEO, deployment, dashboard, caroselli, pagina principale,
flashcard, auto elettriche) deve considerare questo file come fonte di verità su
filosofia, grafica, stack e decisioni prese. Se una richiesta contraddice una
"Decisione presa" (§9), segnalarlo e chiedere conferma prima di procedere.

---

## 1. Filosofia e tono (il manifesto)

- Sito personale, **non commerciale, aperto, trasparente**: dati CC0, codice visibile,
  licenze dichiarate, nessun abbonamento, nessuna gamification forzata.
- **Niente server-side per i visitatori, niente tracking, niente cookie, niente
  localStorage nelle pagine pubbliche.** I progressi/bozze vivono solo in memoria
  della pagina o in file che l'utente salva esplicitamente.
- Il sito deve essere **gentile, amichevole, umano**. Vietate formule aggressive o
  colpevolizzanti: la frase "senza scuse" è stata **bandita** da tagline e meta.
- Tono delle risposte: italiano, caldo, ironico quanto basta, closing ricorrente 🚩.
- Donazioni: link all'ancora **`/#support`** della home (NON `#supportami`).
- Il valore del sito non sono i grandi numeri: strumenti precisi per poche persone
  che cercano esattamente quello.

## 2. Design system (costruttivista)

### Token
| Ruolo | Valore |
|---|---|
| Nero | `#111` |
| Rosso | `#d90429` |
| Crema chiaro (pannelli/slide) | `#f4f1ea` |
| Crema scuro (body) | `#e8e4dc` |
| Bianco | `#fff` |
| Rosso chiaro (testo su nero) | `#ff6b81` |
| Bordi | 2px (3px nelle quiz-card) |
| Ombre dure | `3px 3px 0` (btn), `4px 4px 0` (sel), `6px 6px 0` (quiz-card), `12px 12px 0` (box caroselli) |

### Componenti ricorrenti
- **Banda nera + freccia rossa**: header con titolo Dosis bold uppercase crema;
  freccia rossa a destra che punta a sinistra, via
  `clip-path: polygon(0 50%, 25% 0, 25% 32%, 100% 32%, 100% 68%, 25% 68%, 25% 100%)`.
- **Striscia rossa verticale**: `border-left: 6-7px solid #d90429` + padding (tagline).
- **Rettangolo bianco bordato** / **rettangolo nero** (testo crema).
- **Ombra dura** nera o rossa (mai blur).
- **Riga nera** orizzontale (7px) come separatore.
- **Footer**: striscia nera, Dosis 600 uppercase, letter-spacing.

### Font (tutti OFL, serviti localmente)
| Font | File | Uso |
|---|---|---|
| Dosis 600/700 | `/fonts/Dosis-SemiBold.ttf`, `/fonts/Dosis-Bold.ttf` | titoli, UI, pulsanti, significati italiani nelle card |
| Questrial | `/fonts/Questrial-Regular.ttf` | corpo testo |
| Noto Sans SC (variable) | `/fonts/NotoSansSC-VariableFont_wght.ttf` | **pinyin** (copre i diacritici Latin Extended, es. ǎ) |
| LXGW WenKai GB (subset woff2) | `/progetti/flashcard-cinesi/fonts/LXGWWenKaiGB-{Regular,Medium}.woff2` | **solo hanzi** (calligrafico) |

Storia dei font (non riproporre scelte scartate): WenKai sul latino sembrava
Comic Sans da lontano → scartato per il latino; Roboto mancava di ǎ (Latin
Extended A) → scartato; soluzione finale: WenKai hanzi + Noto Sans SC pinyin +
Dosis italiano. Il subset WenKai si rigenera con `subset_fonts.py` (§5).

## 3. Stack, repo, deploy

- Repo locale: `~/Script/stefanodroghetti-site`. Hosting: **Cloudflare Pages**,
  deploy automatico al `git push`.
- Sito statico: `index.html` generato da `build.sh` a partire da `data.json`
  (dashboard → 🔨 Build). CSS in `style.css`, font in `fonts/`, guide in `pdf/`.
- **Dashboard locale**: `dashboard_server.py` (Flask, `localhost:5000`,
  `debug=False`). Rotte: `/` (dashboard.html), `/api/data` GET/POST (data.json),
  `/api/build` POST (bash build.sh), `/preview`, `/style.css`, `/fonts/<path>`,
  `/pdf/<path>`, `/favicon.png`, `/og-image.jpg`, `/caroselli` (tool), e
  **generica `/<path:filename>` in fondo** (cartella → suo index.html).
  ⚠️ Ogni rotta nuova va inserita **prima** della generica.
- Comandi di pubblicazione (anche nel modal della dashboard):
  `cd ~/Script/stefanodroghetti-site && git add . && git commit -m "..." && git push`.
  **Sempre `commit -m`**: senza messaggio git apre nano e l'utente si blocca.
- Ambiente utente: Ubuntu 26.04, i7, 16 GB RAM, RTX 4070 **8 GB VRAM** (dato
  dichiarato dall'utente), Python di sistema 3.14; prefers `~/Script` per gli
  script, `~/venvs` per i venv, SSD exFAT per i pesi AI. Firefox è il browser
  principale (Page Assistant per chat locale con Ollama: qwen3 default,
  qwen2.5-coder per coding, qwen3.5 in sperimentazione).

## 4. Dashboard

- Sezioni: Informazioni sito (Titolo/Tagline/Bio/Data di nascita/Footer),
  Impostazioni Sezioni (mostra/titolo/descrizione per sezione), Prompt AI,
  Produzioni, **Divagazioni (progetti interattivi)**, Social, Supporto, Eventi,
  Link consigliati, E I COOKIES? (Privacy), Anteprima sito, Pubblica il sito.
- Barra alta: 💾 Salva · 🔨 Build · 🚀 Pubblica · 🌐 Live · **🎠 Caroselli**
  (apre `/caroselli` in nuova scheda).
- **Kit dz** (incollato prima di `</body>`): al load avvolge ogni sezione in un
  blocco collassabile **chiuso di default**, bordo nero 2px + ombra dura, titolo
  cliccabile con caret ▸/▾, e costruisce una **barra-indice sticky** nera in cima
  (un pulsante per sezione + "Espandi/comprimi tutto"). Riconosce i titoli via
  array `TITOLI` (testo normalizzato, elemento più profondo) + fallback h2/h3.
  Se una sezione non viene riconosciuta: aggiungere il suo testo a `TITOLI`.
  Il kit non tocca ID/listener esistenti (sposta nodi, non li ricrea).

## 5. Progetto Flashcard (`/progetti/flashcard-cinesi/`)

Pagina singola `index.html`, vanilla JS, zero dipendenze, niente localStorage.

### Librerie (JSON in `data/`)
| File | Carte | Note |
|---|---|---|
| hsk1.json | 150 | set classico HSK |
| hsk2.json | 150 | |
| hsk3.json | 300 | |
| cibo.json | 164 | include diete/allergie (无糖, 无麸质, 纯素食…) |
| sopravvivenza.json | 104 | include diabete/celiachia/lattosio |
| parentela.json | 80 | tang/biao, suoceri, nuore/generi |
| amministrazione.json | 103 | burocrazia: visti, sportelli, 填写, 复印件… |
| tecnologia.json | 81 | chicche FOSS: 开源, 自由软件, 防火墙, Linux |

Schema: `{"_metadata":{titolo,autore,licenza:"CC0-1.0",nota,aggiornato,copertura},
"carte":[{"id":N,"hanzi":"…","pinyin":"…","italiano":"…"}]}`. ID progressivi per
libreria. Sovrapposizioni con HSK volute (rinforzo tematico).

### Traduzioni approvate (non "correggerle" di nuovo)
乡 = comune rurale · 木耳 = orecchio di Giuda · 锅贴 = ravioli alla piastra ·
羊肉串 = arrosticini cinesi · 服务员 = cameriere/a (neutro).
**Esclusa per scelta**: la carta 美女/帅哥 (non insegnare abitudini oggettificanti).
**Parolacce**: set rimandato a data da destinarsi (rischio ban scolastico).

### Motore quiz: Leitner session-only
- 4 stati: Scatola 1/2/3 + Laureata(4). Sbagli → S1, reinserita ~4 carte dopo.
  Giusta → promuovi: S2 ~12 carte dopo, S3 a fine giro, da S3 giusta → laureata.
  "La so già ✓✓" → laurea immediata.
- Pulsanti autoesplicativi con sottoriga: "la rivedi tra ~4 carte" /
  "la rivedi più tardi" / "oggi non la rivedi più".
- Fine giro = tutte le carte del mazzo viste ≥1 volta → rimescola (mai la stessa
  due volte di fila), round++. Statistiche live: Mazzo·Giro·S1·S2·S3·Laureate.
- **Ponte di carta**: "Riepilogo scatole" elenca gli ID per scatola da copiare nel
  campo intervalli alla sessione dopo (o su quaderno). "Azzera scatole" resetta
  la memoria della libreria. Le scatole vivono in `boxMemory` per libreria finché
  la pagina è aperta; reload = azzeramento (scelta filosofica, NON un bug).
- Selezione: click, Shift+click (intervallo), campo intervalli `2-20, 45, 31-37`,
  "Selezione N a caso" (default 10 a casella vuota). Consiglio istruzioni: blocchi
  da 20-30 carte.
- Scorciatoie: **Spazio** = mostra risposta / la sapevo · **→ o X** = non la
  sapevo · **L** = la so già (laurea).
- Ancoraggio mobile: `portaAllaCard`/`rispostaInVista` scrollano su
  `.fc-quizlayout` (card + pulsanti), non sulla sola card.
- Sezione didattica `<details id="metodo">`: diagramma scatole costruttivista,
  curva dell'oblio, testing+spacing effect, caveat onesto (le scatole sono
  artigianato efficace, non protocollo clinico), compromesso no-localStorage
  spiegato, bibliografia: Leitner 1972 (wiki), Ebbinghaus 1885 (wiki),
  Cepeda 2006 DOI 10.1037/0033-2909.132.3.354, Karpicke & Roediger 2008
  DOI 10.1126/science.1152408, Dunlosky 2013 DOI 10.1177/1529100612453266.

### Rituale subset font
Ogni modifica ai JSON che introduce **nuovi hanzi/diacritici**:
`cd progetti/flashcard-cinesi && python3 subset_fonts.py` poi commit+push.
Modifiche al solo italiano → subset NON necessario.
Validazione: `for f in data/*.json; do python3 -m json.tool "$f" >/dev/null && echo OK || echo ROTTO; done`.
Trappole note: virgola mancante alla giunzione vecchio/nuovo, commenti `//`
invalidi in JSON, cwd sbagliata (i comandi vanno lanciati dalla cartella del progetto).

## 6. Progetto Auto elettriche ("Termica vs Elettrica")

Calcolatore/confronto costo per km e punto di pareggio tra termica ed elettrica,
coi calcoli spiegati in chiaro (spirito: non solo il risultato, ma il conto).
Stessa grafica costruttivista; og:image dedicata prevista (1200×630 dal tool
caroselli). Ogni modifica a formule/assunzioni va dichiarata nella pagina.

## 7. Tool Caroselli & OG (`/caroselli`, file `tools/caroselli/index.html`)

Tool locale single-file, zero dipendenze esterne, niente localStorage
(progetti salvati/caricati come file `.json`).

### BBCode (blocchi: una riga ciascuno; testo libero = paragrafo)
`[titolo]` banda nera+freccia · `[header]` banda nera · `[footer]` striscia nera
in fondo al flusso · `[rossa]` striscia verticale+testo · `[bianco]`/`[nero]`
rettangoli · `[ombrarossa]`/`[ombranera]` che avvolgono `[bianco]`/`[nero]` ·
`[riga]` · `[spazio=N]` · `[center]`.
Inline: `[b] [i] [rosso] [crema] [size=N]…[/size] [font=dosis|questrial|wenkai]…[/font]`.
**Niente autoscale**: le misure le decide l'utente (decisione presa).

### Formati
carosello 1080×1350 · quadrato 1080×1080 (uso raro) · og 1200×630.

### Anteprima
DOM in `#frame` con `transform: scale(s)`, origin 0 0, dentro `#scaler` grande
`s·w × s·h`; `main` a blocco con overflow auto; `s = min(availW/w, availH/h, 1)`
calcolato su `main.clientWidth/Height - 48`. **Le guide sono un nodo JS
(`guidesEl`) ri-appeso dentro `#frame` dopo ogni `innerHTML`**: ereditano la
scala, quindi niente moltiplicazioni manuali (bug storico risolto così).

### Guide v2 (formato-consapevoli; selettore: nessuna / "Vista da tutti" / tutte)
Social considerati: **Instagram** (caroselli), **WhatsApp, Facebook,
Mastodon.uno** (og). **X e LinkedIn esclusi** (utente non iscritto).
| Formato | "Vista da tutti" (rosso spesso) | Secondarie |
|---|---|---|
| carosello | quadrato centrale 1080×1080 (griglia IG + thumb WA) | IG feed: tutto · FB/WA come link: banda 1.91:1 |
| og | quadrato centrale 630×630 (thumb WA ∩ FB  Mastodon) | FB+Mastodon: tutto · Mastodon card: banda 16:9 |
| quadrato | tutto il frame | se riusata come og/link: banda 1.91:1 |

### Export
PNG via **SVG `<foreignObject>`** con CSS+font base64 (fetch da `/fonts/…` e dal
subset WenKai), disegnato su canvas alla risoluzione esatta → motore CSS vero
(frecce/ombre intatte). **ZIP scritto a mano** (metodo stored + CRC32), nessuna
libreria. Le guide non entrano nell'export perché l'export costruisce il proprio
SVG, non usa il DOM dell'anteprima.
Limiti v1 dichiarati: blocchi su una riga; WenKai subset copre solo gli hanzi
delle flashcard (altri → serif di sistema).

## 8. SEO e condivisioni

- Stato (nov 2026): Search Console **3 pagine indicizzate, 4 click**; traffico
  Cloudflare prevalentemente estero/bot; Italia ancora minima (atteso, non un problema).
- Ogni pagina progetto deve avere: `og:title`, `og:description`, `og:image`
  **assoluta** 1200×630 nella propria cartella, `og:image:width/height`,
  `og:image:alt` (descrive **l'immagine**, non la pagina), `og:url`, `og:type`,
  `twitter:card=summary_large_image`. Root: `og-image.jpg` come fallback.
- `og:image:alt` bozze approvate in stile "Locandina costruttivista del progetto
  X: banda nera con titolo e freccia rossa…"; allinearle all'immagine reale
  quando il tool la produce.
- Cache crawler: cambiando immagine **cambiare nome file**; verifica con
  Facebook Sharing Debugger ("Scrape again").
- Safe zone: il quadrato centrale è l'intersezione garantita (vedi §7);
  il quadrato come media non viene tagliato da nessun social usato.
- Canali di condivisione reali: storie IG/FB, post Mastodon.uno; niente X/LinkedIn.

## 9. Decisioni prese (non rinegoziare senza chiedere)

1. Niente localStorage/cookie/tracking nelle pagine pubbliche; Leitner
   session-only + ponte di carta.
2. Niente "senza scuse" né tono aggressivo; tagline gentile ("Benvenuta,
   benvenuto… quaderno aperto…").
3. Niente set parolacce (per ora); niente carta 美女/帅哥.
4. Font: WenKai solo hanzi, Noto Sans SC pinyin, Dosis italiano/UI, Questrial corpo.
5. Caroselli: BBCode, niente autoscale, niente export SVG, ZIP senza librerie.
6. Guide v2 formato-consapevoli; social = IG, WA, FB, Mastodon.uno.
7. Dashboard: sezioni collassabili chiuse di default + indice sticky (kit dz).
8. Quadrato come formato raro; il flusso principale è carosello IG.
9. Patch chirurgiche per modifiche piccole; file intero solo quando la
   struttura cambia o l'utente lo chiede. Spiegare prima, codificare dopo.
10. Sempre `git commit -m`; rituali di §10 dopo ogni modifica.

## 10. Rituali operativi (checklist)

**Modifica JSON flashcard (nuovi caratteri):**
valida tutti i JSON → `python3 subset_fonts.py` → `git add -A` → `commit -m` → `push`.
**Modifica solo testo italiano / HTML / CSS / JS:**
niente subset → `git add -A` → `commit -m` → `push`.
**Nuova rotta Flask:** inserirla prima della generica `/<path:filename>` → riavviare server.
**Font non aggiornati in Firefox:** F12 → Rete → "Disabilita cache" + reload,
oppure lucchetto → cancella dati sito. Ctrl+F5 NON basta a parità di nome file.
**Anteprima/export discordanti:** ricordare che l'export usa CSS_SLIDE + font
base64 propri; ogni nuova regola CSS va messa in CSS_SLIDE, non solo nel CSS pagina.

## 11. Lezioni dai bug storici (non ripeterli)

- `innerHTML = …` cancella i figli: nodi persistenti (guide) vanno ri-appesi dopo.
- Coordinate overlay: o dentro l'elemento trasformato (scala ereditata) o
  moltiplicate per lo scale corrente **sempre**, anche negli onchange.
- Scala anteprima: usare le dimensioni del contenitore reale, non della finestra;
  centrare con margin auto + overflow auto, non con flex center (taglia i bordi).
- `@font-face` serve sia nel CSS pagina sia nel CSS export.
- JSON: una virgola alla giunzione, mai commenti, validare prima del subset.
- Git: senza `-m` si apre nano; cwd errata = FileNotFoundError fuorvianti.

## 12. Mappa delle chat specializzate

| Chat | Sezioni rilevanti |
|---|---|
| SEO | 1, 2, 8, 9, 10 |
| Installazione/Deployment | 3, 9, 10, 11 |
| Dashboard | 2, 3, 4, 9, 10 |
| Caroselli | 2, 3, 7, 8, 9, 10, 11 |
| Pagina principale | 1, 2, 3, 8, 9 |
| Flashcard | 2, 3, 5, 9, 10, 11 |
| Auto elettriche | 1, 2, 3, 6, 8, 9 |

Regola d'ingaggio per tutte: discutere la strategia prima del codice quando
l'utente lo chiede ("non scrivere nulla", "studietto di fattibilità"); proporre
alternative con pro/contro; chiudere con il rito di commit pertinente; tono
gentile e ironico; 🚩.
