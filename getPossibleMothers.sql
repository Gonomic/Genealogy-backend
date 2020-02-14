CREATE DEFINER=`root`@`%` PROCEDURE `getPossibleMothers`(IN `PersonIDin` INT(11))
    SQL SECURITY INVOKER
    COMMENT 'To get the possible mothers of a person based on the persons birthdate'
BEGIN

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

	DECLARE FullNamePerson varchar(100);

	DECLARE BirthDateOfPersonIn date;
    
	DECLARE MessageText CHAR;

	DECLARE ReturnedSqlState INT;

	DECLARE MySQLErrNo INT;
        
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
 	BEGIN

		GET CURRENT DIAGNOSTICS CONDITION 1 MessageText = message_text, ReturnedSqlState = RETURNED_SQLSTATE, MySqlErrNo = MYSQL_ERRNO;
        
		ROLLBACK;

		SET CompletedOk = 2;

		INSERT INTO humans.testlog 

			SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), " SPROC getPossibleMothers(). Error occured(M=", 
								 IFNULL(MessageText, "null"), "/State=", IFNULL(ReturnedSqlState, "null"), "/ErrNo=", IFNULL(MySqlErrNo, "null"), "). Rollback executed. CompletedOk= ", CompletedOk),

				TestLogDateTime = NOW();

		SELECT CompletedOk;

	END;

main_proc:

BEGIN

    SET CompletedOk = 0;

    SET TransResult = 0;

    SET NewTransNo = GetTranNo("getPossibleMothers");

    -- Schrijf start van deze SQL transactie naar log
    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ' START Sproc: getPossibleMothers(). TransResult= ', TransResult, '. Start opbouwen tabel met mogelijke moeders voor persoon met ID= ', PersonIdIn),
			TestLogDateTime = NOW();

    
    SET BirthDateOfPersonIn = fGetBirthDateOfPerson(PersonIDin);

	SELECT DISTINCT

		PersonID, 

		concat(PersonGivvenName, ' ', PersonFamilyName) as PossibleMother,
        
        PersonDateOfBirth as BirthDate,
        
        PersonDateOfDeath 
        
    FROM persons  

		WHERE PersonID <> PersonIDin

		AND YEAR(PersonDateOfBirth) < (YEAR(BirthDateOfPersonIn) - 15)

		AND YEAR(PersonDateOfBirth) > (YEAR(BirthDateOfPersonIn) - 55)
        
        AND PersonIsMale = false
        
      
        -- AND PersonID NOT in
        
		--  	(SELECT RelationPerson
        --     FROM relations
        --     WHERE RelationPerson = PersonID
        --     AND RelationName = 1
        --     OR RelationName = 2)

       ORDER BY persons.PersonDateOfBirth;

    INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. END Sproc: getPOssibleMothers(). TransResult= ', IFNULL(TransResult, 'null'), '. Lijst met mogelijke moeders afgerond.'),

				TestLogDateTime = NOW();

 END;

END