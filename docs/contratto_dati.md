# Contratto Dati – Progetto "Buby Solidale"
**Versione:** 3.0 (Allineata al Modello Dati SQLite da 11 Tabelle)  
**Database:** SQLite (`buby_solidale.db`) con `PRAGMA foreign_keys = ON`  
**Formato scambio API:** JSON (UTF-8)  
**Formato scambio Dataset:** CSV (separatore `,`, encoding UTF-8)  
**Standard Date:** ISO 8601 (`YYYY-MM-DD`)

---

## 1. Schema del Database (11 Tabelle)
Tutti i CSV puliti prodotti dai Data Analyst e le tabelle create in SQLite devono rispettare esattamente questi nomi di colonna, tipi di dato e vincoli `CHECK`.

### 1.1 TABELLE ANAGRAFICHE
**Tabella 1: `punti_ritiro`**
- `id_punto` (`TEXT`, PK): Identificativo univoco (es. `"PR_01"`).
- `nome` (`TEXT`, NOT NULL): Nome del centro (es. `"Emporio Aurora"`).
- `zona` (`TEXT`, NOT NULL): Quartiere o area geografica (es. `"Torino Nord"`).
- `capacita_max_kg` (`REAL`, DEFAULT `1000.0`): Capacità massima del magazzino in kg.
- `famiglie_assistite` (`INTEGER`, DEFAULT `0`): Numero nuclei familiari seguiti.

**Tabella 2: `donatori`**
- `id_donatore` (`TEXT`, PK): Identificativo univoco anonimizzato (es. `"DN_001"`).
- `nome_donatore` (`TEXT`, NOT NULL): Nome azienda o "Privato".
- `tipologia_donatore` (`TEXT`, NULLABLE): Es. "Panificio", "Supermercato", "Privato".

**Tabella 3: `volontari`**
- `id_volontario` (`TEXT`, PK): Identificativo univoco anonimizzato (es. `"VOL_01"`).
- `data_registrazione` (`TEXT`, DEFAULT `CURRENT_DATE`): Data di ingresso.

**Tabella 4: `beneficiari`**
- `id_beneficiario_anonimo` (`TEXT`, PK): Identificativo univoco nucleo familiare (es. `"BEN_001"`).
- `quartiere_riferimento` (`TEXT`, NULLABLE): Zona di residenza per statistiche.

### 1.2 TABELLE OPERATIVE
**Tabella 5: `giacenze`**
- `id_giacenza` (`TEXT`, PK): Identificativo univoco.
- `id_punto` (`TEXT`, FK -> `punti_ritiro.id_punto`, NOT NULL).
- `categoria` (`TEXT`, CHECK): `'ALIMENTARI_FRESCHI'`, `'ALIMENTARI_SECCHI'`, `'IGIENE'`, `'VESTIARIO'`.
- `quantita_attuale_kg` (`REAL`, NOT NULL): Peso netto in magazzino.
- `soglia_min_kg` (`REAL`, DEFAULT `50.0`): Soglia per alert CRITICO.

**Tabella 6: `donazioni`**
- `id_donazione` (`TEXT`, PK): Identificativo univoco.
- `id_donatore` (`TEXT`, FK -> `donatori.id_donatore`, NOT NULL).
- `id_punto_destinazione` (`TEXT`, FK -> `punti_ritiro.id_punto`, NULLABLE).
- `categoria` (`TEXT`, CHECK): `'ALIMENTARI_FRESCHI'`, `'ALIMENTARI_SECCHI'`, `'IGIENE'`, `'VESTIARIO'`.
- `descrizione_prodotto` (`TEXT`, NOT NULL): Es. "Pane e focacce".
- `quantita_kg` (`REAL`, NOT NULL): Peso netto in kg.
- `data_scadenza` (`TEXT`, NULLABLE): Formato `YYYY-MM-DD`.
- `stato` (`TEXT`, CHECK): `'IN_ATTESA'`, `'RITIRATA_STOCCATA'`, `'DISTRIBUITA'`, `'SCADUTA'`.

**Tabella 7: `distribuzioni`**
- `id_distribuzione` (`TEXT`, PK): Identificativo univoco.
- `id_punto` (`TEXT`, FK -> `punti_ritiro.id_punto`, NOT NULL).
- `id_beneficiario_anonimo` (`TEXT`, FK -> `beneficiari.id_beneficiario_anonimo`, NOT NULL).
- `data_distribuzione` (`TEXT`, NOT NULL): Data di consegna.
- `kg_consegnati` (`REAL`, NOT NULL): Quantità erogata al beneficiario.

**Tabella 8: `turni`**
- `id_turno` (`TEXT`, PK): Identificativo univoco.
- `id_punto` (`TEXT`, FK -> `punti_ritiro.id_punto`, NOT NULL).
- `id_volontario` (`TEXT`, FK -> `volontari.id_volontario`, NULLABLE): `NULL` se scoperto.
- `data_turno` (`TEXT`, NOT NULL): Giorno del turno (`YYYY-MM-DD`).
- `fascia_oraria` (`TEXT`, NOT NULL): Es. `"17:00-19:00"`.
- `ore_durata` (`REAL`, DEFAULT `2.0`).
- `stato` (`TEXT`, CHECK): `'SCOPERTO'`, `'COPERTO'`, `'COMPLETATO'`.

### 1.3 TABELLE COMUNICAZIONI E AI (NLP)
**Tabella 9: `email_donatori`**
- `id_email` (`TEXT`, PK).
- `id_donatore` (`TEXT`, FK -> `donatori.id_donatore`, NULLABLE).
- `data_ricezione` (`TEXT`, NOT NULL).
- `testo_anonimizzato` (`TEXT`, NOT NULL).
- `nlp_intent` (`TEXT`, NULLABLE): Es. `'OFFERTA_DONAZIONE'`.
- `urgenza` (`TEXT`, CHECK): `'BASSA'`, `'MEDIA'`, `'ALTA'`, `'NORMALE'`.
- `nlp_extracted_json` (`TEXT`, NULLABLE): Payload estratto (kg, prodotto, scadenza).

**Tabella 10: `messaggi_volontari`**
- `id_messaggio` (`TEXT`, PK).
- `id_volontario` (`TEXT`, FK -> `volontari.id_volontario`, NOT NULL).
- `data_messaggio` (`TEXT`, NOT NULL).
- `testo_anonimizzato` (`TEXT`, NOT NULL).
- `nlp_intent` (`TEXT`, NULLABLE): Es. `'DISPONIBILITA'`, `'DISDETTA'`.

**Tabella 11: `note_operatori`**
- `id_nota` (`TEXT`, PK).
- `id_punto` (`TEXT`, FK -> `punti_ritiro.id_punto`, NOT NULL).
- `data_nota` (`TEXT`, NOT NULL).
- `testo_anonimizzato` (`TEXT`, NOT NULL).
- `nlp_intent` (`TEXT`, NULLABLE).
- `nlp_extracted_json` (`TEXT`, NULLABLE).

---

## 2. Specifiche API ed Esempi JSON

### Endpoint 1: Dashboard KPI
- **Metodo:** `GET /api/v1/kpi`
- **Esempio Risposta (`200 OK`):**
{
  "kpi_impatto": {
    "kg_recuperati_totali": 1450.5,
    "pasti_equivalenti_distribuiti": 2901,
    "ore_volontariato_totali": 186.0
  },
  "alert_squilibri": [
    {
      "id_punto": "PR_01",
      "categoria": "ALIMENTARI_FRESCHI",
      "stato_alert": "CRITICO",
      "quantita_attuale_kg": 8.5,
      "soglia_min_kg": 50.0
    }
  ]
}

### Endpoint 2: Analisi NLP Email Donatore
- **Metodo:** `POST /api/v1/ai/analizza-email`
- **Request Body (JSON):**
{
  "id_donatore": "DN_001",
  "testo_grezzo": "Oggi abbiamo 15 kg di pane invenduto da ritirare subito."
}
- **Esempio Risposta (`200 OK`):**
{
  "nlp_intent": "OFFERTA_DONAZIONE",
  "urgenza": "ALTA",
  "nlp_extracted_json": {
    "categoria": "ALIMENTARI_FRESCHI",
    "descrizione_prodotto": "Pane",
    "quantita_kg": 15.0
  }
}

---

## 3. Regole di Calcolo KPI e Normalizzazione
1. **Normalizzazione Pesi:** Tutte le unità di misura (casse, pacchi, litri) vengono convertite in **kg** (`1 litro = 1.0 kg`) prima dell'inserimento.
2. **Kg Recuperati:** Somma di `quantita_kg` nella tabella `donazioni` dove `stato IN ('RITIRATA_STOCCATA', 'DISTRIBUITA')`.
3. **Pasti Equivalenti Distribuiti:** Somma di `kg_consegnati` nella tabella `distribuzioni`, divisa per `0.5` (`1 pasto = 500g`).
4. **Ore di Volontariato:** Somma di `ore_durata` nella tabella `turni` dove `stato = 'COMPLETATO'`.
5. **Logica Alert Giacenze:**
  - Se `quantita_attuale_kg < soglia_min_kg` in `giacenze` -> **`CRITICO`** (Badge Rosso).
  - Se la somma delle `quantita_attuale_kg` in un punto supera l'`85%` di `capacita_max_kg` del `punti_ritiro` -> **`ECCEDENZA`** (Badge Giallo).