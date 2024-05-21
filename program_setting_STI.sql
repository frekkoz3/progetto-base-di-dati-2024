drop database STI;
create database STI;
use STI;

create table TUFF(
	CodiceFascia int PRIMARY KEY, 
    IndiceProCapite float NOT NULL, 
    IndiceProMetro float NOT NULL
);

insert into TUFF Values (1, 0.05, 0.01),
(2, 0.06, 0.02),
(3, 0.075, 0.03),
(4, 0.1, 0.05),
(5, 0.12, 0.06),
(6, 0.15, 0.1),
(7, 0.2, 0.2);

create table TUCG(
	Valuta varchar(100) PRIMARY KEY,
    TassoDiConversione float NOT NULL
);

insert into TUCG Values ("Agostiniano", 1),
("Bersko", 6.5),
("Cherubo", 1.2),
("Curmino", 8.2),
("Gerano", 14.5),
("Jordano", 3549.1),
("Kilo", 1000),
("Korolo", 2.3),
("Nippo", 1320.3),
("Nuevo", 46.4);

create table Regioni(
	CodiceRegione int PRIMARY KEY,
    DataIngresso Date NOT NULL, 
    Nome varchar (100) NOT NULL, 
    Valuta varchar (100) Default "Agostiniano",
    FOREIGN KEY (Valuta) REFERENCES TUCG(Valuta)
);

create table Distretti(
	CodiceDistretto int PRIMARY KEY,
    CodiceRegione int NOT NULL,
    FOREIGN KEY (CodiceRegione) REFERENCES Regioni(CodiceRegione)
);

create table Consoli(
	CodiceImperiale int PRIMARY KEY,
    Nome varchar (100) NOT NULL, 
    Cognome varchar (100) NOT NULL,
    DataDiNascita Date NOT NULL, 
    DataDiElezione Date NOT NULL, 
    DataDiFineMandato Date default NULL, 
    ContattoTelefonico varchar (100) NOT NULL, 
    CodiceDistretto int NOT NULL, 
    FOREIGN KEY (CodiceDistretto) REFERENCES Distretti(CodiceDistretto)
);

alter table Distretti add column CodiceConsole int;
alter table Distretti add constraint fk FOREIGN KEY (CodiceConsole) REFERENCES Consoli(CodiceImperiale);

create table Mondi(
	CodiceMondo int PRIMARY KEY, 
    Nome varchar(100) NOT NULL,
    DataDiIngresso Date NOT NULL, 
    PIL int NOT NULL, 
    Abitanti int NOT NULL, 
    SuperficieProduttiva int NOT NULL,
    FasciaFiscale int NOT NULL, 
    CodiceDistretto int NOT NULL,
    FOREIGN KEY (FasciaFiscale) REFERENCES TUFF(CodiceFascia), 
    FOREIGN KEY (CodiceDistretto) REFERENCES Distretti(CodiceDistretto)
);

create table Tributi(
	NumeroTributo int auto_increment PRIMARY KEY,
    DataDiEmissione Date NOT NULL, 
    Ammontare float NOT NULL, 
    Status varchar (100) default "Non Pagato",
    CodiceDistretto int NOT NULL, 
    FOREIGN KEY (CodiceDistretto) REFERENCES Distretti(CodiceDistretto)
);

create table Pagamenti(
	NumeroPagamento int auto_increment PRIMARY KEY, 
    DataDiPagamento Date NOT NULL, 
    NumeroTributo int NOT NULL,
    CodiceConsolePagante int NOT NULL, 
    CodiceConsoleTestimone1 int NOT NULL, 
    CodiceConsoleTestimone2 int NOT NULL, 
    FOREIGN KEY (NumeroTributo) REFERENCES Tributi(NumeroTributo), 
    FOREIGN KEY (CodiceConsolePagante) REFERENCES Consoli(CodiceImperiale), 
    FOREIGN KEY (CodiceConsoleTestimone1) REFERENCES Consoli(CodiceImperiale),
    FOREIGN KEY (CodiceConsoleTestimone2) REFERENCES Consoli(CodiceImperiale)
);

insert into Regioni values
(32, '1404-10-02', 'Andromeda', 'Gerano'),
(33, '1253-04-22', 'Antennae', 'Korolo'),
(34, '1039-12-21', 'Hoag', 'Cherubo'),
(35, '1377-11-10', 'Medusa Merger', 'Kilo'),
(36, '1484-04-08', 'Milky Way', 'Korolo'),
(37, '1186-09-06', 'Tapdole', 'Nippo');

SET foreign_key_checks = 0;

insert into Distretti values
(16, 35, 0),
(17, 37, 1),
(18, 37, 2),
(19, 32, 3),
(20, 37, 4),
(21, 32, 5),
(22, 34, 6),
(23, 37, 7),
(24, 32, 8),
(25, 35, 9),
(26, 33, 10),
(27, 37, 11),
(28, 33, 12),
(29, 36, 13),
(30, 37, 14);

SET foreign_key_checks = 1;

delimiter //

CREATE PROCEDURE updateDistretti(
	IN CI int, 
    IN CD int
)
BEGIN
    update Distretti
    set CodiceConsole = CI 
    where CodiceDistretto = CD;
END; //

CREATE PROCEDURE inserisciConsole(
    IN CI int, 
    IN N varchar(100), 
    IN C varchar(100), 
    IN DN Date, 
    IN DE Date, 
    IN CT varchar (100), 
    in CD int
)
BEGIN 
	insert into Consoli 
    (CodiceImperiale, Nome, Cognome, DataDiNascita, DataDiElezione, ContattoTelefonico, CodiceDistretto) 
    values (CI, N, C, DN, DE, CT, CD);
    update Consoli
    set DataDiFineMandato = DE 
    where CD = CodiceDistretto 
    and DataDiFineMandato is null 
    and CI != CodiceImperiale;
END;//

CREATE TRIGGER CambioDiGoverno
AFTER INSERT ON Consoli
FOR EACH ROW
BEGIN        
	CALL updateDistretti(NEW.CodiceImperiale, NEW.CodiceDistretto);
END; //

CREATE TRIGGER aggiornaStatus
AFTER INSERT ON Pagamenti
FOR EACH ROW
BEGIN
	UPDATE Tributi
    SET status = "Pagato"
    WHERE NumeroTributo = NEW.NumeroTributo;
END;//

CREATE PROCEDURE regioneConsole(
IN ci int,
OUT cr int
)
BEGIN
	SELECT codiceRegione INTO cr FROM Distretti where codiceConsole = ci;
END;//

CREATE PROCEDURE distrettoPagamento(
IN nt int,
OUT dp int
)
BEGIN
	SELECT codiceDistretto INTO dp FROM Tributi where numeroTributo = nt;
END;//

CREATE PROCEDURE distrettoConsole(
IN ci int,
OUT cd int
)
BEGIN
	SELECT codiceDistretto INTO cd from Consoli where codiceImperiale = ci;
END;//

CREATE PROCEDURE statusTributo(
IN nt int,
OUT s varchar(100)
)
BEGIN
	SELECT status INTO s from tributi where numeroTributo = nt;
END;//

CREATE TRIGGER controllaPagamenti
BEFORE INSERT ON Pagamenti
FOR EACH ROW
BEGIN
	DECLARE ccp int; -- codice regione console pagante
    DECLARE cct1 int; -- codice regione console testimone 1
    DECLARE cct2 int; -- codice regione console testimone 2
    DECLARE cdc int; -- codice distretto console pagante
    DECLARE cdp int; -- codice distretto pagamento
    DECLARE s varchar(100); -- status tributo di riferimento
    CALL regioneConsole(NEW.CodiceConsolePagante, ccp);
    CALL regioneConsole(NEW.CodiceConsoleTestimone1, cct1);
    CALL regioneConsole(NEW.CodiceConsoleTestimone2, cct2);
    CALL distrettoConsole(NEW.CodiceConsolePagante, cdc);
    CALL distrettoPagamento(NEW.numeroPagamento, cdp);
    CALL statusTributo(NEW.numeroTributo, s);
    IF NEW.CodiceConsoleTestimone1 = NEW.CodiceConsoleTestimone2 THEN
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'il console pagante non governa il distretto interessato dal tributo. pagamento non autorizzato';
    END IF;
    IF s = "Pagato" THEN 
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'pagamento già avvenuto.';
    END IF;
	IF cdc != cdp THEN 
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'il console pagante non governa il distretto interessato dal tributo. pagamento non autorizzato';
    END IF ;
    IF ccp IS NULL or cct1 IS NULL or cct2 IS NULL THEN
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'uno dei consoli non è più in carica. pagamento non autorizzato';
	END IF;
	IF ccp = cct1 or ccp = cct2 THEN 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'testimoni provenienti dalla stessa regione. pagamento non autorizzato';
	END IF;
END;//

delimiter ;

CALL inserisciConsole(0, 'Erik', 'Lavanchy', '1997-09-18', '2024-05-18', '+33 395992033', 16);
CALL inserisciConsole(1, 'Rion', 'Wildner', '1961-02-23', '2024-05-18', '+39 152048470', 17);
CALL inserisciConsole(2, 'Keneth', 'Verrill', '1976-10-17', '2024-05-18', '+31 922336118', 18);
CALL inserisciConsole(3, 'Rion', 'Veillon', '1988-01-28', '2024-05-18', '+35 230313496', 19);
CALL inserisciConsole(4, 'Hawk', 'Irani', '1980-05-03', '2024-05-18', '+32 606159526', 20);
CALL inserisciConsole(5, 'Alex', 'Zechiel', '1991-03-19', '2024-05-18', '+40 813422215', 21);
CALL inserisciConsole(6, 'Boone', 'Vanlaere', '1955-03-14', '2024-05-18', '+33 538158054', 22);
CALL inserisciConsole(7, 'Warrick', 'Veillon', '1960-10-08', '2024-05-18', '+37 863400184', 23);
CALL inserisciConsole(8, 'Zebulon', 'Dilucca', '2008-07-12', '2024-05-18', '+37 669151386', 24);
CALL inserisciConsole(9, 'Corvin', 'Tyrrell', '1989-05-09', '2024-05-18', '+39 702413872', 25);
CALL inserisciConsole(10, 'Brom', 'Erikson', '1983-07-15', '2024-05-18', '+38 951342161', 26);
CALL inserisciConsole(11, 'Falcon', 'Jann', '1947-12-09', '2024-05-18', '+34 697182111', 27);
CALL inserisciConsole(12, 'Ethan', 'Castiglione', '1947-01-18', '2024-05-18', '+39 437435176', 28);
CALL inserisciConsole(13, 'Nevyn', 'Watanabe', '2003-01-01', '2024-05-18', '+33 650623866', 29);
CALL inserisciConsole(14, 'Monte', 'Leath', '1994-07-19', '2024-05-18', '+37 897145892', 30);

insert into Mondi values
(64,'Pegnuinus', '1974-11-12', 5639, 774274, 993726, 1, 17),
(65,'Rinvihines', '1929-12-24', 5089, 167967, 626703, 3, 24),
(66,'Thonnov', '1979-05-19', 1069, 843591, 66579, 6, 17),
(67,'Alorix', '1976-05-05', 7602, 511931, 47626, 6, 23),
(68,'Nalia', '1982-02-15', 3226, 600404, 424659, 6, 29),
(69,'Dulea', '1925-10-13', 3301, 317454, 678091, 1, 19),
(70,'Dreuthea', '1969-09-21', 8549, 291326, 263208, 4, 21),
(71,'Strakoter', '1975-04-15', 8104, 571226, 581875, 5, 29),
(72,'Certh GPV3', '1981-01-18', 7424, 675382, 431831, 2, 28),
(73,'Groria IO7', '1978-07-13', 3986, 763444, 145241, 7, 26),
(74,'Magriuhiri', '1932-06-11', 6024, 761366, 245467, 4, 30),
(75,'Zilnotera', '1960-11-30', 8632, 376988, 373084, 2, 18),
(76,'Radrides', '1972-05-29', 3856, 782191, 895630, 3, 23),
(77,'Engiri', '1968-02-10', 6973, 318104, 947987, 6, 16),
(78,'Patania', '1973-04-14', 6811, 677267, 99959, 2, 18),
(79,'Giagantu', '1928-06-23', 1270, 649097, 852914, 4, 22),
(80,'Chethalia', '1935-04-18', 6486, 451449, 592867, 2, 30),
(81,'Crokoliv', '1943-02-08', 6618, 466582, 903510, 5, 18),
(82,'Brion 21H', '1978-10-25', 1849, 901697, 265256, 4, 23),
(83,'Croria 1HW', '1950-09-01', 7616, 179894, 86524, 2, 18),
(84,'Hivunope', '1936-09-16', 8696, 590412, 3117, 4, 23),
(85,'Ulnacarro', '1937-08-17', 6236, 365927, 707663, 6, 27),
(86,'Sangorix', '1969-08-29', 6993, 349165, 548874, 3, 22),
(87,'Mucrides', '1947-06-25', 5090, 440621, 225885, 2, 22),
(88,'Kanov', '1979-08-31', 3488, 671180, 217543, 6, 17),
(89,'Beapra', '1966-03-09', 5685, 953913, 104181, 3, 21),
(90,'Phoitune', '1927-05-10', 8344, 851075, 146546, 7, 21),
(91,'Vizemia', '1968-07-10', 7100, 718051, 9282, 1, 19),
(92,'Phorix 5844', '1966-09-04', 2855, 930875, 871542, 6, 20),
(93,'Nosie SK', '1942-05-14', 2727, 575231, 797693, 5, 30),
(94,'Zasinerth', '1928-10-28', 3916, 625391, 751569, 5, 25),
(95,'Talmonope', '1976-12-10', 4984, 438269, 726443, 5, 22),
(96,'Salorth', '1961-06-14', 583, 593974, 592074, 3, 27),
(97,'Ulnilia', '1958-11-10', 4253, 716689, 495083, 4, 29),
(98,'Taustea', '1948-12-30', 1894, 138541, 629337, 5, 28),
(99,'Eoria', '1975-10-31', 971, 295747, 976356, 4, 23),
(100,'Birepra', '1967-08-29', 2955, 208744, 414432, 7, 28),
(101,'Zeyolia', '1962-10-08', 2741, 947336, 305396, 1, 18),
(102,'Drorth 3F', '1934-07-21', 5372, 832785, 586421, 3, 22),
(103,'Vichi A11', '1925-02-13', 1241, 879910, 793551, 3, 28),
(104,'Hulnoter', '1936-02-12', 8646, 726072, 763968, 6, 23),
(105,'Oluzuno', '1932-02-17', 875, 448261, 571829, 5, 29),
(106,'Chicrillon', '1957-07-10', 4881, 588175, 216798, 4, 26),
(107,'Yeccichi', '1974-11-09', 4232, 795700, 187683, 7, 16),
(108,'Chanus', '1963-05-19', 2509, 136719, 701984, 4, 18),
(109,'Cheohines', '1975-08-21', 8356, 374500, 392019, 6, 26),
(110,'Drexilea', '1934-12-16', 6329, 266439, 595017, 1, 17),
(111,'Crumezuno', '1963-07-08', 5325, 656226, 185049, 4, 17),
(112,'Beshan D3D0', '1969-08-13', 1522, 366434, 202906, 6, 22),
(113,'Chiuq QC', '1977-04-30', 6485, 191004, 59945, 3, 18);

-- operazione base di batch dei tributi

DELIMITER //
CREATE PROCEDURE batchTributi(
	IN DataAttuale Date
)
BEGIN    
	DECLARE t float;
    DECLARE cd int;
    DECLARE finished int default 0;
    
	DECLARE tributi_cursor CURSOR for 
    select round(sum(indiceprometro * superficieproduttiva + indiceprocapite * abitanti)) as tributo,
    codiceDistretto from mondi 
    join TUFF on mondi.fasciaFiscale = TUFF.codiceFascia 
    group by codiceDIstretto;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    
    OPEN tributi_cursor;
    WHILE (finished = 0) DO 
		FETCH tributi_cursor into t, cd;
        INSERT INTO tributi (DataDiEmissione, Ammontare, CodiceDistretto) values (DataAttuale, t, cd);
	END WHILE;
    CLOSE tributi_cursor;
 END;//
 
 delimiter ;

CALL batchTributi('2024-01-01');
CALL batchTributi('2025-01-01');
CALL batchTributi('2026-01-01');