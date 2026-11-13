# Task Frontend — Buby Solidale

**Responsabile:** sviluppatore frontend  
**Stack:** Angular + Tailwind (Angular CLI).  
**Stima complessiva indicativa:** 10–12 giorni-persona, distribuiti su 4 settimane in parallelo con backend e altri gruppi.

Le issue frontend dipendenti dalle API possono iniziare con mock conformi al [contratto API](../../docs/contratto-dati.md); sostituire i mock con chiamate HTTP quando l'endpoint è disponibile. Il frontend chiama solo il backend. Il selettore dei ruoli è per la demo e non rappresenta autenticazione.

## Settimana 1 — Setup e prototipi navigabili

- [ ] **[FE-01] Generare e configurare l'app Angular/Tailwind** — Stima: 1 giorno.  
  **Dipendenze:** nessuna.  
  **Output:** app Angular CLI, Tailwind configurato e script di avvio/build.  
  **Criteri di accettazione:** dipendenze installabili; server di sviluppo e build production terminano senza errori; pagina iniziale dimostra che Tailwind è attivo.

- [ ] **[FE-02] Implementare layout e selettore demo dei ruoli** — Stima: 1 giorno.  
  **Dipendenze:** [FE-01].  
  **Output:** layout comune e navigazione per Coordinatore, Donatore e Volontario.  
  **Criteri di accettazione:** selezionando un ruolo si apre la relativa vista segnaposto; non vengono richiesti o salvati username, password o credenziali.

- [ ] **[FE-03] Costruire dashboard statica del Coordinatore** — Stima: 1–1,5 giorni.  
  **Dipendenze:** [FE-02].  
  **Output:** una pagina con KPI, tabella giacenze/alert e tabella donazioni in attesa, usando fixture locali.  
  **Criteri di accettazione:** i tre riquadri sono presenti; alert critico ed eccedenza sono distinguibili; dati mock sono identificati come tali.

- [ ] **[FE-04] Costruire form statico di inserimento donazione** — Stima: 1 giorno.  
  **Dipendenze:** [FE-02].  
  **Output:** form con `donatore`, `categoria`, `descrizione_prodotto`, `quantita_kg` e `data_scadenza`.  
  **Criteri di accettazione:** categoria obbligatoria; quantità positiva; formato data verificato; invio mock conferma solo un input valido.

- [ ] **[FE-05] Costruire lista statica dei turni** — Stima: 1 giorno.  
  **Dipendenze:** [FE-02].  
  **Output:** lista con punto, data, fascia oraria, durata, stato e azioni demo.  
  **Criteri di accettazione:** turni scoperti e coperti sono distinguibili; prenotazione/disdetta modificano solo lo stato locale demo e non simulano una risposta API reale.

## Settimana 2 — Collegamento a KPI e donazioni

- [ ] **[FE-06] Collegare dashboard a KPI, punti e donazioni** — Stima: 1–1,5 giorni.  
  **Dipendenze:** [FE-03]; API `GET /api/v1/kpi`, `GET /api/v1/punti-ritiro`, `GET /api/v1/donazioni`.  
  **Output:** servizi Angular per le tre chiamate e dashboard alimentata dai dati ricevuti.  
  **Criteri di accettazione:** i tipi delle risposte corrispondono al contratto; nessun mock è mostrato come dato reale; ogni sezione distingue caricamento, errore, lista vuota e risposta valida. Se un'API non è ancora pronta, il mock mantiene esattamente lo stesso schema.

- [ ] **[FE-07] Collegare il form Donatore a `POST /api/v1/donazioni`** — Stima: 1 giorno.  
  **Dipendenze:** [FE-04]; endpoint `POST /api/v1/donazioni`.  
  **Output:** form collegato al backend con invio e feedback.  
  **Criteri di accettazione:** payload e campi coincidono col contratto; conferma appare solo dopo una risposta di successo; errori di validazione server sono visibili e l'input non viene perso.

## Settimana 3 — Turni, assegnazione e AI

- [ ] **[FE-08] Collegare consultazione, prenotazione e disdetta dei turni** — Stima: 1–1,5 giorni.  
  **Dipendenze:** [FE-05]; API `GET /api/v1/turni`, `POST /api/v1/turni/{id_turno}/prenota`, `POST /api/v1/turni/{id_turno}/disdici`.  
  **Output:** vista Volontario collegata alle API di turni.  
  **Criteri di accettazione:** la lista supporta i filtri previsti dal contratto; si prenotano solo turni scoperti; la disdetta usa l'ID volontario demo; la UI cambia solo dopo successo API e mostra gli errori senza falsare lo stato.

- [ ] **[FE-09] Completare lista donazioni e assegnazione del Coordinatore** — Stima: 1–1,5 giorni.  
  **Dipendenze:** [FE-03]; API `GET /api/v1/donazioni`, `GET /api/v1/punti-ritiro`, `PATCH /api/v1/donazioni/{id_donazione}/assegna`.  
  **Output:** tabella delle donazioni in attesa, selezione del punto e azione di assegnazione.  
  **Criteri di accettazione:** la richiesta invia `id_punto_destinazione`; lista e riga sono aggiornate solo dopo successo; errori, caricamento e assenza di risultati sono gestiti.

- [ ] **[FE-10] Completare la schermata di analisi AI** — Stima: 1 giorno.  
  **Dipendenze:** API `GET /api/v1/comunicazioni` e `POST /api/v1/ai/analizza-testo`.  
  **Output:** lista delle comunicazioni e form per richiedere un'analisi al backend.  
  **Criteri di accettazione:** il form invia `fonte` e `testo_grezzo` esclusivamente al backend; mostra categoria, urgenza, sintesi e dati estratti; il risultato è presentato come suggerimento da verificare da una persona; la UI non registra o persiste localmente il testo grezzo.

## Settimana 4 — Stati UI e collaudo

- [ ] **[FE-11] Uniformare gli stati di caricamento, errore e lista vuota** — Stima: 1 giorno.  
  **Dipendenze:** [FE-06], [FE-07], [FE-08], [FE-09], [FE-10].  
  **Output:** stati coerenti in dashboard, form, turni, assegnazione e pannello AI.  
  **Criteri di accettazione:** ogni chiamata HTTP mostra loading, errore, vuoto o successo; nessun errore viene presentato come successo; azioni non disponibili sono disabilitate o spiegate.

- [ ] **[FE-12] Verificare i flussi frontend su ambiente integrato** — Stima: 0,5–1 giorno.  
  **Dipendenze:** [FE-06]–[FE-11], backend avviabile.  
  **Output:** checklist di verifica per dashboard, invio donazione, assegnazione, prenotazione/disdetta e analisi AI.  
  **Criteri di accettazione:** ogni flusso viene provato con dati sintetici; payload e risposte corrispondono al contratto; bug hanno passaggi riproducibili e sono registrati come issue.

- [ ] **[FE-13] Verificare build e istruzioni di avvio frontend** — Stima: 0,5 giorno.  
  **Dipendenze:** [FE-01]–[FE-12].  
  **Output:** comandi frontend documentati nel README del frontend.  
  **Criteri di accettazione:** una persona diversa dall'autore installa dipendenze, avvia l'app e crea la build seguendo le istruzioni.

## Esclusioni

- Login, autenticazione e autorizzazioni reali.
- Chiamate dirette dal browser al servizio AI.
- Dati personali reali.
