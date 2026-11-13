# Piano operativo e issue — Buby Solidale

**Durata:** 4 settimane (20 giorni lavorativi)  
**Team:** 3 Web Solution Architect (team leader/database, backend, frontend) e 4 Data Analyst (2 dati strutturati, 2 AI/NLP).  
**Frontend:** Angular + Tailwind, generato con Angular CLI.  
**Obiettivo:** demo locale integrata per coordinatore, donatore e volontario, con dati sintetici.

Questo piano è pensato per essere convertito in issue. Ogni riga corrisponde a una issue con un solo risultato principale; le attività che richiedono più risultati sono separate. Stime indicative: 0,5–1,5 giorni per issue. Se una issue richiede più tempo, va spezzata prima di assegnarla. I giorni sono finestre di calendario, non stime cumulative: attività diverse procedono in parallelo.

## Legenda dei codici, delle etichette e degli assegnatari

Il prefisso nel titolo dell'issue identifica **l'area responsabile**, non l'ordine di esecuzione:

| Prefisso | Area | Etichetta GitHub | Assegnatario |
|---|---|---|---|
| `TL` | Coordinamento / team leader | `area:coordinamento` | `leonidaqemeqi` |
| `API`, `BE` | Contratto API e backend | `area:backend` (anche `area:api` per `API`) | `mouadronix` |
| `DB` | Database e import SQLite | `area:database` | `leonidaqemeqi` |
| `FE` | Frontend Angular | `area:frontend` | `federicodincecco-star` |
| `DA-S` | Data Analyst — dati strutturati | `area:dati-strutturati` | Da assegnare dopo aver ricevuto gli username |
| `DA-A` | Data Analyst — AI/NLP e testi | `area:ai-nlp` | Da assegnare dopo aver ricevuto gli username |
| `INT` | Integrazione e collaudo | `area:integrazione` | Assegnare ai referenti nominati nella singola issue |
| `DOC` | Documentazione e repository | `area:documentazione` | In base al lavoro indicato nell'issue |
| `DEMO` | Preparazione e prova demo | `area:demo` | Assegnare al gruppo indicato nell'issue |

Le issue ricevono inoltre l'etichetta `settimana:1`, `settimana:2`, `settimana:3` o `settimana:4`. Per capire l'ordine, seguire settimana/giorno, dipendenze esplicite e collegamenti alle issue: i numeri nel codice sono identificativi per area e **non** una sequenza globale. GitHub mostra i responsabili tramite il campo Assignees; i nomi degli analisti strutturati e AI/NLP vanno aggiunti appena il team conferma i rispettivi username.

## Regole e perimetro

- Board: `Todo` → `In Progress` → `In Review` → `Done`; una persona lavora su non più di 1–2 issue per volta.
- Ogni issue ha un responsabile nominativo, le dipendenze indicate qui sotto e una PR verificabile.
- Il selettore dei tre ruoli serve solo alla demo. Non implementare login, credenziali o autorizzazioni reali.
- Tutti i dati di test sono sintetici. Nessuna comunicazione reale o dato personale reale.
- Il frontend chiama solo il backend. Il browser non chiama direttamente il servizio AI.
- Le API in `docs/contratto-dati.md`, inclusi gli endpoint 6–10, sono approvate per la demo. Il backend le implementa; frontend e team leader/database verificano rispettivamente i payload e la compatibilità con schema/stati. Ogni modifica va concordata e riportata nel contratto prima dell'implementazione.
- “Completata” significa che il deliverable indicato esiste nel repository, il test/controllo richiesto passa e la PR è pronta per revisione.

---

## Settimana 1 — Specifiche, scheletro e dati di prova

### Giorno 1

- [ ] **[TL-01] Confermare perimetro e responsabili** — Team leader, 0,5 g.  
  **Output:** tabella nel board con responsabile per ruolo, data demo, scope incluso/escluso e decisioni aperte assegnate.  
  **Accettazione:** i 7 membri confermano ruolo e disponibilità; login reale e deployment risultano fuori scope.
- [ ] **[API-01] Pubblicare il contratto API approvato e allineare i consumer** — Backend (responsabile), frontend e team leader/database (revisori), 0,5 g.  
  **Dipendenze:** perimetro [TL-01].  
  **Output:** `docs/contratto-dati.md` è il riferimento condiviso per tutti i dieci endpoint.  
  **Accettazione:** il backend conferma di implementare i payload e i comportamenti documentati; frontend e team leader/database verificano campi UI e compatibilità con schema/stati; eventuali correzioni sono applicate al contratto senza riaprire decisioni già approvate.
- [ ] **[BE-01] Avviare il server backend e aggiungere health check** — Backend, 1 g.  
  **Output:** applicazione avviabile localmente e `GET /health`.  
  **Accettazione:** health check restituisce `200` e JSON stabile; comando di avvio è documentato; test automatico passa.

### Giorni 1–2

- [ ] **[FE-01] Generare e configurare l'app Angular/Tailwind** — Frontend, 1 g.  
  **Output:** app Angular CLI con Tailwind e script standard di avvio/build.  
  **Accettazione:** installazione dipendenze, server di sviluppo e build production riescono; una pagina iniziale mostra che Tailwind è attivo.
- [ ] **[DB-01] Creare schema SQLite delle cinque tabelle** — Team leader/database, 1 g.  
  **Dipendenze:** schema in `docs/contratto-dati.md`.  
  **Output:** `schema.sql` (o migrazione equivalente).  
  **Accettazione:** crea le cinque tabelle con PK, FK, `NOT NULL` e `CHECK` previsti; test su database vuoto e `PRAGMA foreign_key_check` passano.
- [ ] **[DA-S01] Specificare colonne e regole di generazione dei dati strutturati** — Coppia dati strutturati, 1 g.  
  **Output:** specifica CSV per punti, giacenze, donazioni e turni.  
  **Accettazione:** ogni colonna ha tipo, unità e valori ammessi; intervallo temporale e distribuzioni sintetiche sono definiti; specifica coerente col contratto e senza dati reali.
- [ ] **[DA-A01] Definire schema delle etichette e casi di test AI** — Coppia AI/NLP, 1 g.  
  **Output:** schema dei campi del corpus e fixture d'esempio con risultati attesi.  
  **Accettazione:** copre le tre fonti ammesse, categorie/urgenze, campi estraibili, casi ambigui e PII fittizi; le etichette sono concordate prima di generare il corpus completo.

### Giorni 2–3

- [ ] **[FE-02] Implementare navigazione e selettore demo dei ruoli** — Frontend, 1 g.  
  **Dipendenze:** [FE-01].  
  **Output:** layout comune e navigazione per Coordinatore, Donatore, Volontario.  
  **Accettazione:** selezionando un ruolo si apre la relativa vista segnaposto; non vengono chiesti né salvati account o password.
- [ ] **[DA-S02] Generare i CSV grezzi strutturati** — Coppia dati strutturati, 1 g.  
  **Dipendenze:** [DA-S01].  
  **Output:** script riproducibile e CSV grezzi per i quattro insiemi strutturati.  
  **Accettazione:** esecuzione con seed produce le stesse righe; identificativi e riferimenti sono validi; istruzioni di esecuzione incluse.
- [ ] **[DA-A02] Generare corpus AI sintetico** — Coppia AI/NLP, 1 g.  
  **Dipendenze:** [DA-A01].  
  **Output:** corpus versionato o generatore più fixture.  
  **Accettazione:** contiene 50–80 testi con fonte e risultati attesi; i casi PII fittizi sono annotati per i test.
- [ ] **[DB-02] Creare inizializzazione DB e fixture minime** — Team leader/database, 1 g.  
  **Dipendenze:** [DB-01].  
  **Output:** comando/script che crea DB vuoto e carica fixture sintetiche minime.  
  **Accettazione:** fixture includono almeno un punto con giacenze critiche, una donazione in attesa, un turno scoperto e uno coperto; rieseguire da DB vuoto è riproducibile.

### Giorni 3–5

- [ ] **[FE-03] Costruire dashboard statica del Coordinatore** — Frontend, 1–1,5 g.  
  **Dipendenze:** [FE-02].  
  **Output:** una pagina con riquadri KPI, tabella giacenze/alert e tabella donazioni in attesa alimentati da fixture locali.  
  **Accettazione:** i tre riquadri sono visibili a desktop; badge critico ed eccedenza sono distinguibili; dati mock sono identificati come tali.
- [ ] **[FE-04] Costruire form statico di inserimento donazione** — Frontend, 1 g.  
  **Dipendenze:** [FE-02].  
  **Output:** form con i cinque campi previsti da `POST /api/v1/donazioni`.  
  **Accettazione:** categoria, descrizione, quantità e data sono validati; invio mock mostra conferma solo con input valido.
- [ ] **[FE-05] Costruire lista statica dei turni** — Frontend, 1 g.  
  **Dipendenze:** [FE-02].  
  **Output:** lista turni con punto, data, fascia, durata, stato e azioni demo.  
  **Accettazione:** turni scoperti e prenotati hanno stati distinguibili; prenota/disdici mostrano il cambiamento solo in stato demo.
- [ ] **[DA-A03] Implementare anonimizzazione deterministica** — Coppia AI/NLP, 1–1,5 g.  
  **Dipendenze:** [DA-A02].  
  **Output:** funzione di anonimizzazione e test automatici.  
  **Accettazione:** i casi sintetici del corpus mascherano almeno email, telefoni e nomi esplicitamente marcati; test dimostrano che i valori di test non compaiono nell'output.

---

## Settimana 2 — Pipeline verificabili e prime API

### Giorni 6–7

- [ ] **[DA-S03] Definire conversioni in kg e formule KPI** — Coppia dati strutturati, 1 g.  
  **Output:** tabella conversioni e formule con esempi numerici per ogni KPI e alert.  
  **Accettazione:** esplicita assunzioni (incluso `1 litro = 1 kg` se mantenuto), arrotondamenti e casi limite; team leader e backend approvano.
- [ ] **[DA-S04] Implementare pulizia/normalizzazione dei CSV** — Coppia dati strutturati, 1–1,5 g.  
  **Dipendenze:** [DA-S02], [DA-S03].  
  **Output:** script che legge i CSV grezzi e scrive i CSV puliti per le quattro tabelle.  
  **Accettazione:** colonne conformi al contratto; unità convertite; righe invalide sono riportate in un file/rapporto d'errore con motivo, non scartate silenziosamente.
- [ ] **[DB-03] Implementare caricamento atomico dei CSV nel DB** — Team leader/database, 1–1,5 g.  
  **Dipendenze:** [DB-01], CSV puliti [DA-S04].  
  **Output:** script di import dei CSV puliti in SQLite.  
  **Accettazione:** una violazione annulla il caricamento senza lasciare import parziali; errori indicano file/riga; test controlla PK/FK.
- [ ] **[DA-A04] Implementare estrazione regole/campi dal testo anonimizzato** — Coppia AI/NLP, 1–1,5 g.  
  **Dipendenze:** [DA-A03], schema AI concordato in [API-01].  
  **Output:** funzione che restituisce categoria, urgenza, sintesi e `dati_estratti`.  
  **Accettazione:** output JSON conforme allo schema; campo sconosciuto è `null`/assente secondo contratto; test su almeno 10 fixture.

### Giorni 6–10 — una issue backend per endpoint

- [ ] **[BE-02] Implementare `GET /api/v1/kpi`** — Backend, 1 g.  
  **Dipendenze:** [DB-01], [DA-S03].  
  **Output:** endpoint e test per KPI e alert del contratto.  
  **Accettazione:** fixture deterministiche producono valori attesi; test coprono DB vuoto e presenza di alert critico/eccedenza.
- [ ] **[BE-03] Implementare `GET /api/v1/punti-ritiro`** — Backend, 0,5–1 g.  
  **Dipendenze:** [DB-01], [API-01].  
  **Output:** endpoint che restituisce punti con giacenze aggregate per categoria.  
  **Accettazione:** campi e filtri coincidono con contratto; test coprono punto senza giacenze e lista vuota.
- [ ] **[BE-04] Implementare `GET /api/v1/turni`** — Backend, 0,5–1 g.  
  **Dipendenze:** [DB-01], [API-01].  
  **Output:** endpoint di elenco turni con filtri concordati.  
  **Accettazione:** filtri `data_da`, `data_a`, `stato`, `id_punto` funzionano; test coprono parametri invalidi e nessun risultato.
- [ ] **[BE-05] Implementare `GET /api/v1/donazioni`** — Backend, 0,5–1 g.  
  **Dipendenze:** [DB-01], [API-01].  
  **Output:** endpoint lista donazioni filtrabile per `stato` e `id_punto_destinazione`.  
  **Accettazione:** include donazioni in attesa quando richiesto; test verificano filtri, lista vuota e campi restituiti.
- [ ] **[BE-06] Implementare `POST /api/v1/donazioni`** — Backend, 1 g.  
  **Dipendenze:** [DB-01].  
  **Output:** endpoint di creazione donazione.  
  **Accettazione:** valida categoria, quantità positiva, campi obbligatori e formato data; crea record `IN_ATTESA` senza punto destinazione; test per successo e input invalido.
- [ ] **[BE-07] Implementare `PATCH /api/v1/donazioni/{id_donazione}/assegna`** — Backend, 1 g.  
  **Dipendenze:** [DB-01].  
  **Output:** endpoint di assegnazione donazione a punto.  
  **Accettazione:** valida donazione in attesa e punto esistente; aggiorna punto e stato in un'unica transazione; test per successo, ID inesistente e stato non assegnabile.

### Giorni 8–10 — collegamento frontend e test dati

- [ ] **[FE-06] Collegare dashboard ai tre endpoint di lettura** — Frontend, 1–1,5 g.  
  **Dipendenze:** [BE-02], [BE-03], [BE-05]; usare mock compatibili se endpoint non sono ancora integrati.  
  **Output:** servizi Angular per KPI, punti e donazioni, collegati alla dashboard.  
  **Accettazione:** nessun dato mock è presentato come reale; ogni riquadro distingue caricamento, errore, lista vuota e risposta valida.
- [ ] **[FE-07] Collegare form donazione al backend** — Frontend, 1 g.  
  **Dipendenze:** [BE-06].  
  **Output:** form collegato a `POST /api/v1/donazioni`.  
  **Accettazione:** payload rispetta contratto; conferma appare solo dopo successo API; errori di validazione server sono mostrati senza perdere input.
- [ ] **[DA-S05] Validare i CSV puliti prima dell'import** — Coppia dati strutturati, 1 g.  
  **Dipendenze:** [DA-S04], [DB-01].  
  **Output:** comando di validazione CSV e report.  
  **Accettazione:** controlla colonne, valori ammessi, riferimenti e unità; exit code non-zero se esistono errori.

---

## Settimana 3 — Turni, AI, assegnazioni e integrazione

### Giorni 11–12 — endpoint turni e AI

- [ ] **[BE-08] Implementare `POST /api/v1/turni/{id_turno}/prenota`** — Backend, 1 g.  
  **Dipendenze:** [DB-01], [API-01].  
  **Output:** endpoint di prenotazione con `volontario_id`.  
  **Accettazione:** prenota solo un turno scoperto e assegna volontario/stato in transazione; test coprono ID inesistente, turno già coperto e successo.
- [ ] **[BE-09] Implementare `POST /api/v1/turni/{id_turno}/disdici`** — Backend, 1 g.  
  **Dipendenze:** [BE-08], [API-01].  
  **Output:** endpoint di disdetta con `volontario_id`.  
  **Accettazione:** disdice solo se l'ID coincide con quello associato alla prenotazione; libera turno secondo contratto; test coprono successo, ID non corrispondente e turno non prenotato.
- [ ] **[BE-10] Implementare `GET /api/v1/comunicazioni`** — Backend, 1 g.  
  **Dipendenze:** [DB-01], [API-01].  
  **Output:** endpoint lista comunicazioni persistite con filtri `fonte` e `urgenza`.  
  **Accettazione:** restituisce solo testo anonimizzato e campi approvati; test verificano filtri e assenza di testo grezzo.
- [ ] **[DA-A05] Esporre analisi AI come servizio interno** — Coppia AI/NLP, 1–1,5 g.  
  **Dipendenze:** [DA-A03], [DA-A04], contratto privacy [API-01].  
  **Output:** endpoint AI interno invocabile dal backend.  
  **Accettazione:** anonimizza prima dell'eventuale modello esterno; non salva/logga testo grezzo; test con PII sintetica verificano che output e log di test non la contengano.
- [ ] **[BE-11] Implementare `POST /api/v1/ai/analizza-testo` e persistenza** — Backend, 1–1,5 g.  
  **Dipendenze:** [DA-A05], [DB-01], [API-01].  
  **Output:** endpoint proxy che chiama il servizio AI e salva comunicazione anonimizzata in SQLite.  
  **Accettazione:** request valida produce risposta con `id_comunicazione`; input invalido/servizio indisponibile restituisce errore documentato; testo grezzo non è persistito né loggato.

### Giorni 11–14 — flussi utente e analisi dati

- [ ] **[FE-08] Collegare lista turni, prenotazione e disdetta** — Frontend, 1–1,5 g.  
  **Dipendenze:** [BE-04], [BE-08], [BE-09].  
  **Output:** vista Volontario collegata alle API.  
  **Accettazione:** lista aggiornata dopo successo; prenota solo turni scoperti; disdetta invia l'ID demo concordato; errori server sono visibili e non falsano lo stato.
- [ ] **[FE-09] Completare lista donazioni e assegnazione Coordinatore** — Frontend, 1–1,5 g.  
  **Dipendenze:** [BE-03], [BE-05], [BE-07].  
  **Output:** tabella donazioni in attesa, selezione punto e azione assegna.  
  **Accettazione:** invia `id_punto_destinazione`; aggiorna riga solo dopo successo; errori e stato vuoto sono gestiti.
- [ ] **[FE-10] Completare schermata di analisi AI** — Frontend, 1 g.  
  **Dipendenze:** [BE-10], [BE-11].  
  **Output:** lista comunicazioni e form di analisi per il Coordinatore.  
  **Accettazione:** invia fonte/testo al backend; mostra sintesi, categoria, urgenza e dati estratti; il risultato è chiaramente un suggerimento da verificare da una persona.
- [ ] **[DA-S06] Produrre data dictionary e riepilogo di qualità** — Coppia dati strutturati, 1 g.  
  **Dipendenze:** [DA-S04], [DA-S05].  
  **Output:** `docs/data-dictionary.md` e report conteggi/anomalie.  
  **Accettazione:** documenta tutti i campi, unità e trasformazioni; conteggi e anomalie corrispondono ai CSV consegnati.
- [ ] **[DA-S07] Produrre riepilogo analitico e grafici riproducibili** — Coppia dati strutturati, 1–1,5 g.  
  **Dipendenze:** [DA-S05], formule [DA-S03].  
  **Output:** notebook/script con grafici di giacenze, donazioni e turni.  
  **Accettazione:** esecuzione da dataset puliti produce grafici etichettati con unità e periodo; KPI coincidono con esempi di test.
- [ ] **[DA-A06] Misurare qualità dell'estrazione sul corpus** — Coppia AI/NLP, 1 g.  
  **Dipendenze:** [DA-A04].  
  **Output:** report con precisione/completezza per etichette e campi estratti.  
  **Accettazione:** metriche calcolate su tutto il corpus con errori rappresentativi annotati; non si dichiara accuratezza senza denominatore e metodo.

### Giorno 15 — integrazione

- [ ] **[DB-04] Verificare inizializzazione DB e import da ambiente pulito** — Team leader/database, 0,5–1 g.  
  **Dipendenze:** [DB-02], [DB-03], [DA-S04].  
  **Output:** sequenza verificata per creare SQLite, caricare fixture e importare CSV puliti.  
  **Accettazione:** esecuzione su database inesistente termina senza errori; controlli FK passano; conteggi importati corrispondono ai CSV.
- [ ] **[DA-A07] Documentare privacy, limiti AI e revisione umana** — Coppia AI/NLP, 1 g.  
  **Dipendenze:** [DA-A03], [DA-A06].  
  **Output:** sezione documentale su anonimizzazione e uso responsabile.  
  **Accettazione:** descrive cosa viene mascherato, limiti misurati e casi da verificare da Coordinatore; chiarisce che l'AI non assegna donazioni automaticamente.

---

## Settimana 4 — Collaudo e consegna

### Giorni 16–17

- [ ] **[INT-01] Collaudare il flusso donazione** — Frontend + backend, 0,5–1 g.  
  **Scenario:** invio form → comparsa in attesa → assegnazione del Coordinatore.  
  **Accettazione:** esito annotato con fixture pulite; payload, stati DB e UI concordano; bug registrati come issue riproducibili.
- [ ] **[INT-02] Collaudare il flusso turni** — Frontend + backend, 0,5–1 g.  
  **Scenario:** consultazione → prenotazione → disdetta.  
  **Accettazione:** stato turno e volontario in DB corrispondono alla UI dopo ciascuna azione; casi non validi mostrano errore.
- [ ] **[INT-03] Collaudare dashboard KPI e alert** — Frontend + backend + dati strutturati, 0,5–1 g.  
  **Accettazione:** valori UI coincidono con calcolo indipendente sulle fixture; almeno un alert critico e uno di eccedenza sono verificati.
- [ ] **[INT-04] Collaudare il flusso AI e l'assenza di PII** — Backend + AI, 0,5–1 g.  
  **Accettazione:** input sintetico attraversa proxy e servizio AI; risposta e record DB contengono solo testo anonimizzato; esito dei test privacy registrato.
- [ ] **[FE-11] Correggere gli stati UI di caricamento, vuoto ed errore** — Frontend, 1 g.  
  **Dipendenze:** [FE-06]–[FE-10].  
  **Output:** stati coerenti per tutte le viste collegate.  
  **Accettazione:** ogni chiamata API ha comportamento visibile per loading, lista vuota, errore e successo; nessun errore viene presentato come successo.

### Giorni 18–20

- [ ] **[DOC-01] Aggiornare README con installazione e avvio locale** — Team leader con backend e frontend, 1 g.  
  **Accettazione:** prerequisiti, comandi e ordine di avvio sono completi; persona non autrice segue il README con esito positivo.
- [ ] **[DOC-02] Verificare assenza di segreti e dati reali nel repository** — Team leader con tutti i gruppi, 0,5 g.  
  **Accettazione:** `.env` e artefatti locali ignorati; repository controllato per chiavi e dati personali; eccezioni risolte prima della demo.
- [ ] **[DEMO-AI-01] Provare la demo AI e preparare esempi sintetici** — Coppia AI/NLP, 0,5–1 g.  
  **Accettazione:** esempi coprono un'offerta, una disponibilità e una nota; risultati attesi e limiti sono noti al presentatore.
- [ ] **[DEMO-01] Provare la demo completa due volte** — Tutto il team, 1 g.  
  **Accettazione:** flusso completo eseguibile con dati sintetici; durata registrata; errori bloccanti risolti o procedura alternativa documentata.
- [ ] **[TL-03] Preparare la consegna e classificare il lavoro residuo** — Team leader, 0,5 g.  
  **Accettazione:** PR necessarie sono revisionate; issue aperte sono classificate bloccanti/non bloccanti; istruzioni, report e demo sono nel repository.
