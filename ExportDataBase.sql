create table Campo
(
	cod char(5) not null
		primary key,
	nome char(30) null,
	tipo char(30) null,
	costo_ora decimal(3,2) null,
	max_persone int(3) null
);

create table Corso
(
	max_persone smallint null,
	nome char(20) not null
		primary key,
	sala char(50) null
);

create table Esercizio
(
	cod int(5) auto_increment
		primary key,
	titolo char(30) not null,
	descrizione char(255) null,
	categoria char(20) not null,
	image_url text null
);

create table Fornitore
(
	p_iva int not null
		primary key,
	nome char(20) null
);

create table Genitore
(
	cod_fiscale char(16) not null
		primary key,
	nome char(50) null,
	cognome char(50) null,
	sesso char null,
	data_nascita date null,
	luogo_nascita char(50) null comment 'provincia o nazione di nascita',
	image_url text null
);

create table Cliente
(
	cod_fiscale char(16) not null
		primary key,
	nome char(50) null,
	cognome char(50) null,
	sesso char null,
	data_nascita date null,
	luogo_nascita char(50) null comment 'provincia o nazione di nascita',
	cod_patente char(10) null,
	image_url text null,
	genitore_associato char(16) null,
	constraint Cliente_Genitore_cod_fiscale_fk
		foreign key (genitore_associato) references Genitore (cod_fiscale)
);

create table Auto
(
	targa char(7) not null
		primary key,
	modello char(25) null,
	marca char(25) null,
	clienteAssociato char(16) not null,
	constraint Auto_Cliente_cod_fiscale_fk
		foreign key (clienteAssociato) references Cliente (cod_fiscale)
);

create table CertificatoMedico
(
	cod int(7) auto_increment
		primary key,
	tipo char not null comment 'A:agonistico
N:normale
',
	data_scadenza date not null,
	medico char(50) null,
	cliente_associato char(16) not null,
	constraint CertificatoMedico_ibfk_1
		foreign key (cliente_associato) references Cliente (cod_fiscale)
);

create index cliente_associato
	on CertificatoMedico (cliente_associato);

create definer = LUPOSaymon@`%` trigger CertMedicoLessEqual2
	before insert
	on CertificatoMedico
	for each row
	BEGIN
        IF (select count(cliente_associato)
            from CertificatoMedico
            WHERE cliente_associato = new.cliente_associato
            group by cliente_associato) = 2 THEN
            SIGNAL  SQLSTATE '45000' SET  MESSAGE_TEXT = 'ERROR: Client already has 2 Medical Certificates';
        END IF;
    END;

create definer = LUPOSaymon@`%` trigger DriverLicenseCheck
	before insert
	on Cliente
	for each row
	BEGIN
        IF DATEDIFF(CURDATE(),new.data_nascita)/365 < 18 AND new.cod_patente IS NOT NULL
            THEN
            SIGNAL  SQLSTATE '45000' SET  MESSAGE_TEXT = 'ERROR: driver license under of age';
        END IF;
    END;

create table ClienteCorso
(
	cliente_associato char(16) not null,
	corso_associato char(20) not null,
	primary key (corso_associato, cliente_associato),
	constraint ClienteCorso_ibfk_1
		foreign key (corso_associato) references Corso (nome),
	constraint ClienteCorso_ibfk_2
		foreign key (cliente_associato) references Cliente (cod_fiscale)
);

create index cod_fiscale_Cliente
	on ClienteCorso (cliente_associato);

create definer = LUPOSaymon@`%` trigger IfCourseIsFullCheck
	before insert
	on ClienteCorso
	for each row
	BEGIN
        IF (select count(*)
            from TrainerCorso
            WHERE corso_associato = new.corso_associato
            ) > (select max_persone
                from Corso
                WHERE nome = new.corso_associato) THEN
            SIGNAL  SQLSTATE '45000' SET  MESSAGE_TEXT = 'ERROR: Max_persone reached for the course';
        END IF;
    END;

create table Fattura
(
	cod int not null
		primary key,
	data datetime null,
	importo decimal(15,2) null,
	cliente_associato char(16) not null,
	constraint Fattura_Cliente_cod_fiscale_fk
		foreign key (cliente_associato) references Cliente (cod_fiscale)
);

create table Gestore
(
	codice_fiscale char(16) not null
		primary key,
	nome char(20) not null,
	cognome char(20) not null,
	sesso char not null,
	data_nascita date not null,
	luogo_nascita char(50) not null,
	data_lavoro date not null comment 'data di inizio lavoro',
	image_url text null
);

create table Attrezzatura
(
	cod int auto_increment
		primary key,
	nome char(50) null,
	descrizione char(200) null,
	p_iva_fornitore int not null,
	cod_fiscale_gestore char(16) not null,
	constraint Attrezzatura_Fornitore_p_iva_fk
		foreign key (p_iva_fornitore) references Fornitore (p_iva),
	constraint Attrezzatura_Gestore_codice_fiscale_fk
		foreign key (cod_fiscale_gestore) references Gestore (codice_fiscale)
);

create table PrenotazioneCampo
(
	cod int(5) auto_increment
		primary key,
	dataora_inizio date null,
	dataora_fine date null,
	campoAssociato char(5) not null,
	clienteAssociato char(16) not null,
	constraint PrenotazioneCampo_Cliente_cod_fiscale_fk
		foreign key (clienteAssociato) references Cliente (cod_fiscale),
	constraint PrenotazioneCampo_ibfk_1
		foreign key (campoAssociato) references Campo (cod)
);

create index campoAssociato
	on PrenotazioneCampo (campoAssociato);

create table PrenotazioneCorso
(
	cod int(10) auto_increment
		primary key,
	dataora_inizio datetime not null,
	dataora_fine datetime not null,
	cliente_associato char(16) not null,
	corso_associato char(20) not null,
	constraint PrenotazioneCorso_Cliente_cod_fiscale_fk
		foreign key (cliente_associato) references Cliente (cod_fiscale),
	constraint PrenotazioneCorso_Corso_nome_fk
		foreign key (corso_associato) references Corso (nome)
);

create definer = LUPOSaymon@`%` trigger Max2TimesPerDay
	before insert
	on PrenotazioneCorso
	for each row
	BEGIN
        IF new.dataora_inizio > new.dataora_fine
            THEN
            SIGNAL  SQLSTATE '45000' SET  MESSAGE_TEXT = 'ERROR: dataora_inizio > dataora_fine';
        END IF;
    END;

create table Segretario
(
	codice_fiscale char(16) not null
		primary key,
	nome char(20) not null,
	cognome char(20) not null,
	sesso char not null,
	data_nascita date not null,
	luogo_nascita char(50) not null,
	data_lavoro date not null comment 'data di inizio lavoro',
	image_url text null
);

create table Tessera
(
	cliente_associato char(16) null,
	segretario_associato char(16) null,
	cod char(5) not null
		primary key,
	data_rilascio char(5) null,
	constraint Tessera_Cliente_cod_fiscale_fk
		foreign key (cliente_associato) references Cliente (cod_fiscale),
	constraint Tessera_Segretario_codice_fiscale_fk
		foreign key (segretario_associato) references Segretario (codice_fiscale)
);

create table TipoAbbonamento
(
	nome char(30) not null
		primary key,
	descrizione char(255) not null,
	data_creazione date not null
);

create table Abbonamento
(
	cod int(7) auto_increment
		primary key,
	scadenza date null,
	segretario_creatore char(16) not null,
	tipo_abbonamento char(30) not null,
	cliente_associato char(16) not null,
	constraint Abbonamento_Cliente_cod_fiscale_fk
		foreign key (cliente_associato) references Cliente (cod_fiscale),
	constraint Abbonamento_Segretario_codice_fiscale_fk
		foreign key (segretario_creatore) references Segretario (codice_fiscale),
	constraint Abbonamento_TipoAbbonamento_nome_fk
		foreign key (tipo_abbonamento) references TipoAbbonamento (nome)
);

create table TorneoSingolo
(
	cod int(7) auto_increment
		primary key,
	nome char(50) not null,
	descrizione char(255) null,
	sport char(50) not null comment 'sport riferito al torneo',
	gestore_creatore char(16) not null,
	constraint TorneoSingolo_Gestore_codice_fiscale_fk
		foreign key (gestore_creatore) references Gestore (codice_fiscale)
);

create table TorneoSquadre
(
	cod int(7) auto_increment
		primary key,
	nome char(50) not null,
	descrizione char(255) null,
	sport char(50) not null comment 'sport riferito al torneo
',
	gestore_creatore char(16) not null,
	constraint TorneoSquadre_Gestore_codice_fiscale_fk
		foreign key (gestore_creatore) references Gestore (codice_fiscale)
);

create table Trainer
(
	cod_fiscale char(16) not null
		primary key,
	nome char(20) null,
	cognome char(20) null,
	sesso char null,
	specializzazione char(30) null,
	data_lavoro date null
);

create table SchedaAllenamento
(
	cod int(5) auto_increment
		primary key,
	titolo char(20) null,
	descrizione char(200) null,
	durata date null,
	cod_fiscale_cliente char(16) not null,
	cod_fiscale_trainer char(16) not null,
	constraint SchedaAllenamento_ibfk_1
		foreign key (cod_fiscale_cliente) references Cliente (cod_fiscale),
	constraint SchedaAllenamento_ibfk_2
		foreign key (cod_fiscale_trainer) references Trainer (cod_fiscale)
);

create table Contenere_ScEs
(
	cod_scheda_allenamento int(5) not null,
	cod_esercizio int(5) not null,
	constraint Contenere_ScEs_Esercizio_cod_fk
		foreign key (cod_esercizio) references Esercizio (cod),
	constraint Contenere_ScEs_SchedaAllenamento_cod_fk
		foreign key (cod_scheda_allenamento) references SchedaAllenamento (cod)
);

create index cod_fiscale_Cliente
	on SchedaAllenamento (cod_fiscale_cliente);

create definer = LUPOSaymon@`%` trigger CreatedBySalaPesiTrainer
	before insert
	on SchedaAllenamento
	for each row
	BEGIN
        IF (select count(*)
            from TrainerCorso
            WHERE TrainerCorso.cod_fiscale_Trainer = new.cod_fiscale_trainer  AND TrainerCorso.corso = 'sala pesi'
            ) < 1 THEN
            SIGNAL  SQLSTATE '45000' SET  MESSAGE_TEXT = 'ERROR: trainer is not doing course sala pesi';
        END IF;
    END;

create definer = LUPOSaymon@`%` trigger DurationUnder1WeekCheck
	before insert
	on SchedaAllenamento
	for each row
	BEGIN
        IF DATEDIFF(new.durata,CURDATE()) < 7
            THEN
            SIGNAL  SQLSTATE '45000' SET  MESSAGE_TEXT = 'ERROR: durata under 1 week';
        END IF;
    END;

create table SchedaAllenamentoEsercizio
(
	sched_all_associata int(5) not null,
	esercizio_associato int(5) not null,
	serie int null,
	ripetizioni int null,
	constraint SchedaAllenamentoEsercizio_Esercizio_cod_fk
		foreign key (esercizio_associato) references Esercizio (cod),
	constraint SchedaAllenamentoEsercizio_SchedaAllenamento_cod_fk
		foreign key (sched_all_associata) references SchedaAllenamento (cod)
);

create table Squadra
(
	cod int(7) auto_increment
		primary key,
	nome char(20) null,
	trainer_associato char(16) not null,
	sport char(25) null comment 'sport associato alla squadra',
	constraint Squadra_ibfk_1
		foreign key (trainer_associato) references Trainer (cod_fiscale)
);

create table PartecipazioneTorneoSquadra
(
	squadra_associata int(7) not null,
	torneo_squadra_associato int(7) not null,
	constraint PartecipazioneTorneoSquadra_Squadra_cod_fk
		foreign key (squadra_associata) references Squadra (cod),
	constraint PartecipazioneTorneoSquadra_TorneoSquadre_cod_fk
		foreign key (torneo_squadra_associato) references TorneoSquadre (cod)
);

create table Sportivo
(
	cod_fiscale char(16) not null
		primary key,
	data_nascita date not null,
	nome char(16) not null,
	cognome char(16) not null,
	sesso char not null,
	squadra_partecipazione int(7) null,
	constraint Sportivo_Squadra_cod_fk
		foreign key (squadra_partecipazione) references Squadra (cod)
);

create table PartecipazioneTorneoSingolo
(
	sportivo_associato char(16) not null,
	torneo_singolo_associato int(7) not null,
	constraint PartecipazioneTorneoSingolo_Sportivo_cod_fiscale_fk
		foreign key (sportivo_associato) references Sportivo (cod_fiscale),
	constraint PartecipazioneTorneoSingolo_TorneoSingolo_cod_fk
		foreign key (torneo_singolo_associato) references TorneoSingolo (cod)
);

create index cod_fiscale_Traier
	on Squadra (trainer_associato);

create table TrainerCorso
(
	corso char(20) not null,
	cod_fiscale_Trainer char(16) not null,
	primary key (corso, cod_fiscale_Trainer),
	constraint TrainerCorso_ibfk_1
		foreign key (corso) references Corso (nome),
	constraint TrainerCorso_ibfk_2
		foreign key (cod_fiscale_Trainer) references Trainer (cod_fiscale)
);

create index cod_fiscale_Trainer
	on TrainerCorso (cod_fiscale_Trainer);

create definer = LUPOSaymon@`%` view CertificatoMedicoRecente as
	SELECT `TotalGym`.`CertificatoMedico`.`cliente_associato`  AS `cliente_associato`,
       MAX(`TotalGym`.`CertificatoMedico`.`data_scadenza`) AS `minimum`
FROM `TotalGym`.`CertificatoMedico`
GROUP BY `TotalGym`.`CertificatoMedico`.`cliente_associato`;

create definer = LUPOSaymon@`%` view ClienteConUnCertificatoMedicoScaduto as
	SELECT `TotalGym`.`CertificatoMedico`.`cliente_associato` AS `cliente_associato`
FROM `TotalGym`.`CertificatoMedico`
WHERE (`TotalGym`.`CertificatoMedico`.`cod` IN (SELECT `TotalGym`.`CertificatoMedico`.`cod`
                                                FROM `TotalGym`.`CertificatoMedico`
                                                         JOIN `TotalGym`.`ContaCeritificatiMedici`
                                                WHERE (`ContaCeritificatiMedici`.`n` = 1)) AND
       (`TotalGym`.`CertificatoMedico`.`data_scadenza` < CURDATE()));

create definer = LUPOSaymon@`%` view ClientiConAuto as
	SELECT `TotalGym`.`Auto`.`clienteAssociato` AS `clienteAssociato`
FROM `TotalGym`.`Auto`;

create definer = LUPOSaymon@`%` view CodEserciziUsatiPiuVolte as
	SELECT `TotalGym`.`SchedaAllenamentoEsercizio`.`esercizio_associato` AS `esercizio_associato`
FROM `TotalGym`.`SchedaAllenamentoEsercizio`
GROUP BY `TotalGym`.`SchedaAllenamentoEsercizio`.`esercizio_associato`
HAVING (COUNT(0) > 1);

create definer = LUPOSaymon@`%` view CodFiscalePiuSchede as
	SELECT `TotalGym`.`SchedaAllenamento`.`cod_fiscale_cliente` AS `cod_fiscale_cliente`
FROM `TotalGym`.`SchedaAllenamento`
GROUP BY `TotalGym`.`SchedaAllenamento`.`cod_fiscale_cliente`
HAVING (COUNT(0) > 1);

create definer = LUPOSaymon@`%` view ContaCeritificatiMedici as
	SELECT `TotalGym`.`CertificatoMedico`.`cliente_associato` AS `cliente_associato`, COUNT(0) AS `n`
FROM `TotalGym`.`CertificatoMedico`
GROUP BY `TotalGym`.`CertificatoMedico`.`cliente_associato`;

create definer = LUPOSaymon@`%` view PrenotatiCampo as
	SELECT `TotalGym`.`PrenotazioneCorso`.`cliente_associato` AS `cliente_associato`
FROM `TotalGym`.`PrenotazioneCorso`;

create definer = LUPOSaymon@`%` view PrenotatiCorso as
	SELECT `TotalGym`.`PrenotazioneCampo`.`clienteAssociato` AS `clienteAssociato`
FROM `TotalGym`.`PrenotazioneCampo`;

create definer = LUPOSaymon@`%` view TrainersConSchedaAllenamento as
	SELECT `TotalGym`.`SchedaAllenamento`.`cod_fiscale_trainer` AS `cod_fiscale_trainer`
FROM `TotalGym`.`SchedaAllenamento`;

create definer = LUPOSaymon@`%` view genitoriConDueFigli as
	SELECT `TotalGym`.`Cliente`.`genitore_associato` AS `genitore_associato`, COUNT(0) AS `n`
FROM `TotalGym`.`Cliente`
WHERE (((TO_DAYS(CURDATE()) - TO_DAYS(`TotalGym`.`Cliente`.`data_nascita`)) / 365) < 18)
GROUP BY `TotalGym`.`Cliente`.`genitore_associato`
HAVING (`n` = 2);

