CREATE DEFINER=`root`@`%` PROCEDURE `GetPlainListOfPersons`(NameInLike char(30))
BEGIN
	-- ----------------------------------------------------------------------------------------------------------------------------------------------
    -- Author: 	Frans Dekkers (GoNomics)
    -- Date:	10-01-2019
    -- -----------------------------------
    -- Prurpose of this Sproc:
    -- Return a list with names of Persons in order to let user see if a person already exist before adding persons or to change or delete a person's data
    -- 
    -- Parameters of this Sproc:
    -- 'NameInLike'= String in used to find people who's name is like the givven string
    -- 
    -- High level flow of this Sproc:
    -- => Simply find all persons with a familyname that is like the gvven string and send back some basic data of the found persons
    --   
    -- Note:	None
    --		
    -- TODO's:
    -- => --/--/-- None
    -- ----------------------------------------------------------------------------------------------------------------------------------------------
    
    DECLARE CompletedOk INT;
    DECLARE NewTransNo INT;
    DECLARE TransResult INT;
	
    SET CompletedOk = true;
    SET TransResult = 0;
    SET NewTransNo = GetTranNo("GetPlainListOfPersons");
    
    SET NameInLike = CONCAT(NameInLike, '%');
    
    SELECT NameInLike;
    
    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), '. TransResult= ', IFNULL(TransResult, ''),
							 '. Start SPROC: GetPlainListOfPersons(). Get all persons who s name is like:', IFNULL(NameInLike, 'null')),
			TestLogDateTime = NOW();
    
	SELECT PersonID, CONCAT(PersonFamilyName, ", ", PersonGivvenName) as Name, PersonDateOfBirth as Birth, PersonIsMale as Gender
	FROM persons
	WHERE PersonFamilyName LIKE NameInLike;
        
       
	INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
			'. TransResult= ', IFNULL(TransResult, ''),
			'. End SPROC: GetPlainListOfPersons(). Got all persons who s name is like: ', IFNULL(NameInLike, 'null')),
			TestLogDateTime = NOW();
   

	
END