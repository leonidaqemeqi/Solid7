PRAGMA foreign_keys = ON;

-- Reset del database (l'ordine dei DROP è inverso alle dipendenze)
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

-- ==========================================
-- 1. TABELLE ANAGRAFICHE
-- ==========================================
CREATE TABLE punti_ritiro (
    id_punto TEXT PRIMARY KEY,
    nome TEXT NOT NULL,
    zona TEXT NOT NULL,
    capacita_max_kg REAL DEFAULT 1000.0,
    famiglie_assistite INTEGER DEFAULT 0
);

CREATE TABLE donatori (
    id_donatore TEXT PRIMARY KEY,
    nome_donatore TEXT NOT NULL,
    tipologia_donatore TEXT
);

CREATE TABLE volontari (
    id_volontario TEXT PRIMARY KEY,
    data_registrazione TEXT DEFAULT CURRENT_DATE
);

CREATE TABLE beneficiari (
    id_beneficiario_anonimo TEXT PRIMARY KEY,
    quartiere_riferimento TEXT
);

-- ==========================================
-- 2. TABELLE OPERATIVE
-- ==========================================
CREATE TABLE giacenze (
    id_giacenza TEXT PRIMARY KEY,
    id_punto TEXT NOT NULL,
    categoria TEXT CHECK(categoria IN ('ALIMENTARI_FRESCHI', 'ALIMENTARI_SECCHI', 'IGIENE', 'VESTIARIO')),
    quantita_attuale_kg REAL NOT NULL,
    soglia_min_kg REAL DEFAULT 50.0,
    FOREIGN KEY(id_punto) REFERENCES punti_ritiro(id_punto)
);

CREATE TABLE donazioni (
    id_donazione TEXT PRIMARY KEY,
    id_donatore TEXT NOT NULL,
    id_punto_destinazione TEXT,
    categoria TEXT CHECK(categoria IN ('ALIMENTARI_FRESCHI', 'ALIMENTARI_SECCHI', 'IGIENE', 'VESTIARIO')),
    descrizione_prodotto TEXT NOT NULL,
    quantita_kg REAL NOT NULL,
    data_scadenza TEXT,
    stato TEXT CHECK(stato IN ('IN_ATTESA', 'RITIRATA_STOCCATA', 'DISTRIBUITA', 'SCADUTA')),
    FOREIGN KEY(id_donatore) REFERENCES donatori(id_donatore),
    FOREIGN KEY(id_punto_destinazione) REFERENCES punti_ritiro(id_punto)
);

CREATE TABLE distribuzioni (
    id_distribuzione TEXT PRIMARY KEY,
    id_punto TEXT NOT NULL,
    id_beneficiario_anonimo TEXT NOT NULL,
    data_distribuzione TEXT NOT NULL,
    kg_consegnati REAL NOT NULL,
    FOREIGN KEY(id_punto) REFERENCES punti_ritiro(id_punto),
    FOREIGN KEY(id_beneficiario_anonimo) REFERENCES beneficiari(id_beneficiario_anonimo)
);

CREATE TABLE turni (
    id_turno TEXT PRIMARY KEY,
    id_punto TEXT NOT NULL,
    id_volontario TEXT,
    data_turno TEXT NOT NULL,
    fascia_oraria TEXT NOT NULL,
    ore_durata REAL DEFAULT 2.0,
    stato TEXT CHECK(stato IN ('SCOPERTO', 'COPERTO', 'COMPLETATO')),
    FOREIGN KEY(id_punto) REFERENCES punti_ritiro(id_punto),
    FOREIGN KEY(id_volontario) REFERENCES volontari(id_volontario),
    UNIQUE(id_volontario, data_turno, fascia_oraria)
);

-- ==========================================
-- 3. TABELLE COMUNICAZIONI E AI (NLP)
-- ==========================================
CREATE TABLE email_donatori (
    id_email TEXT PRIMARY KEY,
    id_donatore TEXT,
    data_ricezione TEXT NOT NULL,
    testo_anonimizzato TEXT NOT NULL,
    nlp_intent TEXT,
    urgenza TEXT CHECK(urgenza IN ('BASSA', 'MEDIA', 'ALTA', 'NORMALE')),
    nlp_extracted_json TEXT,
    FOREIGN KEY(id_donatore) REFERENCES donatori(id_donatore)
);

CREATE TABLE messaggi_volontari (
    id_messaggio TEXT PRIMARY KEY,
    id_volontario TEXT NOT NULL,
    data_messaggio TEXT NOT NULL,
    testo_anonimizzato TEXT NOT NULL,
    nlp_intent TEXT,
    FOREIGN KEY(id_volontario) REFERENCES volontari(id_volontario)
);

CREATE TABLE note_operatori (
    id_nota TEXT PRIMARY KEY,
    id_punto TEXT NOT NULL,
    data_nota TEXT NOT NULL,
    testo_anonimizzato TEXT NOT NULL,
    nlp_intent TEXT,
    nlp_extracted_json TEXT,
    FOREIGN KEY(id_punto) REFERENCES punti_ritiro(id_punto)
);