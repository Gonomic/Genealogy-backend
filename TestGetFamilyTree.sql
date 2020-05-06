CREATE DEFINER=`root`@`%` PROCEDURE `TestGetFamilyTree`(PersonToStartWith int, NumberOfGenerationsToGoUp int, NumberOfGenerationsToGoDown int, InclusivePartners bool)
BEGIN
	    
	DECLARE GenerationStartingLevel INT DEFAULT 0;
    DECLARE GenerationCounter INT;
    DECLARE pMother INT;
    DECLARE MotherAsNExtPerson INT;
    DECLARE FatherAsNextPerson INT;
    DECLARE PartnerAsNextPerson INT;
    DECLARE pFather INT;
    DECLARE pPartner INT;
    DECLARE pPersonsParentsPartners INT;
    DECLARE FatherFoundAsPerson BOOL;
    DECLARE MotherFoundAsPerson BOOL;
    DECLARE NextPerson INT;
    DECLARE NextPersonToGetChildrenFor INT;
    DECLARE PersonToFindBack INT;
    DECLARE PartnerToFindBack INT;
    DECLARE CompletedOk INT;
    DECLARE NewTransNo INT;
    DECLARE TransResult INT;
    DECLARE PersonAlreadyInFamilyTree INT;
    DECLARE RecordIndex INT;
    DECLARE Generation_level INT DEFAULT 0;
    DECLARE Finished INT DEFAULT 0;
    DECLARE Walkthrough CURSOR FOR SELECT PersonId,  
											CONCAT(PersonGivvenName, " ", PersonFamilyName) as PersonName, 
                                            PersonDateOfBirth as PersonBirth, 
                                            PersonDateOfDeath as PersonDeath, 
                                            PersonIsMale,
                                            fGetFather(PersonToStartWith) AS PersonFather,
                                            fGetMother(PersonToStartWith) AS PersonMother, 
                                            fGetPartner(PersonToStartWith) AS PersonPartner,
                                            fCheckIfParentsAreAlsoPartners(PersonId) as ParentsAreAlsoPartners,
                                            Generation_level AS Generation
                                            FROM persons where persons.PersonId = PersonToStartWith;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finished = 1;
    
    
    SET CompletedOk = true;
    SET TransResult = 0;
    
    OPEN Walkthrough;
    buildTree: LOOP
    
		INSERT INTO Walkthrough (PersonId, PersonName, PersonBirth, PersonDeath, PersonIsMale, PersonsFather, PersonsMother, PersonsPartner, ParentsAreAlsoPartners, Generation)
		SELECT DISTINCT PersonID as PersonId, 
						CONCAT(PersonGivvenName, " ", PersonFamilyName) as PersonName,
                        PersonDateOfBirth as PersonBirth, 
                        PersonDateOfDeath as PersonDeath, 
                        PersonIsMale,
                        fGetFather(PersonID) AS PersonsFather, 
                        fGetMother(PersonID) AS PersonsMother, 
                        fGetPartner(PersonID) as PersonsPartner, 
                        fCheckIfParentsAreAlsoPartners(PersonId) as ParentsAreAlsoPartners,
                        @Generation_level as Generation FROM persons 
		WHERE PersonID IN 
				(SELECT RelationPerson FROM relations
				WHERE RelationWithPerson = PersonToStartWith 
				AND (RelationName = 1 OR RelationName = 2));
    
		IF Finished = 1 THEN
			LEAVE buildTree;
		END IF;
	END LOOP buildTree;
    CLOSE Walkthrough;
    
    
    
    -- SET @Generation_level = 0;
    SET NewTransNo = GetTranNo("GetFamilyTree");
    
    INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
        '. TransResult= ', IFNULL(TransResult, ''),
        '. Start SPROC: GetFamilyTree() voor persoon met ID= ', IFNULL(PersonToStartWith, 'null'),
        '. Number of generations to go up= ', IFNULL(NumberOfGenerationsToGoUp, 'null'),
        '. Number of generations to go down= ', IFNULL(NumberOfGenerationsToGoDown, 'null'),
        '. Include partner= ', IFNULL(InclusivePartners, 'null')),
		TestLogDateTime = NOW();

     
     INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
			'. TransResult= ', IFNULL(TransResult, ''),
			'. Opslaan data voor persoon met ID= ', IFNULL(PersonToStartWith, 'null')),
			TestLogDateTime = NOW();
            
   --  CREATE TEMPORARY TABLE IF NOT EXISTS FamilyTree(
		-- RecordId  INT NOT NULL AUTO_INCREMENT,
        -- PersonId INT NOT NULL,
        -- PersonName CHAR(50),
        -- PersonIsMale BOOL,
        -- PersonBirth DATE,
        -- PersonDeath DATE,
        -- PersonsFather INT,
        -- FatherFetched BOOL,
        -- PersonsMother INT,
        -- MotherFetched BOOL,
        -- PersonsParentsArePartners BOOL,
        -- PersonsPartner INT,
        -- PartnerFetched BOOL,
        -- Generation INT,
        -- ParentsAreAlsoPartners BOOL,
        -- PRIMARY KEY (RecordId, PersonId))
	-- AS       
      -- select PersonId,  CONCAT(PersonGivvenName, " ", PersonFamilyName) as PersonName,  PersonDateOfBirth as PersonBirth, PersonDateOfDeath as PersonDeath, PersonIsMale FROM persons where persons.PersonId = PersonToStartWith;
     
    -- SET pMother = fGetMother(PersonToStartWith);
	-- SET pFather = fGetFather(PersonToStartWith);
	-- SET pPartner = fGetPartner(PersonToStartWith);  
	
    -- UPDATE FamilyTree SET PersonsFather = pFather, FatherFetched = false, PersonsMother = pMother, MotherFetched=false, PersonsPartner = pPartner, PartnerFetched=false, PersonsParentsArePartners = pPersonsParentsPartners, Generation=@Generation_level WHERE (PersonId = PersonToStartWith AND RecordId <> 0);
    
    -- SET @Generation_level = @Generation_level + 1;
    -- SET GenerationCounter = GenerationStartingLevel + 1;
    -- SET RecordIndex = 1;
    
	INSERT INTO humans.testlog 
		SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
			'. TransResult= ', IFNULL(TransResult, ''),
			'. =====>> Going down! Getting all (grand) children (down to the requested level) for person= ', IFNULL(PersonToStartWith, 'null')),
			TestLogDateTime = NOW();
   
	
                  
	IF InclusivePartners = 1 THEN
		
        INSERT INTO humans.testlog 
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
					'. TransResult= ', IFNULL(TransResult, ''),
					'. ----->> Before inclusive partner. RecordIndex= ', IFNULL(RecordIndex, 'null')),
					TestLogDateTime = NOW();
                    
		IF EXISTS (SELECT RecordId FROM FamilyTree WHERE RecordId = RecordIndex) THEN
			SELECT PersonId, PersonsPartner INTO @PersonToFindBack, @PartnerToFindBack FROM FamilyTree WHERE RecordId = RecordIndex;
            
			INSERT INTO humans.testlog 
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
					'. TransResult= ', IFNULL(TransResult, ''),
					'. ----->> Before inclusive partner. Finding partner= ', IFNULL(@PartnerToFindBack, 'null'), ' for person= ', IFNULL(@PersonToFindBack, 'null')),
					TestLogDateTime = NOW();
    

			INSERT INTO FamilyTree (PersonId, PersonName, PersonBirth, PersonDeath, PersonsFather, PersonsMother, PersonIsMale)
			SELECT DISTINCT PersonID as PersonId,  CONCAT(PersonGivvenName, " ", PersonFamilyName) as PersonName,  PersonDateOfBirth as PersonBirth, PersonDateOfDeath as PersonDeath, fGetFather(PersonID) AS PersonsFather, fGetMother(PersonID) AS PersonsMother, PersonIsMale 
				FROM persons JOIN relations ON persons.PersonID = relations.RelationWithPerson 
					WHERE RelationPerson =  @PersonToFindBack
						AND RelationWithPerson = @PartnerToFindBack 
						AND RelationName = 3;
               
			INSERT INTO humans.testlog 
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
					'. TransResult= ', IFNULL(TransResult, ''),
					'. ----->> After inclusive partner'),
					TestLogDateTime = NOW();
                   
		END IF;
	END IF;
   
   SET GenerationCounter = GenerationStartingLevel + 1;
                    
	
    going_down: LOOP
    
		INSERT INTO humans.testlog 
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
				'. TransResult= ', IFNULL(TransResult, ''),
				'. ++++++++++++++++=> Looping. Top of loop. RecordIndex= ', IFNULL(RecordIndex, 'null'), '. RowCount=',  RowCountForFamilyTree()),
				TestLogDateTime = NOW();
    
		
        IF RecordIndex <= (RowCountForFamilyTree() + 5) THEN 
        
			INSERT INTO humans.testlog 
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
					'. TransResult= ', IFNULL(TransResult, ''),
					'. ++++++++++++++++=> Looping. First step of loop. RecordIndex= ', IFNULL(RecordIndex, 'null'), '. RowCount=',  RowCountForFamilyTree()),
					TestLogDateTime = NOW();
        
 			SELECT DISTINCT PersonId from FamilyTree WHERE RecordId = RecordIndex LIMIT 1 INTO NextPersonToGetChildrenFor; 
            
            IF NextPersonToGetChildrenFor = 0 THEN
				INSERT INTO humans.testlog 
					SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
						'. TransResult= ', IFNULL(TransResult, ''),
						'. ++++++++++++++++=> Looping. NextPersonToGetChildrenFor IS NULL'),
						TestLogDateTime = NOW();
				
            ELSE
            
				INSERT INTO humans.testlog 
				SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
					'. TransResult= ', IFNULL(TransResult, ''),
					'. ++++++++++++++++=> Looping. Second step. Finding the (grand)children for grandfather/mother= ', IFNULL(PersonToStartWith, 'null'), ' and father/mother (NextPersonTogetChildrenFor)=', IFNULL(NextPersonToGetChildrenFor, 'null'), ' WITHOUT the partners of the (grand)children.'),
					TestLogDateTime = NOW();
				
				INSERT IGNORE INTO FamilyTree (PersonId, PersonName, PersonBirth, PersonDeath, PersonsFather, PersonsMother, PersonsPartner, PersonIsMale)
				SELECT DISTINCT PersonID as PersonId,  CONCAT(PersonGivvenName, " ", PersonFamilyName) as PersonName,  PersonDateOfBirth as PersonBirth, PersonDateOfDeath as PersonDeath, fGetFather(PersonID) AS PersonsFather, fGetMother(PersonID) AS PersonsMother, fGetPartner(PersonID) as PersonsPartner, PersonIsMale FROM persons 
					WHERE PersonID IN 
						(SELECT RelationPerson FROM relations
						 WHERE RelationWithPerson = NextPersonToGetChildrenFor 
						 AND (RelationName = 1 OR RelationName = 2));
                         
                         
				IF InclusivePartners = 1 THEN
					INSERT INTO humans.testlog 
						SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
						'. TransResult= ', IFNULL(TransResult, ''),
						'. ++++++++++++++++=> Looping. Second step. Finding the partners for the (grand)children of grandfather/mother= ', IFNULL(PersonToStartWith, 'null'), ' and father/mother (NextPersonTogetChildrenFor)=', IFNULL(NextPersonToGetChildrenFor, 'null')),
						TestLogDateTime = NOW();
                        
                        
					
                    INSERT IGNORE INTO FamilyTree (PersonId, PersonName, PersonBirth, PersonDeath, PersonsFather, PersonsMother, PersonsPartner, PersonIsMale)
					SELECT DISTINCT PersonID as PersonId,  CONCAT(PersonGivvenName, " ", PersonFamilyName) as PersonName,  PersonDateOfBirth as PersonBirth, PersonDateOfDeath as PersonDeath, fGetFather(PersonID) AS PersonsFather, fGetMother(PersonID) AS PersonsMother, fGetPartner(PersonID) as PersonsPartner, PersonIsMale FROM persons 
					WHERE PersonID IN   
						(SELECT DISTINCT RelationPerson FROM relations WHERE RelationName = 3 AND RelationWithPerson IN
							(SELECT RelationPerson FROM relations
							WHERE RelationWithPerson = NextPersonToGetChildrenFor 
							AND (RelationName = 1 OR RelationName = 2)));
					
                        
				END IF;
				SET NextPersonToGetChildrenFor = 0;
 			END IF;
			SET RecordIndex = RecordIndex  + 1;      
		ELSE 
			LEAVE going_down;
        END IF;
        
		SET GenerationCounter = GenerationCounter + 1;
        IF GenerationCounter = NumberOfGenerationsToGoDown THEN
				LEAVE going_down;
		END IF;
    END LOOP going_down;
    
    SELECT * FROM FamilyTree;
    
    DROP TEMPORARY TABLE FamilyTree;
    
    INSERT INTO humans.testlog 
			SET TestLog = CONCAT('TransAction-', IFNULL(NewTransNo, 'null'), 
				'. TransResult= ', IFNULL(TransResult, ''),
				'. Einde SPROC: GetFamilyTRee() voor persoon met ID= ', IFNULL(PersonToStartWith, 'null')),
				TestLogDateTime = NOW();
	END