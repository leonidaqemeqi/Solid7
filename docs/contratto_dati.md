# Contratto Dati – Progetto "Buby Solidale" (Solid7)
**Versione:** 4.0 (SAL 1 – Allineata allo Schema SQLite Reale da 11 Tabelle)  
**Data:** 2026-11-25  
**Database:** SQLite (`buby_solidale.db`) con `PRAGMA foreign_keys = ON`  
**Formato scambio API:** JSON (UTF-8)  
**Formato scambio Dataset:** CSV (separatore `,`, encoding UTF-8)  
**Standard Date:** ISO 8601 (`YYYY-MM-DD` / `YYYY-MM-DD HH:MM:SS`)

---

## 1. Domini Condivisi e Vincoli Globali

### 1.1 Categorie Merceologiche Ufficiali (7 Valori)
Valide sulle tabelle `giacenze`, `donazioni` e `distribuzioni`:
1. `'Pasta e Cereali'`
2. `'Frutta e Verdura'`
3. `'Latticini e Formaggi'`
4. `'Prodotti da Forno'`
5. `'Scatolame e Legumi'`
6. `'Prodotti Infanzia'`
7. `'Beni Prima Necessità (Igiene)'`

### 1.2 Indici Prestazionali Definizione Schema
- `idx_donazioni_data` su `donazioni(data_ricezione)`
- `idx_donazioni_stato_scad` su `donazioni(stato, data_scadenza)`
- `idx_distribuzioni_punto` su `distribuzioni(id_punto, data_distribuzione)`
- `idx_distribuzioni_benef` su `distribuzioni(id_beneficiario_anonimo)`
- `idx_turni_data_stato` su `turni(data_turno, stato)`

---

## 2. Schema del Database (11 Tabelle)

### 2.1 TABELLE ANAGRAFICHE (MVP)

**Tabella 1: `punti_ritiro`**
- `id_punto` (`TEXT`, PK): Identificativo univoco (es. `"PR_01"`).
- `nome` (`TEXT`, NOT NULL): Nome del punto di distribuzione/ritiro.
- `quartiere` (`TEXT`, NOT NULL): Quartiere o area cittadina di riferimento.
- `capacita_max_kg` (`REAL`, NOT NULL, DEFAULT `1000.0`, CHECK `capacita_max_kg > 0`): Capacità massima di stoccaggio in kg.
- `famiglie_assistite` (`INTEGER`, NOT NULL, DEFAULT `0`, CHECK `famiglie_assistite >= 0`): Numero nuclei familiari seguiti dal punto.

**Tabella 2: `donatori`**
- `id_donatore` (`TEXT`, PK): Identificativo univoco anonimizzato (es. `"DN_001"`).
- `nome_donatore` (`TEXT`, NOT NULL): Ragione sociale o nominativo donatore.
- `tipologia_donatore` (`TEXT`, NULLABLE): Tipologia attività (es. `"Panificio"`, `"Supermercato"`, `"Privato"`).

**Tabella 3: `volontari`**
- `id_volontario` (`TEXT`, PK): Identificativo univoco anonimizzato (es. `"VOL_01"`).
- `codice_accesso` (`TEXT`, NOT NULL, DEFAULT `'DA_ASSEGNARE'`): Credenziale personale per autenticazione volontario (`id_volontario` + `codice_accesso`). Nel dataset iniziale SAL 1 assume il valore predefinito `'DA_ASSEGNARE'`; la generazione dei codici individuali è pianificata in Fase 2.
- `data_registrazione` (`TEXT`, NOT NULL, DEFAULT `CURRENT_DATE`): Data di registrazione del volontario (`YYYY-MM-DD`).

**Tabella 4: `beneficiari`**
- `id_beneficiario_anonimo` (`TEXT`, PK): Identificativo univoco anonimizzato del nucleo familiare (es. `"BEN_001"`).
- `fascia_eta` (`TEXT`, NULLABLE, CHECK `fascia_eta IN ('18-30', '31-45', '46-64', '65+')`): Fascia anagrafica del referente del nucleo.
- `componenti_nucleo` (`INTEGER`, NULLABLE, CHECK `componenti_nucleo > 0`): Numero componenti del nucleo familiare.
- `quartiere_residenza` (`TEXT`, NULLABLE): Quartiere di residenza per analisi territoriali.

---

### 2.2 TABELLE OPERATIVE (MVP)

**Tabella 5: `giacenze`**
- `id_giacenza` (`TEXT`, PK): Identificativo univoco della riga di giacenza.
- `id_punto` (`TEXT`, NOT NULL, FK -> `punti_ritiro.id_punto`): Punto di ritiro proprietario dello stock.
- `categoria` (`TEXT`, NOT NULL, CHECK sulle 7 categorie ufficiali).
- `quantita_disponibile_kg` (`REAL`, NOT NULL, DEFAULT `0`, CHECK `quantita_disponibile_kg >= 0`): Quantità attualmente presente in magazzino (kg).
- `soglia_minima_kg` (`REAL`, NOT NULL, DEFAULT `50.0`, CHECK `soglia_minima_kg >= 0`): Soglia minima di sicurezza (kg).
- `kg_in_scadenza_48h` (`REAL`, NOT NULL, DEFAULT `0`, CHECK `kg_in_scadenza_48h >= 0`): Quantità prossima alla scadenza entro 48 ore (kg).
- `stato_scorte` (`TEXT`, NOT NULL, DEFAULT `'OTTIMALE'`, CHECK `stato_scorte IN ('CARENZA', 'OTTIMALE', 'RISCHIO_SPRECO')`): Stato operativo delle scorte.
- `ultimo_aggiornamento` (`TEXT`, NOT NULL, DEFAULT `CURRENT_TIMESTAMP`): Timestamp ultimo aggiornamento.
- **Vincolo di unicità:** `UNIQUE (id_punto, categoria)`.

**Tabella 6: `donazioni`**
- `id_donazione` (`TEXT`, PK): Identificativo univoco della donazione.
- `id_donatore` (`TEXT`, NOT NULL, FK -> `donatori.id_donatore`): Donatore conferente.
- `id_punto` (`TEXT`, NULLABLE, FK -> `punti_ritiro.id_punto`): Punto assegnato al ritiro/stoccaggio (`NULL` consentito solo se `stato` è `'IN_ATTESA'` o `'SCADUTA'`).
- `categoria` (`TEXT`, NOT NULL, CHECK sulle 7 categorie ufficiali).
- `deperibilita` (`TEXT`, NOT NULL, CHECK `deperibilita IN ('Alta (Fresco)', 'Immediata', 'Lunga Conservazione', 'Media Conservazione', 'Non Deperibile')`): Classe di conservazione del lotto.
- `descrizione_prodotto` (`TEXT`, NULLABLE): Descrizione sintetica dei beni donati.
- `quantita_kg` (`REAL`, NOT NULL, CHECK `quantita_kg > 0`): Peso netto conferito (kg).
- `data_ricezione` (`TEXT`, NOT NULL, DEFAULT `CURRENT_DATE`): Data di registrazione/ricezione (`YYYY-MM-DD`).
- `data_scadenza` (`TEXT`, NULLABLE): Data di scadenza stimata o dichiarata (`YYYY-MM-DD`).
- `stato` (`TEXT`, NOT NULL, DEFAULT `'IN_ATTESA'`, CHECK `stato IN ('IN_ATTESA', 'RITIRATA_STOCCATA', 'DISTRIBUITA', 'SCADUTA')`): Stato del ciclo di vita.
- **Vincolo di coerenza:** `CHECK (stato NOT IN ('RITIRATA_STOCCATA', 'DISTRIBUITA') OR id_punto IS NOT NULL)`.

**Tabella 7: `distribuzioni`**
- `id_distribuzione` (`TEXT`, PK): Identificativo univoco dell'erogazione.
- `id_punto` (`TEXT`, NOT NULL, FK -> `punti_ritiro.id_punto`): Punto erogatore.
- `id_beneficiario_anonimo` (`TEXT`, NOT NULL, FK -> `beneficiari.id_beneficiario_anonimo`): Nucleo beneficiario.
- `categoria` (`TEXT`, NOT NULL, CHECK sulle 7 categorie ufficiali).
- `data_distribuzione` (`TEXT`, NOT NULL): Data di consegna (`YYYY-MM-DD`).
- `kg_distribuiti` (`REAL`, NOT NULL, CHECK `kg_distribuiti > 0`): Peso netto consegnato (kg).
- `pasti_equivalenti` (`INTEGER`, NOT NULL, CHECK `pasti_equivalenti >= 0`): Unità di supporto equivalente calcolata sulla consegna (vedi §5.2).

**Tabella 8: `turni`**
- `id_turno` (`TEXT`, PK): Identificativo univoco del turno.
- `id_punto` (`TEXT`, NOT NULL, FK -> `punti_ritiro.id_punto`): Punto operativo del turno.
- `id_volontario` (`TEXT`, NULLABLE, FK -> `volontari.id_volontario`): Volontario assegnato.
- `data_turno` (`TEXT`, NOT NULL): Data del turno (`YYYY-MM-DD`).
- `fascia_oraria` (`TEXT`, NOT NULL): Fascia oraria (es. `"09:00-13:00"`).
- `ore_durata` (`REAL`, NOT NULL, CHECK `ore_durata > 0`): Durata in ore.
- `mansione` (`TEXT`, NOT NULL): Attività prevista (es. `"Ritiro Donazioni"`, `"Distribuzione"`, `"Smistamento Magazzino"`).
- `stato` (`TEXT`, NOT NULL, DEFAULT `'SCOPERTO'`, CHECK `stato IN ('SCOPERTO', 'COPERTO', 'COMPLETATO', 'ANNULLATO')`): Stato operativo del turno.
- **Vincoli di integrità:**
  - `UNIQUE (id_volontario, data_turno, fascia_oraria)` (impedisce allo stesso volontario due turni con la stessa identica fascia; le sovrapposizioni parziali sono controllate dal backend, vedi §5.2).
  - `CHECK ((stato IN ('SCOPERTO', 'ANNULLATO') AND id_volontario IS NULL) OR (stato IN ('COPERTO', 'COMPLETATO') AND id_volontario IS NOT NULL))`.

---

### 2.3 TABELLE COMUNICAZIONI E AI / NLP (Fase 2)

**Tabella 9: `email_donatori`**
- `id_email` (`TEXT`, PK): Identificativo univoco comunicazione.
- `id_donatore` (`TEXT`, NULLABLE, FK -> `donatori.id_donatore`): Donatore associato (se riconosciuto).
- `mittente` (`TEXT`, NULLABLE): Indirizzo o riferimento mittente anonimizzato.
- `oggetto` (`TEXT`, NULLABLE): Oggetto dell'email.
- `data_ricezione` (`TEXT`, NOT NULL): Timestamp/data di ricezione.
- `testo_anonimizzato` (`TEXT`, NOT NULL): Corpo email ripulito da PII.
- `nlp_intent` (`TEXT`, NULLABLE): Intento rilevato dal motore NLP (es. `'OFFERTA_DONAZIONE'`).
- `urgenza` (`TEXT`, NOT NULL, DEFAULT `'NORMALE'`, CHECK `urgenza IN ('BASSA', 'NORMALE', 'MEDIA', 'ALTA')`): Priorità operativa.
- `nlp_extracted_json` (`TEXT`, NULLABLE): Entità strutturate estratte in JSON (categoria, quantità, scadenza).
- `stato_validazione` (`TEXT`, NOT NULL, DEFAULT `'DA_VALIDARE'`, CHECK `stato_validazione IN ('DA_VALIDARE', 'APPROVATA', 'RIFIUTATA')`): Stato revisione umana (Human-in-the-loop).
- `data_validazione` (`TEXT`, NULLABLE): Data/ora della validazione da parte dell'operatore.

**Tabella 10: `messaggi_volontari`**
- `id_messaggio` (`TEXT`, PK): Identificativo univoco messaggio.
- `id_volontario` (`TEXT`, NOT NULL, FK -> `volontari.id_volontario`): Volontario mittente.
- `canale` (`TEXT`, NULLABLE): Canale di provenienza (es. `"Telegram"`, `"WhatsApp"`, `"SMS"`).
- `data_messaggio` (`TEXT`, NOT NULL): Timestamp/data invio.
- `testo_anonimizzato` (`TEXT`, NOT NULL): Contenuto anonimizzato.
- `nlp_intent` (`TEXT`, NULLABLE, CHECK `nlp_intent IS NULL OR nlp_intent IN ('DISPONIBILITA_TURNO', 'DISDETTA_TURNO', 'SEGNALAZIONE_RITARDO', 'ALTRO')`): Intento classificato.
- `stato_validazione` (`TEXT`, NOT NULL, DEFAULT `'DA_VALIDARE'`, CHECK `stato_validazione IN ('DA_VALIDARE', 'APPROVATA', 'RIFIUTATA')`): Stato revisione umana.
- `data_validazione` (`TEXT`, NULLABLE): Data/ora validazione.

**Tabella 11: `note_operatori`**
- `id_nota` (`TEXT`, PK): Identificativo univoco nota.
- `id_punto` (`TEXT`, NOT NULL, FK -> `punti_ritiro.id_punto`): Punto di ritiro oggetto della nota.
- `operatore` (`TEXT`, NULLABLE): Identificativo operatore autore della nota.
- `data_nota` (`TEXT`, NOT NULL): Data inserimento nota.
- `testo_anonimizzato` (`TEXT`, NOT NULL): Testo operativo anonimizzato.
- `nlp_intent` (`TEXT`, NULLABLE): Intento/categoria operativa estratta.
- `nlp_extracted_json` (`TEXT`, NULLABLE): Dettagli strutturati estratti in JSON.
- `stato_validazione` (`TEXT`, NOT NULL, DEFAULT `'DA_VALIDARE'`, CHECK `stato_validazione IN ('DA_VALIDARE', 'APPROVATA', 'RIFIUTATA')`): Stato revisione umana.
- `data_validazione` (`TEXT`, NULLABLE): Data/ora validazione.

---

## 3. Specifiche API ed Esempi JSON

### Endpoint 1: Dashboard KPI e Alert Scorte
- **Metodo:** `GET /api/v1/kpi`
- **Esempio Risposta (`200 OK`):**
```json
{
  "kpi_impatto": {
    "kg_recuperati_totali": 2467.3,
    "pasti_equivalenti_distribuiti": 4929,
    "famiglie_beneficiarie_attive": 251,
    "ore_volontariato_completate": 124.0
  },
  "alert_scorte": [
    {
      "id_giacenza": "GIAC_003",
      "id_punto": "PR_01",
      "categoria": "Latticini e Formaggi",
      "stato_scorte": "RISCHIO_SPRECO",
      "quantita_disponibile_kg": 42.0,
      "soglia_minima_kg": 20.0,
      "kg_in_scadenza_48h": 18.5
    },
    {
      "id_giacenza": "GIAC_011",
      "id_punto": "PR_02",
      "categoria": "Prodotti da Forno",
      "stato_scorte": "CARENZA",
      "quantita_disponibile_kg": 12.0,
      "soglia_minima_kg": 30.0,
      "kg_in_scadenza_48h": 0.0
    }
  ]
}
```

---

## 4. Elenco Endpoint API (MVP)

Prefisso comune: `/api/v1`. Payload dettagliati da definire per ciascun endpoint prima dello sviluppo; qui sono fissati metodo, percorso e scopo.

| Metodo | Percorso | Scopo | Attore | Caso d'uso |
|---|---|---|---|---|
| GET | `/kpi` | KPI di impatto e alert scorte (già definito al §3) | Coordinatore | UC1, UC2 |
| GET | `/giacenze` | Giacenze per punto di ritiro e stato scorte | Coordinatore | UC2 |
| POST | `/donazioni` | Inserire un'offerta di donazione | Donatore | UC8 |
| GET | `/donazioni` | Storico donazioni e kg salvati (filtro per donatore) | Donatore | UC9 |
| PATCH | `/donazioni/{id}/assegna` | Assegnare una donazione a un punto di ritiro | Coordinatore | UC3 |
| POST | `/beneficiari` | Censire un beneficiario anonimizzato | Coordinatore | UC5 |
| POST | `/distribuzioni` | Registrare una distribuzione e i pasti equivalenti | Coordinatore | UC4 |
| GET | `/turni` | Consultare i turni (filtro per stato e data) | Volontario, Coordinatore | UC10, UC6 |
| POST | `/turni` | Pianificare un nuovo turno | Coordinatore | UC6 |
| POST | `/turni/{id}/prenota` | Prenotare un turno scoperto | Volontario | UC10 |
| POST | `/turni/{id}/disdici` | Disdire un turno prenotato | Volontario | UC11 |
| PATCH | `/turni/{id}/completa` | Segnare un turno come completato (rendicontazione) | Coordinatore | UC6 |

Gli endpoint di Fase 2 (messaggi volontari, email donatori, note operatori, validazione AI / HITL) verranno definiti nella Fase 2.

---

## 5. Decisioni e Limiti Noti (SAL 1)

### 5.1 Decisioni prese
- **SQLite** come database: semplice, file singolo, adatto a un MVP con pochi utenti concorrenti.
- **MVP prima, AI dopo**: 8 tabelle operative/anagrafiche ora, 3 tabelle NLP/AI in Fase 2.
- **Human-in-the-loop** su tutto ciò che estrae l'AI: nessun dato estratto entra nel flusso operativo senza validazione di un operatore.
- **Anonimizzazione** di beneficiari e volontari tramite identificativi non riconducibili alla persona.

### 5.2 Semplificazioni accettate nell'MVP
- **Autenticazione**: nessun login reale; i controlli di ruolo sono gestiti a livello di applicazione. Il campo `codice_accesso` dei volontari è predisposto per la Fase 2.
- **Aggiornamento giacenze e stati**: `quantita_disponibile_kg`, `kg_in_scadenza_48h` e `stato_scorte` sono aggiornati dal backend quando una donazione diventa `RITIRATA_STOCCATA` o quando si registra una distribuzione. Non c'è FK diretta tra donazioni, giacenze e distribuzioni.
- **Sovrapposizione turni**: il vincolo `UNIQUE` blocca solo fasce orarie identiche; le sovrapposizioni parziali sono controllate dal backend.
- **Dati derivati** (`famiglie_assistite`, KPI aggregati): calcolati o aggiornati dal backend, non da trigger.
- **Pasti equivalenti**: nel dataset attuale `pasti_equivalenti = 2 × kg_distribuiti`, uguale per tutte le 7 categorie. Regola da validare con il cliente, in particolare per le categorie non alimentari (Prodotti Infanzia, Beni Prima Necessità).

### 5.3 Da rifinire in Fase 2
- Uniformare i valori di `deperibilita` ("Alta (Fresco)" e "Immediata" si sovrappongono).
- Aggiungere CHECK sui valori di `nlp_intent` anche in `email_donatori` e `note_operatori`.
- Definire chi anonimizza i testi a runtime e come la pipeline AI scrive nel database (evitare doppi scrittori su SQLite).
- Chiarire i canali esterni (Telegram, WhatsApp, SMS, email) nel diagramma C4.
- Decidere il framework frontend definitivo (React).
