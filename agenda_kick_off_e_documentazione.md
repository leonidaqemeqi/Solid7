# 🚀 Agenda Kick-off: Progetto Buby Solidale

**Obiettivo dell'incontro:** Strutturare l'applicativo, definire i requisiti visivi e stipulare il "Contratto Dati" (Data Contract) tra il team Web Solution Architect (WSA) e il team Data & AI.

---

## ✅ Checklist Pre-Incontro (Per il Team Leader)
*Azioni da completare prima di avviare la call su Meet:*
- [ ] Creare cartella Google Drive/OneDrive condivisa (Sottocartelle consigliate: `01_Dati_Grezzi`, `02_Documentazione_API`, `03_Design_UI`).
- [ ] Preparare una lavagna virtuale (Miro, Figma/FigJam, Excalidraw) per disegnare le bozze dell'interfaccia.
- [ ] Inizializzare la bacheca operativa (Trello o Notion) con le colonne: *To Do, In Progress, Review, Done*.
- [ ] Creare repository GitHub vuoto (es. `buby-solidale-app`) e richiedere gli username dei membri per l'accesso.

---

## 📊 1. Definizione dei KPI (Numeri da mostrare)
**Attività:** Brainstorming per decidere quali metriche mostrare nella Dashboard (senza ancora preoccuparsi di come calcolarle).

*Spunti da discutere in base alle richieste aziendali:*
*   **Impatto Sociale:** Quanti pasti distribuiti in totale? Quanti Kg di cibo recuperati questo mese?
    *   *🎯 Sfida per il team Data:* Oltre alla somma matematica, è possibile creare un modello predittivo (Time Series) per stimare i Kg che recupereremo il mese prossimo?
*   **Allarmi Spreco:** Come mostriamo le eccedenze in scadenza nei vari punti di ritiro?
    *   *🎯 Sfida per il team AI:* Usare modelli NLP/LLM per leggere le email caotiche dei donatori ed estrarre in automatico: `[Cibo]`, `[Data di Scadenza]` e `[Sede]`, restituendo un livello di rischio.
*   **Gestione Turni:** Come evidenziamo quanti volontari mancano per i prossimi giorni?

**Risultato atteso:** Lista definitiva di 4-5 KPI che l'interfaccia dovrà ospitare.

---

## 🎨 2. Wireframing e Design App (In diretta)
**Attività:** Disegnare sulla lavagna virtuale condivisa le "scatole" del sito web, concentrandosi sui 3 flussi utente principali.

1.  **Dashboard (Admin/Coordinatore):** Disposizione dei grafici e dei box di allarme decisi al Punto 1.
2.  **Gestione Turni (Volontari):** Interfaccia mobile-first per la prenotazione dei turni.
3.  **Inserimento Eccedenze (Donatori):** Form strutturato per sostituire le email disordinate.

---

## 🤝 3. Il "Contratto Dati" (Data Contract)
**Attività:** Stabilire come i due team (Web e Data) comunicheranno tecnicamente.

*   **Regola d'oro per i WSA:** Il Frontend si aspetta di ricevere i dati in un formato specifico (es. JSON via API REST) e con chiavi precise. 
*   **Accordo sulle API AI:** Quando il modello NLP analizza un'email, deve restituire un payload strutturato (es. `{"mittente": "...", "quantita": "...", "alimento": "..."}`).
*   *Nota per lo sviluppo:* Qualsiasi modifica alla struttura di questi file/JSON andrà comunicata e concordata preventivamente tra i due team.

---

## 🚀 4. Divisione Compiti - Sprint Settimana 1
Assegnazione delle task per i prossimi 7 giorni per garantire un lavoro parallelo senza blocchi.

### 💻 Team Web Solution Architect (WSA - 3 membri)
- [ ] Inizializzare il progetto frontend/backend sul repository GitHub.
- [ ] Scelta dello stack tecnologico definitivo.
- [ ] Sviluppo delle viste (UI) inserendo dati *hardcoded* (finti) per testare l'impostazione della pagina e dei grafici.

### 📈 Team Data Analyst & AI (4 membri)
- [ ] **Generazione Mock Data (Priorità Alta):** Fornire ai WSA entro 48h un file JSON finto ma strutturato secondo il Contratto Dati, per sbloccare lo sviluppo web.
- [ ] Iniziare la pulizia massiva dei file Excel (giacenze, turni).
- [ ] Test di fattibilità per l'estrazione NLP sulle email dei donatori.