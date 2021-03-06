DECLARE
	@peopleID						INT = 1,
	@currentPageIndex				INT = 0,
	@pageSize 						INT = 25,
	@searchQuery 					NVARCHAR(MAX) = 'SELECT DISTINCT DOCUMENT_ALIAS.DOCUMENTID FROM dbo.DOCUMENT AS DOCUMENT_ALIAS WITH (NOLOCK)  WHERE (DOCUMENT_ALIAS.PUBDNUMBER LIKE N''%'')',
	@sortColumn						NVARCHAR(100),
	@sortDirection 					NVARCHAR(4),
	@downloadResults				BIT = 0,
	@roleID							INT = 3,
	@totalRecords 					INT = NULL

	
	DECLARE 
		@sortDirection_ASC VARCHAR(4) = 'ASC',
		@sortDirection_DESC VARCHAR(4) = 'DESC';
		
	-- Starting Row Index, 1 based, for the Current Page Index
	DECLARE @RowStartIndex INT = (@currentPageIndex) * @pageSize + 1;
	
	-- table that contains document ids that match the passed in search query
	DECLARE @SearchMatchesTable TABLE (DOCUMENTID INT)
	
	-- table that returns the correct records requested
	DECLARE @LookupTable TABLE(DOCUMENTID INT NOT NULL, ROWNUMBER INT NOT NULL)
	
	-- was added in previous query (usp_SelectSearchProposalResults)
	-- keeping it unless told otherwise
	DECLARE @actualSearchQuery NVARCHAR(MAX)
	
	DECLARE @editorRemoveSubmissionStatusID INT = (SELECT DSTATUSID FROM dbo.EVENT WHERE EVENTID = 33)
	
	SET @actualSearchQuery = '
		SELECT DISTINCT 
			DOCUMENT.DOCUMENTID
		FROM 
			dbo.DOCUMENT WITH (NOLOCK)
			INNER JOIN dbo.DSTATUS
				ON  DSTATUS.DSTATUSID = DOCUMENT.DSTATUS
			INNER JOIN dbo.DCATEGOR
				ON  DOCUMENT.DCATEGOID = DCATEGOR.DCATEGOID
					AND DCATEGOR.ARTICLE_TYPE_FAMILY_ID = 2
		WHERE
			DOCUMENT.DSTATUS != ' + CONVERT(VARCHAR,@editorRemoveSubmissionStatusID) + '
			AND NOT EXISTS 
				( 
					SELECT 1 
					FROM dbo.BLINDED_EDITORS
					WHERE BLINDED_EDITORS.EDITOR_ID = ' + CONVERT(VARCHAR,@peopleID)+ '
					AND BLINDED_EDITORS.DOCUMENT_ID = DOCUMENT.DOCUMENTID
				)
			AND DOCUMENT.DOCUMENTID IN(' + @searchQuery + ')'
				
	INSERT INTO @SearchMatchesTable
	EXEC (@actualSearchQuery)
	
	--SELECT * FROM @SearchMatchesTable
	
	SET @sortColumn = N'colNoInvitedAuthors'
	SET @sortDirection = @sortDirection_ASC
	INSERT INTO @LookupTable
	(
		ROWNUMBER,
		DOCUMENTID
	)
	SELECT ROW_NUMBER() OVER
		(
			ORDER BY
				CASE WHEN @sortDirection = @sortDirection_ASC  THEN MatchedCounts.THE_COUNT END ASC,
				CASE WHEN @sortDirection = @sortDirection_DESC THEN MatchedCounts.THE_COUNT END DESC
		) AS ROWNUMBER
		,MatchedCounts.DOCUMENTID
	FROM
		(
			SELECT
				MatchesTable.DOCUMENTID,
				(
					SELECT THE_COUNT
					FROM   [dbo].UDF_CountInvitedAuthors(MatchesTable.DOCUMENTID)					
				) THE_COUNT
			FROM
				@SearchMatchesTable MatchesTable
		) MatchedCounts
	
			
	SELECT 
		 ROWNUMBER
		,DOCUMENTID
	FROM	
		@LookupTable
	WHERE
		ROWNUMBER BETWEEN @RowStartIndex AND (@RowStartIndex + @pageSize - 1)
		
	SELECT COUNT(1) FROM @LookupTable
	


	
	