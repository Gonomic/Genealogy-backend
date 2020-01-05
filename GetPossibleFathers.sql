DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `getPossibleFathers`(IN `PersonIDin` INT(11))
    SQL SECURITY INVOKER
    COMMENT 'To get the possible fathers of a person based on the persons birthdate'
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

	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION

	BEGIN

		-- SET MessageText = MESSAGE_TEXT;

		-- SET ReturnedSqlState = RETURNED_SQLSTATE;

		-- SET MySQLErrNo = MYSQL_ERRNO;

		-- GET CURRENT DIAGNOSTICS CONDITION 1 MessageText : MESSAGE_TEXT, ReturnedSqlState : RETURNED_SQLSTATE, MySqlErrNo : MYSQL_ERRNO;

		ROLLBACK;

		SET CompletedOk = 2;

		INSERT INTO humans.testlog 

			SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), ". ", "Error occured. Rollback executed. CompletedOk= ", CompletedOk),

				TestLogDateTime = NOW();

		SELECT CompletedOk;

	END;



main_proc:

BEGIN



    SET CompletedOk = 0;



    SET TransResult = 0;



    SET NewTransNo = GetTranNo("getPossibleFathers");



    -- Schrijf start van deze SQL transactie naar log

    INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Start opbouwen tabel met mogelijke vaders voor persoon met ID= ', PersonIdIn),

		TestLogDateTime = NOW();



	SELECT DISTINCT

    

    -- Mogelijke vader:

    P.PersonID as PossibleFatherID, 

    concat(P.PersonGivvenName, ' ', P.PersonFamilyName) as PossibleFather

    

    FROM persons P 



    -- Mogelijke vader moet man zijn

    WHERE P.PersonIsMale = true



    -- Minimale leeftijd waarop de mogelijke vader, vader is geworden is 15 (geboortedatum vaqder = geboordedatum kind - 15 jaar)

    AND YEAR(P.PersonDateOfBirth) 

		<  

		(SELECT YEAR(PersonDateOfBirth) - 15

        FROM persons 

        WHERE PersonID = PersonIDin)



    -- Maximale leeftijd waarop de mogelijke vader, vader is geworden is 50 jaar (geboortedatum vader = geboortedatum kind - 50 jaar)

	AND YEAR(P.PersonDateOfBirth) 

		>  

		(SELECT YEAR(PersonDateOfBirth) - 50

        FROM persons 

        WHERE PersonID = PersonIDin) 

        

	-- Mogelijke vader mag niet de partner zijn

    AND P.PersonID NOT IN 

		(SELECT RelationWithPerson

		 FROM relations R

		 JOIN (relationnames RN, persons P)

		 ON (R.RelationName = RN.RelationnameID AND 

			 P.PersonID = R.RelationPerson AND 

			 RN.RelationnameName = "Partner")

		 WHERE P.PersonID = PersonIDin)

           

    ORDER BY P.PersonDateOfBirth;

    

    INSERT INTO humans.testlog

			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, 'null'), '. Lijst met mogelijke vader afgerond.'),

				TestLogDateTime = NOW();

 END;

END$$
DELIMITER ;
