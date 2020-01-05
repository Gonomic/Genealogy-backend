DELIMITER $$
CREATE DEFINER=`root`@`%` PROCEDURE `getPossiblePartners`(IN `PersonIDin` INT(11))
    SQL SECURITY INVOKER
    COMMENT 'To get the possible partners of a person based on the persons birth'
BEGIN

	/* This procedure takes into account that Fathers and Mothers as well as Sisters and Brothers */

    /* may not be returned as (possible) partners */

    SELECT DISTINCT

    

    P.PersonID as PossiblePartnerID, 

    concat(P.PersonGivvenName, ' ', P.PersonFamilyName) as PossiblePartner,

    P.PersonDateOfBirth

    

    FROM persons P 

    

    WHERE P.PersonID <> PersonIDin

    

    AND YEAR(P.PersonDateOfBirth) 

		>  

		(SELECT YEAR(PersonDateOfBirth) - 15

        FROM persons 

        WHERE PersonID = PersonIDin)

	

    AND YEAR(P.PersonDateOfBirth) 

		<  

		(SELECT YEAR(PersonDateOfBirth) + 15

        FROM persons 

        WHERE PersonID = PersonIDin) 

        

	AND P.PersonID NOT IN 

    /* A Partner may not be the Father or Mother, so do not select a person who is the father or mother */

		(SELECT RelationWithPerson

		 FROM relations R

		 JOIN (relationnames RN, persons P)

		 ON (R.RelationName = RN.RelationnameID AND 

			 P.PersonID = R.RelationPerson AND 

				(RN.RelationnameName = "Vader" OR

				 RN.RelationnameName = "Moeder"))

		 WHERE P.PersonID = PersonIDin)

   

   AND P.PersonID NOT IN 

    /* A Partner may not be a Sister or a Brother, so do not select a person with same father or mother */

		(SELECT RelationPerson as Persons 

		FROM relations R

		JOIN (relationnames RN, persons P)

		ON R.RelationName = RN.RelationnameID AND 

		P.PersonID = R.RelationPerson AND 

		(RN.RelationnameName = "Vader" OR RN.RelationnameName = "Moeder") AND

		RelationWithPerson NOT IN 

			(SELECT RelationWithPerson as Parents

			FROM relations R

			JOIN (relationnames RN, persons P)

			ON R.RelationName = RN.RelationnameID AND 

			P.PersonID = R.RelationPerson AND 

			R.RelationPerson = PersonIDin AND

			(RN.RelationnameName = "Vader" OR RN.RelationnameName = "Moeder")))

             

        

    ORDER BY P.PersonDateOfBirth;    

 END$$
DELIMITER ;
