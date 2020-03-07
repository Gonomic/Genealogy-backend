CREATE DEFINER=`root`@`%` PROCEDURE `getPossiblePartnersBasedOnDate`(IN `DateIn` DATE)
    SQL SECURITY INVOKER
    COMMENT 'To get possible partners based on a certain date'
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

	-- --DECLARE FullNamePerson varchar(100);

	-- --DECLARE BirthDateOfPersonIn date;
    
	DECLARE MessageText CHAR;

	DECLARE ReturnedSqlState INT;

	DECLARE MySQLErrNo INT;
        
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
 	BEGIN

		GET CURRENT DIAGNOSTICS CONDITION 1 MessageText = message_text, ReturnedSqlState = RETURNED_SQLSTATE, MySqlErrNo = MYSQL_ERRNO;
        
		ROLLBACK;

		SET CompletedOk = 2;

		INSERT INTO humans.testlog 

			SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), " SPROC getPossiblePartnersBasedOnDate(). Error occured(M=", 
								 IFNULL(MessageText, "null"), "/State=", IFNULL(ReturnedSqlState, "null"), "/ErrNo=", IFNULL(MySqlErrNo, "null"), "). Rollback executed. CompletedOk= ", CompletedOk),

				TestLogDateTime = NOW();

		SELECT CompletedOk;

	END;

main_proc:

BEGIN

	SET CompletedOk = 0;

    SET TransResult = 0;

    SET NewTransNo = GetTranNo("getPossiblePartnersBasedOnDate");

    -- Schrijf start van deze SQL transactie naar log
    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), ' START Sproc: getPossiblePartnersBasedOnDate(). TransResult= ', IFNULL(TransResult, 'null'), '. Start opbouwen tabel met mogelijke partners gebaseerd op datum= ', IFNULL(DateIn, 'null')),
			TestLogDateTime = NOW();


    SELECT DISTINCT

        P.PersonID as PersonID, 

		concat(P.PersonGivvenName, ' ', P.PersonFamilyName) as PossiblePartner,

		P.PersonDateOfBirth

		FROM persons P 

		WHERE 
			YEAR(P.PersonDateOfBirth) > (YEAR(DateIn) - 15)
    
			AND YEAR(P.PersonDateOfBirth) < (YEAR(DateIn) + 15)

		ORDER BY P.PersonDateOfBirth;    

	INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. END Sproc: getPOssiblePartnersBasedOnDate(). TransResult= ', IFNULL(TransResult, 'null'), '. Lijst met mogelijke partners afgerond.'),

				TestLogDateTime = NOW();
 END;
 
 END