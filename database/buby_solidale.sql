PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS note_operatori;
DROP TABLE IF EXISTS messaggi_volontari;
DROP TABLE IF EXISTS email_donatori;
DROP TABLE IF EXISTS turni;
DROP TABLE IF EXISTS distribuzioni;
DROP TABLE IF EXISTS donazioni;
DROP TABLE IF EXISTS giacenze;
DROP TABLE IF EXISTS beneficiari;
DROP TABLE IF EXISTS volontari;
DROP TABLE IF EXISTS donatori;
DROP TABLE IF EXISTS punti_ritiro;

-- ------------------------------------------------------------
-- 1. ANAGRAFICHE (MVP)
-- ------------------------------------------------------------
CREATE TABLE punti_ritiro (
    id_punto            TEXT PRIMARY KEY,
    nome                TEXT NOT NULL,
    quartiere           TEXT NOT NULL,
    capacita_max_kg     REAL NOT NULL DEFAULT 1000.0 CHECK (capacita_max_kg > 0),
    famiglie_assistite  INTEGER NOT NULL DEFAULT 0 CHECK (famiglie_assistite >= 0)
);

CREATE TABLE donatori (
    id_donatore         TEXT PRIMARY KEY,
    nome_donatore       TEXT NOT NULL,
    tipologia_donatore  TEXT
);

CREATE TABLE volontari (
    id_volontario       TEXT PRIMARY KEY,
    codice_accesso      TEXT NOT NULL DEFAULT 'DA_ASSEGNARE',
    data_registrazione  TEXT NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE beneficiari (
    id_beneficiario_anonimo TEXT PRIMARY KEY,
    fascia_eta              TEXT CHECK (fascia_eta IN ('18-30', '31-45', '46-64', '65+')),
    componenti_nucleo       INTEGER CHECK (componenti_nucleo > 0),
    quartiere_residenza     TEXT
);

-- ------------------------------------------------------------
-- 2. OPERATIVE (MVP)
-- ------------------------------------------------------------
CREATE TABLE giacenze (
    id_giacenza              TEXT PRIMARY KEY,
    id_punto                 TEXT NOT NULL,
    categoria                TEXT NOT NULL CHECK (categoria IN (
                                 'Pasta e Cereali',
                                 'Frutta e Verdura',
                                 'Latticini e Formaggi',
                                 'Prodotti da Forno',
                                 'Scatolame e Legumi',
                                 'Prodotti Infanzia',
                                 'Beni Prima Necessità (Igiene)'
                             )),
    quantita_disponibile_kg  REAL NOT NULL DEFAULT 0 CHECK (quantita_disponibile_kg >= 0),
    soglia_minima_kg         REAL NOT NULL DEFAULT 50.0 CHECK (soglia_minima_kg >= 0),
    kg_in_scadenza_48h       REAL NOT NULL DEFAULT 0 CHECK (kg_in_scadenza_48h >= 0),
    stato_scorte             TEXT NOT NULL DEFAULT 'OTTIMALE' CHECK (stato_scorte IN (
                                 'CARENZA', 'OTTIMALE', 'RISCHIO_SPRECO'
                             )),
    ultimo_aggiornamento     TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_punto) REFERENCES punti_ritiro(id_punto),
    UNIQUE (id_punto, categoria)
);

CREATE TABLE donazioni (
    id_donazione          TEXT PRIMARY KEY,
    id_donatore           TEXT NOT NULL,
    id_punto              TEXT,
    categoria             TEXT NOT NULL CHECK (categoria IN (
                              'Pasta e Cereali',
                              'Frutta e Verdura',
                              'Latticini e Formaggi',
                              'Prodotti da Forno',
                              'Scatolame e Legumi',
                              'Prodotti Infanzia',
                              'Beni Prima Necessità (Igiene)'
                          )),
    deperibilita          TEXT NOT NULL CHECK (deperibilita IN (
                              'Alta (Fresco)',
                              'Immediata',
                              'Lunga Conservazione',
                              'Media Conservazione',
                              'Non Deperibile'
                          )),
    descrizione_prodotto  TEXT,
    quantita_kg           REAL NOT NULL CHECK (quantita_kg > 0),
    data_ricezione        TEXT NOT NULL DEFAULT CURRENT_DATE,
    data_scadenza         TEXT,
    stato                 TEXT NOT NULL DEFAULT 'IN_ATTESA' CHECK (stato IN (
                              'IN_ATTESA', 'RITIRATA_STOCCATA', 'DISTRIBUITA', 'SCADUTA'
                          )),
    FOREIGN KEY (id_donatore) REFERENCES donatori(id_donatore),
    FOREIGN KEY (id_punto) REFERENCES punti_ritiro(id_punto),
    CHECK (stato NOT IN ('RITIRATA_STOCCATA', 'DISTRIBUITA')
           OR id_punto IS NOT NULL)
);

CREATE TABLE distribuzioni (
    id_distribuzione         TEXT PRIMARY KEY,
    id_punto                 TEXT NOT NULL,
    id_beneficiario_anonimo  TEXT NOT NULL,
    categoria                TEXT NOT NULL CHECK (categoria IN (
                                 'Pasta e Cereali',
                                 'Frutta e Verdura',
                                 'Latticini e Formaggi',
                                 'Prodotti da Forno',
                                 'Scatolame e Legumi',
                                 'Prodotti Infanzia',
                                 'Beni Prima Necessità (Igiene)'
                             )),
    data_distribuzione       TEXT NOT NULL,
    kg_distribuiti           REAL NOT NULL CHECK (kg_distribuiti > 0),
    pasti_equivalenti        INTEGER NOT NULL CHECK (pasti_equivalenti >= 0),
    FOREIGN KEY (id_punto) REFERENCES punti_ritiro(id_punto),
    FOREIGN KEY (id_beneficiario_anonimo) REFERENCES beneficiari(id_beneficiario_anonimo)
);

CREATE TABLE turni (
    id_turno       TEXT PRIMARY KEY,
    id_punto       TEXT NOT NULL,
    id_volontario  TEXT,
    data_turno     TEXT NOT NULL,
    fascia_oraria  TEXT NOT NULL,
    ore_durata     REAL NOT NULL CHECK (ore_durata > 0),
    mansione       TEXT NOT NULL,
    stato          TEXT NOT NULL DEFAULT 'SCOPERTO' CHECK (stato IN (
                       'SCOPERTO', 'COPERTO', 'COMPLETATO', 'ANNULLATO'
                   )),
    FOREIGN KEY (id_punto) REFERENCES punti_ritiro(id_punto),
    FOREIGN KEY (id_volontario) REFERENCES volontari(id_volontario),
    UNIQUE (id_volontario, data_turno, fascia_oraria),
    CHECK ((stato IN ('SCOPERTO', 'ANNULLATO') AND id_volontario IS NULL)
        OR (stato IN ('COPERTO', 'COMPLETATO') AND id_volontario IS NOT NULL))
);

-- ------------------------------------------------------------
-- 3. COMUNICAZIONI E AI/NLP (Fase 2)
-- ------------------------------------------------------------
CREATE TABLE email_donatori (
    id_email            TEXT PRIMARY KEY,
    id_donatore         TEXT,
    mittente            TEXT,
    oggetto             TEXT,
    data_ricezione      TEXT NOT NULL,
    testo_anonimizzato  TEXT NOT NULL,
    nlp_intent          TEXT,
    urgenza             TEXT NOT NULL DEFAULT 'NORMALE' CHECK (urgenza IN (
                            'BASSA', 'NORMALE', 'MEDIA', 'ALTA'
                        )),
    nlp_extracted_json  TEXT,
    stato_validazione   TEXT NOT NULL DEFAULT 'DA_VALIDARE' CHECK (stato_validazione IN (
                            'DA_VALIDARE', 'APPROVATA', 'RIFIUTATA'
                        )),
    data_validazione    TEXT,
    FOREIGN KEY (id_donatore) REFERENCES donatori(id_donatore)
);

CREATE TABLE messaggi_volontari (
    id_messaggio        TEXT PRIMARY KEY,
    id_volontario       TEXT NOT NULL,
    canale              TEXT,
    data_messaggio      TEXT NOT NULL,
    testo_anonimizzato  TEXT NOT NULL,
    nlp_intent          TEXT CHECK (nlp_intent IS NULL OR nlp_intent IN (
                            'DISPONIBILITA_TURNO',
                            'DISDETTA_TURNO',
                            'SEGNALAZIONE_RITARDO',
                            'ALTRO'
                        )),
    stato_validazione   TEXT NOT NULL DEFAULT 'DA_VALIDARE' CHECK (stato_validazione IN (
                            'DA_VALIDARE', 'APPROVATA', 'RIFIUTATA'
                        )),
    data_validazione    TEXT,
    FOREIGN KEY (id_volontario) REFERENCES volontari(id_volontario)
);

CREATE TABLE note_operatori (
    id_nota             TEXT PRIMARY KEY,
    id_punto            TEXT NOT NULL,
    operatore           TEXT,
    data_nota           TEXT NOT NULL,
    testo_anonimizzato  TEXT NOT NULL,
    nlp_intent          TEXT,
    nlp_extracted_json  TEXT,
    stato_validazione   TEXT NOT NULL DEFAULT 'DA_VALIDARE' CHECK (stato_validazione IN (
                            'DA_VALIDARE', 'APPROVATA', 'RIFIUTATA'
                        )),
    data_validazione    TEXT,
    FOREIGN KEY (id_punto) REFERENCES punti_ritiro(id_punto)
);

-- ------------------------------------------------------------
-- 4. INDICI
-- ------------------------------------------------------------
CREATE INDEX idx_donazioni_data           ON donazioni(data_ricezione);
CREATE INDEX idx_donazioni_stato_scad     ON donazioni(stato, data_scadenza);
CREATE INDEX idx_distribuzioni_punto      ON distribuzioni(id_punto, data_distribuzione);
CREATE INDEX idx_distribuzioni_benef      ON distribuzioni(id_beneficiario_anonimo);
CREATE INDEX idx_turni_data_stato         ON turni(data_turno, stato);