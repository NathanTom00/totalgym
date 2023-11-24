--Op1: I clienti maggiorenni che non hanno una macchina registrata Ok(annidato)

CREATE VIEW ClientiConAuto AS
SELECT clienteAssociato FROM Auto;

SELECT * FROM Cliente
WHERE DATEDIFF(CURDATE(),Cliente.data_nascita)/365 >= 18 AND Cliente.cod_fiscale NOT IN (SELECT * FROM ClientiConAuto)


--Op2:dato il codice fiscale di un gestore si vuole ricavare una lista dei nomi dei fornitori che hanno fornito l’attrezzatura per quel gestore Ok (annidato)
SELECT Fornitore.nome
FROM Fornitore
WHERE Fornitore.p_iva IN (SELECT Attrezzatura.p_iva_fornitore FROM Attrezzatura WHERE Attrezzatura.cod_fiscale_gestore = 'ZHLYML80C12Z155E')


Op3:lista dei gestori che ha comprato N attrezzature Ok (aggregato)
SELECT Gestore.codice_fiscale,Gestore.nome, Gestore.cognome, COUNT(*) AS n
FROM Gestore,Attrezzatura
WHERE Attrezzatura.cod_fiscale_gestore = Gestore.codice_fiscale
GROUP BY Gestore.codice_fiscale
HAVING n = 1


--Op4: nome e cognome dei trainer che gestiscono almeno una squadra e che hanno almeno realizzato una scheda di allenamento Ok (tutte e due)
SELECT Trainer.nome,Trainer.cognome
FROM Trainer
WHERE Trainer.cod_fiscale IN (SELECT Squadra.trainer_associato FROM Squadra)
 AND Trainer.cod_fiscale IN (SELECT SchedaAllenamento.cod_fiscale_trainer FROM SchedaAllenamento)


--Op5:Il numero dei clienti minorenni prenotati in un corso in una data iniziale specifica Ok (aggregato)
SELECT COUNT(*)
FROM Cliente
WHERE DATEDIFF(CURDATE(),Cliente.data_nascita)/365 < 18
AND Cliente.cod_fiscale IN
       (SELECT PrenotazioneCorso.cliente_associato
        FROM PrenotazioneCorso
        WHERE PrenotazioneCorso.dataora_inizio = '2021-06-29 16:20:41')


--Op6:Dato il codice fiscale del cliente e il codice di un corso si vuole vedere la sua prenotazione del campo più recente Ok (annidato)
SELECT PrenotazioneCampo.*
FROM PrenotazioneCampo
WHERE ClienteAssociato = 'PNNNLG71P55A960W' AND
                                               CampoAssociato= 'A2321' AND
                                               dataora_inizio IN (Select MIN(dataora_inizio ) FROM PrenotazioneCampo )


--Op7:Lista dei genitori che hanno due figli minorenni iscritti Ok (annidato)
CREATE VIEW genitoriConDueFigli AS
SELECT genitore_associato,COUNT(*) AS n
FROM Cliente
WHERE DATEDIFF(CURDATE(),Cliente.data_nascita)/365 < 18
GROUP BY genitore_associato
HAVING n= 2;

SELECT Genitore.*
FROM Genitore
WHERE Genitore.cod_fiscale IN (SELECT genitore_associato FROM genitoriConDueFigli)


--Op8:tutti i nomi dei gestori con il numero totale degli acquisti effettuati ok (aggregato)
SELECT Gestore.nome,COUNT(Attrezzatura.cod)
FROM Gestore,Attrezzatura
WHERE Attrezzatura.cod_fiscale_gestore = Gestore.codice_fiscale
GROUP BY  Gestore.codice_fiscale


--Op9:nome e cognome dei clienti che hanno il certificato medico scaduto (andando a vedere il certificato medico più recente perché ne abbiamo 2 per cliente) Ok (aggregato)
CREATE VIEW CertificatoMedicoRecente AS
SELECT CertificatoMedico.cliente_associato,MAX(CertificatoMedico.data_scadenza) as minimum
FROM CertificatoMedico
GROUP BY CertificatoMedico.cliente_associato;


SELECT Cliente.nome,Cliente.cognome
FROM Cliente,CertificatoMedicoRecente
WHERE CertificatoMedicoRecente.cliente_associato = Cliente.cod_fiscale AND CertificatoMedicoRecente.minimum < CURDATE()


--Op10:Il numero di squadre che partecipano ad un dato Torneo di squadre ok (aggregato)
SELECT COUNT(*)
FROM Squadra,PartecipazioneTorneoSquadra
WHERE PartecipazioneTorneoSquadra.torneo_squadra_associato = 1
   AND PartecipazioneTorneoSquadra.squadra_associata = Squadra.cod;

--Op11:i nomi dei trainer che non hanno creato una scheda di allenamento ok (annidato)
CREATE VIEW TrainersConSchedaAllenamento AS
SELECT SchedaAllenamento.cod_fiscale_trainer
FROM SchedaAllenamento;


SELECT Trainer.cod_fiscale
FROM Trainer
WHERE Trainer.cod_fiscale NOT IN (SELECT cod_fiscale_trainer FROM TrainersConSchedaAllenamento)



--Op12:nome e cognome dei clienti che hanno più di una scheda di allenamento ok (aggregato)
CREATE VIEW CodFiscalePiuSchede AS
SELECT cod_fiscale_cliente
FROM SchedaAllenamento
GROUP BY SchedaAllenamento.cod_fiscale_cliente
HAVING COUNT(*) > 1;

SELECT nome,cognome
FROM Cliente,CodFiscalePiuSchede
WHERE cod_fiscale = CodFiscalePiuSchede.cod_fiscale_cliente

--Op13: Nome degli esercizi che sono utilizzati da più di una scheda di allenamento ok(annidato)
CREATE VIEW CodEserciziUsatiPiuVolte AS
SELECT SchedaAllenamentoEsercizio.esercizio_associato
FROM SchedaAllenamentoEsercizio
GROUP BY esercizio_associato
HAVING COUNT(*) > 1;

SELECT Esercizio.titolo
FROM Esercizio,CodEserciziUsatiPiuVolte
WHERE Esercizio.cod = CodEserciziUsatiPiuVolte.esercizio_associato

--Op14:nome e cognome dei clienti che hanno prenotato sia per un corso che per un campo ok (annidato)
CREATE VIEW PrenotatiCampo AS
SELECT cliente_associato
FROM PrenotazioneCorso;

CREATE VIEW PrenotatiCorso AS
SELECT clienteAssociato
FROM PrenotazioneCampo;

SELECT Cliente.cod_fiscale
FROM PrenotatiCampo,PrenotatiCorso,Cliente
WHERE Cliente.cod_fiscale = cliente_associato AND cod_fiscale = clienteAssociato

--Op15:Nome dei fornitori con il numero delle proprie attrezzature fornite ok (aggregato)
SELECT Fornitore.p_iva,Fornitore.nome, COUNT(*) AS n
FROM Fornitore,Attrezzatura
WHERE Attrezzatura.p_iva_fornitore = Fornitore.p_iva
GROUP BY Fornitore.p_iva

--Op16: Nome e Cognome dei genitori che hanno un figlio con il certificato medico scaduto e dove il certificato medico è solo uno.
CREATE VIEW ContaCeritificatiMedici AS
SELECT cliente_associato,count(*) AS n
FROM CertificatoMedico
GROUP BY cliente_associato;

CREATE VIEW ClienteConUnCertificatoMedicoScaduto AS
SELECT CertificatoMedico.cliente_associato
FROM CertificatoMedico
WHERE CertificatoMedico.cod IN
(
SELECT CertificatoMedico.cod
FROM CertificatoMedico,ContaCeritificatiMedici
WHERE n=1
) AND CertificatoMedico.data_scadenza < CURDATE();

SELECT Genitore.nome,Genitore.cognome
FROM Cliente,Genitore
WHERE Cliente.genitore_associato = Genitore.cod_fiscale AND Cliente.cod_fiscale IN (SELECT cliente_associato FROM ClienteConUnCertificatoMedicoScaduto )