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
								 IFNULL(MessageText, "null"), "/State=", IFNULL(ReturnedSqlState, "null"), "/ErrNo=", IFNULL(MySqlErrNo, "null"), "). Rollback executed. CompletedOk= ", CompletedOk),
								 TestLogDateTime = NOW();

		SELECT CompletedOk;

	END;


main_proc:

BEGIN

SET CompletedOk = 0;

SET TransResult = 0;

SET NewTransNo = GetTranNo("ChangePerson");

INSERT INTO humans.testlog 
	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ", SPROC ChangePerson(). TransResult= ", IFNULL(transResult, null), '. Start change record for person with name ', PersonGivvenNameIn, ' ', PersonFamilyNameIn),
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

		INSERT INTO humans.testlog 
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Gegevens zijn gewijzigd van Persoon met naam= ', PersonGivvenNameIn, ' ', PersonFamilyNameIn),
				TestLogDateTime = NOW();


		-- Based on if Mother params are filled do either nothing or update or insert Mother

		-- -------------------------------------------------

		-- If Mother params are filled

		-- Determine if Person has Mother

		-- UPDATE Mother if Person already has Mother

		-- INSERT Mother if Person does not yet have Mother

		IF PersonMotherIdIn = '' OR PersonMotherIdIn = null THEN
			INSERT INTO humans.testlog
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder NIET in transactie aanwezig, als moeder in de database aanwezig is wordt ze verwijderd als moeder'),
				TestLogDateTime = NOW();
                IF fGetMother(PersonIdIn) != null THEN
					DELETE FROM humans.relations WHERE RelationPerson = PersonIDIn AND RelationName = fGetRelationId("Moeder");
                    INSERT INTO humans.testlog
                    SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder was in de database aanwezig  en is verwijderd als moeder uit de database.'),
						TestLogDateTime = NOW();
                END IF;
        ELSE
			UPDATE humans.relations 
				SET RelationWithPerson = PersonPartnerIdIn
                WHERE RelationPerson = PersonIdIn
                AND RelationName = fGetRelationId("Moeder");
            INSERT INTO humans.testlog
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder in transactie aanwezig, moeder wordt gewijzigd. Moeder ID wordt: ', IFNULL(PersonMotherIdIn, 'null')),
				TestLogDateTime = NOW();
		END IF;

		-- Based on if Father params are filled do either nothing or update or insert Father

		-- --------------------------------------------------

		-- If Father param is filled

		-- Determine if Person has Father

		-- UPDATE Father if Person already has Father

		-- INSERT Father if Person does not yet have Father

		IF PersonFatherIdIn = '' OR PersonFatherIdIn = null THEN
			INSERT INTO humans.testlog
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader NIET in transactie aanwezig, als vader in de database aanwezig is wordt hij verwijderd als vader'),
				TestLogDateTime = NOW();
			IF fGetFather(FatherIdIn) != null THEN
				DELETE FROM humans.relations WHERE RelationPerson = PersonIDIn AND RelationName = fGetRelationId("Vader");
                INSERT INTO humans.testlog
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader was in de database aanwezig  en is verwijderd als vader uit de database.'),
					TestLogDateTime = NOW();
			END IF;
        ELSE
			UPDATE humans.relations 
				SET RelationWithPerson = PersonFatherIdIn
                WHERE RelationPerson = PersonIdIn
                AND RelationName = fGetRelationId("Vader");
            INSERT INTO humans.testlog
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader in transactie aanwezig, vader wordt gewijzigd. Vader ID wordt: ', IFNULL(PersonFatherIdIn, 'null')),
				TestLogDateTime = NOW();
		END IF;
        

		-- Based on if Partner params are filled do either nothing or update or insert Partner

		-- ----------------------------------------------------

		-- If Partner param is filled

		-- Determine if Person has Partner

		-- UPDATE Partner if Person already has Partner

		-- INSERT Partner if Person does not yet have Partner

		IF PersonPartnerIdIn <> '' OR PersonPartnerIdIn <> null THEN
			INSERT INTO humans.testlog
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partner NIET in transactie aanwezig, als partner in de database aanwezig is wordt deze verwijderd uit de database.'),
				TestLogDateTime = NOW();
            IF fCheckPersonsArePartners(PersonIdIn1, PersonPartnerIdIn) THEN
				DELETE FROM humans.relations WHERE (RelationPerson = PersonIn1 OR RelationPerson = PersonIn2) AND (RelationWithPerson = PersonIn2 OR RelationWithPerson = PersonIn1) AND RelationName = fGetRelationId("Partner");
				INSERT INTO humans.testlog
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partners in de database aanwezig en verwijderd als partners uit de database.'),
					TestLogDateTime = NOW();
			END IF;
		ELSE
			UPDATE humans.relations 
				SET RelationWithPerson = PersonPartnerIdIn
                WHERE RelationPerson = PersonIdIn
                AND RelationName = fGetRelationId("Partner");
			UPDATE humans.relations 
				SET RelationWithPerson = PersonIdIn 
                WHERE RelationPerson = PersonPartnerIdIn
                AND RelationName = fGetRelationId("Partner");                
            INSERT INTO humans.testlog
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partner in transactie aanwezig. Partner in database gewijzigd. Partner ID= ', IFNULL(PersonPartnerIdIn, 'null')),
				TestLogDateTime = NOW();
		END IF;
	COMMIT;
	END transactionBody;
		
	INSERT INTO humans.testlog
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Transactie afgerond, alle wijzigingen zijn comitted. Calling GetPersonDetails.'),
			TestLogDateTime = NOW();

	CALL GetPersonDetails(PersonIdIn);

	END;

END