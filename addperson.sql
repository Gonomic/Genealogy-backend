CREATE DEFINER=`root`@`%` PROCEDURE `AddPerson`(IN `PersonIdIn` INT(11), 
												IN `PersonGivvenNameIn` VARCHAR(25), 
                                                IN `PersonFamilyNameIn` VARCHAR(50), 
                                                IN `PersonDateOfBirthIn` DATETIME, 
                                                IN `PersonPlaceOfBirthIn` VARCHAR(50), 
                                                IN `PersonDateOfDeathIn` DATETIME, 
                                                IN `PersonPlaceOfDeathIn` VARCHAR(50), 
                                                IN `PersonIsMaleIn` TINYINT(1), 
                                                IN `PersonPartnerIdIn` INT(11), 
                                                IN `PersonFatherIdIn` INT(11), 
                                                IN `PersonMotherIdIn` INT(11))
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

		CALL GetPersonDetails(PersonIdIn);

	END;


main_proc:

BEGIN

START TRANSACTION;

SET CompletedOk = 0;

SET TransResult = 0;

SET NewTransNo = GetTranNo("AddPerson");

INSERT INTO humans.testlog 
	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), " SPROC AddPerson(). TransResult= ", TIFNULL(transResult, null), '. Start add record for person with ID= ', PersonIdIn),
		TestLogDateTime = NOW();
        
 INSERT INTO humans.testlog 
	SET TestLog = concat('TransAction-', IFNULL(NewTransNo, 'null'), '. SPROV AddPerson() ',
							  'Toevoegen nieuwe persoon=> ', 
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

INSERT INTO humans.persons

			(PersonGivvenName, 

			PersonFamilyName, 

			PersonDateOfBirth, 

			PersonPlaceOfBirth, 

			PersonDateOfDeath, 

			PersonPlaceOfDeath, 

			PersonIsMale)

		VALUES
        
			(PersonGivvenNameIn,

			PersonFamilyNameIn,

			PersonDateOfBirthIn,

			PersonPlaceOfBirthIn,

			PersonDateOfDeathIn,

			PersonPlaceOfDeathIn,

			PersonIsMaleIn);
        

SET TransResult = 1;

SET RecCount = 0;

INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Gegevens zijn toegevoegd van Persoon met ID= ', PersonIdIn),
		TestLogDateTime = NOW();


-- Based on if Mother params are filled do either nothing or update or insert Mother

-- -------------------------------------------------

-- If Mother params are filled

-- Determine if Person has Mother

-- UPDATE Mother if Person already has Mother

-- INSERT Mother if Person does not yet have Mother

IF PersonMotherIn <> '' OR PersonMotherIn <> null THEN

	INSERT INTO humans.testlog
	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Moeder in transactie aanwezig. Moeder ID= ', IFNULL(PersonMotherIdIn, 'null')),
		TestLogDateTime = NOW();

		SET RecCount = 

				(SELECT COUNT(*)

					FROM relations R

					JOIN relationnames RN

						ON R.RelationName = RN.RelationnameID

					WHERE R.RelationPerson = PersonIDIn AND

						RN.RelationnameName = "Moeder");

		INSERT INTO humans.testlog

		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. In database aantal gevonden moeders= ', IFNULL(RecCount, '0')),

		TestLogDateTime = NOW();

		IF RecCount > 0 THEN

			-- Als moeder wel bestaat;

			UPDATE relations R, relationnames RN

			SET R.RelationWithPerson=PersonMotherIdIn

			WHERE R.RelationName = RN.RelationnameID AND

					R.RelationPerson = PersonIdIn AND 

					RN.RelationnameName = "Moeder";

			SET TransResult = TransResult + 1;

			INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Moeder gevonden in database en updated.'),

			TestLogDateTime = NOW();

		ELSEIF RecCount <= 0 THEN

				-- Als moeder NIET bestaat;

				SET @RelNameID = (SELECT RelationnameID FROM relationnames WHERE RelationnameName = "Moeder");

				INSERT INTO relations

				SET RelationName = @RelNameId,

					RelationPerson = PersonIDIn,

					RelationWithPerson = PersonMotherIdIn;

				SET TransResult = TransResult + 1;

				INSERT INTO humans.testlog

				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Toegevoegd in database moeder met ID= ', IFNULL(PersonMotherIdIn, 'null')),

				TestLogDateTime = NOW();

			END IF;

		END IF;

		

		

-- Based on if Father params are filled do either nothing or update or insert Father

-- --------------------------------------------------

-- If Father param is filled

-- Determine if Person has Father

-- UPDATE Father if Person already has Father

-- INSERT Father if Person does not yet have Father

IF PersonFatherIn <> '' OR PersonFatherIn <> null THEN

	INSERT INTO humans.testlog

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Vader in transactie aanwezig. Vader ID= ', IFNULL(PersonFatherIdIn, 'null')),

		TestLogDateTime = NOW();

	SET RecCount = 

			(SELECT COUNT(*)

				FROM relations R

				JOIN relationnames RN

					ON R.RelationName = RN.RelationnameID

				WHERE R.RelationPerson = PersonIDIn AND

					RN.RelationnameName = "Vader");

	INSERT INTO humans.testlog

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. In database aantal gevonden vaders= ', IFNULL(RecCount, '0')),

		TestLogDateTime = NOW();

	IF RecCount > 0 THEN

		-- Als vader wel bestaat;

		UPDATE relations R, relationnames RN

		SET R.RelationWithPerson=PersonFatherIdIn

		WHERE R.RelationName = RN.RelationnameID AND

				R.RelationPerson = PersonIDIn AND 

				RN.RelationnameName = "Vader";

		SET TransResult = TransResult + 1;

		INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Vader gevonden in database en updated.'),

				TestLogDateTime = NOW();

	ELSEIF RecCount <= 0 THEN

		-- Als vader NIET bestaat;

		SET @RelNameID = (SELECT RelationnameID FROM relationnames WHERE RelationnameName = "Vader");

		INSERT INTO relations

			SET RelationName = @RelNameID,

				RelationPerson = PersonIDIn,

				RelationWithPerson = PersonFatherIdIn;

		SET TransResult = TransResult + 1;

		INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Toegevoegd in database vader met ID= ', IFNULL(PersonFatherIdIn, 'null')),

				TestLogDateTime = NOW();

	END IF;

END IF;

		

		

-- Based on if Partner params are filled do either nothing or update or insert Partner

-- ----------------------------------------------------

-- If Partner param is filled

-- Determine if Person has Partner

-- UPDATE Partner if Person already has Partner

-- INSERT Partner if Person does not yet have Partner

IF PersonPartnerIn <> '' OR PersonPartnerIn <> null THEN

	INSERT INTO humans.testlog

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Partner in transactie aanwezig. Partner ID= ', IFNULL(PersonPartnerIdIn, 'null')),

		TestLogDateTime = NOW();

	SET RecCount = 

		(SELECT COUNT(*)

			FROM relations R

			JOIN relationnames RN

				ON R.RelationName = RN.RelationnameID

			WHERE R.RelationPerson = PersonIDIn AND

				RN.RelationnameName = "Partner");

	INSERT INTO humans.testlog

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. In database aantal gevonden partners= ', IFNULL(RecCount, '0')),

		TestLogDateTime = NOW();

	IF RecCount > 0 THEN

		-- Als partner wel bestaat;

		-- -> Update Partner for this Person

		UPDATE relations R, relationnames RN

		SET R.RelationWithPerson=PersonPartnerIdIn

		WHERE R.RelationName = RN.RelationnameID AND

				R.RelationPerson = PersonIDIn AND 

				RN.RelationnameName = "Partner";

		SET TransResult = TransResult + 1;

		INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Partner in database en updated.'),

				TestLogDateTime = NOW();

		-- -> Update as well Partner field for the other person (the partner)

		UPDATE relations R, relationnames RN

		SET R.RelationPerson=PersonPartnerIdIn,

			R.RelationWithPerson=PersonIDIn

		WHERE R.RelationName = RN.RelationnameID AND

				R.RelationPerson = PersonPartnerIdIn AND

				R.RelationWithPerson=PersonIdIn AND

				RN.RelationnameName = "Partner";

		SET TransResult = TransResult + 1;

		INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Reverse partner gevonden in database en updated.'),

				TestLogDateTime = NOW();

	ELSEIF RecCount <= 0 THEN

		-- Als partner NIET bestaat;

		-- -> Insert Partner for tis Person

		SET @RelNameID = (SELECT RelationnameID FROM relationnames WHERE RelationnameName = 'Partner');

		INSERT INTO relations

		SET RelationName = @RelNameID,

			RelationPerson = PersonIDIn,

			RelationWithPerson = PersonPartnerIdIn;

		SET TransResult = TransResult + 1;

		INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Partner toegevoegd aan database ID= ', PersonPartnerIdIn),

				TestLogDateTime = NOW();

		-- -> Insert as well Partner field for the other Person (the partner) bot now for this Person as partner

		INSERT INTO relations

		SET RelationName = @RelNameID,

			RelationPerson = PersonPartnerIDIn,

			RelationWithPerson = PersonIDIn;

		SET TransResult = TransResult + 1;

		INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Reverse Partner toegevoegd aan database ID= ', PersonIDIn),

				TestLogDateTime = NOW();

	END IF;

END IF;  

COMMIT;

INSERT INTO humans.testlog

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. Transactie afgerond, alle wijzigingen zijn comitted. Calling GetPersonDetails.'),

		TestLogDateTime = NOW();

CALL GetPersonDetails(PersonIdIn);

END;

END