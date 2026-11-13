# Contratto Dati – Progetto "Buby Solidale"
**Versione:** 2.0 (Allineata al Modello Dati SQLite definitivo)  
**Database:** SQLite (`buby_solidale.db`) con `PRAGMA foreign_keys = ON`  
**Formato scambio API:** JSON (UTF-8)  
**Formato scambio Dataset:** CSV (separatore `,`, encoding UTF-8)  
**Standard Date:** ISO 8601 (`YYYY-MM-DD`)

---

## 1. Schema del Database (5 Tabelle)
Tutti i CSV puliti prodotti dai Data Analyst e le tabelle create in SQLite devono rispettare esattamente questi nomi di colonna, tipi di dato e vincoli `CHECK`.

### Tabella 1: `punti_ritiro`
Contiene l'anagrafica dei centri di distribuzione e i dati aggregati/anonimi sui beneficiari per stimare i fabbisogni.
* `id_punto` (`TEXT`, PK): Identificativo univoco (es. `"PR_01"`).
* `nome` (`TEXT`, NOT NULL): Nome del centro (es. `"Emporio Aurora"`).
* `zona` (`TEXT`, NOT NULL): Quartiere o area geografica (es. `"Torino Nord"`).
* `capacita_max_kg` (`REAL`, NOT NULL): Capacità massima del magazzino in kg.
* `famiglie_assistite` (`INTEGER`, NOT NULL): Numero nuclei familiari seguiti (dato anonimo aggregato).

### Tabella 2: `giacenze`
Fotografia in tempo reale delle scorte disponibili per categoria in ogni punto di ritiro.
* `id_giacenza` (`TEXT`, PK): Identificativo univoco (es. `"GC_01"`).
* `id_punto` (`TEXT`, FK -> `punti_ritiro.id_punto`, NOT NULL): Punto di ritiro di riferimento.
* `categoria` (`TEXT`, NOT NULL, `CHECK`): Valori ammessi: `'ALIMENTARI_FRESCHI'`, `'ALIMENTARI_SECCHI'`, `'IGIENE'`, `'VESTIARIO'`.
* `quantita_attuale_kg` (`REAL`, NOT NULL): Peso netto attualmente in magazzino in kg.
* `soglia_min_kg` (`REAL`, NOT NULL): Soglia minima sotto la quale scatta l'alert **CRITICO / FABBISOGNO**.

### Tabella 3: `donazioni`
Traccia l'intero ciclo di vita dei beni: dall'offerta del donatore, all'assegnazione a un punto di ritiro, fino alla distribuzione alle famiglie.
* `id_donazione` (`TEXT`, PK): Identificativo univoco (es. `"DN_001"`).
* `donatore` (`TEXT`, NOT NULL): Nome azienda partner (es. `"Panificio Rossi"`) oppure `"Privato"` per garantire l'anonimato GDPR.
* `id_punto_destinazione` (`TEXT`, FK -> `punti_ritiro.id_punto`, NULLABLE): Punto assegnato dal Coordinatore (`NULL` finché lo stato è `'IN_ATTESA'`).
* `categoria` (`TEXT`, NOT NULL, `CHECK`): Valori ammessi: `'ALIMENTARI_FRESCHI'`, `'ALIMENTARI_SECCHI'`, `'IGIENE'`, `'VESTIARIO'`.
* `descrizione_prodotto` (`TEXT`, NOT NULL): Descrizione sintetica (es. `"Pane e focacce"`, `"Pasta di semola"`).
* `quantita_kg` (`REAL`, NOT NULL): Peso netto normalizzato in kg.
* `data_scadenza` (`TEXT`, NULLABLE): Data di scadenza in formato `YYYY-MM-DD` (null per vestiario).
* `stato` (`TEXT`, NOT NULL, `CHECK`): Valori ammessi: `'IN_ATTESA'`, `'ASSEGNATA'`, `'DISTRIBUITA'`, `'SCADUTA'`.

### Tabella 4: `turni_volontari`
Gestione operativa dei turni di ritiro/distribuzione e calcolo delle ore di volontariato.
* `id_turno` (`TEXT`, PK): Identificativo univoco (es. `"TR_001"`).
* `id_punto` (`TEXT`, FK -> `punti_ritiro.id_punto`, NOT NULL): Punto di ritiro di riferimento.
* `data_turno` (`TEXT`, NOT NULL): Giorno del turno (`YYYY-MM-DD`).
* `fascia_oraria` (`TEXT`, NOT NULL): Es. `"17:00-19:00"`.
* `ore_durata` (`REAL`, NOT NULL): Durata del turno in ore (es. `2.0`).
* `volontario_id` (`TEXT`, NULLABLE): Codice anonimo volontario (es. `"VOL_01"`), `NULL` se il turno è scoperto.
* `stato` (`TEXT`, NOT NULL, `CHECK`): Valori ammessi: `'SCOPERTO'`, `'COPERTO'`, `'COMPLETATO'`.

### Tabella 5: `comunicazioni_ai`
Archivia i dati non strutturati (email, messaggi, note sociali) anonimizzati e i risultati estratti dal motore AI.
* `id_comunicazione` (`TEXT`, PK): Identificativo univoco (es. `"CM_001"`).
* `id_punto_riferimento` (`TEXT`, FK -> `punti_ritiro.id_punto`, NULLABLE): Eventuale punto di ritiro citato nel testo.
* `id_donazione_generata` (`TEXT`, FK -> `donazioni.id_donazione`, NULLABLE): Eventuale donazione creata a partire dall'analisi dell'email.
* `fonte` (`TEXT`, NOT NULL, `CHECK`): Valori ammessi: `'EMAIL_DONATORE'`, `'MESSAGGIO_VOLONTARIO'`, `'NOTA_OPERATORE'`.
* `testo_anonimizzato` (`TEXT`, NOT NULL): Testo originale ripulito da nomi, telefoni e indirizzi privati.
* `categoria_rilevata` (`TEXT`, NULLABLE): Es. `'OFFERTA_DONAZIONE'`, `'DISPONIBILITA_TURNO'`, `'URGENZA_SOCIALE'`.
* `urgenza` (`TEXT`, NULLABLE, `CHECK`): Valori ammessi: `'BASSA'`, `'MEDIA'`, `'ALTA'`.
* `sintesi_ai` (`TEXT`, NULLABLE): Riassunto operativo generato dall'AI (max 1-2 frasi).
* `dati_estratti_json` (`TEXT`, NULLABLE): Stringa JSON con eventuali entità estratte (prodotto, kg, scadenza).

---

## 2. Specifiche API ed Esempi JSON

### Endpoint 1: Dashboard KPI e Alert Squilibri
* **Metodo:** `GET /api/v1/kpi`
* **Esempio Risposta (`200 OK`):**
```json
{
  "kpi_impatto": {
    "kg_recuperati_totali": 1450.5,
    "pasti_equivalenti_distribuiti": 2901,
    "ore_volontariato_totali": 186.0,
    "turni_coperti_perc": 88.5
  },
  "alert_squilibri": [
    {
      "id_punto": "PR_01",
      "nome_punto": "Emporio Aurora",
      "categoria": "ALIMENTARI_FRESCHI",
      "stato_alert": "CRITICO",
      "quantita_attuale_kg": 8.5,
      "soglia_min_kg": 30.0
    }
  ]
}
```

### Endpoint 2: Analisi Testi Non Strutturati (Motore AI/NLP)
* **Metodo:** `POST /api/v1/ai/analizza-testo`
* **Request Body (JSON):**
```json
{
  "fonte": "EMAIL_DONATORE",
  "testo_grezzo": "Buongiorno, siamo il Panificio Rossi. Oggi alle 18:30 abbiamo 15 kg di pane invenduto da ritirare."
}
```
* **Esempio Risposta (`200 OK`):**
```json
{
  "categoria_rilevata": "OFFERTA_DONAZIONE",
  "urgenza": "ALTA",
  "sintesi_ai": "Ritiro urgente di 15 kg di pane presso Panificio Rossi entro le 18:30.",
  "dati_estratti": {
    "donatore": "Panificio Rossi",
    "categoria": "ALIMENTARI_FRESCHI",
    "descrizione_prodotto": "Pane",
    "quantita_kg": 15.0
  },
  "id_punto_consigliato": "PR_01"
}
```

### Endpoint 3: Inserimento Donazione (Area Donatore)
* **Metodo:** `POST /api/v1/donazioni`
* **Request Body (JSON):**
```json
{
  "donatore": "Supermercato Centrale",
  "categoria": "ALIMENTARI_SECCHI",
  "descrizione_prodotto": "Pasta e legumi in scatola",
  "quantita_kg": 40.0,
  "data_scadenza": "2027-05-20"
}
```

### Endpoint 4: Assegnazione Donazione a Punto di Ritiro (Area Coordinatore)
* **Metodo:** `PATCH /api/v1/donazioni/{id_donazione}/assegna`
* **Request Body (JSON):**
```json
{
  "id_punto_destinazione": "PR_01"
}
```

### Endpoint 5: Prenotazione Turno (Area Volontario)
* **Metodo:** `POST /api/v1/turni/{id_turno}/prenota`
* **Request Body (JSON):**
```json
{
  "volontario_id": "VOL_04"
}
```

---

## 3. Regole di Calcolo KPI e Normalizzazione
1. **Normalizzazione Pesi:** Tutte le unità di misura (casse, pacchi, litri) vengono convertite in **kg** dai Data Analyst prima del caricamento in SQLite (`1 litro = 1.0 kg`).
2. **Kg Recuperati:** Somma di `quantita_kg` nella tabella `donazioni` dove `stato IN ('ASSEGNATA', 'DISTRIBUITA')`.
3. **Pasti Equivalenti Distribuiti:** Somma di `quantita_kg` nella tabella `donazioni` dove `stato = 'DISTRIBUITA'`, divisa per `0.5` (`1 pasto = 500g`).
4. **Ore di Volontariato:** Somma di `ore_durata` nella tabella `turni_volontari` dove `stato = 'COMPLETATO'`.
5. **Logica Alert Giacenze:**
   * Se `quantita_attuale_kg < soglia_min_kg` -> **`CRITICO`** (Badge Rosso).
   * Se la somma delle giacenze del punto supera l'`85%` di `capacita_max_kg` -> **`ECCEDENZA`** (Badge Giallo).
