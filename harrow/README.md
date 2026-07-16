# ⚔️ Harrow

Et **Gauntlet-inspirert** arkade-eventyr (2026-utgave) — laget for mobil, fungerer også på desktop.
Én HTML-fil, null avhengigheter, null byggesteg.

> *«Kriger trenger mat – sårt!»* 🍗

## Spill det

Åpne `index.html` i en nettleser — det er alt. For mobil: legg mappa ut på en statisk host
(Netlify, Vercel, GitHub Pages …) og åpne på telefonen. Spillet er en PWA og kan legges til
på hjemskjermen (fullskjerm + offline).

## Slik spiller du

| | Mobil | Desktop |
|---|---|---|
| Løpe | venstre tommel (virtuell joystick) | WASD / piltaster |
| Sikte & skyte | høyre tommel (twin-stick, hold) | hold museknappen (sikter mot pekeren) — eller mellomrom |
| Trylledrikk | ⚗️-knappen | K eller Enter |
| Pause | ⏸ | P / Escape |

Skuddene har diskré siktehjelp som snapper mot nærmeste fiende.

## Reglene (som i 1985 — med 2026-følelse)

- **Helsen tikker ned hele tiden.** Spis mat 🍗 for å overleve. Ikke skyt maten!
- Fire helter: **Kriger** (rå styrke), **Valkyrje** (best rustning), **Trollmann** (skudd går gjennom fiender), **Alv** (lynrask).
- **Monstergeneratorer** spyr ut spøkelser, grunter og demoner — ødelegg generatorene!
- **Nøkler** 🔑 åpner dører til skattkamre. **Trylledrikker** ⚗️ svir alt på skjermen.
- **Våpenruner** gir deg 25 sekunder med trippelskudd 🔱, kjedelyn ⚡ eller hurtigild 🔥.
  Godsaker: fartsstøvler 👢, skjold 🛡️ og magnet 🧲. Kister skjuler av og til en rune.
- **Portalstormer** ⛈️ — med jevne mellomrom går generatorene amok. Overlev.
- **Døden** 💀 kan ikke skytes. Løp. (Eller ofre en trylledrikk. Skjold hjelper ikke.)
- Finn den grønne portalen for å nå neste nivå. Nivå 1–4 er håndlaget, deretter genereres grottene prosedyrelt — i det uendelige.

## 2026-forbedringene

- Dynamisk lys/mørke, partikkeleffekter, skjermristing og HD-retro pikselkunst
- Virtuelle touch-kontroller med haptikk (vibrasjon)
- Minimap, poengrekord (lagres lokalt), pause ved app-bytte
- Syntetisert lyd + norsk «announcer» (talesyntese) — helt uten lydfiler
- PWA: installer på hjemskjermen, spill offline

## Teknisk

- `index.html` — hele spillet (motor, grafikk, lyd, nivåer)
- `manifest.webmanifest`, `icon.svg`, `icon-192/512.png`, `sw.js` — PWA-innpakning
- Grafikken er programmatisk pikselkunst (ingen bildefiler), lyden er WebAudio-syntese

Dette prosjektet er en hyllest til Atari Games' *Gauntlet* (1985). Alt innhold her er
originalt; «Gauntlet» er et varemerke som tilhører rettighetshaverne.
