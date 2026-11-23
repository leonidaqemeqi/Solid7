# Dizionario dati - Buby Solidale (file puliti)

Le descrizioni sono una proposta di Michele e Christian da validare con i WSA, insieme allo schema delle API.

## donazioni_clean.csv
Una riga per ogni donazione ricevuta.

| Colonna | Tipo | Nullable | Valori ammessi | Descrizione |
|---|---|---|---|---|
| id_donazione | testo | no |  | Chiave primaria della donazione |
| id_donatore | testo | no | DON_01, DON_02, DON_03, DON_04, DON_05, DON_06, DON_07 | Identificativo dell'organizzazione donatrice |
| nome_donatore | testo | no | Caseificio Piemontese Srl, Coop Piemonte - Sede Nord, Farmacia Centrale Solidale, Mensa Aziendale Politecnico, Mercato Ortofrutticolo CAAT, Panificio Artigianale Mole, Supermercato Esselunga Corso Traiano | Denominazione dell'organizzazione donatrice |
| tipologia_donatore | testo | no | Farmacia, Forno, GDO, Ingrosso Ortofrutta, Produttore, Ristorazione | Tipo di donatore |
| id_punto_ritiro | testo | no | PR_01, PR_02, PR_03, PR_04, PR_05 | Punto di ritiro. Chiave esterna verso giacenze_clean.csv |
| categoria_bene | testo | no | Beni Prima Necessità (Igiene), Frutta e Verdura, Latticini e Formaggi, Pasta e Cereali, Prodotti Infanzia, Prodotti da Forno, Scatolame e Legumi | Categoria merceologica del bene donato |
| deperibilita | testo | no | Alta (Fresco), Immediata, Lunga Conservazione, Media Conservazione, Non Deperibile | Livello di deperibilità del bene |
| quantita_kg | decimale | no |  | Peso della donazione in kg |
| data_ricezione | testo | no |  | Data di ricezione (YYYY-MM-DD) |
| data_scadenza | testo | no |  | Data di scadenza del bene (YYYY-MM-DD) |
| stato | testo | no | In Attesa di Ritiro, Ritirata e Stoccata | Stato della donazione. Solo 'Ritirata e Stoccata' conta come kg recuperati |

## giacenze_clean.csv
Una riga per ogni coppia punto di ritiro e categoria di bene: stato delle scorte.

| Colonna | Tipo | Nullable | Valori ammessi | Descrizione |
|---|---|---|---|---|
| id_giacenza | testo | no |  | Chiave primaria |
| id_punto_ritiro | testo | no | PR_01, PR_02, PR_03, PR_04, PR_05 | Punto di ritiro |
| nome_punto_ritiro | testo | no | Centro Solidale Porta Palazzo, Emporio Barriera, Hub San Paolo, Punto Amico Mirafiori, Rete San Salvario | Nome del punto di ritiro |
| quartiere | testo | no | Aurora / Centro, Barriera di Milano, Borgo San Paolo, Mirafiori Sud, San Salvario | Quartiere del punto di ritiro |
| categoria_bene | testo | no | Beni Prima Necessità (Igiene), Frutta e Verdura, Latticini e Formaggi, Pasta e Cereali, Prodotti Infanzia, Prodotti da Forno, Scatolame e Legumi | Categoria merceologica |
| quantita_disponibile_kg | decimale | no |  | Scorta disponibile in kg |
| soglia_minima_kg | decimale | no |  | Soglia minima di scorta in kg |
| kg_in_scadenza_48h | decimale | no |  | Kg che scadono entro 48 ore |
| stato_scorte | testo | no | CARENZA, OTTIMALE, RISCHIO_SPRECO | CARENZA se scorta < soglia minima; RISCHIO_SPRECO se quota in scadenza 48h >= 20%; altrimenti OTTIMALE |
| ultimo_aggiornamento | testo | no | 2026-11-12T00:00:00 | Data e ora dell'ultimo aggiornamento (YYYY-MM-DDTHH:MM:SS) |

## distribuzioni_clean.csv
Una riga per ogni distribuzione a un beneficiario. Nessun nome reale.

| Colonna | Tipo | Nullable | Valori ammessi | Descrizione |
|---|---|---|---|---|
| id_distribuzione | testo | no |  | Chiave primaria |
| id_beneficiario_anonimo | testo | no |  | ID pseudonimo del beneficiario (BEN_ + 10 caratteri). Non ricostruibile dal nome |
| fascia_eta_richiedente | testo | no | 18-30, 31-45, 46-64, 65+ | Fascia d'età del richiedente |
| componenti_nucleo_familiare | intero | no |  | Numero di componenti del nucleo familiare |
| quartiere_residenza | testo | no | Aurora / Centro, Barriera di Milano, Borgo San Paolo, Mirafiori Sud, San Salvario | Quartiere di residenza |
| id_punto_ritiro | testo | no | PR_01, PR_02, PR_03, PR_04, PR_05 | Punto di ritiro. Chiave esterna verso giacenze_clean.csv |
| categoria_ritirata | testo | no | Beni Prima Necessità (Igiene), Frutta e Verdura, Latticini e Formaggi, Pasta e Cereali, Prodotti Infanzia, Prodotti da Forno, Scatolame e Legumi | Categoria di bene ritirata |
| kg_distribuiti | decimale | no |  | Peso distribuito in kg |
| pasti_equivalenti | intero | no |  | Pasti equivalenti stimati dal peso (circa 2 per kg nei dati) |
| data_distribuzione | testo | no |  | Data della distribuzione (YYYY-MM-DD) |

## turni_clean.csv
Una riga per ogni turno di volontariato.

| Colonna | Tipo | Nullable | Valori ammessi | Descrizione |
|---|---|---|---|---|
| id_turno | testo | no |  | Chiave primaria |
| id_punto_ritiro | testo | no | PR_01, PR_02, PR_03, PR_04, PR_05 | Punto di ritiro. Chiave esterna verso giacenze_clean.csv |
| nome_punto_ritiro | testo | no | Centro Solidale Porta Palazzo, Emporio Barriera, Hub San Paolo, Punto Amico Mirafiori, Rete San Salvario | Nome del punto di ritiro |
| data_turno | testo | no |  | Data del turno (YYYY-MM-DD) |
| fascia_oraria | testo | no | 08:30 - 12:30, 14:00 - 18:00, 17:30 - 20:30 | Fascia oraria del turno |
| mansione | testo | no | Accoglienza Beneficiari, Distribuzione al Banco, Logistica e Ritiro Furgone, Smistamento Alimenti | Mansione richiesta |
| id_volontario | testo | no |  | Volontario assegnato. 'NON_ASSEGNATO' nei turni Scoperti |
| stato_copertura | testo | no | Annullato, Completato, Coperto, Scoperto | Completato, Coperto, Scoperto (futuro) o Annullato (passato non coperto) |

## note_operatori_clean.json
Note degli operatori sociali con nomi, telefoni e codici fiscali sostituiti da segnaposto ([NOME_OSCURATO], [TEL_OSCURATO], [CF_OSCURATO], [EMAIL_OSCURATA]).

## email_donatori_clean.json
Email dei donatori. Campo aggiunto nlp_extracted con: kg_rilevati (somma dei kg citati), kg_dettaglio (i singoli valori), urgenza (ALTA o NORMALE), motivi_urgenza (regole scattate). Estrazione basata su regole, non su un modello.

## messaggi_volontari_clean.json
Messaggi dei volontari. Campo aggiunto nlp_intent: DISPONIBILITA_TURNO, DISDETTA_TURNO, SEGNALAZIONE_RITARDO oppure ALTRO. Classificazione basata su regole.
