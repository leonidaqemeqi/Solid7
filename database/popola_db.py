import csv
import json
import os
import re
import sqlite3

DB_PATH = os.path.join("database", "buby_solidale.db")
SQL_PATH = os.path.join("database", "buby_solidale.sql")
DATA_DIR = os.path.join("data-ai-engine", "processed_data")

SENTINEL_NULLS = {
    "null", "none", "nan", "n/a",
    "non_assegnato", "non assegnato",
    "da_assegnare", "da assegnare",
    "nessuno", "-",
}

STATO_DONAZIONE_MAP = {
    "in attesa di ritiro": "IN_ATTESA",
    "in_attesa": "IN_ATTESA",
    "ritirata e stoccata": "RITIRATA_STOCCATA",
    "ritirata_stoccata": "RITIRATA_STOCCATA",
    "distribuita": "DISTRIBUITA",
    "scaduta": "SCADUTA",
}


def read_csv(filename):
    path = os.path.join(DATA_DIR, filename)
    with open(path, mode="r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def read_json(filename):
    path = os.path.join(DATA_DIR, filename)
    with open(path, mode="r", encoding="utf-8-sig") as f:
        data = json.load(f)
        if isinstance(data, dict):
            for v in data.values():
                if isinstance(v, list):
                    return v
        return data


def clean_str(val):
    if val is None:
        return None
    s = str(val).strip()
    return s if s and s.lower() not in SENTINEL_NULLS else None


def load_check_constraints(sql_text):
    checks = {}
    for tbl_m in re.finditer(r"CREATE TABLE\s+(\w+)\s*\((.*?)\);", sql_text, re.S | re.I):
        tbl = tbl_m.group(1).lower()
        body = tbl_m.group(2)
        for col_m in re.finditer(r"(\w+)\s+TEXT[^,]*?CHECK\s*\(\s*\1\s+IN\s*\((.*?)\)\s*\)", body, re.S | re.I):
            col = col_m.group(1).lower()
            vals = re.findall(r"'([^']*)'", col_m.group(2))
            if vals:
                checks[(tbl, col)] = vals
    return checks


def normalize_check(checks, tbl, col, val, default=None):
    if val is None:
        return default
    allowed = checks.get((tbl, col))
    if not allowed or val in allowed:
        return val
    norm_val = re.sub(r"[\s\-]+", "_", val.strip().lower())
    for opt in allowed:
        norm_opt = re.sub(r"[\s\-]+", "_", opt.strip().lower())
        if norm_val == norm_opt:
            return opt
    if "ALTRO" in allowed:
        return "ALTRO"
    return default


def calc_ore_durata(fascia):
    if not fascia:
        return 4.0
    m = re.search(r"(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})", fascia)
    if m:
        h1, m1, h2, m2 = map(int, m.groups())
        dur = (h2 + m2 / 60.0) - (h1 + m1 / 60.0)
        if dur > 0:
            return round(dur, 2)
    return 4.0


def main():
    giacenze_rows = read_csv("giacenze_clean.csv")
    donazioni_rows = read_csv("donazioni_clean.csv")
    distribuzioni_rows = read_csv("distribuzioni_clean.csv")
    turni_rows = read_csv("turni_clean.csv")

    email_rows = read_json("email_donatori_clean.json")
    messaggi_rows = read_json("messaggi_volontari_clean.json")
    note_rows = read_json("note_operatori_clean.json")

    with open(SQL_PATH, mode="r", encoding="utf-8") as f:
        sql_text = f.read()

    checks = load_check_constraints(sql_text)

    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.executescript(sql_text)
    conn.execute("PRAGMA foreign_keys = ON;")
    cur = conn.cursor()

    # 1. PUNTI_RITIRO
    punti = {}
    famiglie_per_punto = {}
    for r in distribuzioni_rows:
        pid = clean_str(r.get("id_punto_ritiro"))
        bid = clean_str(r.get("id_beneficiario_anonimo"))
        if pid and bid:
            famiglie_per_punto.setdefault(pid, set()).add(bid)

    for r in giacenze_rows:
        pid = clean_str(r.get("id_punto_ritiro"))
        if pid:
            punti[pid] = {
                "nome": clean_str(r.get("nome_punto_ritiro")) or pid,
                "quartiere": clean_str(r.get("quartiere")) or "Non specificato",
            }

    for r in turni_rows:
        pid = clean_str(r.get("id_punto_ritiro"))
        if pid and pid not in punti:
            punti[pid] = {
                "nome": clean_str(r.get("nome_punto_ritiro")) or pid,
                "quartiere": "Non specificato",
            }

    for pid in (
        [clean_str(r.get("id_punto_ritiro")) for r in donazioni_rows]
        + [clean_str(r.get("id_punto_ritiro")) for r in distribuzioni_rows]
        + [clean_str(r.get("id_punto_ritiro")) for r in note_rows]
    ):
        if pid and pid not in punti:
            punti[pid] = {"nome": pid, "quartiere": "Non specificato"}

    for pid, info in sorted(punti.items()):
        cur.execute(
            """
            INSERT INTO punti_ritiro (id_punto, nome, quartiere, capacita_max_kg, famiglie_assistite)
            VALUES (?, ?, ?, 1000.0, ?)
            """,
            (pid, info["nome"], info["quartiere"], len(famiglie_per_punto.get(pid, set()))),
        )

    # 2. DONATORI
    donatori = {}
    for r in donazioni_rows:
        did = clean_str(r.get("id_donatore"))
        if did and did not in donatori:
            tipo = normalize_check(checks, "donatori", "tipologia_donatore", clean_str(r.get("tipologia_donatore")))
            donatori[did] = (clean_str(r.get("nome_donatore")) or did, tipo)

    for did, (nome, tipo) in sorted(donatori.items()):
        cur.execute(
            "INSERT INTO donatori (id_donatore, nome_donatore, tipologia_donatore) VALUES (?, ?, ?)",
            (did, nome, tipo),
        )

    # 3. VOLONTARI
    volontari = set()
    for r in turni_rows:
        vid = clean_str(r.get("id_volontario"))
        if vid:
            volontari.add(vid)
    for r in messaggi_rows:
        vid = clean_str(r.get("id_volontario"))
        if vid:
            volontari.add(vid)

    for vid in sorted(volontari):
        cur.execute("INSERT INTO volontari (id_volontario) VALUES (?)", (vid,))

    # 4. BENEFICIARI
    beneficiari = {}
    for r in distribuzioni_rows:
        bid = clean_str(r.get("id_beneficiario_anonimo"))
        if bid and bid not in beneficiari:
            fascia = normalize_check(checks, "beneficiari", "fascia_eta", clean_str(r.get("fascia_eta_richiedente")))
            comp_raw = clean_str(r.get("componenti_nucleo_familiare"))
            try:
                comp = int(float(comp_raw)) if comp_raw else None
                if comp is not None and comp <= 0:
                    comp = None
            except ValueError:
                comp = None
            quartiere = clean_str(r.get("quartiere_residenza"))
            beneficiari[bid] = (fascia, comp, quartiere)

    for bid, (fascia, comp, quartiere) in sorted(beneficiari.items()):
        cur.execute(
            """
            INSERT INTO beneficiari (id_beneficiario_anonimo, fascia_eta, componenti_nucleo, quartiere_residenza)
            VALUES (?, ?, ?, ?)
            """,
            (bid, fascia, comp, quartiere),
        )

    # 5. GIACENZE
    for r in giacenze_rows:
        cat = normalize_check(checks, "giacenze", "categoria", clean_str(r.get("categoria_bene")), "Pasta e Cereali")
        stato_scorte = normalize_check(checks, "giacenze", "stato_scorte", clean_str(r.get("stato_scorte")), "OTTIMALE")
        cur.execute(
            """
            INSERT INTO giacenze (
                id_giacenza, id_punto, categoria, quantita_disponibile_kg,
                soglia_minima_kg, kg_in_scadenza_48h, stato_scorte, ultimo_aggiornamento
            ) VALUES (?, ?, ?, ?, ?, ?, ?, COALESCE(?, CURRENT_TIMESTAMP))
            """,
            (
                clean_str(r.get("id_giacenza")),
                clean_str(r.get("id_punto_ritiro")),
                cat,
                float(r.get("quantita_disponibile_kg") or 0),
                float(r.get("soglia_minima_kg") or 50),
                float(r.get("kg_in_scadenza_48h") or 0),
                stato_scorte,
                clean_str(r.get("ultimo_aggiornamento")),
            ),
        )

    # 6. DONAZIONI
    for r in donazioni_rows:
        stato_raw = (clean_str(r.get("stato")) or "IN_ATTESA").lower()
        stato = STATO_DONAZIONE_MAP.get(stato_raw, "IN_ATTESA")
        id_punto = clean_str(r.get("id_punto_ritiro"))
        if stato in ("RITIRATA_STOCCATA", "DISTRIBUITA") and not id_punto:
            stato = "IN_ATTESA"
        cat = normalize_check(checks, "donazioni", "categoria", clean_str(r.get("categoria_bene")), "Pasta e Cereali")
        dep = normalize_check(checks, "donazioni", "deperibilita", clean_str(r.get("deperibilita")), "Lunga Conservazione")
        cur.execute(
            """
            INSERT INTO donazioni (
                id_donazione, id_donatore, id_punto, categoria, deperibilita,
                descrizione_prodotto, quantita_kg, data_ricezione, data_scadenza, stato
            ) VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?, ?)
            """,
            (
                clean_str(r.get("id_donazione")),
                clean_str(r.get("id_donatore")),
                id_punto,
                cat,
                dep,
                float(r.get("quantita_kg")),
                clean_str(r.get("data_ricezione")),
                clean_str(r.get("data_scadenza")),
                stato,
            ),
        )

    # 7. DISTRIBUZIONI
    for r in distribuzioni_rows:
        cat = normalize_check(checks, "distribuzioni", "categoria", clean_str(r.get("categoria_ritirata")), "Pasta e Cereali")
        cur.execute(
            """
            INSERT INTO distribuzioni (
                id_distribuzione, id_punto, id_beneficiario_anonimo, categoria,
                data_distribuzione, kg_distribuiti, pasti_equivalenti
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                clean_str(r.get("id_distribuzione")),
                clean_str(r.get("id_punto_ritiro")),
                clean_str(r.get("id_beneficiario_anonimo")),
                cat,
                clean_str(r.get("data_distribuzione")),
                float(r.get("kg_distribuiti")),
                int(float(r.get("pasti_equivalenti") or 0)),
            ),
        )

    # 8. TURNI
    def turno_priority(row):
        s = (clean_str(row.get("stato_copertura")) or "").lower()
        return 0 if s in ("completato", "coperto") else 1

    seen_turni_slots = set()
    for r in sorted(turni_rows, key=turno_priority):
        id_vol = clean_str(r.get("id_volontario"))
        stato_default = "COPERTO" if id_vol else "SCOPERTO"
        stato = normalize_check(checks, "turni", "stato", clean_str(r.get("stato_copertura")), stato_default)
        data_t = clean_str(r.get("data_turno"))
        fascia = clean_str(r.get("fascia_oraria"))

        if stato in ("SCOPERTO", "ANNULLATO"):
            id_vol = None
        elif not id_vol and stato in ("COPERTO", "COMPLETATO"):
            stato = "SCOPERTO"

        if id_vol:
            slot_key = (id_vol, data_t, fascia)
            if slot_key in seen_turni_slots:
                id_vol = None
                stato = "SCOPERTO"
            else:
                seen_turni_slots.add(slot_key)

        mansione = normalize_check(checks, "turni", "mansione", clean_str(r.get("mansione")))
        cur.execute(
            """
            INSERT INTO turni (
                id_turno, id_punto, id_volontario, data_turno,
                fascia_oraria, ore_durata, mansione, stato
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                clean_str(r.get("id_turno")),
                clean_str(r.get("id_punto_ritiro")),
                id_vol,
                data_t,
                fascia,
                calc_ore_durata(fascia),
                mansione,
                stato,
            ),
        )

    # 9. EMAIL_DONATORI
    seen_emails = set()
    for r in email_rows:
        eid = clean_str(r.get("id_email"))
        if not eid or eid in seen_emails:
            continue
        seen_emails.add(eid)
        nlp_ext = r.get("nlp_extracted")
        intent = None
        urgenza = "NORMALE"
        id_don = clean_str(r.get("id_donatore"))
        if isinstance(nlp_ext, dict):
            intent = clean_str(nlp_ext.get("intent") or nlp_ext.get("nlp_intent"))
            urgenza = normalize_check(checks, "email_donatori", "urgenza", clean_str(nlp_ext.get("urgenza")), "NORMALE")
            if not id_don:
                cand_don = clean_str(nlp_ext.get("id_donatore"))
                if cand_don in donatori:
                    id_don = cand_don
        intent = normalize_check(checks, "email_donatori", "nlp_intent", intent)
        nlp_json = json.dumps(nlp_ext, ensure_ascii=False) if nlp_ext is not None else None
        cur.execute(
            """
            INSERT INTO email_donatori (
                id_email, id_donatore, mittente, oggetto, data_ricezione,
                testo_anonimizzato, nlp_intent, urgenza, nlp_extracted_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                eid,
                id_don if id_don in donatori else None,
                clean_str(r.get("mittente")),
                clean_str(r.get("oggetto")),
                clean_str(r.get("data_invio")),
                clean_str(r.get("corpo_testo")) or "",
                intent,
                urgenza,
                nlp_json,
            ),
        )

    # 10. MESSAGGI_VOLONTARI
    seen_msgs = set()
    for r in messaggi_rows:
        mid = clean_str(r.get("id_msg"))
        if not mid or mid in seen_msgs:
            continue
        seen_msgs.add(mid)
        canale = normalize_check(checks, "messaggi_volontari", "canale", clean_str(r.get("canale")))
        intent = normalize_check(checks, "messaggi_volontari", "nlp_intent", clean_str(r.get("nlp_intent")))
        cur.execute(
            """
            INSERT INTO messaggi_volontari (
                id_messaggio, id_volontario, canale, data_messaggio,
                testo_anonimizzato, nlp_intent
            ) VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                mid,
                clean_str(r.get("id_volontario")),
                canale,
                clean_str(r.get("timestamp")),
                clean_str(r.get("testo")) or "",
                intent,
            ),
        )

    # 11. NOTE_OPERATORI
    seen_note = set()
    for r in note_rows:
        nid = clean_str(r.get("id_nota"))
        if not nid or nid in seen_note:
            continue
        seen_note.add(nid)
        cur.execute(
            """
            INSERT INTO note_operatori (
                id_nota, id_punto, operatore, data_nota, testo_anonimizzato
            ) VALUES (?, ?, ?, ?, ?)
            """,
            (
                nid,
                clean_str(r.get("id_punto_ritiro")),
                clean_str(r.get("operatore")),
                clean_str(r.get("data")),
                clean_str(r.get("testo_nota")) or "",
            ),
        )

    conn.commit()

    tables = [
        "punti_ritiro", "donatori", "volontari", "beneficiari",
        "giacenze", "donazioni", "distribuzioni", "turni",
        "email_donatori", "messaggi_volontari", "note_operatori",
    ]
    print("=== POPOLAMENTO COMPLETATO CON SUCCESSO ===")
    for t in tables:
        count = cur.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        print(f"  {t:<22}: {count} record")

    conn.close()


if __name__ == "__main__":
    main()
