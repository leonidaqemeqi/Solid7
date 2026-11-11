-- =====================================================================
-- Buby Solidale - Database SQLite (versione semplice, v0.1)
-- Un solo file: schema + dati finti + viste per i KPI.
--
-- Come creare il database (dalla cartella del progetto):
--   sqlite3 buby.db < buby_solidale.sql
-- oppure da Python:
--   import sqlite3
--   con = sqlite3.connect("buby.db")
--   con.executescript(open("buby_solidale.sql", encoding="utf-8").read())
--
-- Il file buby.db NON va committato (e' nel .gitignore): ognuno lo
-- genera in locale da questo script.
-- =====================================================================

-- ATTENZIONE: in SQLite le chiavi esterne sono SPENTE di default.
-- Questa riga vale solo per la connessione corrente: va rimessa
-- ad ogni connessione (anche nel codice Python del backend).
PRAGMA foreign_keys = ON;

-- Ripartenza pulita: ricreare il db da zero e' normale in questa fase
DROP VIEW  IF EXISTS v_kpi_mensili;
DROP VIEW  IF EXISTS v_giacenza;
DROP TABLE IF EXISTS distribuzione;
DROP TABLE IF EXISTS donazione;
DROP TABLE IF EXISTS donatore;
DROP TABLE IF EXISTS punto_ritiro;

-- ---------------------------------------------------------------------
-- 1) PUNTO DI RITIRO: dove si consegna e da dove si distribuisce
-- ---------------------------------------------------------------------
CREATE TABLE punto_ritiro (
    id     INTEGER PRIMARY KEY,           -- in SQLite diventa auto-incrementale da solo
    nome   TEXT NOT NULL UNIQUE,
    citta  TEXT
) STRICT;

-- ---------------------------------------------------------------------
-- 2) DONATORE: volutamente senza dati personali (privacy, vedi piano)
--    Solo il nome dell'azienda/ente e il tipo.
-- ---------------------------------------------------------------------
CREATE TABLE donatore (
    id    INTEGER PRIMARY KEY,
    nome  TEXT NOT NULL,
    tipo  TEXT NOT NULL DEFAULT 'azienda'
          CHECK (tipo IN ('azienda', 'privato', 'ente'))
) STRICT;

-- ---------------------------------------------------------------------
-- 3) DONAZIONE: e' il cuore. Corrisponde ai campi del form (opzione B):
--    tipo di cibo, kg, scadenza, punto di ritiro.
--    'stato' serve per la conferma del coordinatore (proposta C):
--      - form compilato a mano  -> nasce 'confermata'
--      - estratta dall'AI/email -> nasce 'da_confermare'
-- ---------------------------------------------------------------------
CREATE TABLE donazione (
    id               INTEGER PRIMARY KEY,
    donatore_id      INTEGER REFERENCES donatore(id),   -- puo' essere NULL (donazione anonima)
    punto_ritiro_id  INTEGER NOT NULL REFERENCES punto_ritiro(id),
    tipologia_cibo   TEXT NOT NULL,
    quantita_kg      REAL NOT NULL CHECK (quantita_kg > 0),
    data_scadenza    TEXT,                               -- formato AAAA-MM-GG (Contratto Dati)
    stato            TEXT NOT NULL DEFAULT 'confermata'
                     CHECK (stato IN ('da_confermare', 'confermata', 'rifiutata')),
    origine          TEXT NOT NULL DEFAULT 'form'
                     CHECK (origine IN ('form', 'ai_email')),
    confidenza       REAL CHECK (confidenza BETWEEN 0 AND 1),  -- solo per origine = 'ai_email'
    inserita_il      TEXT NOT NULL DEFAULT (date('now'))       -- equivalente di GETDATE()
) STRICT;

-- ---------------------------------------------------------------------
-- 4) DISTRIBUZIONE: cosa esce da un punto di ritiro.
--    Nel prototipo (proposta B) e' popolata con dati dimostrativi.
-- ---------------------------------------------------------------------
CREATE TABLE distribuzione (
    id               INTEGER PRIMARY KEY,
    punto_ritiro_id  INTEGER NOT NULL REFERENCES punto_ritiro(id),
    data             TEXT NOT NULL,                      -- AAAA-MM-GG
    quantita_kg      REAL NOT NULL CHECK (quantita_kg > 0)
) STRICT;

-- ---------------------------------------------------------------------
-- VISTE (sono "query salvate": non contengono dati propri)
-- La giacenza NON e' una tabella: si calcola, cosi' non puo' mai
-- andare fuori sincrono con donazioni e distribuzioni.
--   giacenza = kg donazioni confermate - kg distribuiti
-- ---------------------------------------------------------------------
CREATE VIEW v_giacenza AS
SELECT
    p.id   AS punto_ritiro_id,
    p.nome AS punto_ritiro,
    COALESCE((SELECT SUM(d.quantita_kg) FROM donazione d
              WHERE d.punto_ritiro_id = p.id AND d.stato = 'confermata'), 0)
  - COALESCE((SELECT SUM(x.quantita_kg) FROM distribuzione x
              WHERE x.punto_ritiro_id = p.id), 0)
    AS giacenza_kg
FROM punto_ritiro p;

-- KPI per mese. ASSUNZIONE NOSTRA (da confermare col cliente):
--   1 pasto = 0,5 kg  ->  pasti = kg * 2
-- Qui "kg recuperati" = kg donati confermati (ipotesi di partenza del piano).
CREATE VIEW v_kpi_mensili AS
SELECT
    strftime('%Y-%m', inserita_il) AS mese,
    ROUND(SUM(quantita_kg), 1)     AS kg_recuperati,
    CAST(SUM(quantita_kg) * 2 AS INTEGER) AS pasti_stimati
FROM donazione
WHERE stato = 'confermata'
GROUP BY mese;

-- ---------------------------------------------------------------------
-- DATI FINTI (inventati, nessun dato personale)
-- ---------------------------------------------------------------------
INSERT INTO punto_ritiro (nome, citta) VALUES
    ('Punto Nord',   'Cuneo'),
    ('Punto Centro', 'Alba'),
    ('Punto Sud',    'Mondovi');

INSERT INTO donatore (nome, tipo) VALUES
    ('Supermercato Alfa', 'azienda'),
    ('Panificio Beta',    'azienda'),
    ('Ortofrutta Gamma',  'azienda');

INSERT INTO donazione
    (donatore_id, punto_ritiro_id, tipologia_cibo, quantita_kg, data_scadenza, stato, origine, confidenza, inserita_il)
VALUES
    (1, 1, 'Pasta secca',    120.0, '2027-03-01', 'confermata',    'form',     NULL, '2026-10-05'),
    (2, 1, 'Pane fresco',     15.5, '2026-11-12', 'confermata',    'form',     NULL, '2026-10-20'),
    (3, 2, 'Frutta mista',    80.0, '2026-11-15', 'confermata',    'form',     NULL, '2026-10-28'),
    (1, 3, 'Latte UHT',       60.0, '2027-01-10', 'confermata',    'form',     NULL, '2026-11-02'),
    (2, 2, 'Pane fresco',     12.0, '2026-11-13', 'da_confermare', 'ai_email', 0.87, '2026-11-09');

INSERT INTO distribuzione (punto_ritiro_id, data, quantita_kg) VALUES
    (1, '2026-10-25', 90.0),
    (2, '2026-11-03', 40.0),
    (3, '2026-11-08', 25.0);

-- ---------------------------------------------------------------------
-- PROVA RAPIDA (decommenta per controllare):
--   SELECT * FROM v_giacenza;
--   SELECT * FROM v_kpi_mensili;
--   SELECT * FROM donazione WHERE stato = 'da_confermare';
-- ---------------------------------------------------------------------
