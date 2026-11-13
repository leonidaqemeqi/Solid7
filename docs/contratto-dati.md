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

Gli endpoint da 1 a 5 erano presenti nel contratto iniziale. Gli endpoint da 6 a 10 sono stati aggiunti per completare i flussi descritti e approvati per il perimetro della demo. Il Backend li implementa secondo queste specifiche; il Frontend li usa per le schermate e il Team Leader verifica la compatibilità con schema e stati del database. Ogni modifica successiva va concordata e aggiornata qui prima dell'implementazione.

**Formato errori comune:**
```json
{
  "errore": {
    "codice": "VALIDATION_ERROR",
    "messaggio": "La quantità deve essere maggiore di zero."
  }
}
```
Usare `400` per request/filtri non validi, `404` per risorse inesistenti, `409` per conflitti di stato e `500` per errori interni. Non includere stack trace, request body grezzi o dati personali nei messaggi/log.

### Endpoint 1: Dashboard KPI e Alert Squilibri
* **Metodo:** `GET /api/v1/kpi`
* **Risposta:** `200 OK`; in caso di errore interno `500`.
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
* **Risposta:** `200 OK`; `400` per fonte/testo non validi; `503` se il servizio AI interno non è disponibile.
* **Request Body (JSON):**
```json
{
  "fonte": "EMAIL_DONATORE",
  "testo_grezzo": "Buongiorno, abbiamo 15 kg di pane invenduto da ritirare oggi entro le 18:30."
}
```
* **Regole privacy:** il testo grezzo può contenere dati personali e viene inviato esclusivamente al backend del progetto. Il backend lo inoltra al servizio AI interno, che lo anonimizza prima di qualsiasi elaborazione affidata a un modello esterno. Il testo grezzo non deve essere salvato né scritto nei log applicativi. Risposta e dati persistiti contengono solo testo anonimizzato e risultati senza dati personali identificativi.
* **Esempio Risposta (`200 OK`):**
```json
{
  "id_comunicazione": "CM_001",
  "categoria_rilevata": "OFFERTA_DONAZIONE",
  "urgenza": "ALTA",
  "sintesi_ai": "Ritiro urgente di 15 kg di pane entro le 18:30.",
  "dati_estratti": {
    "categoria": "ALIMENTARI_FRESCHI",
    "descrizione_prodotto": "Pane",
    "quantita_kg": 15.0
  },
  "id_punto_consigliato": "PR_01"
}
```
* **Persistenza:** il backend salva in `comunicazioni_ai` solo `testo_anonimizzato` e i risultati dell'analisi; non salva il request body grezzo. `id_comunicazione` identifica il record creato.

### Endpoint 3: Inserimento Donazione (Area Donatore)
* **Metodo:** `POST /api/v1/donazioni`
* **Risposta in caso di successo:** `201 Created`.
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
* **Corpo risposta:** oggetto `donazione` con `id_donazione`, i campi ricevuti, `id_punto_destinazione: null` e `stato: "IN_ATTESA"`.
* **Errori:** `400` per campi/categoria/quantità/data non validi.

### Endpoint 4: Assegnazione Donazione a Punto di Ritiro (Area Coordinatore)
* **Metodo:** `PATCH /api/v1/donazioni/{id_donazione}/assegna`
* **Risposta in caso di successo:** `200 OK`.
* **Request Body (JSON):**
```json
{
  "id_punto_destinazione": "PR_01"
}
```
* **Corpo risposta:** oggetto `donazione` aggiornato con `id_punto_destinazione` e `stato: "ASSEGNATA"`.
* **Errori:** `400` per body non valido; `404` se donazione o punto non esistono; `409` se la donazione non è `IN_ATTESA`.

### Endpoint 5: Prenotazione Turno (Area Volontario)
* **Metodo:** `POST /api/v1/turni/{id_turno}/prenota`
* **Risposta in caso di successo:** `200 OK`.
* **Request Body (JSON):**
```json
{
  "volontario_id": "VOL_04"
}
```
* **Corpo risposta:** oggetto `turno` aggiornato con `volontario_id` e `stato: "COPERTO"`.
* **Errori:** `400` per body non valido; `404` se il turno non esiste; `409` se non è `SCOPERTO`.

### Endpoint 6: Elenco punti di ritiro e giacenze
* **Metodo:** `GET /api/v1/punti-ritiro`
* **Uso:** popolare dashboard e selettore del punto di destinazione durante l'assegnazione. Le giacenze annidate permettono di evidenziare i punti sotto soglia senza una chiamata per punto.
* **Query opzionale:** `id_punto` per richiedere un singolo punto.
* **Esempio risposta (`200 OK`):**
```json
{
  "punti_ritiro": [
    {
      "id_punto": "PR_01",
      "nome": "Emporio Aurora",
      "zona": "Torino Nord",
      "capacita_max_kg": 500.0,
      "famiglie_assistite": 40,
      "giacenze": [
        {
          "categoria": "ALIMENTARI_FRESCHI",
          "quantita_attuale_kg": 8.5,
          "soglia_min_kg": 30.0
        }
      ]
    }
  ]
}
```
* **Comportamento:** includere le giacenze per categoria; `id_punto` inesistente restituisce `404`.

### Endpoint 7: Elenco turni
* **Metodo:** `GET /api/v1/turni`
* **Query opzionali:** `data_da`, `data_a` (`YYYY-MM-DD`), `stato`, `id_punto`.
* **Esempio risposta (`200 OK`):**
```json
{
  "turni": [
    {
      "id_turno": "TR_001",
      "id_punto": "PR_01",
      "nome_punto": "Emporio Aurora",
      "data_turno": "2026-11-20",
      "fascia_oraria": "17:00-19:00",
      "ore_durata": 2.0,
      "volontario_id": null,
      "stato": "SCOPERTO"
    }
  ]
}
```
* **Comportamento:** intervallo date inclusivo; `data_da` successiva a `data_a` o stato non ammesso restituiscono `400`; senza risultati restituisce `200` con array vuoto.

### Endpoint 8: Elenco donazioni
* **Metodo:** `GET /api/v1/donazioni`
* **Query opzionali:** `stato`, `id_punto_destinazione`.
* **Esempio risposta (`200 OK`):**
```json
{
  "donazioni": [
    {
      "id_donazione": "DN_001",
      "donatore": "Panificio Rossi",
      "id_punto_destinazione": null,
      "categoria": "ALIMENTARI_FRESCHI",
      "descrizione_prodotto": "Pane",
      "quantita_kg": 15.0,
      "data_scadenza": "2026-11-21",
      "stato": "IN_ATTESA"
    }
  ]
}
```
* **Comportamento:** filtri validi si combinano; stato o punto non validi restituiscono `400`; nessun risultato restituisce `200` con array vuoto. Nel prototipo senza autenticazione si usano esclusivamente dati sintetici.

### Endpoint 9: Disdetta prenotazione
* **Metodo:** `POST /api/v1/turni/{id_turno}/disdici`
* **Motivazione:** mantenere l'identificativo volontario nel body è necessario perché il prototipo non ha autenticazione; il backend può verificare che la prenotazione appartenga al volontario indicato.
* **Request body:**
```json
{
  "volontario_id": "VOL_04"
}
```
* **Esempio risposta (`200 OK`):**
```json
{
  "id_turno": "TR_001",
  "volontario_id": null,
  "stato": "SCOPERTO"
}
```
* **Comportamento:** riporta a `SCOPERTO` solo il turno prenotato dallo stesso `volontario_id`; turno inesistente restituisce `404`, prenotazione assente o appartenente a un altro ID restituisce `409`. L'ID è dimostrativo e non costituisce autenticazione.

### Endpoint 10: Elenco comunicazioni analizzate
* **Metodo:** `GET /api/v1/comunicazioni`
* **Query opzionali:** `fonte`, `urgenza`.
* **Esempio risposta (`200 OK`):**
```json
{
  "comunicazioni": [
    {
      "id_comunicazione": "CM_001",
      "fonte": "EMAIL_DONATORE",
      "testo_anonimizzato": "Abbiamo 15 kg di pane da ritirare entro le 18:30.",
      "categoria_rilevata": "OFFERTA_DONAZIONE",
      "urgenza": "ALTA",
      "sintesi_ai": "Ritiro di 15 kg di pane entro le 18:30.",
      "dati_estratti": {
        "categoria": "ALIMENTARI_FRESCHI",
        "descrizione_prodotto": "Pane",
        "quantita_kg": 15.0
      }
    }
  ]
}
```
* **Comportamento:** la risposta non include testo grezzo; valori di filtro non ammessi restituiscono `400`; nessun risultato restituisce `200` con array vuoto.

---

## 3. Regole di Calcolo KPI e Normalizzazione
1. **Normalizzazione Pesi:** Tutte le unità di misura (casse, pacchi, litri) vengono convertite in **kg** dai Data Analyst prima del caricamento in SQLite (`1 litro = 1.0 kg`).
2. **Kg Recuperati:** Somma di `quantita_kg` nella tabella `donazioni` dove `stato IN ('ASSEGNATA', 'DISTRIBUITA')`.
3. **Pasti Equivalenti Distribuiti:** Somma di `quantita_kg` nella tabella `donazioni` dove `stato = 'DISTRIBUITA'`, divisa per `0.5` (`1 pasto = 500g`).
4. **Ore di Volontariato:** Somma di `ore_durata` nella tabella `turni_volontari` dove `stato = 'COMPLETATO'`.
5. **Logica Alert Giacenze:**
   * Se `quantita_attuale_kg < soglia_min_kg` -> **`CRITICO`** (Badge Rosso).
   * Se la somma delle giacenze del punto supera l'`85%` di `capacita_max_kg` -> **`ECCEDENZA`** (Badge Giallo).
