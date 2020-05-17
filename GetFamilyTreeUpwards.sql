CREATE DEFINER=`root`@`172.%` PROCEDURE `GetFamilyTreeUpwards`(IN personIdIn INT, IN numberOfGenerationsIn INT)
BEGIN
    WITH RECURSIVE FamTree (Limitter, PersonId, PersonName, PersonBirth, PersonDeath, PersonIsMale, Father, Mother, Partner) AS 
    (
        SELECT	1 as Limitter, 
				PersonID, 
                CONCAT(PersonGivvenName, ' ', PersonFamilyName) as PersonName,
				PersonDateOfBirth, 
				PersonDateOfDeath, 
				PersonIsMale,
				rf.RelationWithPerson as Father,
                rm.RelationWithPerson as Mother,
                rp.RelationWithPerson as Partner
			FROM persons p 
            LEFT JOIN relations rf ON p.PersonID = rf.RelationPerson AND rf.RelationName = "1"
            LEFT JOIN relations rm ON p.PersonID = rm.RelationPerson AND rm.RelationName = "2"            
            LEFT JOIN relations rp ON p.PersonID = rp.RelationPerson AND rp.RelationName = "3"      
            WHERE p.PersonId = personIdIn
	    UNION ALL
        SELECT	Limitter + 1,
				p.PersonID, 
                CONCAT(p.PersonGivvenName, ' ', p.PersonFamilyName) as PersonName,
				p.PersonDateOfBirth, 
				p.PersonDateOfDeath, 
				p.PersonIsMale,
				rf.RelationWithPerson as Father,
                rm.RelationWithPerson as Mother,
                rp.RelationWithPerson as Partner
 			FROM persons p 
            LEFT JOIN relations rf ON p.PersonID = rf.RelationPerson AND rf.RelationName = "1"
            LEFT JOIN relations rm ON p.PersonID = rm.RelationPerson AND rm.RelationName = "2"            
            LEFT JOIN relations rp ON p.PersonID = rp.RelationPerson AND rp.RelationName = "3"      
            INNER JOIN FamTree FT ON FT.Father = p.PersonID  
			WHERE Limitter < numberOfGenerationsIn
	) 
    SELECT * FROM FamTree ORDER BY PersonBirth; 
END