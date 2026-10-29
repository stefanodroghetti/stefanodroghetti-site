#!/usr/bin/env python3
"""
subset_fonts.py — Rigenera i subset WOFF2 del LXGW WenKai GB a partire dai JSON.

Uso:  python3 subset_fonts.py [--src PERCORSO_TTF]
Default sorgente: ~/Scaricati/lxgw-wenkai-gb-v1.530
I TTF master restano FUORI dal repo: nel sito finiscono solo i WOFF2.
"""
import argparse, json, subprocess, sys, datetime
from pathlib import Path
from fontTools.ttLib import TTFont

QUI   = Path(__file__).resolve().parent   # progetti/flashcard-cinesi/
DATA  = QUI / "data"
FONTS = QUI / "fonts"

# Base fissa: alfabeto italiano, cifre, punteggiatura, TUTTI i diacritici
# del pinyin (anche quelli non ancora usati) e punteggiatura CJK.
BASE = set(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "0123456789 "
    "àèéìòùÀÈÉÌÒÙ"
    ".,;:!?()[]{}'\"«»–—-…·/"
    "āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ"
    "ĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙǕǗǙǛ"
    "êÊ"
    "，。！？、；：""''（）《》〈〉—～·"
)

PESI = [
    ("LXGWWenKaiGB-Regular.ttf", "LXGWWenKaiGB-Regular.woff2"),
    ("LXGWWenKaiGB-Medium.ttf",  "LXGWWenKaiGB-Medium.woff2"),
]


def raccogli_caratteri():
    """Unione di BASE + tutti i caratteri di hanzi/pinyin/italiano dei JSON."""
    caratteri = set(BASE)
    for file_json in sorted(DATA.glob("*.json")):
        with open(file_json, encoding="utf-8") as f:
            dati = json.load(f)
        for carta in dati.get("carte", []):
            for campo in ("hanzi", "pinyin", "italiano"):
                caratteri.update(carta.get(campo, ""))
    return sorted(caratteri)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src",
                        default=str(Path.home() / "Scaricati" / "lxgw-wenkai-gb-v1.530"),
                        help="cartella coi TTF master LXGW WenKai GB")
    args = parser.parse_args()
    src = Path(args.src)

    if not DATA.is_dir():
        sys.exit(f"Cartella data/ non trovata in {DATA}")
    FONTS.mkdir(exist_ok=True)

    caratteri = raccogli_caratteri()
    print(f"Caratteri unici nel subset: {len(caratteri)}")

    tmp = FONTS / "_caratteri.txt"
    tmp.write_text("".join(caratteri), encoding="utf-8")

    for nome_ttf, nome_woff in PESI:
        ttf = src / nome_ttf
        if not ttf.exists():
            sys.exit(f"Manca il TTF master: {ttf}")

        # Avviso preventivo: caratteri richiesti ma assenti nel font sorgente
        cmap = TTFont(ttf, lazy=True).getBestCmap()
        mancanti = [c for c in caratteri if not c.isspace() and ord(c) not in cmap]
        if mancanti:
            print(f"⚠️  Assenti in {nome_ttf}: {''.join(mancanti)}")

        out = FONTS / nome_woff
        subprocess.run([
            "pyftsubset", str(ttf),
            f"--text-file={tmp}",
            f"--output-file={out}",
            "--flavor=woff2",      # TTF → WOFF2 durante il subset
            "--no-hinting",        # toglie l'hinting: meno KB, resa identica a schermo
            "--layout-features=*", # conserva le feature OpenType
        ], check=True)
        print(f"✅ {out.name}: {out.stat().st_size / 1024:.0f} KB")

    tmp.unlink()
    (FONTS / "SUBSET-INFO.txt").write_text(
        f"Subset generato il {datetime.date.today().isoformat()}\n"
        f"Caratteri unici: {len(caratteri)}\n"
        f"Sorgente: LXGW WenKai GB v1.530 — SIL Open Font License 1.1\n"
        f"JSON scansionati: {', '.join(p.name for p in sorted(DATA.glob('*.json')))}\n",
        encoding="utf-8")
    print("\nFatto. Ora: git add data fonts && git commit && git push")


if __name__ == "__main__":
    main()
