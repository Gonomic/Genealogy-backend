DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `deletePerson`(IN `PersonIdIn` INT, IN `TimestampIn` DATETIME)
    SQL SECURITY INVOKER
    COMMENT 'To delete a Person from the database, incl. links from Family to this Person.'
BEGIN

	-- CompletedOk defines the result of a database transaction, like this:

    -- 0 = Transaction finished without problems.

    -- 1 = Transaction aborted due to Person's details changed in the mean time

    -- 2 = Transaction aborted due to problems during update and rollback performed

    -- ...

    DECLARE CompletedOk int;



    -- NewTransNo is autonumber counter fetched from a seperate table and used for logging in a seperate log table

	DECLARE NewTransNo int;



    -- TransResult is used to count the number of seperate database operations and rissen with each step

	DECLARE TransResult int;



    -- RecCount is used to count the number of related records in depended tables.

	DECLARE RecCount int;



	DECLARE EXIT HANDLER FOR SQLEXCEPTION

	BEGIN

		ROLLBACK;

		SET CompletedOk = 2;

		INSERT INTO humans.testLog 

			SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), ". TransResult= ", TransResult, ". Error occured in SPROC: deletePerson(). Rollback executed. CompletedOk= ", CompletedOk),

				TestLogDateTime = NOW();

		SELECT CompletedOk;

	END;



main_proc:

BEGIN

    SET CompletedOk = 0;



    SET TransResult = 0;



    SET NewTransNo = GetTranNo("deletePerson");



    -- Schrijf start van deze SQL transactie naar log

    INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Start SPROC: deletePerson() voor persoon met ID= ', PersonIdIn),

		TestLogDateTime = NOW();



    IF RecordHasBeenChangedBySomebodyElse(PersonIdIn, TimeStampIn) THEN

	    SET CompletedOk = 1;

	    INSERT INTO humans.testLog 

		    SET TestLog = CONCAT("Transaction-", IFNULL(NewTransNo, "null"), ". TransResult= ", TransResult, ". Records has been changed in mean time. Update aborted."),

			    TestLogDateTime = NOW();

	    SELECT CompletedOk;

	    LEAVE main_proc;

    END IF;



    -- Delete all refferences from family relative to this person

    DELETE FROM relations 

    WHERE RelationPerson = PersonIdIn;

    SET TransResult = TransResult + 1;

    INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Alle familie referenties verwijderd vanaf persoon met ID= ', PersonIdIn),

		TestLogDateTime = NOW();





    -- Delete all references from this person to family relatives

    DELETE FROM relations

    WHERE RelationWithPerson= PersonIdIn;

    SET TransResult = TransResult + 1;

    INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Alle familie referenties verwijderd naar persoon met ID= ', PersonIdIn),

		TestLogDateTime = NOW();





    -- Delete all adresses from this person to family relatives

    DELETE FROM adresses

    WHERE Person = PersonIdIn;

    SET TransResult = TransResult + 1;

    INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Alle adressen verwijderen van persoon met ID= ', PersonIdIn),

		TestLogDateTime = NOW();





    -- Delete Person record itself.

    DELETE FROM persons

    WHERE PersonID = PersonIdIn;

    INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. Persoon verwijderd met ID= ', PersonIdIn),

		TestLogDateTime = NOW();



    SELECT CompletedOk;

    INSERT INTO humans.testlog 

	SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', TransResult, '. SPROC DeletePerson afgerond. CompletedOk= ', CompletedOk),

		TestLogDateTime = NOW();



END ;

END$$
DELIMITER ;
