# Kandel Stadtplan App — Technische Spezifikation
**Für Claude Code Handoff**
Version 1.0 — Mai 2026

---

## Überblick

Eine webbasierte, iPad-optimierte Lern-App für den Unterricht. Schüler werden in Gruppen aufgeteilt und bewerten verschiedene Orte in Kandel mithilfe eines Ampelsystems aus der Perspektive einer zugewiesenen Persona. Eine Live-Dashboard-Ansicht aggregiert die Ergebnisse aller Gruppen in Echtzeit.

**Stack:** Vanilla HTML/CSS/JS (Single HTML File) + Supabase (Realtime DB)
**Deployment:** GitHub Pages (statische Datei, kein Build-Step)
**Sprache der UI:** Deutsch

---

## Supabase Schema

```sql
-- Sitzungen (von Diana erstellt)
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Personas (hardcoded im Frontend, keine Tabelle nötig)

-- Gruppen
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id),
  name TEXT NOT NULL,           -- z.B. "Gruppe 1"
  persona_id TEXT NOT NULL,     -- z.B. "lena", "max", "sara"
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stimmen
CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id),
  location_id TEXT NOT NULL,    -- z.B. "skaterpark", "buecherei"
  color TEXT NOT NULL,          -- "red" | "yellow" | "green"
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, location_id) -- Pro Gruppe nur eine Stimme pro Ort
);

-- Maßnahmen-Auswahl
CREATE TABLE group_interventions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id),
  location_id TEXT NOT NULL,
  intervention_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, location_id, intervention_id)
);
```

**Supabase Realtime** aktivieren für Tabelle `votes` und `group_interventions`.

---

## Hardcoded Daten (im Frontend, kein DB)

### Orte (Locations)
```js
const LOCATIONS = [
  { id: "skaterpark",  name: "Skaterpark",  x: 43.8, y: 73.5, color: "#FF6B35" },
  { id: "buecherei",   name: "Bücherei",    x: 58.5, y: 44.8, color: "#3478D4" },
  { id: "bahnhof",     name: "Bahnhof",     x: 68.5, y: 60.1, color: "#7B50E0" },
  { id: "freibad",     name: "Freibad",     x: 58.2, y: 89.6, color: "#00A8CC", labelAbove: true },
  { id: "spielplatz",  name: "Spielplatz",  x: 62.9, y: 74.0, color: "#2EAA5E" }
];
```

### Personas (Placeholder — werden später von Diana ersetzt)
```js
const PERSONAS = [
  {
    id: "lena",
    name: "Lena, 10 Jahre",
    emoji: "👧",
    description: "Lena lebt seit Geburt in Kandel und kennt die Stadt sehr gut.",
    needs: ["Sichere Spielorte", "Barrierefreiheit", "Grünflächen"]
  },
  {
    id: "max",
    name: "Max, 12 Jahre",
    emoji: "🧒",
    description: "Max ist neu in Kandel und kennt noch nicht viele Orte.",
    needs: ["Orientierung", "Treffpunkte", "Öffentlicher Transport"]
  },
  {
    id: "sara",
    name: "Sara, 11 Jahre",
    emoji: "👧🦽",
    description: "Sara nutzt einen Rollstuhl und braucht barrierefreie Zugänge.",
    needs: ["Rollstuhlzugang", "Rampen", "Breite Wege"]
  }
];
```

### Maßnahmen pro Ort (Placeholder — Kosten in Krediten)
```js
const INTERVENTIONS = {
  skaterpark: [
    { id: "sk1", name: "Neue Rampe bauen",         credits: 4 },
    { id: "sk2", name: "Beleuchtung verbessern",   credits: 2 },
    { id: "sk3", name: "Sitzbank aufstellen",      credits: 1 },
    { id: "sk4", name: "Rollstuhlzugang",          credits: 3 }
  ],
  buecherei: [
    { id: "bu1", name: "Barrierefreier Eingang",   credits: 4 },
    { id: "bu2", name: "Mehr Jugendliteratur",     credits: 2 },
    { id: "bu3", name: "Leseecke gestalten",       credits: 1 },
    { id: "bu4", name: "Öffnungszeiten verlängern",credits: 3 }
  ],
  bahnhof: [
    { id: "bh1", name: "Fahrradstellplätze",       credits: 2 },
    { id: "bh2", name: "Aufzug installieren",      credits: 5 },
    { id: "bh3", name: "Wartebereich verbessern",  credits: 2 },
    { id: "bh4", name: "Digitale Anzeige",         credits: 3 }
  ],
  freibad: [
    { id: "fb1", name: "Rollstuhlrampe ins Wasser",credits: 5 },
    { id: "fb2", name: "Schattenbereich bauen",    credits: 3 },
    { id: "fb3", name: "Spielbereich für Kinder",  credits: 2 },
    { id: "fb4", name: "Eintritt vergünstigen",    credits: 2 }
  ],
  spielplatz: [
    { id: "sp1", name: "Inklusives Spielgerät",    credits: 5 },
    { id: "sp2", name: "Zaun reparieren",          credits: 1 },
    { id: "sp3", name: "Trinkwasserbrunnen",       credits: 2 },
    { id: "sp4", name: "Neue Schaukel",            credits: 2 }
  ]
};
```

---

## App-Ansichten (Views)

Die gesamte App ist **eine einzelne HTML-Datei**. Views werden per JS geswitch (kein Router).

```
/
├── VIEW: home          → Startseite, Auswahl Admin/Gruppe
├── VIEW: admin-setup   → Diana erstellt Sitzung und Gruppen
├── VIEW: admin-join    → Diana teilt Session-Code mit Gruppen
├── VIEW: group-join    → Gruppe gibt Session-Code ein
├── VIEW: group-map     → Hauptansicht: Karte + Abstimmung
└── VIEW: dashboard     → Live-Ergebnis-Dashboard
```

---

## View-Details

### 1. Home (`home`)
- Zwei große Buttons: **"Neue Sitzung starten"** (Diana) und **"Gruppe beitreten"**
- Klein unten: **"Dashboard öffnen"**
- Kein Login, kein Auth

---

### 2. Admin Setup (`admin-setup`)
- Eingabefeld: **Name der Sitzung** (z.B. "Klasse 5B — 27. Mai")
- Auswahl Anzahl Gruppen: **Stepper 2–8**
- Für jede Gruppe: Dropdown zur Persona-Auswahl (Lena / Max / Sara)
- **"Sitzung erstellen"** Button
  - Erstellt `session` in Supabase
  - Erstellt alle `groups` mit zugewiesenen Personas
  - Generiert einen **4-stelligen Session-Code** (z.B. "K7X2") — wird als session name gespeichert
- Übergang zu `admin-join`

---

### 3. Admin Join (`admin-join`)
- Zeigt den **Session-Code groß** an (zum Vorzeigen/Projizieren)
- Darunter: Liste aller Gruppen mit zugewiesener Persona
- Button: **"Zum Dashboard"**
- Button: **"← Zurück zum Setup"**

---

### 4. Group Join (`group-join`)
- Eingabe des **4-stelligen Session-Codes**
- Dropdown: **Gruppe auswählen** (wird nach Code-Eingabe geladen aus Supabase)
- **"Beitreten"** Button
- Übergang zu `group-map`

---

### 5. Group Map (`group-map`)

**Header-Bereich:**
- Persona-Karte: Emoji + Name + Kurzbeschreibung + Bedürfnisse (als Tags)
- Gruppen-Name (z.B. "Gruppe 3")
- Kredit-Anzeige: "💰 Verbleibende Kredite: 7 / 10"

**Karte:**
- Kandel-Karte (Base64 eingebettet) mit den 5 Ort-Icons
- Jedes Icon zeigt aktuellen Abstimmungsstatus (Ampelfarbe als Badge)
- Tap auf Icon → Bottom Sheet (kein Popup, besser für iPad)

**Bottom Sheet (pro Ort):**
- Ort-Name + Icon
- **Ampel:** Drei Buttons Rot / Gelb / Grün (bereits gewählter ist hervorgehoben)
- **Maßnahmen-Bereich** (nur wenn ein Semaphor gewählt):
  - Liste aller Maßnahmen mit Kredit-Kosten
  - Checkbox zum Auswählen (max. 10 Kredite insgesamt über alle Orte)
  - Wenn Kredit-Limit erreicht: restliche deaktivieren mit Hinweis
- **Speichern**-Button → schreibt in Supabase, schließt Sheet

**Fortschrittsbalken:** Zeigt wie viele von 5 Orten bewertet wurden

---

### 6. Dashboard (`dashboard`)

**Zugriffsweg:** Über Home → "Dashboard öffnen" → Session-Code eingeben

**Layout:**
- Oben: Session-Name + Anzahl aktiver Gruppen
- **Karte** (kleinere Version, nicht interaktiv)
  - Neben/über jedem Ort-Icon: Mini-Ampel-Balken (Anzahl 🔴🟡🟢 pro Ort)
- Unten: **Tabelle**
  - Zeilen = Orte
  - Spalten = 🔴 Rot | 🟡 Gelb | 🟢 Grün | Top-Maßnahmen
  - "Top-Maßnahmen" zeigt die 3 am häufigsten gewählten Interventionen pro Ort

**Realtime:** Supabase Realtime Subscription auf `votes` und `group_interventions` — Dashboard aktualisiert sich sofort ohne Reload.

**Keine Gruppen-Namen** im Dashboard (Anonymität der Abstimmung).

---

## UX-Regeln

- **iPad-First**: Alle Touch-Targets min. 48px, Bottom Sheet statt Popups
- **Kein Login**: Zugang nur über Session-Code
- **Offline-tolerant**: Votes werden lokal gecacht (localStorage) und bei Reconnect synced
- **Eine Stimme pro Gruppe pro Ort**: UNIQUE constraint in DB + UI-Feedback
- **Kreditlimit**: Wird client-side geprüft, visuelles Feedback bei Überschreitung

---

## Technische Notizen für Claude Code

- Die **Karte** ist als Base64-JPEG eingebettet (190KB, im Prototype bereits vorhanden)
- Die SVG-Icons für die 5 Orte sind im Prototype definiert — übernehmen
- **Supabase credentials** kommen als Konstanten oben in der Datei:
  ```js
  const SUPABASE_URL = 'https://xxx.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJ...';
  ```
- Supabase JS SDK via CDN: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2`
- **Keine npm, kein build** — alles in einer Datei, öffnet direkt im Browser
- GitHub Pages Deployment: einfach `index.html` in ein repo pushen

---

## Dateien aus dem Prototype (wiederverwenden)

Aus `kandel_prototipo.html`:
- Base64-Kartenbild (JPEG, 900×936px)
- Pin-Icons (SVG inline) für alle 5 Orte
- Pin-Positionen (x%, y%) — bereits korrekt kalibriert
- Basis-CSS (Ampel-Buttons, Pin-Styling)

---

## Out of Scope (für diese Version)

- Authentifizierung / Passwortschutz
- Bearbeitung von Personas aus der UI
- Export/PDF der Ergebnisse
- Mehrsprachigkeit
- History mehrerer Sitzungen

