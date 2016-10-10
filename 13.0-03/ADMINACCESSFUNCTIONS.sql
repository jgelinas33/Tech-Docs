IF NOT EXISTS (SELECT 1 FROM ADMINACCESSFUNCTIONS 
	WHERE 
		PAGEID = 4
		AND
		SECTIONID = 3
		AND 
		GROUPID = 3
		AND
		PRODUCTID = 1
		AND
		ITEMTEXT = 'Configure checkCIF')
	BEGIN
		INSERT INTO ADMINACCESSFUNCTIONS
		(
			PAGEID,
			SECTIONID,
			GROUPID,
			ITEMORDER,
			PRODUCTID,
			ITEMTEXT,
			WEBPAGENAME,
			ACTIVE,
			ADMINRESTRICTEDACTIVE,
			ELIGIBLEADMINACCESS,
			POLICYDISPLAYRULES,
			RESOURCEID
		)
		SELECT
			4,
			3,
			3,
			ITEMORDER,
			1,
			'Configure checkCIF',
			'CheckCIFSettings.aspx',
			1,
			0,
			1,
			0,
			'Pages.Admin.PolicyManager.LinkConfigureCIFCheck'
		FROM ADMINACCESSFUNCTIONS
		WHERE ITEMTEXT = 'Configure Similarity Check';
	

		WITH ItemList
		(
			ADMINFUNCTIONID,
			ITEMORDER,
			ROW
		)
		AS
		(
			SELECT
			ADMINFUNCTIONID,
			ITEMORDER,
			ROW_NUMBER() over (ORDER BY ITEMORDER) AS ROW
			FROM ADMINACCESSFUNCTIONS
			WHERE
			PAGEID = 4
			AND
			SECTIONID = 3
			AND 
			GROUPID = 3
			AND
			PRODUCTID = 1
		)

		UPDATE ADMINACCESSFUNCTIONS
		SET ITEMORDER = l.ROW
		FROM ADMINACCESSFUNCTIONS t
		INNER JOIN ItemList l ON
		t.ADMINFUNCTIONID = l.ADMINFUNCTIONID

END;
