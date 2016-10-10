/*
* ----------------------------------------------------------------------------------------
* 	Copyright © 2015-Present Aries Systems Corporation. All Rights Reserved.
* 	Copying, reverse engineering, adaptation or any other derivative use
* 	prohibited.  This material is proprietary and confidential information
* 	of Aries Systems Corporation.
* 
*   Date Created:		20151012 by JGG
*   Version Introduced:	13.0
*   Bugfix #:			13.0-18
* 
* 	Description:  Retrieves PEOPLE records matching first and last name and email 
* 
* 	History:
*   ***********************************************
* 
* ----------------------------------------------------------------------------------------
*/

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES
	   WHERE ROUTINE_NAME  = N'usp_SelectPeopleByNamesAndEmails'
	   AND ROUTINE_TYPE = N'PROCEDURE')    			
BEGIN
    DROP PROCEDURE dbo.usp_SelectPeopleByNamesAndEmails
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SelectPeopleByNamesAndEmails]
	@parameters AS XML
AS
BEGIN
/* expeced xml format:
	<parameters>		
	<parameter>
		<firstname>X</firstname>
		<lastname>X</lastname>
			<email>X</email>
		</parameter>
	</parameters>
*/
	SET NOCOUNT ON

	DECLARE @NamesAndEmailsTable TABLE (FirstName nvarchar(50) null, LastName nvarchar(50) not null, Email nvarchar(256) not null)

	INSERT INTO @NamesAndEmailsTable (FirstName, LastName, Email )
	SELECT 
		LOWER(parameter.value('(firstname)[1]','varchar(50)')),
		LOWER(parameter.value('(lastname)[1]','varchar(50)')),
		LOWER(parameter.value('(email)[1]','varchar(256)'))
	FROM
		@parameters.nodes('/parameters/parameter') as PARAMETERS(parameter)

	-- Select the matching persons (if any)
	SELECT 
		PEOPLE.PEOPLEID,
		PEOPLE.FIRSTNAME,
		MIDDLENAME,
		PEOPLE.LASTNAME,
		PTITLE,
		DEGREE,
		GREETING,
		WLOGIN,
		WPASSWORD,
		PNOTE,
		PUBLISHER,
		PUBLISHERROLEID,
		EDITOR,
		EDITORROLEID,
		REVIEWER,
		REVIEWERROLEID,
		FORBIDREVIEW,
		BOARD,
		LASTUPDATE,
		INACTIVE,
		PROTECT_CONTACT_INFO,
		LAST_SYNC_DATE,
		GUID,
		PROXY_REG,
		REG_DATE,
		PROXY_REG_OPERATOR,
		URL1,
		URL2,
		URL3,
		EDITOR_DESCRIPTION,
		AVAILABLE_FOR_ROTATION,
		LAST_ROTATION,
		USID,
		PREFERRED_LOGIN,
		PASSWORD_ENCRYPTED,
		DEFAULT_LOGIN_MENU,
		NEVER_LOGGED_IN_BEFORE,
		IMPORT_PEOPLE_ID,
		RESET_PWD,
		LOCKED,
		LOCK_DATE,
		CROSS_PUB_LOGIN_LIST,
		DEFAULT_LANGUAGE,
		PERSONAL_IDENTIFIERS_ID,
		IMPORT_PEOPLE_ORCID,
		TEMP_PWD_EXPIRATION_START,
		TEMP_PWD_EXPIRATION_TYPE
	FROM dbo.PEOPLE WITH (NOLOCK)
	INNER JOIN dbo.ADDRESS_EMAIL WITH (NOLOCK)
		ON  PEOPLE.PEOPLEID = ADDRESS_EMAIL.PeopleID	
    INNER JOIN @NamesAndEmailsTable ParametersTable
		ON  
			ADDRESS_EMAIL.Email = ParametersTable.Email
			AND
			PEOPLE.FIRSTNAME = ParametersTable.FirstName
			AND
			PEOPLE.LASTNAME = ParametersTable.LastName
	WHERE
		PEOPLE.INACTIVE = 0 
		AND
		EXISTS(SELECT * FROM dbo.[ADDRESS] WITH (NOLOCK)
			WHERE	ADDRESS.ADDRESSID = ADDRESS_EMAIL.ADDRESSID AND 
					ADDRESS.INACTIVE = 0 AND 
					(ADDRESS.[PRIMARY] = 1 OR ((ADDRESS.[PRIMARY] = 0) AND (ADDRESS.ENDDATE > GETDATE()))))	
END

GO