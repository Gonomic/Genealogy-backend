CREATE DEFINER=`root`@`%` PROCEDURE `ChangePerson`(IN `PersonIdIn` INT(11), 
												IN `PersonGivvenNameIn` VARCHAR(25), 
                                                IN `PersonFamilyNameIn` VARCHAR(50), 
                                                IN `PersonDateOfBirthIn` DATE, 
                                                IN `PersonPlaceOfBirthIn` VARCHAR(50), 
                                                IN `PersonDateOfDeathIn` DATE, 
                                                IN `PersonPlaceOfDeathIn` VARCHAR(50), 
                                                IN `PersonIsMaleIn` TINYINT(1), 
                                                IN `PersonMotherIdIn` INT(11),
                                                IN `PersonFatherIdIn` INT(11),
                                                IN `PersonPartnerIdIn` INT(11))
    SQL SECURITY INVOKER
    COMMENT 'To update the details of a specific person'
BEGIN
	-- ----------------------------------------------------------------------------------------------------------------------------------------------
    -- Author: 	Frans Dekkers (GoNomics)
    -- Date:	1-3-2020
    -- -----------------------------------
    -- Prurpose of this Sproc:
    -- Add a person record 
    -- 
    -- Parameters of this Sproc:
    -- Alle persons fields and fields for mother, father and parent

    -- 
    -- High level flow of this Sproc:
    -- => Simply add a record to the persons table and table relations which (if applicable) ties this person to his/fer father, mother and partner
    --   
    -- Note:	None
    --		
    -- TODO's:
    -- => xx/xx/xxxx -> 
    -- ----------------------------------------------------------------------------------------------------------------------------------------------
	-- CompletedOk defines the result of a database transaction, like this:

    -- 0 = Transaction finished without problems.

    -- 1 = Transaction aborted due to intermediate changes (possibly from other users) in the mean time

    -- 2 = Transaction aborted due to problems during update and rollback performed

    DECLARE CompletedOk int;

    -- NewTransNo is autonumber counter fetched from a seperate table and used for logging in a seperate log table
	DECLARE NewTransNo int;

    -- TransResult is used to count the number of seperate database operations and rissen with each step
	DECLARE TransResult int;

    -- RecCount is used to count the number of related records in depended tables.
	DECLARE RecCount int;

    -- LastRecInserted is the autonumber ID value for each addition
	DECLARE LastRecIdInserted INT(11);
    
     DECLARE RelationIdOfMother int;
    
    DECLARE RelationIdOfFather int;
    
    DECLARE RelationIdOfPartner int;

	DECLARE FullNamePerson varchar(100);
    
	DECLARE MessageText CHAR;

	DECLARE ReturnedSqlState INT;

	DECLARE MySQLErrNo INT;
        
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
 	BEGIN

		GET CURRENT DIAGNOSTICS CONDITION 1 MessageText = message_text, ReturnedSqlState = RETURNED_SQLSTATE, MySqlErrNo = MYSQL_ERRNO;
        
		ROLLBACK;

		SET CompletedOk = 2;

		INSERT INTO humans.testlog 
			SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), " SPROC AddPerson(). Error occured()=", 
								 IFNULL(MessageText, "null"), "/State=", IFNULL(ReturnedSqlState, "null"), "/ErrNo=", IFNULL(MySqlErrNo, "null"), "). Rollback executed. CompletedOk= ", IFNULL(CompletedOk, 'null')),
								 TestLogDateTime = NOW();

		SELECT CompletedOk;

	END;


main_proc:

BEGIN

SET CompletedOk = 0;

SET TransResult = 0;

SET NewTransNo = GetTranNo("ChangePerson");

INSERT INTO humans.testlog 
	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ", SPROC ChangePerson(). TransResult= ", IFNULL(transResult, null), '. Start change record for person with name ', IFNULL(PersonGivvenNameIn, 'null'), ' ', IFNULL(PersonFamilyNameIn, 'null')),
		TestLogDateTime = NOW();
        
 INSERT INTO humans.testlog 
	SET TestLog = concat('TransAction-', IFNULL(NewTransNo, 'null'), ', SPROC ChangePerson() ',
							  'Wijzigen bestaande persoon=> ', 
                              'PersonIdIn= ', IFNULL(PersonIdIn, 'null'), ', ',
							  'PersonGivvenNameIn= ', IFNULL(PersonGivvenNameIn, 'null'), ', ',
							  'PersonFamilyNameIn= ', IFNULL(PersonFamilyNameIn, 'null'), ', ',
							  'PersonDateOfBirthIn= ', IFNULL(PersonDateOfBirthIn, 'null'), ', ',
							  'PersonPlaceOfBirthIn= ', IFNULL(PersonPlaceOfBirthIn, 'null'), ', ',
							  'PersonDateOfDeathIn= ', IFNULL(PersonDateOfDeathIn, 'null'), ', ',
							  'PersonPlaceOfDeathIn= ',  IFNULL(PersonPlaceOfDeathIn, 'null'), ', ',
							  'PersonIsMaleIn= ', IFNULL(PersonIsMaleIn, 'null'), ', ',
							  'PersonPartnerIdIn= ', IFNULL(PersonPartnerIdIn, 'null'), ', ',
							  'PersonFatherIdIn= ',  IFNULL(PersonFatherIdIn, 'null'), ', ',
							  'PersonMotherIdIn= ',  IFNULL(PersonMotherIdIn, 'null'), '. '),
	TestLogDateTime = NOW();

	SET RelationIdOfMother = fGetRelationId("Moeder");
    
    SET RelationIdOfFather = fGetRelationId("Vader");
    
    SET RelationIdOfPartner = fGetRelationId("Partner");

transactionBody:BEGIN
	START TRANSACTION;
		UPDATE humans.persons
			SET
				PersonGivvenName = PersonGivvenNameIn, 

				PersonFamilyName = PersonFamilyNameIn, 

				PersonFamilyName = PersonFamilyNameIn, 

				PersonPlaceOfBirth = PersonPlaceOfBirthIn, 

				PersonDateOfDeath = PersonDateOfDeathIn, 

				PersonPlaceOfDeath = PersonPlaceOfDeathIn, 

				PersonIsMale = PersonIsMaleIn,
                    
                Timestamp = NOW()
			WHERE
				PersonID = PersonIdIn;

		SET TransResult = 1;

		SET RecCount = 0;

		-- Based on if Mother params are filled do either nothing or update or insert Mother

		-- -------------------------------------------------

		-- If Mother params are filled

		-- Determine if Person has Mother

		-- UPDATE Mother if Person already has Mother

		-- INSERT Mother if Person does not yet have Mother

		IF PersonMotherIdIn = '' OR PersonMotherIdIn IS null THEN
			INSERT INTO humans.testlog
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder NIET in transactie aanwezig, als moeder in de database aanwezig is wordt ze verwijderd als moeder'),
				TestLogDateTime = NOW();
                IF fGetMother(PersonIdIn) IS NOT null THEN
					DELETE FROM humans.relations WHERE RelationPerson = PersonIdIn AND RelationName = RelationIdOfMother;
                    INSERT INTO humans.testlog
                    SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder was in de database aanwezig  en is verwijderd als moeder uit de database.'),
						TestLogDateTime = NOW();
                END IF;
        ELSE
			IF fGetMother(PersonIdIn) IS null THEN
                INSERT INTO humans.relations
					(RelationName, 
					RelationPerson,
					RelationWithPerson)
			    VALUES
			        (RelationIdOfMother,
					PersonIdIn,
					PersonMotherIdIn);
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder in transactie aanwezig maar niet in de database, moeder wordt in de database toegevoegd. Moeder ID wordt: ', IFNULL(PersonMotherIdIn, 'null')),
						TestLogDateTime = NOW();
				SET TransResult = TransResult + 1;
			ELSE
				UPDATE humans.relations 
					SET RelationWithPerson = PersonMotherIdIn
					WHERE RelationPerson = PersonIdIn
					AND RelationName = RelationIdOfMother;
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder in transactie en in de database aanwezig, moeder wordt gewijzigd. Moeder ID wordt: ', IFNULL(PersonMotherIdIn, 'null')),
						TestLogDateTime = NOW();
				SET TransResult = TransResult + 1;  
			END IF;
		END IF;

		-- Based on if Father params are filled do either nothing or update or insert Father
		-- --------------------------------------------------
		-- If Father param is filled
		-- Determine if Person has Father
		-- UPDATE Father if Person already has Father
		-- INSERT Father if Person does not yet have Father

		IF PersonFatherIdIn = '' OR PersonFatherIdIn IS null THEN
			INSERT INTO humans.testlog
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader NIET in transactie aanwezig, als vader in de database aanwezig is wordt hij verwijderd als vader'),
				TestLogDateTime = NOW();
			IF fGetFather(FatherIdIn) IS NOT null THEN
				DELETE FROM humans.relations WHERE RelationPerson = PersonIDIn AND RelationName = RelationIdOfFather;
                INSERT INTO humans.testlog
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader was in de database aanwezig  en is verwijderd als vader uit de database.'),
					TestLogDateTime = NOW();
			END IF;
        ELSE
			IF fGetFather(PersonIdIn) IS null THEN
                INSERT INTO humans.relations
					(RelationName, 
					RelationPerson,
					RelationWithPerson)
			    VALUES
			        (RelationIdOfFather,
					PersonIdIn,
					PersonFatherIdIn);
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader in transactie aanwezig maar niet in de database, vader wordt in de database toegevoegd. Vader ID wordt: ', IFNULL(PersonMotherIdIn, 'null')),
						TestLogDateTime = NOW();
				SET TransResult = TransResult + 1;
			ELSE
				UPDATE humans.relations 
					SET RelationWithPerson = PersonFatherIdIn
					WHERE RelationPerson = PersonIdIn
					AND RelationName = RelationIdOfFather;
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader in transactie en in de database aanwezig, vader wordt gewijzigd. Vader ID wordt: ', IFNULL(PersonFatherIdIn, 'null')),
						TestLogDateTime = NOW();
			END IF;
		END IF;
        

		-- Based on if Partner params are filled do either nothing or update or insert Partner
		-- ----------------------------------------------------
		-- If Partner param is filled
		-- Determine if Person has Partner
		-- UPDATE Partner if Person already has Partner
		-- INSERT Partner if Person does not yet have Partner

		IF PersonPartnerIdIn = '' OR PersonPartnerIdIn IS null THEN
			INSERT INTO humans.testlog
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partner NIET in transactie aanwezig, als partner in de database aanwezig is wordt deze verwijderd uit de database.'),
					TestLogDateTime = NOW();
			IF fGetPartner(PersonIdIn) IS NOT null THEN
				DELETE FROM humans.relations
					WHERE RelationPerson = PersonIdIn AND RelationName = RelationIdOfPartner;
                DELETE FROM humans.relations 
					WHERE RelationWithPerson = PersonIdIn AND RelationName = RelationIdOfPartner;
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partners in de database aanwezig en verwijderd als partners uit de database.'),
						TestLogDateTime = NOW();
			ELSE 
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partners was al niet in de database aanwezig, geen verdere actie.'),
						TestLogDateTime = NOW();            
			END IF;
		ELSE
			IF fGetPartner(PersonIdIn) IS null THEN
				INSERT INTO humans.relations
						(RelationName, 
						RelationPerson,
						RelationWithPerson)
					VALUES
						(RelationIdOfPartner,
						PersonIdIn,
						PersonPartnerIdIn);
					INSERT INTO humans.testlog
						SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partner in transactie aanwezig maar niet in de database, partner wordt in de database toegevoegd. Partner ID wordt: ', IFNULL(PersonMotherIdIn, 'null')),
							TestLogDateTime = NOW();
					SET TransResult = TransResult + 1;
				INSERT INTO humans.relations
						(RelationName, 
						RelationPerson,
						RelationWithPerson)
					VALUES
						(RelationIdOfPartner,
                        PersonPartnerIdIn,
						PersonIdIn);
					INSERT INTO humans.testlog
						SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. (Omgegekeerde toevoeging:) Partner in transactie aanwezig maar niet in de database, partner wordt in de database toegevoegd. Partner ID wordt: ', IFNULL(PersonMotherIdIn, 'null')),
							TestLogDateTime = NOW();
					SET TransResult = TransResult + 1;
			ELSE 
				UPDATE humans.relations 
					SET RelationWithPerson = PersonPartnerIdIn
						WHERE RelationPerson = PersonIdIn
						AND RelationName = RelationIdOfPartner;
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partner in transactie en in database aanwezig. Partner in database gewijzigd. Persoon= ', IFNULL(PersonIdIn, 'null'), ' en Partner ID= ', IFNULL(PersonPartnerIdIn, 'null')),
						TestLogDateTime = NOW();              
                
				UPDATE humans.relations 
					SET RelationWithPerson = PersonIdIn 
						WHERE RelationPerson = PersonPartnerIdIn
						AND RelationName = RelationIdOfPartner;                
				INSERT INTO humans.testlog
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partner in transactie en in de database aanwezig. Partner in database gewijzigd. Partner ID= ', IFNULL(PersonPartnerIdIn, 'null'), ' en Persoon= ', IFNULL(PersonIdIn, 'null')),
						TestLogDateTime = NOW();
			END IF;
		END IF;
	
    COMMIT;
	END transactionBody;
		
	INSERT INTO humans.testlog
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Transactie afgerond, alle wijzigingen zijn comitted. Calling GetPersonDetails.'),
			TestLogDateTime = NOW();

	CALL GetPersonDetails(PersonIdIn);

	END;

END