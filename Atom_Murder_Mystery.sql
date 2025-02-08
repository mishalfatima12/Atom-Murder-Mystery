CREATE DATABASE ATOM_MURDER_MYSTERY;
USE ATOM_MURDER_MYSTERY;
SET SQL_SAFE_UPDATES=0;
-- ---------------------------------------------------------- Data Exploration
SELECT * FROM accused_person order by person_id; -- Clean, might have to extract cities later on/100 Rows
SELECT * FROM annual_income order by annual_income desc; -- Clean/100 Rows, Is there a way to change Income format
SELECT * FROM atom_fit; -- where check_in_date = 3092023; --  100 Rows/Change date format and search time formats
SELECT * FROM crime_scene_report; -- 286 Rows/ change date format
SELECT * FROM interviews; -- 100/Rows, change replace sepcial characters
SELECT *FROM drivers_license; -- 100 Rows, Two people are using same license but different cars_make & model
SELECT *FROM annual_dinner; -- 99 Rows/ change date format
-- ---------------------------------------------------------- Data Cleaning
-- accused person table
ALTER TABLE accused_person
ADD COLUMN street_name varchar(50) AFTER address_street_name,
ADD COLUMN city varchar(20) AFTER street_name;
UPDATE accused_person
SET city = SUBSTRING_INDEX(address_street_name,",",-1);
UPDATE accused_person
SET street_name = SUBSTRING(address_street_name,1,length(address_street_name)-(length(city)+1));
ALTER TABLE accused_person
DROP COLUMN address_street_name;
ALTER TABLE accused_person
RENAME COLUMN address_street_number TO street_number;

-- annual income
SELECT * FROM annual_income order by annual_income desc; 

-- atom_fit
SELECT * FROM atom_fit;
select data_type from information_schema.columns
where table_name = "atom_fit" and column_name= "check_in_date";
update atom_fit
set check_in_date = str_to_date((case when length(check_in_date) = 7 then concat("0",check_in_date) 
								else check_in_date
								End),"%m%d%Y");
alter table atom_fit
modify column check_in_date date;

-- crime_scene_report
update crime_scene_report
set date = str_to_date((case when length(date) = 7 then concat("0",date) 
								else date
								End),"%m%d%Y");
alter table crime_scene_report
modify column date date;

-- interviews
SELECT * FROM interviews;
update interviews 
set transcript = replace(transcript , "Ã¢â‚¬â„¢", "'"),
transcript = replace(transcript , "Ã¢â‚¬Ëœ", "'");

-- drivers_license
SELECT *FROM drivers_license;

-- annual_dinner
SELECT *FROM annual_dinner;
update annual_dinner
set date =str_to_date( if (length(date)=7 ,concat("0",date),date),"%m%d%Y");
alter table annual_dinner
modify column date date;

-- ---------------------------------------------------------- Defining Keys
ALTER TABLE accused_person
ADD PRIMARY KEY (person_id);
ALTER TABLE annual_dinner
ADD PRIMARY KEY (person_id);
ALTER TABLE annual_income
ADD PRIMARY KEY (ssn);
ALTER TABLE atom_fit
MODIFY COLUMN membership_id varchar(7);
ALTER TABLE atom_fit
ADD PRIMARY KEY (person_id,membership_id);
ALTER TABLE crime_scene_report
ADD PRIMARY KEY (index_report);
ALTER TABLE interviews
ADD PRIMARY KEY (person_id);
ALTER TABLE drivers_license
ADD PRIMARY KEY (license_id);
ALTER TABLE accused_person
ADD CONSTRAINT fk_ssn
FOREIGN KEY (ssn) references annual_income(ssn),
ADD CONSTRAINT fk_license_id
FOREIGN KEY (license_id) REFERENCES drivers_license(license_id);

-- ---------------------------------------------------------- Solving The Case
-- STEP 1: Like a true detective let's start with the crime scene on 9th March 2023 in Atom-City
SELECT * FROM CRIME_SCENE_REPORT 
WHERE date = "2023-03-09" AND city = "Atom-city";
-- STEP 2: Now I wish I did not clean the address but no worries. Lets investigate the witnesses.
-- Lets note down the witness person_ids, license_ids  205019,641569 (Sanam Akhtar) & 257998,351718 (Meera Devi)
SELECT * FROM ACCUSED_PERSON 
WHERE (NAME = "SANAM AKHTAR" AND CITY ="LAHORE" AND STREET_NAME ="GULSHAN-E-RAVI") OR 
	  (CITY ="RAWALPINDI" AND STREET_NAME ="SADDAR BAZAAR" AND STREET_NUMBER = (SELECT MAX(STREET_NUMBER) FROM ACCUSED_PERSON
																				WHERE CITY ="RAWALPINDI" AND STREET_NAME ="SADDAR BAZAAR"
                                                                                GROUP BY CITY))
ORDER BY CITY;
-- STEP 3: Let's check their interviews and whereabouts for the day of the murder and just a bit of screening.
-- You might think its excessive but if we are investigating we will do it properly,
-- SELECT * FROM INTERVIEWS
-- WHERE PERSON_ID IN(205019,257998);

SELECT A.NAME,I.* FROM INTERVIEWS AS I
JOIN ACCUSED_PERSON AS A ON A.PERSON_ID = I.PERSON_ID
WHERE (NAME = "SANAM AKHTAR" AND CITY ="LAHORE" AND STREET_NAME ="GULSHAN-E-RAVI") OR 
	  (CITY ="RAWALPINDI" AND STREET_NAME ="SADDAR BAZAAR" AND STREET_NUMBER = (SELECT MAX(STREET_NUMBER) FROM ACCUSED_PERSON
																				WHERE CITY ="RAWALPINDI" AND STREET_NAME ="SADDAR BAZAAR"
                                                                                GROUP BY CITY));
-- More complicated: Just trying out
-- SELECT * FROM INTERVIEWS
-- WHERE PERSON_ID IN(SELECT person_id FROM ACCUSED_PERSON 
-- WHERE (NAME = "SANAM AKHTAR" AND CITY ="LAHORE" AND STREET_NAME ="GULSHAN-E-RAVI") OR 
-- 	  (CITY ="RAWALPINDI" AND STREET_NAME ="SADDAR BAZAAR" AND STREET_NUMBER = (SELECT MAX(STREET_NUMBER) FROM ACCUSED_PERSON
-- 																				WHERE CITY ="RAWALPINDI" AND STREET_NAME ="SADDAR BAZAAR"
-- 	 																		GROUP BY CITY)));

SELECT * from annual_income where ssn in (SELECT ssn FROM accused_person
										  WHERE PERSON_ID IN(205019,257998));
SELECT * FROM accused_person
WHERE PERSON_ID IN(205019,257998); 
-- Neither of them seems to have used the gym on the day of murder even tou 205019 (Sanam Akhtar) claims to that she was working out that day.
-- She could be using someone elses membership id. From the following query there is only one record for the date 9th March 2023.
SELECT * FROM atom_fit
WHERE CHECK_IN_DATE = "2023-03-09"; 
Select a.name ,d.* from drivers_license as d
right join accused_person as a on a.license_id = d.license_id
where a.person_id in (205019,257998);


-- IDENTIFY THE KILLER USING ABOVE INFORMATION: DATE, GENDER,MEMBERSHIP_ID = AT3326, PLATE_NUMBER =LHR7303, CAR_MAKE = AUDI
SELECT * FROM DRIVERS_LICENSE
WHERE PLATE_NUMBER = "LHR7303" AND CAR_MAKE ="AUDI";
-- THERE ARE TWO RECORDS FOR THE NUMBER PLATE (NONE OF THEM A FEMALE) AND ONLY ONE FOR BOTH NUMBER PLATE AND CAR MAKE.
SELECT * FROM ATOM_FIT
WHERE CHECK_IN_DATE = "2023-03-09" OR MEMBERSHIP_ID ="AT3326"; 
-- GIVES ONLY ONE RECORD. LET'S IDENTIFY THE PERSON AMONGST THE ACCUSED

WITH T1 AS (
SELECT * FROM DRIVERS_LICENSE
WHERE PLATE_NUMBER = "LHR7303" AND CAR_MAKE ="AUDI"),
T2 AS(
SELECT * FROM ATOM_FIT
WHERE CHECK_IN_DATE = "2023-03-09" OR MEMBERSHIP_ID ="AT3326"
)
SELECT A.*, T1. PLATE_NUMBER,T1.CAR_MAKE, T2.CHECK_IN_DATE, T2.MEMBERSHIP_ID FROM ACCUSED_PERSON AS A
RIGHT JOIN T1 AS T1 ON A.LICENSE_ID = T1.LICENSE_ID
RIGHT JOIN T2 AS T2 ON A.PERSON_ID = T2.PERSON_ID;

-- SURPRISINGLY ALL OF THE DATA POINTS TO THE SAME PERSON. BUT THE MYSTERY REMAINS AS TO THE PERSONS GENDER. LETS GET THEIR INTERVIEW.

SELECT * FROM INTERVIEWS
WHERE PERSON_ID =(SELECT PERSON_ID FROM ATOM_FIT
				  WHERE CHECK_IN_DATE = "2023-03-09" AND MEMBERSHIP_ID ="AT3326");

-- NEW INFORMATION: FEMALE, MILLIONAIRE, BLUE EYES,60 YEARS OLD, MERCEDES BENZ, DINNER ON 9th MARCH 2023.
SELECT A.PERSON_ID, A.NAME, A. SSN, D.* FROM DRIVERS_LICENSE AS D
LEFT JOIN ACCUSED_PERSON AS A ON D.LICENSE_ID = A.LICENSE_ID
WHERE AGE = 60 AND EYE_COLOR ="BLUE" AND GENDER ="FEMALE" AND CAR_MAKE ="MERCEDES" AND CAR_MODEL ="BENZ";
-- THE RESULTS HAVE BEEN NARROWED DOWN TO TWO PEOPLE. NOW THE ONLY THING LEFT TO DO IS COMPARE THEIR ACCOUNT STATEMENTS AND WHEREABOUTS.
WITH T1 AS(
SELECT A.PERSON_ID AS PERSON_ID, A.NAME AS NAME,A.SSN AS SSN FROM DRIVERS_LICENSE AS D
LEFT JOIN ACCUSED_PERSON AS A ON D.LICENSE_ID = A.LICENSE_ID
WHERE AGE = 60 AND EYE_COLOR ="BLUE" AND GENDER ="FEMALE" AND CAR_MAKE ="MERCEDES" AND CAR_MODEL ="BENZ"
)
SELECT T1.PERSON_ID, T1.NAME, AI.* FROM ANNUAL_INCOME AS AI
LEFT JOIN T1 AS T1 ON AI.SSN = T1.SSN
WHERE AI.SSN = T1.SSN AND AI.ANNUAL_INCOME>999999;
-- ACCORDING TO THE ABOVE ANALYSIS ONE "SHABNAM AKHTAR" IS FOUND GUILTY.
-- LETS'S FETCH THE RECORDS OF A DINNER HELD ON 9TH MARCH 2023 TO SETTLE ANY DOUBTS LEFT.
SELECT * FROM ACCUSED_PERSON
WHERE PERSON_ID IN (SELECT PERSON_ID FROM ANNUAL_DINNER
					WHERE DATE ="2023-03-09");
-- THE RECORDS REAFFIRM THAT THE PERSON NAMED "SHABNAM AKHTAR", ID NO. 541190, LICENSE NO. 573532 IS A KILLER AND MUST BE TAKEN INTO CUSTODY.


-- WITH T1 AS(
-- SELECT A.PERSON_ID AS PERSON_ID, A.NAME AS NAME,A.SSN AS SSN FROM DRIVERS_LICENSE AS D
-- LEFT JOIN ACCUSED_PERSON AS A ON D.LICENSE_ID = A.LICENSE_ID
-- WHERE AGE = 60 AND EYE_COLOR ="BLUE" AND GENDER ="FEMALE" AND CAR_MAKE ="MERCEDES" AND CAR_MODEL ="BENZ"
-- ),
-- T2 AS(
-- SELECT PERSON_ID,DATE FROM ANNUAL_DINNER
-- WHERE DATE = "2023-03-09"
-- )
-- SELECT T1.PERSON_ID, T1.NAME, AI.* FROM ANNUAL_INCOME AS AI
-- LEFT JOIN T1 AS T1 ON AI.SSN = T1.SSN
-- LEFT JOIN T2 ON T1.PERSON_ID=T2.PERSON_ID
-- WHERE AI.SSN = T1.SSN AND AI.ANNUAL_INCOME>999999 AND T2.DATE ="2023-03-09";