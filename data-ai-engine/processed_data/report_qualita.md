# Report qualità dati - Buby Solidale

Data di riferimento del dataset: 2026-11-12

## KPI

| Indicatore | Valore |
|---|---|
| kg_recuperati | 26105.3 |
| kg_in_attesa_di_ritiro | 243.1 |
| kg_distribuiti | 2467.3 |
| pasti_equivalenti | 4929 |
| beneficiari_unici | 251 |
| turni_totali | 120 |
| turni_scoperti_futuri | 11 |
| turni_annullati_passati | 9 |
| turni_scoperti_pct | 9.2 |

## Dati personali oscurati nei JSON

| Tipo | Occorrenze |
|---|---|
| codici_fiscali | 1 |
| email | 0 |
| nomi | 3 |
| telefoni | 1 |

## Anomalie

| Gravità | Tabella | Controllo | Casi | Dettaglio | Azione |
|---|---|---|---|---|---|
| ALTA | distribuzioni | id_beneficiario_anonimo ricostruibile con SHA-256 del nome | 300 | Chi ha una lista di nomi può ricavare gli ID con un semplice tentativo | Corretto: ID rigenerati con HMAC e sale segreto |
| MEDIA | turni | stesso volontario in due turni nella stessa data e fascia | 7 | 14 turni coinvolti, anche in punti di ritiro diversi | Corretto: mantenuto il primo turno per ID, liberato il secondo (NON_ASSEGNATO / Scoperto) |
| MEDIA | distribuzioni | stesso beneficiario con fascia d'età, nucleo o quartiere diversi tra richieste | 46 | 46 beneficiari su 46 con più richieste: gli attributi sembrano generati per riga e non per persona | Corretto: attributi uniformati per singolo beneficiario (prima richiesta cronologica) |
| BASSA | turni | turni Scoperti con data precedente alla data di riferimento | 6 | Un turno passato dovrebbe essere Completato o annullato | Corretto: stato_copertura impostato a Annullato |
| BASSA | giacenze | stato OTTIMALE con quota in scadenza pari o superiore alla più bassa classificata RISCHIO_SPRECO | 1 | soglia implicita circa 21%; manca una regola unica per stato_scorte | Corretto: ricalcolato stato_scorte con soglia unica >= 20% in scadenza 48h |
| BASSA | distribuzioni | combinazioni quartiere + fascia d'età + nucleo con una sola riga | 26 | Rischio teorico su dati sintetici (k-anonymity) | Documentato: nessuna alterazione necessaria su dati sintetici |
| INFO | donazioni | donazioni non ancora ritirate | 2 | 243.1 kg | Corretto: esclusi dal KPI dei kg recuperati |

## Parametri della pulizia

- Turni scoperti: NON_ASSEGNATO
- ID beneficiari: HMAC-SHA256 con sale segreto, 10 caratteri esadecimali
- Sale da variabile BUBY_SALT: no, sale casuale per questa esecuzione