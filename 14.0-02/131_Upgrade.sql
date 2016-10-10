
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'FILE_TYPES_FOR_NEW_SUBMISSION_FILTER' AND TABLE_NAME = 'DFILETYPE')
	ALTER TABLE dbo.DFILETYPE ADD FILE_TYPES_FOR_NEW_SUBMISSION_FILTER TINYINT NOT NULL CONSTRAINT DF_FILE_TYPES_FOR_NEW_SUBMISSION_FILTER DEFAULT (0);
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'FILE_TYPES_FOR_NEW_SUBMISSION_FILTER' AND TABLE_NAME = 'DFILETYPE')
	AND NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE [name] = 'CK_FILE_TYPES_FOR_NEW_SUBMISSION_FILTER')	
	ALTER TABLE dbo.DFILETYPE ADD  CONSTRAINT CK_FILE_TYPES_FOR_NEW_SUBMISSION_FILTER CHECK(FILE_TYPES_FOR_NEW_SUBMISSION_FILTER BETWEEN 0 AND 2);	
	GO
	
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'FILE_TYPES_FOR_REVISION_FILTER' AND TABLE_NAME = 'DFILETYPE')
	ALTER TABLE dbo.DFILETYPE ADD FILE_TYPES_FOR_REVISION_FILTER TINYINT NOT NULL CONSTRAINT DF_FILE_TYPES_FOR_REVISION_FILTER DEFAULT (0);
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'FILE_TYPES_FOR_REVISION_FILTER' AND TABLE_NAME = 'DFILETYPE')
	AND NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE [name] = 'CK_FILE_TYPES_FOR_REVISION_FILTER')	
	ALTER TABLE dbo.DFILETYPE ADD  CONSTRAINT CK_FILE_TYPES_FOR_REVISION_FILTER CHECK(FILE_TYPES_FOR_REVISION_FILTER BETWEEN 0 AND 2);	
	GO	

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'DISPLAY_LINE_NUMBERS' AND TABLE_NAME = 'DFILETYPE' AND DATA_TYPE = 'INT')
AND EXISTS (SELECT 1 FROM sys.default_constraints WHERE [NAME] = 'DF_DFILETYPE_DISPLAY_LINE_NUMBERS')
	ALTER TABLE dbo.DFILETYPE DROP CONSTRAINT DF_DFILETYPE_DISPLAY_LINE_NUMBERS;
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'DISPLAY_LINE_NUMBERS' AND TABLE_NAME = 'DFILETYPE' AND DATA_TYPE = 'INT')
	ALTER TABLE DFILETYPE ALTER COLUMN 	DISPLAY_LINE_NUMBERS BIT; 	
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = 'DISPLAY_LINE_NUMBERS' AND TABLE_NAME = 'DFILETYPE' AND DATA_TYPE = 'BIT')
AND NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE [NAME] = 'DF_DFILETYPE_DISPLAY_LINE_NUMBERS')
	ALTER TABLE dbo.DFILETYPE ADD CONSTRAINT DF_DFILETYPE_DISPLAY_LINE_NUMBERS DEFAULT(0) FOR DISPLAY_LINE_NUMBERS;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SUBMISSION_ITEM_FILE_TYPE_RESTRICTIONS' AND TABLE_SCHEMA = 'dbo')
CREATE TABLE dbo.SUBMISSION_ITEM_FILE_TYPE_RESTRICTIONS (
	SUBMISSION_ITEM_TYPE_ID INT NOT NULL,
	FILE_TYPE_ID TINYINT NOT NULL,
	INCLUDE_IN_FILTER_FOR_NEW_SUBMISSION BIT CONSTRAINT DF_INCLUDE_IN_FILTER_FOR_NEW_SUBMISSION DEFAULT(0),
	INCLUDE_IN_FILTER_FOR_REVISION BIT CONSTRAINT DF_INCLUDE_IN_FILTER_FOR_REVISION DEFAULT(0),
	CONSTRAINT [PK_SUBMISSION_ITEM_FILE_TYPE_RESTRICTIONS] PRIMARY KEY NONCLUSTERED 
	(SUBMISSION_ITEM_TYPE_ID,
	FILE_TYPE_ID)
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY],
	CONSTRAINT FK_SUBMISSION_ITEM_FILE_TYPE_RESTRICTIONS_SUBMISSION_ITEM_TYPE_ID__DFILETYPE_DFILETYPEID FOREIGN KEY (SUBMISSION_ITEM_TYPE_ID)
	REFERENCES dbo.DFILETYPE (DFILETYPEID)
	ON DELETE CASCADE
) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EDITORROLE' AND COLUMN_NAME = 'CAN_BYPASS_FILE_TYPE_RESTRICTIONS')
	BEGIN
		ALTER TABLE dbo.EDITORROLE ADD [CAN_BYPASS_FILE_TYPE_RESTRICTIONS] [bit] NOT NULL CONSTRAINT [DF_EDITORROLE_CAN_BYPASS_FILE_TYPE_RESTRICTIONS]  DEFAULT ((0))
	END	
GO

UPDATE dbo.EDITORROLE SET CAN_BYPASS_FILE_TYPE_RESTRICTIONS = 1 WHERE EDITAFTERDECISION = 1 OR ATTACHFILES = 1;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'PUBLISHERROLE' AND COLUMN_NAME = 'CAN_BYPASS_FILE_TYPE_RESTRICTIONS')
	BEGIN
		ALTER TABLE dbo.PUBLISHERROLE ADD [CAN_BYPASS_FILE_TYPE_RESTRICTIONS] [bit] NOT NULL CONSTRAINT [DF_PUBLISHERROLE_CAN_BYPASS_FILE_TYPE_RESTRICTIONS]  DEFAULT ((0))
	END		
GO

UPDATE dbo.PUBLISHERROLE SET CAN_BYPASS_FILE_TYPE_RESTRICTIONS = 1 WHERE EDIT_SUB_BEFORE_DECISION = 1 OR EDIT_SUB_AFTER_DECISION_FINAL_DISPOSITION = 1;                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
GO




--Spec 13.0-19
DECLARE @exportclass INT = 37;
DECLARE @fileresourceid INT;

DECLARE @Em2EmExportXSL NVARCHAR(MAX) = 	'<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">
	<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<xsl:variable name="var1_initial" select="."/>
		<Submission>
			<xsl:attribute name="xsi:noNamespaceSchemaLocation" namespace="http://www.w3.org/2001/XMLSchema-instance">file:///D:/export/em_to_em_transfer_import.xsd</xsl:attribute>
			<xsl:copy-of select="Submission/@node()"/>
			<xsl:copy-of select="Submission/node()"/>
		</Submission>
	</xsl:template>
</xsl:stylesheet>';

DECLARE @Em2EmExportXSD NVARCHAR(MAX) = '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xs:element name="Submission">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Journal"/>
				<xs:element ref="DocumentID"/>
				<xs:element ref="Title"/>
				<xs:element ref="ShortTitle" minOccurs="0"/>
				<xs:element ref="Notes" minOccurs="0"/>
				<xs:element ref="ArticleTypeName" minOccurs="0"/>
				<xs:element ref="ReceivedDate"/>
				<xs:element ref="Revision"/>
				<xs:element ref="OriginalStartDate"/>
				<xs:element ref="ManuscriptNumber" minOccurs="0"/>
				<xs:element ref="SubmissionNumber"/>
				<xs:element ref="Abstract" minOccurs="0"/>
				<xs:element ref="FinalDecisionDate" minOccurs="0"/>
				<xs:element ref="FinalDispositionDate" minOccurs="0"/>
				<xs:element ref="Section" minOccurs="0"/>
				<xs:element ref="DisplayManuscriptNotesFlag" minOccurs="0"/>
				<xs:element ref="FinalDecisionEditor" minOccurs="0"/>
				<xs:element ref="DiscussionClosingDate" minOccurs="0"/>
				<xs:element ref="ShortTitleLimitCount" minOccurs="0"/>
				<xs:element ref="AbstractLimitCount" minOccurs="0"/>
				<xs:element ref="TransferredFromSiteID" minOccurs="0"/>
				<xs:element ref="TransferredFromJournal" minOccurs="0"/>
				<xs:element ref="TransferredFromDocumentID" minOccurs="0"/>
				<xs:element ref="FundingInformationNotAvailable" minOccurs="0"/>
				<xs:element ref="ContributorRolesTaxonomyVersion" minOccurs="0"/>
				<xs:element ref="CustomRegionOfOriginID" minOccurs="0"/>
				<xs:element ref="ISORegionOfOriginCode" minOccurs="0"/>
				<xs:element ref="RevisionHistory"/>
				<xs:element ref="AuthorAssignment"/>
				<xs:element ref="Authors"/>
				<xs:element ref="AuthorVerifications" minOccurs="0"/>
				<xs:element ref="AssignedEditors" minOccurs="0"/>
				<xs:element ref="PeopleDetails"/>
				<xs:element ref="EditorAssignments" minOccurs="0"/>
				<xs:element ref="AuthorInfo"/>
				<xs:element ref="ProductionInformation" minOccurs="0"/>
				<xs:element ref="FundingInformation" minOccurs="0"/>
				<xs:element ref="Classifications" minOccurs="0"/>
				<xs:element ref="ClassificationHierarchy" minOccurs="0"/>
				<xs:element ref="Keywords" minOccurs="0"/>
				<xs:element ref="GeneralMetadata" minOccurs="0"/>
				<xs:element ref="AdditionalManuscriptMetadata" minOccurs="0"/>
				<xs:element ref="ManuscriptMetadata" minOccurs="0"/>
				<xs:element ref="TransmittalTracking" minOccurs="0"/>
				<xs:element ref="Questionnaire" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="SubmissionFiles" minOccurs="0"/>
				<xs:element ref="FileMetadata" minOccurs="0"/>
				<xs:element ref="ReviewerAttachment" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="InclusionList" minOccurs="0"/>
				<xs:element ref="TransferInfo" minOccurs="0"/>
				<xs:element ref="APC" minOccurs="0"/>
				<xs:element ref="ReviewerAssignments" minOccurs="0"/>
				<xs:element ref="ReviewerAnswers" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="ReviewerManuscriptRatings" maxOccurs="unbounded"/>
				<xs:element ref="AuthorTransferOffer" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="TransferLetter" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Journal">
		<xs:complexType>
			<xs:simpleContent>
				<xs:extension base="xs:string">
					<xs:attribute name="id" type="xs:string" use="required"/>
					<xs:attribute name="issn" type="xs:string" use="required"/>
					<xs:attribute name="fulltitle" type="xs:string" use="required"/>
					<xs:attribute name="journal-email" type="xs:string" use="required"/>
					<xs:attribute name="JournalID" type="xs:string" use="required"/>
				</xs:extension>
			</xs:simpleContent>
		</xs:complexType>
	</xs:element>
	<xs:element name="DocumentID">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="1"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="Title" type="xs:string"/>
	<xs:element name="ShortTitle" type="xs:string"/>
	<xs:element name="Notes" type="xs:string"/>
	<xs:element name="EditorAssignments">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EditorInfo" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="EditorInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EditorAssignmentStart"/>
				<xs:element ref="EditorAssignmentStop" minOccurs="0"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
				<xs:element ref="DaysWithEditor" minOccurs="0"/>
				<xs:element ref="CommentsToEditor" minOccurs="0"/>
				<xs:element ref="CommentsToAuthor" minOccurs="0"/>
				<xs:element ref="PeopleId" minOccurs="0"/>
				<xs:element ref="DocRating" minOccurs="0"/>
				<xs:element ref="Editor"/>
				<xs:element ref="Chain" minOccurs="0"/>
				<xs:element ref="Accept" minOccurs="0"/>
				<xs:element ref="AcceptDate" minOccurs="0"/>
				<xs:element ref="CommunicatedToAuthor" minOccurs="0"/>
				<xs:element ref="DecisionFamily" minOccurs="0"/>
				<xs:element ref="DecisionTerm" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Editor">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="AlternateAddress" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
				<xs:element ref="AssignmentEditorRole" minOccurs="0"/>
				<xs:element ref="Decision" minOccurs="0"/>
				<xs:element ref="ImportPeopleID" minOccurs="0"/>
				<xs:element ref="PeopleID" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="Revision" use="optional">
				<xs:simpleType>
					<xs:restriction base="xs:byte">
						<xs:minInclusive value="0"/>
						<xs:maxInclusive value="100"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="ImportPeopleID" type="xs:integer"/>
	<xs:element name="id" type="xs:integer"/>
	<xs:element name="APC">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="StatusCode"/>
				<xs:element ref="Status" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Fax" type="xs:string"/>
	<xs:element name="City" type="xs:string"/>
	<xs:element name="Item">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PeopleID"/>
				<xs:element ref="Value" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Rank" type="xs:integer"/>
	<xs:element name="Text" type="xs:string"/>
	<xs:element name="Chain" type="xs:integer"/>
	<xs:element name="Email">
		<xs:simpleType>
			<xs:restriction base="xs:string">
				<xs:pattern value="([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="State" type="xs:string"/>
	<xs:element name="DisplayManuscriptNotesFlag" type="xs:boolean"/>
	<xs:element name="ShortTitleLimitCount" type="xs:integer"/>
	<xs:element name="AbstractLimitCount" type="xs:integer"/>
	<xs:element name="TransferredFromSiteID" type="xs:integer"/>
	<xs:element name="TransferredFromJournal" type="xs:string"/>
	<xs:element name="TransferredFromDocumentID" type="xs:integer"/>
	<xs:element name="FundingInformationNotAvailable" type="xs:boolean"/>
	<xs:element name="ReceivedDate" type="xs:dateTime"/>
	<xs:element name="Value" type="xs:string"/>
	<xs:element name="TransmittalCustomIdentifier" type="xs:string"/>
	<xs:element name="Answer" type="xs:string"/>
	<xs:element name="Degree" type="xs:string"/>
	<xs:element name="Hidden" type="xs:boolean"/>
	<xs:element name="GrantRecepient">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Affiliation" minOccurs="0"/>
				<xs:element ref="Revision" minOccurs="0"/>
				<xs:element ref="AuthorType"/>
				<xs:element ref="Person" minOccurs="0"/>
				<xs:element ref="PeopleID" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="Address1" minOccurs="0"/>
				<xs:element ref="Address2" minOccurs="0"/>
				<xs:element ref="Address3" minOccurs="0"/>
				<xs:element ref="Address4" minOccurs="0"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="Rank" minOccurs="0"/>
				<xs:element ref="RevisionIndependentID" minOccurs="0"/>
				<xs:element ref="IsDeceased" minOccurs="0"/>
				<xs:element ref="IsEqualContributor" minOccurs="0"/>
				<xs:element ref="IsPostPubCorrAuthor" minOccurs="0"/>
				<xs:element ref="InstituteID" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Person">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Phone1" type="xs:string"/>
	<xs:element name="Status">
		<xs:complexType/>
	</xs:element>
	<xs:element name="Authors">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Author" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Author">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:choice>
					<xs:sequence>
						<xs:element ref="FirstName"/>
						<xs:element ref="MiddleName" minOccurs="0"/>
						<xs:element ref="LastName"/>
						<xs:element ref="Affiliation" minOccurs="0"/>
						<xs:element ref="Revision" minOccurs="0"/>
						<xs:element ref="AuthorType" minOccurs="0"/>
						<xs:element ref="Person" minOccurs="0"/>
						<xs:element ref="PeopleID" minOccurs="0"/>
						<xs:element ref="Degree" minOccurs="0"/>
						<xs:element ref="Email"/>
						<xs:element ref="Title" minOccurs="0"/>
						<xs:element ref="Position" minOccurs="0"/>
						<xs:element ref="Department" minOccurs="0"/>
						<xs:element ref="Institute" minOccurs="0"/>
						<xs:element ref="Address1" minOccurs="0"/>
						<xs:element ref="Address2" minOccurs="0"/>
						<xs:element ref="Address3" minOccurs="0"/>
						<xs:element ref="Address4" minOccurs="0"/>
						<xs:element ref="City" minOccurs="0"/>
						<xs:element ref="State" minOccurs="0"/>
						<xs:element ref="Zipcode" minOccurs="0"/>
						<xs:element ref="Country" minOccurs="0"/>
						<xs:element ref="Rank" minOccurs="0"/>
						<xs:element ref="RevisionIndependentID" minOccurs="0"/>
						<xs:element ref="IsDeceased" minOccurs="0"/>
						<xs:element ref="IsEqualContributor" minOccurs="0"/>
						<xs:element ref="IsPostPubCorrAuthor" minOccurs="0"/>
						<xs:element ref="InstituteID" minOccurs="0"/>
					</xs:sequence>
					<xs:sequence>
						<xs:element ref="IdentityValue"/>
						<xs:element ref="FirstName"/>
						<xs:element ref="MiddleName" minOccurs="0"/>
						<xs:element ref="LastName"/>
						<xs:element ref="Title" minOccurs="0"/>
						<xs:element ref="Degree" minOccurs="0"/>
						<xs:element ref="AuthorRole" minOccurs="0"/>
						<xs:element ref="EditorRole" minOccurs="0"/>
						<xs:element ref="ReviewerRole" minOccurs="0"/>
						<xs:element ref="PublisherRole" minOccurs="0"/>
						<xs:element ref="IjrsGUID" minOccurs="0"/>
						<xs:element ref="ActiveAddress" minOccurs="0"/>
						<xs:element ref="Email"/>
						<xs:element ref="PersonalKeywords" minOccurs="0"/>
						<xs:element ref="PersonalClassifications" minOccurs="0"/>
						<xs:element ref="Phone1" minOccurs="0"/>
						<xs:element ref="CountryCode" minOccurs="0"/>
						<xs:element ref="Zipcode" minOccurs="0"/>
						<xs:element ref="Country" minOccurs="0"/>
					</xs:sequence>
				</xs:choice>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AuthorVerifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="AuthorVerification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AuthorVerification">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RevisionIndependentAuthorID" minOccurs="0"/>
				<xs:element ref="VerificationStatus" minOccurs="0"/>
				<xs:element ref="StatusDate" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="RevisionIndependentAuthorID" type="xs:string"/>
	<xs:element name="VerificationStatus" type="xs:string"/>
	<xs:element name="StatusDate" type="xs:dateTime"/>
	<xs:element name="Country" type="xs:string"/>
	<xs:element name="EndDate" type="xs:dateTime"/>
	<xs:element name="Zipcode" type="xs:string"/>
	<xs:element name="Affiliation" type="xs:string"/>
	<xs:element name="Address1" type="xs:string"/>
	<xs:element name="Address2" type="xs:string"/>
	<xs:element name="Address3" type="xs:string"/>
	<xs:element name="Address4" type="xs:string"/>
	<xs:element name="Contents" type="xs:string"/>
	<xs:element name="CorrDate" type="xs:dateTime"/>
	<xs:element name="Decision">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EditorAssignmentStart"/>
				<xs:element ref="EditorAssignmentStop" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
				<xs:element ref="DaysWithEditor" minOccurs="0"/>
				<xs:element ref="CommentsToEditor" minOccurs="0"/>
				<xs:element ref="CommentsToAuthor" minOccurs="0"/>
				<xs:element ref="PeopleId" minOccurs="0"/>
				<xs:element ref="DocRating" minOccurs="0"/>
				<xs:element ref="Editor"/>
				<xs:element ref="Chain"/>
				<xs:element ref="Accept" minOccurs="0"/>
				<xs:element ref="AcceptDate" minOccurs="0"/>
				<xs:element ref="CommunicatedToAuthor"/>
				<xs:element ref="DecisionFamily"/>
				<xs:element ref="DecisionTerm"/>
				<xs:element ref="FinalDecisionFamily" minOccurs="0"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="DaysWithEditor" type="xs:integer"/>
	<xs:element name="DocRating" type="xs:integer"/>
	<xs:element name="Accept" type="xs:boolean"/>
	<xs:element name="AcceptDate" type="xs:dateTime"/>
	<xs:element name="Keywords">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Keyword" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="LastName" type="xs:string"/>
	<xs:element name="IjrsGUID" type="xs:string"/>
	<xs:element name="PeopleID">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="0"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="Position" type="xs:string"/>
	<xs:element name="Question">
		<xs:complexType>
			<xs:choice>
				<xs:sequence>
					<xs:element ref="QuestionText"/>
					<xs:element ref="AdditionalQuestionText" minOccurs="0"/>
					<xs:element ref="Revision" minOccurs="0"/>
					<xs:element ref="DataType" minOccurs="0"/>
					<xs:element ref="Rank"/>
					<xs:element ref="Answer" minOccurs="0" maxOccurs="unbounded"/>
				</xs:sequence>
				<xs:sequence>
					<xs:element ref="HiddenTransmittal"/>
					<xs:element ref="LastUpdate"/>
					<xs:element ref="ControlType"/>
					<xs:element ref="Text"/>
					<xs:element ref="TransmittalCustomIdentifier" minOccurs="0" maxOccurs="1"/>
					<xs:element ref="Answer"/>
					<xs:element ref="Revision"/>
					<xs:element ref="RevisionIndependentID"/>
					<xs:element ref="QuestionID"/>
					<xs:element ref="ParentQuestionID" minOccurs="0"/>
					<xs:element ref="IsCorrespondingAuthor"/>
					<xs:element ref="TransmitAsAuthorNote"/>
				</xs:sequence>
			</xs:choice>
			<xs:attribute name="QuestionID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="ParentQuestionID" type="xs:integer"/>
	<xs:element name="IsCorrespondingAuthor" type="xs:boolean"/>
	<xs:element name="Reviewer">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="AlternateAddress" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Revision">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="0"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="RoleName" type="xs:string"/>
	<xs:element name="ClassCode" type="xs:decimal"/>
	<xs:element name="FirstName" type="xs:string"/>
	<xs:element name="Institute" type="xs:string"/>
	<xs:element name="InstituteID" type="xs:integer"/>
	<xs:element name="StartDate" type="xs:dateTime"/>
	<xs:element name="DiscussionClosingDate" type="xs:dateTime"/>
	<!--ASSIGNMENT START-->
	<xs:element name="Assignment">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="Address1" minOccurs="0"/>
				<xs:element ref="Address2" minOccurs="0"/>
				<xs:element ref="Address3" minOccurs="0"/>
				<xs:element ref="Address4" minOccurs="0"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="Fax" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="ActiveAddress"/>
				<xs:element ref="Email"/>
				<xs:element ref="AlternateAddress" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
				<xs:element ref="AssignmentEditorRole" minOccurs="0"/>
				<xs:element ref="Decision" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="Revision" use="required">
				<xs:simpleType>
					<xs:restriction base="xs:byte">
						<xs:minInclusive value="0"/>
						<xs:maxInclusive value="100"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<!--ASSIGNMENT END-->
	<xs:element name="AuthorInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="FirstAuthorFirstName"/>
				<xs:element ref="FirstAuthorMiddleName" minOccurs="0"/>
				<xs:element ref="FirstAuthorLastName"/>
				<xs:element ref="FirstAuthordegree" minOccurs="0"/>
				<xs:element ref="AllAuthorsText"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="FunderName" type="xs:string"/>
	<xs:element name="FunderID" type="xs:string"/>
	<xs:element name="GrantNumber" type="xs:string"/>
	<xs:element name="AuthorType" type="xs:string"/>
	<xs:element name="Department" type="xs:string"/>
	<xs:element name="EditorRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="PublisherRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Section">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="SectionID"/>
				<xs:element ref="SectionName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="SectionID" type="xs:integer"/>
	<xs:element name="SectionName" type="xs:string"/>
	<xs:element name="IsDeceased" type="xs:boolean"/>
	<xs:element name="LastUpdate" type="xs:dateTime"/>
	<xs:element name="LetterBody" type="xs:string"/>
	<xs:element name="MiddleName" type="xs:string"/>
	<xs:element name="QuestionID" type="xs:integer"/>
	<xs:element name="StatusCode" type="xs:integer"/>
	<xs:element name="ContributorRolesTaxonomyVersion" type="xs:integer"/>
	<xs:element name="ReviewerManuscriptRatings">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Rating" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
			<xs:attribute name="ReviewerID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="Rating">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="QuestionText"/>
				<xs:element ref="QuestionID"/>
				<xs:element ref="ScaleLow"/>
				<xs:element ref="ScaleHigh"/>
				<xs:element ref="Rank"/>
			</xs:sequence>
			<xs:attribute name="ReviewerID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="QuestionText" type="xs:string"/>
	<xs:element name="ScaleLow" type="xs:string"/>
	<xs:element name="ScaleHigh" type="xs:string"/>
	<xs:element name="FileMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="File" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="ReviewerAttachment" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="File">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="FileName"/>
				<xs:element ref="FileFamilyType"/>
				<xs:element ref="FileDescription"/>
				<xs:element name="ForPublisher" type="xs:string"/>
				<xs:element ref="Rank" minOccurs="0"/>
				<xs:element name="Metadata" minOccurs="0" maxOccurs="unbounded">
					<xs:complexType>
						<xs:sequence>
							<xs:element ref="Description" minOccurs="0"/>
							<xs:element ref="Value" minOccurs="0"/>
						</xs:sequence>
					</xs:complexType>
				</xs:element>
			</xs:sequence>
			<xs:attribute name="IsTransmittalFile" type="xs:boolean"/>
			<xs:attribute name="AmendedFile" type="xs:boolean" use="optional"/>
			<xs:attribute name="IsCompanionFile" type="xs:boolean" use="optional"/>
			<xs:attribute name="Revision" type="xs:byte"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="FileName" type="xs:string"/>
	<xs:element name="FileFamilyType" type="xs:string"/>
	<xs:element name="FileDescription" type="xs:string"/>
	<xs:element name="FinalDecisionEditor">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
				<xs:element ref="CommunicatedToAuthor" minOccurs="0"/>
				<xs:element ref="DecisionFamily" minOccurs="0"/>
				<xs:element ref="DecisionTerm" minOccurs="0"/>
				<xs:element ref="Chain" minOccurs="0"/>
				<xs:element ref="EditorAssignmentStart" minOccurs="0"/>
				<xs:element ref="EditorAssignmentStop" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
				<xs:element ref="FinalDecisionFamily" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AdditionalManuscriptMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="GeneralMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ManuscriptMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="TransmittalTracking">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Metadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Value" minOccurs="0"/>
				<xs:element ref="HiddenTransmittalForm" minOccurs="0"/>
				<xs:element ref="TransmittalCustomIdentifier" minOccurs="0"/>
				<xs:element ref="Hidden" minOccurs="0"/>
				<xs:element ref="DefinitionID" minOccurs="0"/>
				<xs:element ref="Description" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="CustomRegionOfOriginID" type="xs:string"/>
	<xs:element name="ISORegionOfOriginCode" type="xs:string"/>
	<xs:element name="ControlType" type="xs:string"/>
	<xs:element name="CountryCode" type="xs:string"/>
	<xs:element name="Description" type="xs:string"/>
	<xs:element name="RevisedDate" type="xs:dateTime"/>
	<xs:element name="DecisionTerm" type="xs:string"/>
	<xs:element name="DefinitionID">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="1"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<!--ROLES START-->
	<xs:element name="AuthorRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="RoleName" type="xs:string"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<!--ROLES END-->
	<xs:element name="ActiveAddress">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EndDate" minOccurs="0"/>
				<xs:element ref="StartDate" minOccurs="0"/>
				<xs:element ref="Fax" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="Address1" minOccurs="0"/>
				<xs:element ref="Address2" minOccurs="0"/>
				<xs:element ref="Address3" minOccurs="0"/>
				<xs:element ref="Address4" minOccurs="0"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="InstituteID" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="id" use="required">
				<xs:simpleType>
					<xs:restriction base="xs:integer">
						<xs:minInclusive value="1"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="IdentityValue" type="xs:integer"/>
	<xs:element name="InclusionList">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="id" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="LetterSubject" type="xs:string"/>
	<xs:element name="PeopleDetails">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Item" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Questionnaire">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Question" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AllAuthorsText" type="xs:string"/>
	<xs:element name="AdditionalQuestionText" type="xs:string"/>
	<xs:element name="DataType" type="xs:string"/>
	<xs:element name="AuthorNotified" type="xs:boolean"/>
	<xs:element name="Classification">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ClassCode"/>
				<xs:element ref="Description"/>
				<xs:element ref="ChildClassifications" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="isTop">
				<xs:simpleType>
					<xs:restriction base="xs:boolean">
						<xs:pattern value="true"/>
						<xs:pattern value="false"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
			<xs:attribute name="isSelected">
				<xs:simpleType>
					<xs:restriction base="xs:boolean">
						<xs:pattern value="true"/>
						<xs:pattern value="false"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
			<xs:attribute name="hasChildGroup">
				<xs:simpleType>
					<xs:restriction base="xs:boolean">
						<xs:pattern value="true"/>
						<xs:pattern value="false"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
			<xs:attribute name="hierarchyLevel">
				<xs:simpleType>
					<xs:restriction base="xs:string">
						<xs:pattern value="([0-9])*"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="ChildClassifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<!--ROLES END-->
	<xs:element name="DecisionFamily" type="xs:string"/>
	<xs:element name="DecisionLetter">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="CorrDate"/>
				<xs:element ref="BlindedLetterContents"/>
				<xs:element ref="BlindedLetterBody" minOccurs="0"/>
				<xs:element ref="BlindedLetterSubject" minOccurs="0"/>
				<xs:element ref="IsFullyBlinded" minOccurs="0"/>
				<xs:element ref="CCList" minOccurs="0"/>
				<xs:element ref="LetterSubject" minOccurs="0"/>
				<xs:element ref="LetterBody" minOccurs="0"/>
				<xs:element ref="Contents" minOccurs="0"/>
				<xs:element ref="Revision" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="EditorDecision" type="xs:string"/>
	<!--DECISIONSS END-->
	<xs:element name="IsFullyBlinded" type="xs:boolean"/>
	<xs:element name="ReviewerRating" type="xs:integer"/>
	<xs:element name="ArticleTypeName" type="xs:string"/>
	<xs:element name="AssignedEditors">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Assignment" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Classifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ColorImageCount" type="xs:integer"/>
	<xs:element name="ReviewerAnswers">
		<xs:complexType>
			<xs:sequence minOccurs="0">
				<xs:element ref="AllowPersonalInfoTransferLastRevision" minOccurs="0"/>
				<xs:element ref="AllowReviewTransfer" minOccurs="0"/>
				<xs:element ref="AllowPersonalInfoTransfer" minOccurs="0"/>
				<xs:element ref="AllowReviewPublication" minOccurs="0"/>
				<xs:element ref="Question" maxOccurs="unbounded"/>
			</xs:sequence>
			<xs:attribute name="RoleID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="RevisionHistory">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="SubmissionRevision" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="SubmissionFiles">
		<xs:complexType/>
	</xs:element>
	<xs:element name="ReviewerAttachment">
		<xs:complexType>
			<xs:sequence minOccurs="0">
				<xs:element ref="FileName" minOccurs="0"/>
				<xs:element name="OriginalFileName" type="xs:string"/>
				<xs:element ref="Revision" minOccurs="0"/>
				<xs:element ref="Submitter" minOccurs="0"/>
				<xs:element ref="ReviewerNumber" minOccurs="0"/>
				<xs:element ref="AttachmentType" minOccurs="0"/>
				<xs:element ref="Description" maxOccurs="unbounded"/>
				<xs:element name="VisibleToAuthor" type="xs:string"/>
				<xs:element name="VisibleToReviewer" type="xs:string"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AlternateAddress">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Address1"/>
				<xs:choice>
					<xs:sequence>
						<xs:element ref="Email"/>
						<xs:element ref="City"/>
						<xs:element ref="State"/>
						<xs:element ref="Zipcode"/>
						<xs:element ref="Institute"/>
						<xs:element ref="Department"/>
						<xs:element ref="Position"/>
						<xs:element ref="Phone1"/>
					</xs:sequence>
					<xs:sequence>
						<xs:element ref="Address2"/>
						<xs:element ref="Email"/>
						<xs:element ref="City"/>
						<xs:element ref="State"/>
						<xs:element ref="Zipcode"/>
						<xs:element ref="Institute"/>
						<xs:element ref="Department"/>
						<xs:element ref="Position"/>
						<xs:element ref="Phone1"/>
						<xs:element ref="Fax"/>
					</xs:sequence>
				</xs:choice>
				<xs:element ref="CountryCode"/>
				<xs:element ref="Country"/>
				<xs:element ref="StartDate"/>
				<xs:element ref="EndDate"/>
			</xs:sequence>
			<xs:attribute name="id" use="required">
				<xs:simpleType>
					<xs:restriction base="xs:byte">
						<xs:enumeration value="3"/>
						<xs:enumeration value="4"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="AuthorAssignment">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="CorrespondingAuthor"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="CommentsToAuthor" type="xs:string"/>
	<xs:element name="CommentsToEditor" type="xs:string"/>
	<xs:element name="ManuscriptNumber" type="xs:string"/>
	<xs:element name="SubmissionNumber" type="xs:string"/>
	<xs:element name="Abstract" type="xs:string"/>
	<xs:element name="ReviewerNumber" type="xs:string"/>
	<xs:element name="AttachmentType" type="xs:string"/>
	<xs:element name="PersonalKeywords">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Keyword" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Keyword">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Rank"/>
				<xs:element ref="Word"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Word" type="xs:string"/>
	<xs:element name="BlindedLetterBody" type="xs:string"/>
	<xs:element name="CCList" type="xs:string"/>
	<xs:element name="HiddenTransmittal" type="xs:boolean"/>
	<xs:element name="OriginalStartDate" type="xs:dateTime"/>
	<xs:element name="FundingInformation">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Funding" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="IsEqualContributor" type="xs:boolean"/>
	<xs:element name="ReviewerAssignment">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="IdentityValue"/>
				<xs:element ref="Revision"/>
				<xs:element ref="ReviewerAssignmentStart"/>
				<xs:element ref="ReviewerAssignmentStop"/>
				<xs:element ref="ReviewerRecommendation"/>
				<xs:element ref="CommentsToEditor"/>
				<xs:element ref="CommentsToAuthor"/>
				<xs:element ref="Rank"/>
				<xs:element ref="ReviewerRating"/>
				<xs:element ref="Reviewer"/>
				<xs:element ref="AllowPersonalInfoTransferLastRevision"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="SubmissionRevision">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Revision"/>
				<xs:element ref="RevisedDate"/>
				<xs:element ref="AuthorNotified"/>
				<xs:element ref="DecisionLetter" minOccurs="0"/>
				<xs:element ref="TechnicalCheckCompleteDate" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AllowReviewTransfer" type="xs:boolean"/>
	<xs:element name="CorrespondingAuthor">
		<xs:complexType>
			<xs:sequence minOccurs="0">
				<xs:element ref="PeopleID" minOccurs="0"/>
				<xs:element ref="StartDate" minOccurs="0"/>
				<xs:element ref="EndDate" minOccurs="0"/>
				<xs:element ref="Author"/>
				<xs:element ref="Revision"/>
				<xs:element ref="Comments" minOccurs="0"/>
				<xs:element ref="RevisionAssignedDate" minOccurs="0"/>
				<xs:element ref="ResponseToReviewers" minOccurs="0"/>
				<xs:element ref="AllAuthorsText"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Comments" type="xs:string"/>
	<xs:element name="RevisionAssignedDate" type="xs:dateTime"/>
	<xs:element name="ResponseToReviewers" type="xs:string"/>
	<xs:element name="FinalDecisionFamily">
		<xs:complexType/>
	</xs:element>
	<xs:element name="FirstAuthorMiddleName" type="xs:string"/>
	<xs:element name="FirstAuthorLastName" type="xs:string"/>
	<xs:element name="FirstAuthordegree" type="xs:string"/>
	<xs:element name="IsPostPubCorrAuthor" type="xs:boolean"/>
	<xs:element name="PersonalIdentifiers">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ISNI" minOccurs="0"/>
				<xs:element ref="ORCID" minOccurs="0"/>
				<xs:element ref="PubMedAuthorID" minOccurs="0"/>
				<xs:element ref="ResearcherID" minOccurs="0"/>
				<xs:element ref="ScopusAuthorID" minOccurs="0"/>
				<xs:element ref="OrcidAuthenticated" minOccurs="0" maxOccurs="2"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerAssignments">
		<xs:complexType>
			<xs:choice>
				<xs:sequence>
					<xs:element ref="ReviewerAssignment" minOccurs="0"/>
				</xs:sequence>
				<xs:sequence>
					<xs:element ref="ReviewerInfo" minOccurs="0" maxOccurs="unbounded"/>
				</xs:sequence>
			</xs:choice>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PeopleId" minOccurs="0"/>
				<xs:element ref="OriginalReviewFormID" minOccurs="0"/>
				<xs:element ref="ReviewerAssignmentStart" minOccurs="0"/>
				<xs:element ref="ReviewerAssignmentStop" minOccurs="0"/>
				<xs:element ref="ReviewerRecommendation" minOccurs="0"/>
				<xs:element ref="CommentsToAuthor" minOccurs="0"/>
				<xs:element ref="ReviewerRating" minOccurs="0"/>
				<xs:element ref="Reviewer" minOccurs="0"/>
				<xs:element ref="Revision" minOccurs="0"/>
				<xs:element ref="RoleID"/>
				<xs:element ref="Rank"/>
				<xs:element ref="AllowReviewTransfer" minOccurs="0"/>
				<xs:element ref="AllowReviewPublication" minOccurs="0"/>
				<xs:element ref="AllowPersonalInfoTransferLastRevision" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="PeopleId" type="xs:integer"/>
	<xs:element name="RoleID" type="xs:integer"/>
	<xs:element name="DOI" type="xs:string"/>
	<xs:element name="TargetNumberOfPages" type="xs:integer"/>
	<xs:element name="OriginalReviewFormID" type="xs:integer"/>
	<xs:element name="AssignmentEditorRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Funding">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Revision"/>
				<xs:element ref="RevisionIndependentID"/>
				<xs:element ref="FunderName"/>
				<xs:element ref="FunderID" minOccurs="0"/>
				<xs:element ref="GrantNumber"/>
				<xs:element ref="GrantRecepient"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ISNI" type="xs:string"/>
	<xs:element name="ORCID" type="xs:string"/>
	<xs:element name="PubMedAuthorID" type="xs:string"/>
	<xs:element name="ResearcherID" type="xs:string"/>
	<xs:element name="ScopusAuthorID" type="xs:string"/>
	<xs:element name="OrcidAuthenticated" type="xs:boolean"/>
	<xs:element name="BlindedLetterSubject" type="xs:string"/>
	<xs:element name="CommunicatedToAuthor" type="xs:string"/>
	<xs:element name="EditorAssignmentStop" type="xs:dateTime"/>
	<xs:element name="FinalDecisionDate" type="xs:dateTime"/>
	<xs:element name="FinalDispositionDate" type="xs:dateTime"/>
	<xs:element name="FirstAuthorFirstName" type="xs:string"/>
	<xs:element name="TransmitAsAuthorNote" type="xs:string"/>
	<xs:element name="BlindedLetterContents" type="xs:string"/>
	<xs:element name="EditorAssignmentStart" type="xs:dateTime"/>
	<xs:element name="HiddenTransmittalForm" type="xs:boolean"/>
	<xs:element name="ProductionInformation">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ProductionNotes" minOccurs="0"/>
				<xs:element ref="DOI" minOccurs="0"/>
				<xs:element ref="TargetNumberOfPages" minOccurs="0"/>
				<xs:element ref="BlackAndWhiteImageCount" minOccurs="0"/>
				<xs:element ref="ColorImageCount" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="RevisionIndependentID">
		<xs:simpleType>
			<xs:restriction base="xs:string">
				<xs:pattern value="[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="AllowReviewPublication" type="xs:boolean"/>
	<xs:element name="ReviewerAssignmentStop" type="xs:dateTime"/>
	<xs:element name="ReviewerRecommendation" type="xs:string"/>
	<xs:element name="BlackAndWhiteImageCount" type="xs:integer"/>
	<xs:element name="ClassificationHierarchy">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="PersonalClassifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerAssignmentStart" type="xs:dateTime"/>
	<xs:element name="AllowPersonalInfoTransfer">
		<xs:complexType/>
	</xs:element>
	<xs:element name="TechnicalCheckCompleteDate" type="xs:dateTime"/>
	<xs:element name="AllowPersonalInfoTransferLastRevision" type="xs:string"/>
	<xs:element name="TransferInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ReviewerAssignments" minOccurs="0"/>
				<xs:element ref="ReviewerAnswers" minOccurs="0"/>
				<xs:element name="Journal" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Submitter">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName" minOccurs="0"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName" minOccurs="0"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Issn" type="xs:string"/>
	<xs:element name="ContactUs" type="xs:string"/>
	<xs:element name="EMail" type="xs:string"/>
	<xs:element name="AuthorTransferOffer">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="TriggeringRoleFamily" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ProductionNotes" type="xs:string"/>
	<xs:element name="TransferLetter">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Contents" minOccurs="0"/>
				<xs:element ref="Description" minOccurs="0"/>
				<xs:element ref="Subject" minOccurs="0"/>
				<xs:element ref="UserEnteredDate" minOccurs="0"/>
				<xs:element ref="Sender" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Subject" type="xs:string"/>
	<xs:element name="UserEnteredDate" type="xs:string"/>
	<xs:element name="Sender" type="xs:string"/>
</xs:schema>';

DECLARE @Em2EmImportXSL NVARCHAR(MAX) = 
	'<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" doctype-system="test.dtd"/>
	<xsl:variable name="unavailableDateCount" select="count(/metadata/corrunavailabilityinfo/unavail-start-date)"/>
	<xsl:variable name="finalRevision">
		<xsl:choose>
			<xsl:when test="/Submission/Revision/text()">
				<xsl:value-of select="/Submission/Revision/text()"/>
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:template name="SubmissionRevision">
		<xsl:param name="revision" select="0"/>
		<xsl:if test="$revision &lt;= $finalRevision">
			<SubmissionRevision>
				<Revision>
					<xsl:value-of select="$revision"/>
				</Revision>
				<xsl:if test="$revision = 0">
					<xsl:if test="/Submission/RevisionHistory/SubmissionRevision/RevisedDate">
						<RevisedDate>
							<xsl:value-of select="/Submission/RevisionHistory/SubmissionRevision/RevisedDate"/>
						</RevisedDate>
						<AuthorNotified>False</AuthorNotified>
					</xsl:if>
				</xsl:if>
				<xsl:if test="$finalRevision != 0 and $revision = $finalRevision">
					<xsl:if test="/Submission/RevisionHistory/SubmissionRevision/RevisedDate">
						<RevisedDate>
							<xsl:value-of select="/Submission/RevisionHistory/SubmissionRevision/RevisedDate"/>
						</RevisedDate>
						<AuthorNotified>True</AuthorNotified>
					</xsl:if>
				</xsl:if>
			</SubmissionRevision>
			<xsl:call-template name="SubmissionRevision">
				<xsl:with-param name="revision" select="$revision + 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="FileFamilyType">
		<xsl:choose>
			<xsl:when test="FileFamilyType/text() = ''Default''">
				<FamilyTypeID>1</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Figure''">
				<FamilyTypeID>2</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Document''">
				<FamilyTypeID>3</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Supplemental''">
				<FamilyTypeID>4</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Table''">
				<FamilyTypeID>5</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''TransferredFile''">
				<FamilyTypeID>7</FamilyTypeID>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="/">
		<Manuscript>
			<Submission>
				<xsl:if test="/Submission/Title/text()">
					<Title>
						<xsl:value-of select="/Submission/Title"/>
					</Title>
					<ShortTitle>
						<xsl:value-of select="/Submission/ShortTitle"/>
					</ShortTitle>
				</xsl:if>
				<xsl:if test="/Submission/Abstract/text()">
					<Abstract>
						<xsl:value-of select="/Submission/Abstract"/>
					</Abstract>
				</xsl:if>
				<Section>
					<xsl:copy-of select="/Submission/Section/node()"/>
				</Section>
				<xsl:if test="/Submission/DisplayManuscriptNotesFlag/text()">
					<DisplayManuscriptNotesFlag>
						<xsl:value-of select="/Submission/DisplayManuscriptNotesFlag"/>
					</DisplayManuscriptNotesFlag>
				</xsl:if>
				<xsl:if test="/Submission/ShortTitleLimitCount/text()">
					<ShortTitleLimitCount>
						<xsl:value-of select="/Submission/ShortTitleLimitCount"/>
					</ShortTitleLimitCount>
				</xsl:if>
				<xsl:if test="/Submission/AbstractLimitCount/text()">
					<AbstractLimitCount>
						<xsl:value-of select="/Submission/AbstractLimitCount"/>
					</AbstractLimitCount>
				</xsl:if>
				<xsl:if test="/Submission/TransferredFromSiteID/text()">
					<TransferredFromSiteID>
						<xsl:value-of select="/Submission/TransferredFromSiteID"/>
					</TransferredFromSiteID>
				</xsl:if>
				<xsl:if test="/Submission/TransferredFromJournal/text()">
					<TransferredFromJournal>
						<xsl:value-of select="/Submission/TransferredFromJournal"/>
					</TransferredFromJournal>
				</xsl:if>
				<xsl:if test="/Submission/TransferredFromDocumentID/text()">
					<TransferredFromDocumentID>
						<xsl:value-of select="/Submission/TransferredFromDocumentID"/>
					</TransferredFromDocumentID>
				</xsl:if>
				<xsl:if test="/Submission/FundingInformationNotAvailable/text()">
					<FundingInformationNotAvailable>
						<xsl:value-of select="/Submission/FundingInformationNotAvailable"/>
					</FundingInformationNotAvailable>
				</xsl:if>
				<xsl:if test="/Submission/ContributorRolesTaxonomyVersion/text()">
					<ContributorRolesTaxonomyVersion>
						<xsl:value-of select="/Submission/ContributorRolesTaxonomyVersion"/>
					</ContributorRolesTaxonomyVersion>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="/Submission/Revision/text()">
						<Revision>
							<xsl:value-of select="/Submission/Revision"/>
						</Revision>
					</xsl:when>
					<xsl:otherwise>
						<Revision>0</Revision>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="/Submission/ReceivedDate">
					<ReceivedDate>
						<xsl:value-of select="/Submission/ReceivedDate"/>
					</ReceivedDate>
					<OriginalStartDate>
						<xsl:value-of select="/Submission/OriginalStartDate"/>
					</OriginalStartDate>
				</xsl:if>
				<AuthoritativeVersion>2</AuthoritativeVersion>
				<EditSubmissionStatus>0</EditSubmissionStatus>
				<ArticleTypeName>
					<xsl:value-of select="/Submission/ArticleTypeName"/>
				</ArticleTypeName>
			</Submission>
			<xsl:for-each select="/Submission/Keywords/Keyword/Word">
				<SubmissionKeyword>
					<Keyword>
						<Word>
							<xsl:value-of select="text()"/>
						</Word>
					</Keyword>
				</SubmissionKeyword>
			</xsl:for-each>
			<SubmissionRevisions>
				<xsl:call-template name="SubmissionRevision">
					<xsl:with-param name="revision" select="0"/>
				</xsl:call-template>
			</SubmissionRevisions>
			<AdditionalManuscriptMetadata>
				<xsl:if test="/metadata/articleinfo/manuscript-editor">
					<metadata name="Manuscript Editor" value="{/metadata/articleinfo/manuscript-editor/text()}"/>
				</xsl:if>
				<xsl:if test="/metadata/history/copyright-received-date">
					<metadata name="Copyright Received Date" value="{/metadata/history/copyright-received-date/@year}/{/metadata/history/copyright-received-date/@month}-{/metadata/history/copyright-received-date/@day}"/>
				</xsl:if>
				<xsl:if test="/metadata/history/colour-authorisation-received-date">
					<metadata name="Color Authorization Received Date|Colour Authorisation Received Date" value="{/metadata/history/colour-authorisation-received-date/@year}-{/metadata/history/colour-authorisation-received-date/@month}-{/metadata/history/colour-authorisation-received-date/@day}"/>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/number-of-tables/text()">
					<metadata name="Number of Tables" value="{/metadata/billinfo/number-of-tables}"/>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/number-of-coloronline/text()">
					<metadata name="Number of Color Online Figures|Number of Colour Online Figures" value="{/metadata/billinfo/number-of-coloronline}"/>
				</xsl:if>
				<xsl:if test="/metadata/digitalinfo/digital-files-submitted/text()">
					<metadata name="Digital Files Submitted" value="{/metadata/digitalinfo/digital-files-submitted}"/>
				</xsl:if>
				<xsl:if test="/metadata/digitalinfo/hard-copy-figures-available/text()">
					<metadata name="Hard Copy Figures Available" value="{/metadata/digitalinfo/hard-copy-figures-available}"/>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/web-si-comments/text()">
					<metadata name="Web SI Comments" value="{/metadata/billinfo/web-si-comments}"/>
				</xsl:if>
				<xsl:if test="/metadata/linkedfiles/@required">
					<metadata name="Linked Files Required" value="{/metadata/linkedfiles/@required}"/>
				</xsl:if>
				<xsl:if test="count(/metadata/linkedfiles/linked[@number != '''']) > 0">
					<xsl:element name="metadata">
						<xsl:attribute name="name">Linked Number</xsl:attribute>
						<xsl:attribute name="value"><xsl:for-each select="/metadata/linkedfiles/linked[@number != '''']"><xsl:value-of select="@number"/><xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if></xsl:for-each></xsl:attribute>
					</xsl:element>
				</xsl:if>
				<xsl:if test="count(/metadata/linkedfiles/linked[@msid != '''']) > 0">
					<xsl:element name="metadata">
						<xsl:attribute name="name">Linked ID</xsl:attribute>
						<xsl:attribute name="value"><xsl:for-each select="/metadata/linkedfiles/linked[@msid != '''']"><xsl:value-of select="@msid"/><xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if></xsl:for-each></xsl:attribute>
					</xsl:element>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/supp-info/@available">
					<metadata name="Supplemental Information Available" value="{/metadata/billinfo/supp-info/@available}"/>
				</xsl:if>
				<xsl:for-each select="/metadata/articleinfo/additional-manuscript-details/additional-manuscript-detail">
					<metadata name="{amd-description}" value="{amd-value}" flagstate="{amd-flag-state}"/>
				</xsl:for-each>
			</AdditionalManuscriptMetadata>
			<CorrespondingAuthor>
				<Person>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/FirstName/text()">
						<FirstName>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/FirstName"/>
						</FirstName>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/MiddleName/text()">
						<MiddleName>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/MiddleName"/>
						</MiddleName>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/LastName/text()">
						<LastName>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/LastName"/>
						</LastName>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Title/text()">
						<Title>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Title"/>
						</Title>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue/text()">
						<ImportPeopleID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
						</ImportPeopleID>
						<PeopleID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
						</PeopleID>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IjrsGUID/text()">
						<IjrsGUID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IjrsGUID"/>
						</IjrsGUID>
					</xsl:if>					
				</Person>
				<Address>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address1/text()">
						<Address1>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address1"/>
						</Address1>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address2">
						<Address2>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address2"/>
						</Address2>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/City/text()">
						<City>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/City"/>
						</City>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Country/text()">
						<Country>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Country"/>
						</Country>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Department/text()">
						<Department>
							<xsl:value-of select="/Submission/AuthorAssignments/AuthorAssignment/Author/Department"/>
						</Department>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Email/text()">
						<Email>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Email"/>
						</Email>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Fax/text()">
						<Fax>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Fax"/>
						</Fax>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Institute/text()">
						<Institute>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Institute"/>
						</Institute>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Phone1/text()">
						<Phone1>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Phone1"/>
						</Phone1>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/State/text()">
						<State>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/State"/>
						</State>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Zip/text()">
						<Zipcode>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Zip"/>
						</Zipcode>
					</xsl:if>
					<Primary>true</Primary>
				</Address>
				<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-address-1/text() or /metadata/corralternateinfo/corresponding-author-alternate-address-2/text() or         /metadata/corralternateinfo/corresponding-author-alternate-city/text() or         /metadata/corralternateinfo/corresponding-author-alternate-country/text() or         /metadata/corralternateinfo/corresponding-author-alternate-department/text() or         /metadata/corralternateinfo/corresponding-author-alternate-email/text() or         /metadata/corralternateinfo/corresponding-author-alternate-fax/text() or        /metadata/corralternateinfo/corresponding-author-alternate-institution/text() or        /metadata/corralternateinfo/corresponding-author-alternate-phone/text() or        /metadata/corralternateinfo/corresponding-author-alternate-state/text() or        /metadata/corralternateinfo/corresponding-author-alternate-zipcode/text()">
					<Address>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-address-1/text()">
							<Address1>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-address-1"/>
							</Address1>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-address-2/text()">
							<Address2>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-address-2"/>
							</Address2>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-city/text()">
							<City>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-city"/>
							</City>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-country/text()">
							<Country>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-country"/>
							</Country>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-department/text()">
							<Department>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-department"/>
							</Department>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-email/text()">
							<Email>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-email"/>
							</Email>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-fax/text()">
							<Fax>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-fax"/>
							</Fax>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-institution/text()">
							<Institute>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-institution"/>
							</Institute>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-phone/text()">
							<Phone1>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-phone"/>
							</Phone1>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-state/text()">
							<State>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-state"/>
							</State>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-zipcode/text()">
							<Zipcode>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-zipcode"/>
							</Zipcode>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/alt-address-start-date">
							<StartDate>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-start-date/@year"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-start-date/@month"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-start-date/@day"/>
							</StartDate>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/alt-address-end-date">
							<EndDate>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-end-date/@year"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-end-date/@month"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-end-date/@day"/>
							</EndDate>
						</xsl:if>
						<Primary>false</Primary>
					</Address>
				</xsl:if>
			</CorrespondingAuthor>
			<AuthorAssignments>
				<xsl:for-each select="/Submission/AuthorAssignment/CorrespondingAuthor/Author">
					<AuthorAssignment>
						<PeopleID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
						</PeopleID>
						<StartDate>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/StartDate"/>
						</StartDate>
						<EndDate>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/EndDate"/>
						</EndDate>
						<xsl:for-each select="/Submission/AuthorAssignment/CorrespondingAuthor/Author">
							<Author>
								<xsl:if test="name() = ''IdentityValue''">
									<PeopleID>
										<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
									</PeopleID>
								</xsl:if>
								<xsl:if test="name() != ''IdentityValue'' or name() != ''Author''">
									<xsl:copy-of select="node()"/>
								</xsl:if>
								<AuthorType>1</AuthorType>
							</Author>
						</xsl:for-each>
						<Revision>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Revision"/>
						</Revision>
						<Comments>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Comments"/>
						</Comments>
						<RevisionAssignedDate>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/RevisionAssignedDate"/>
						</RevisionAssignedDate>
						<ResponseToReviewers>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/ResponseToReviewers"/>
						</ResponseToReviewers>
						<AllAuthorsText>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/AllAuthorsText"/>
						</AllAuthorsText>
					</AuthorAssignment>
				</xsl:for-each>
			</AuthorAssignments>
			<xsl:if test="count(/Submission/Authors/Author) > 0">
				<CoAuthors>
					<xsl:for-each select="/Submission/Authors/Author">
						<xsl:if test="AuthorType/text() != ''CorrespondingAuthor'' and Revision/text() = ''0''">
							<CoAuthor>
								<Person>
									<xsl:if test="FirstName/text()">
										<FirstName>
											<xsl:value-of select="FirstName"/>
										</FirstName>
									</xsl:if>
									<xsl:if test="MiddleName/text()">
										<MiddleName>
											<xsl:value-of select="MiddleName"/>
										</MiddleName>
									</xsl:if>
									<xsl:if test="LastName/text()">
										<LastName>
											<xsl:value-of select="LastName"/>
										</LastName>
									</xsl:if>
									<xsl:if test="Title/text()">
										<Title>
											<xsl:value-of select="Title"/>
										</Title>
									</xsl:if>
									<xsl:if test="Degree/text()">
										<Degree>
											<xsl:value-of select="Degree"/>
										</Degree>
									</xsl:if>
									<xsl:if test="IdentityValue/text()">
										<ImportPeopleID>
											<xsl:value-of select="Submission/Journal/@id"/>
											<xsl:value-of select="IdentityValue"/>
										</ImportPeopleID>
									</xsl:if>
								</Person>
								<Address>
									<xsl:if test="Address1/text()">
										<Address1>
											<xsl:value-of select="Address1"/>
										</Address1>
									</xsl:if>
									<xsl:if test="Address2/text()">
										<Address2>
											<xsl:value-of select="Address2"/>
										</Address2>
									</xsl:if>
									<xsl:if test="Address3/text()">
										<Address3>
											<xsl:value-of select="Address3"/>
										</Address3>
									</xsl:if>
									<xsl:if test="Address4/text()">
										<Address4>
											<xsl:value-of select="Address4"/>
										</Address4>
									</xsl:if>
									<xsl:if test="City/text()">
										<City>
											<xsl:value-of select="City"/>
										</City>
									</xsl:if>
									<xsl:if test="State/text()">
										<State>
											<xsl:value-of select="State"/>
										</State>
									</xsl:if>
									<xsl:if test="Zipcode/text()">
										<Zipcode>
											<xsl:value-of select="Zipcode"/>
										</Zipcode>
									</xsl:if>
									<xsl:if test="Country/text()">
										<Country>
											<xsl:value-of select="Country"/>
										</Country>
									</xsl:if>
									<xsl:if test="CountryCode/text()">
										<CountryCode>
											<xsl:value-of select="CountryCode"/>
										</CountryCode>
									</xsl:if>
									<xsl:if test="Position/text()">
										<Position>
											<xsl:value-of select="Position"/>
										</Position>
									</xsl:if>
									<xsl:if test="Department/text()">
										<Department>
											<xsl:value-of select="Department"/>
										</Department>
									</xsl:if>
									<xsl:if test="Institute/text()">
										<Institute>
											<xsl:value-of select="Institute"/>
										</Institute>
									</xsl:if>
									<xsl:if test="Email/text()">
										<Email>
											<xsl:value-of select="Email"/>
										</Email>
										<Primary>true</Primary>
									</xsl:if>
								</Address>
							</CoAuthor>
						</xsl:if>
					</xsl:for-each>
				</CoAuthors>
			</xsl:if>
			<Authors>
				<xsl:copy-of select="Submission/Authors/node()"/>
			</Authors>
			<xsl:if test="count(Submission/FundingInformation/Funding) > 0">
			<Funders>
			<xsl:for-each select="Submission/FundingInformation/Funding">
				<FundingInformation>
					<xsl:copy-of select="node()"></xsl:copy-of>
				</FundingInformation>
			</xsl:for-each>
			</Funders>
			</xsl:if>
			<xsl:if test="count(Submission/AuthorVerifications/AuthorVerification) > 0">
				<xsl:copy-of select="Submission/AuthorVerifications"></xsl:copy-of>
			</xsl:if>
			<EditorAssignments>
				<xsl:for-each select="/Submission/EditorAssignments/EditorInfo">
					<EditorAssignment>
						<xsl:if test="EditorAssignmentStart/text()">
							<EditorAssignmentStart>
								<xsl:value-of select="EditorAssignmentStart"/>
							</EditorAssignmentStart>
						</xsl:if>
						<xsl:if test="EditorAssignmentStop/text()">
							<EditorAssignmentStop>
								<xsl:value-of select="EditorAssignmentStop"/>
							</EditorAssignmentStop>
						</xsl:if>
						<xsl:if test="EditorDecision/text()">
							<EditorDecision>
								<xsl:value-of select="EditorDecision"/>
							</EditorDecision>
						</xsl:if>
						<xsl:if test="DaysWithEditor/text()">
							<DaysWithEditor>
								<xsl:value-of select="DaysWithEditor"/>
							</DaysWithEditor>
						</xsl:if>
						<xsl:if test="CommentsToEditor/text()">
							<CommentsToEditor>
								<xsl:value-of select="CommentsToEditor"/>
							</CommentsToEditor>
						</xsl:if>
						<xsl:if test="PeopleId/text()">
							<PeopleId>
								<xsl:value-of select="PeopleId"/>
							</PeopleId>
						</xsl:if>
						<xsl:if test="DocRating/text()">
							<DocRating>
								<xsl:value-of select="DocRating"/>
							</DocRating>
						</xsl:if>
						<Editor>
							<xsl:attribute name="IndentityReference"><xsl:value-of select="Editor/IdentityValue"/></xsl:attribute>
							<xsl:copy-of select="Editor/node()"/>
							<ImportPeopleID>
								<xsl:value-of select="Editor/IdentityValue"/>
							</ImportPeopleID>
						</Editor>
						<xsl:if test="Chain/text()">
							<Chain>
								<xsl:value-of select="Chain"/>
							</Chain>
						</xsl:if>
						<xsl:if test="AcceptDate/text()">
							<AcceptDate>
								<xsl:value-of select="AcceptDate"/>
							</AcceptDate>
						</xsl:if>
						<xsl:if test="CommunicatedToAuthor/text()">
							<CommunicatedToAuthor>
								<xsl:value-of select="CommunicatedToAuthor"/>
							</CommunicatedToAuthor>
						</xsl:if>
						<xsl:if test="DecisionFamily/text()">
							<DecisionFamily>
								<xsl:value-of select="DecisionFamily"/>
							</DecisionFamily>
						</xsl:if>
						<xsl:if test="DecisionTerm/text()">
							<DecisionTerm>
								<xsl:value-of select="DecisionTerm"/>
							</DecisionTerm>
						</xsl:if>
					</EditorAssignment>
				</xsl:for-each>
			</EditorAssignments>
			<SubmissionClassifications>
				<xsl:for-each select="/Submission/Classifications/Classification">
				<SubmissionClassification>
					<Classification>
						<ClassCode>
							<xsl:value-of select="ClassCode"/>
						</ClassCode>
						<Description>
							<xsl:value-of select="Description"/>
						</Description>
					</Classification>
				</SubmissionClassification>
				</xsl:for-each>
			</SubmissionClassifications>
			<Files>
				<xsl:for-each select="/Submission/FileMetadata/File">
					<xsl:choose>
						<xsl:when test="@IsCompanionFile">
						<companionfile>
							<xsl:if test="/Submission/FileMetadata/File/@AmendedFile">
								<xsl:attribute name="AmendedFile">true</xsl:attribute>
							</xsl:if>
							<filename>
								<xsl:value-of select="FileName"/>
							</filename>
							<description>
									<xsl:value-of select="FileDescription"/>
								</description>
							<typename>
								 <xsl:text>Transferred File</xsl:text>
							</typename>
							<xsl:call-template name="FileFamilyType"/>
							<revision>
								<xsl:value-of select="@Revision"/>
							</revision>							
						</companionfile>						
						</xsl:when>
						<xsl:otherwise>
							<submissionfile>
								<filename>
									<xsl:value-of select="FileName"/>
								</filename>
								<description>
									<xsl:value-of select="FileDescription"/>
								</description>
								<typename>
									<xsl:value-of select="FileFamilyType"/>
								</typename>
								<xsl:call-template name="FileFamilyType"/>
								<revision>
									<xsl:value-of select="@Revision"/>
								</revision>
							</submissionfile>						
						</xsl:otherwise>  
					</xsl:choose>
				</xsl:for-each>
				<xsl:for-each select="/Submission/ReviewerAttachment">
					<reviewerattachment>
						<xsl:if test="FileName/text()">
							<filename>
								<xsl:value-of select="FileName"/>
							</filename>
						</xsl:if>
						<xsl:if test="Description/text()">
							<description>
								<xsl:value-of select="Description"/>
							</description>
						</xsl:if>
						<xsl:if test="AttachmentType/text()">
							<typename>
								<xsl:value-of select="AttachmentType"/>
							</typename>
						</xsl:if>
					<xsl:if test="Submitter/IdentityValue/text()">
							<submittedby>
								<xsl:value-of select="Submitter/IdentityValue"/>
							</submittedby>
						</xsl:if>
											<xsl:if test="Revision/text()">
							<revision>
								<xsl:value-of select="Revision"/>
							</revision>
						</xsl:if>	
					</reviewerattachment>
				</xsl:for-each>
			</Files>
			<ReviewerAssignments>
				<xsl:for-each select="/Submission/ReviewerAssignments/ReviewerInfo">
					<ReviewerAssignment>
						<PeopleId>
							<xsl:value-of select="PeopleId"/>
						</PeopleId>
						<Revision>
							<xsl:value-of select="Revision"/>
						</Revision>
						<ReviewerAssignmentStart>
							<xsl:value-of select="ReviewerAssignmentStart"/>
						</ReviewerAssignmentStart>
						<ReviewerAssignmentStop>
							<xsl:value-of select="ReviewerAssignmentStop"/>
						</ReviewerAssignmentStop>
						<ReviewerRecommendation>
							<xsl:value-of select="ReviewerRecommendation"/>
						</ReviewerRecommendation>
						<CommentsToAuthor>
							<xsl:value-of select="CommentsToAuthor"/>
						</CommentsToAuthor>
						<Rank>
							<xsl:value-of select="Rank/text()"/>
						</Rank>
						<ReviewerRating>
							<xsl:value-of select="ReviewerRating"/>
						</ReviewerRating>
						<RoleID>
							<xsl:value-of select="RoleID/text()"/>
						</RoleID>
						<AllowReviewTransfer>
							<xsl:value-of select="AllowReviewTransfer/text()"/>
						</AllowReviewTransfer>
						<AllowReviewPublication>
							<xsl:value-of select="AllowReviewPublication/text()"/>
						</AllowReviewPublication>
						<AllowPersonalInfoTransferLastRevision>
							<xsl:value-of select="AllowPersonalInfoTransferLastRevision/text()"/>
						</AllowPersonalInfoTransferLastRevision>
						<Reviewer>
							<xsl:attribute name="IndentityReference"><xsl:value-of select="PeopleId"/></xsl:attribute>
							<xsl:copy-of select="Reviewer/node()"/>
							<ImportPeopleID>
								<xsl:value-of select="PeopleId"/>
							</ImportPeopleID>
						</Reviewer>
					</ReviewerAssignment>
				</xsl:for-each>
			</ReviewerAssignments>
			<ReviewerManuscriptRatings>
				<xsl:for-each select="/Submission/ReviewerManuscriptRatings/node()">
					<xsl:copy-of select="current()"/>
				</xsl:for-each>
			</ReviewerManuscriptRatings>
			<ReviewerAnswers>
				<xsl:for-each select="/Submission/ReviewerAnswers/node()">
					<xsl:if test="name() = ''Question''">
						<Question>
							<xsl:attribute name="RoleID"><xsl:value-of select="/Submission/ReviewerAnswers/@RoleID"/></xsl:attribute>
							<xsl:copy-of select="node()"/>
						</Question>
					</xsl:if>
				</xsl:for-each>
			</ReviewerAnswers>
			<AuthorTransferOffer>
				<xsl:copy-of select="/Submission/AuthorTransferOffer/node()"/>
			</AuthorTransferOffer>
			<TransferLetter>
				<xsl:copy-of select="/Submission/TransferLetter/node()"/>
			</TransferLetter>
		</Manuscript>
	</xsl:template>
</xsl:stylesheet> ';
	


  IF NOT EXISTS (SELECT 1 FROM DBO.SERVICE_CLASSES WITH (NOLOCK) WHERE DESCRIPTION = 'Em To Em Manuscript Transfer Export')
	BEGIN
	  IF EXISTS (SELECT 1 FROM DBO.SERVICE_CLASSES WITH (NOLOCK) WHERE SERVICE_CLASS_ID = 37)
		BEGIN
			INSERT INTO DBO.SERVICE_CLASSES (DESCRIPTION) VALUES('Em To Em Manuscript Transfer Export')
	 	
			SET @exportclass = (SELECT SERVICE_CLASS_ID FROM DBO.SERVICE_CLASSES WITH (NOLOCK)  WHERE [DESCRIPTION] = 'Em To Em Manuscript Transfer Export')
		END
	ELSE   
	     BEGIN
			SET IDENTITY_INSERT dbo.SERVICE_CLASSES  ON
			INSERT INTO DBO.SERVICE_CLASSES (SERVICE_CLASS_ID, DESCRIPTION) VALUES(@exportclass,'Em To Em Manuscript Transfer Export')	     	
	     	SET IDENTITY_INSERT dbo.SERVICE_CLASSES OFF;
	     END
	
	END
ELSE
	BEGIN
		SET @exportclass = (SELECT SERVICE_CLASS_ID FROM DBO.SERVICE_CLASSES WITH (NOLOCK)  WHERE [DESCRIPTION] = 'Em To Em Manuscript Transfer Export')
	END
	
DECLARE @importclass AS INT = 38

  IF NOT EXISTS (SELECT 1 FROM DBO.SERVICE_CLASSES WITH (NOLOCK) WHERE DESCRIPTION = 'Em To Em Manuscript Transfer Import')
	BEGIN
	  IF EXISTS (SELECT 1 FROM DBO.SERVICE_CLASSES WITH (NOLOCK) WHERE SERVICE_CLASS_ID = 37)
		BEGIN
			INSERT INTO DBO.SERVICE_CLASSES (DESCRIPTION) VALUES('Em To Em Manuscript Transfer Import')
	 	
			SET @importclass = (SELECT SERVICE_CLASS_ID FROM DBO.SERVICE_CLASSES WITH (NOLOCK)  WHERE [DESCRIPTION] = 'Em To Em Manuscript Transfer Import')
		END
	ELSE   
	     BEGIN
			SET IDENTITY_INSERT dbo.SERVICE_CLASSES  ON
			INSERT INTO DBO.SERVICE_CLASSES (SERVICE_CLASS_ID, DESCRIPTION) VALUES(@exportclass,'Em To Em Manuscript Transfer Import')	     	
	     	SET IDENTITY_INSERT dbo.SERVICE_CLASSES OFF;
	     END
	
	END
ELSE
	BEGIN
		SET @importclass = (SELECT SERVICE_CLASS_ID FROM DBO.SERVICE_CLASSES WITH (NOLOCK)  WHERE [DESCRIPTION] = 'Em To Em Manuscript Transfer Import')
	END

IF NOT EXISTS (SELECT 1 FROM dbo.SERVICE_PROFILE_TYPES WHERE PROFILE_TYPE_ID = 21)
BEGIN 
	SET IDENTITY_INSERT dbo.SERVICE_PROFILE_TYPES ON;
	INSERT INTO dbo.SERVICE_PROFILE_TYPES ([PROFILE_TYPE_ID],[DESCRIPTION]) VALUES(21, 'Manuscript Export')
	SET IDENTITY_INSERT dbo.SERVICE_PROFILE_TYPES OFF;
END
 
 IF NOT EXISTS (SELECT 1 FROM SERVICE_PROFILES WHERE PROFILE_ID = 58)
	BEGIN
		INSERT INTO SERVICE_PROFILES (PROFILE_ID, PROFILE_TYPE_ID, DESCRIPTION, SERVICE_CLASS, OVERWRITE_NAMES) VALUES (58, 21, 'Em To Em Manuscript Transfer Export', @exportclass, 0);
		 	
		INSERT INTO FILE_RESOURCES (RESOURCE_GUID, FILE_RESOURCE_TYPE_ID, DESCRIPTION, FILENAME, CONTENTS, READONLY, BASE64_ENCODED) 
			VALUES ('086075F1-116A-46D0-984B-69A52AF5D11C', 3, 'Em To Em Manuscript Transfer Export Transform file', 'em_to_em_transfer_Export.xsl', @Em2EmExportXSL, 0, 0);
			
		SET @fileresourceid =(SELECT SCOPE_IDENTITY());
		
		INSERT INTO SERVICE_PROFILE_RESOURCES (PROFILE_ID, RESOURCE_ID, RESOURCE_TYPE_ID, RESOURCE_IDENTIFIER,  [DESCRIPTION], [REQUIRED])
		 VALUES (58, @fileresourceid, 1, 'TRANSFORM_FILE',  'EM to Em Transfer Export', 0)
		
		--insert EXPORT XSD	
	 
		INSERT INTO FILE_RESOURCES (RESOURCE_GUID, FILE_RESOURCE_TYPE_ID, DESCRIPTION, FILENAME, CONTENTS, READONLY, BASE64_ENCODED) 
			VALUES ('6EF76940-C7E1-421C-B7AF-E33797830165',2, 'Em To Em Manuscript Transfer XSD', 'em_to_em_transfer_Export.xsd', @Em2EmExportXSD, 0, 0);

		
		SET @fileresourceid =(SELECT SCOPE_IDENTITY());
		
		INSERT INTO SERVICE_PROFILE_RESOURCES (PROFILE_ID, RESOURCE_ID, RESOURCE_TYPE_ID, RESOURCE_IDENTIFIER,  [DESCRIPTION], [REQUIRED])
		 VALUES (58, @fileresourceid, 1, 'DEFINITION_FILE',  'EM to Em Transfer Export', 0)

	--FTP RESOURCE START		
		 INSERT INTO [dbo].[FTP_RESOURCES] ([RESOURCE_GUID],[DESCRIPTION], [ADDRESS],[USERNAME],[PASSWORD],[Tooltip])
		 VALUES ('974384A5-F5D1-4542-86D1-6320F1E49E70','EM 2 EM Transfer FTP ','Not Used','Not Used','Not Used','')
		
		DECLARE @ftpresourceid AS INT
		SET @ftpresourceid =(SELECT SCOPE_IDENTITY());
		
		INSERT INTO SERVICE_PROFILE_RESOURCES (PROFILE_ID, RESOURCE_ID, RESOURCE_TYPE_ID, RESOURCE_IDENTIFIER,  [DESCRIPTION], [REQUIRED])
		 VALUES (58, @ftpresourceid, 2, 'FTP_SERVER',  'EM to Em Transfer Export', 0)
	 
	END
ELSE
	BEGIN
	
		UPDATE	FILE_RESOURCES SET CONTENTS = @Em2EmExportXSL
		WHERE RESOURCE_GUID = '086075F1-116A-46D0-984B-69A52AF5D11C';
		
		UPDATE	FILE_RESOURCES SET CONTENTS = @Em2EmExportXSD
		WHERE RESOURCE_GUID = '6EF76940-C7E1-421C-B7AF-E33797830165';
		
	END


--Spec 13.0-19
 IF NOT EXISTS (SELECT 1 FROM SERVICE_PROFILES WHERE PROFILE_ID = 59)
	BEGIN
		INSERT INTO SERVICE_PROFILES (PROFILE_ID, PROFILE_TYPE_ID, DESCRIPTION, SERVICE_CLASS, OVERWRITE_NAMES) VALUES (59, 2, 'Em To Em Manuscript Transfer Import', @importclass, 0);
	-- INSERT XSL
		 	
		INSERT INTO FILE_RESOURCES (RESOURCE_GUID, FILE_RESOURCE_TYPE_ID, DESCRIPTION, FILENAME, CONTENTS, READONLY, BASE64_ENCODED) 
			VALUES ('BA4DA770-F333-4CED-949C-9DEFA5C86DC6', 3, 'Em To Em Manuscript Transfer Import Transform file', 'em_to_em_transfer_import.xsl', @Em2EmImportXSL, 0, 0);

		SET @fileresourceid =(SELECT SCOPE_IDENTITY());
		
		INSERT INTO SERVICE_PROFILE_RESOURCES (PROFILE_ID, RESOURCE_ID, RESOURCE_TYPE_ID, RESOURCE_IDENTIFIER,  [DESCRIPTION], [REQUIRED])
			VALUES (59, @fileresourceid, 1, 'TRANSFORM_FILE', 'EM to Em Transfer Import', 0)


		--insert XSD
	 	
		INSERT INTO FILE_RESOURCES (RESOURCE_GUID, FILE_RESOURCE_TYPE_ID, DESCRIPTION, FILENAME, CONTENTS, READONLY, BASE64_ENCODED) 
			VALUES ('D1466F7D-9CC3-429B-B82D-B2B690D87638', 2, 'Em To Em Manuscript Transfer Import XSD', 'em_to_em_transfer_import.xsd', @Em2EmExportXSD, 0, 0);

		SET @fileresourceid =(SELECT SCOPE_IDENTITY());
		
		INSERT INTO SERVICE_PROFILE_RESOURCES (PROFILE_ID, RESOURCE_ID, RESOURCE_TYPE_ID, RESOURCE_IDENTIFIER,  [DESCRIPTION], [REQUIRED])
			VALUES (59, @fileresourceid, 1, 'DEFINITION_FILE', 'EM to Em Transfer Import', 0)

	--FTP RESOURCE START		
		 INSERT INTO [dbo].[FTP_RESOURCES] ([RESOURCE_GUID],[DESCRIPTION], [ADDRESS],[USERNAME],[PASSWORD],[Tooltip])
		 VALUES ('27401D7D-BA5E-417E-AC2A-16ADD508A44E','EM 2 EM Transfer FTP ','Not Used','Not Used','Not Used', '')
		
 		SET @ftpresourceid =(SELECT SCOPE_IDENTITY());
		
		INSERT INTO DBO.SERVICE_PROFILE_RESOURCES (PROFILE_ID, RESOURCE_ID, RESOURCE_TYPE_ID, RESOURCE_IDENTIFIER,  [DESCRIPTION], [REQUIRED])
		 VALUES (59, @ftpresourceid, 2, 'FTP_SERVER',  'EM to Em Transfer Import', 0)

	--FTP RESOURCE END		

	END
ELSE
	BEGIN
	
		UPDATE	FILE_RESOURCES SET CONTENTS = @Em2EmImportXSL
		WHERE RESOURCE_GUID = 'BA4DA770-F333-4CED-949C-9DEFA5C86DC6';
		
		UPDATE	FILE_RESOURCES SET CONTENTS = @Em2EmExportXSD
		WHERE RESOURCE_GUID = 'D1466F7D-9CC3-429B-B82D-B2B690D87638';
		
	END	
GO

--Spec 13.0-15

 IF NOT EXISTS (SELECT 1 FROM dbo.INSTRUCTIONS WHERE ASP_ID = 29)
	BEGIN
	DECLARE @rank int

	SELECT @rank = EDIT_INSTRUCTIONS_DISPLAY_ORDER
		FROM dbo.INSTRUCTIONS
		WHERE ASP_ID=4

	UPDATE dbo.INSTRUCTIONS
	SET [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = ([EDIT_INSTRUCTIONS_DISPLAY_ORDER]+1)
	WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] > @rank

	INSERT INTO dbo.INSTRUCTIONS
		  (
		   [NEW_DEFAULT]
		  ,[REVISED_DEFAULT]
		  ,[NEW_CUSTOM]
		  ,[REVISED_CUSTOM]
		  ,[LAST_UPDATE_DATE]
		  ,[EDIT_INSTRUCTIONS_DISPLAY_ORDER]
		  ,[ASP_ID]
		  ,[NEW_DEFAULT_RESOURCE_ID]
		  ,[REVISED_DEFAULT_RESOURCE_ID]
		  ,[SUPPRESS_DISPLAY])
	VALUES
		(NULL
		,NULL
		,NULL
		,NULL
		,GETDATE()
		,@rank + 1
		,29	-- Hidden
		,'Common.SubmissionSteps.FundingInfoReqCheckbox.NewDefaultInstructions'
		,'Common.SubmissionSteps.FundingInfoReqCheckbox.RevisedDefaultInstructions'
		,0)
	END		
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'INSTRUCTIONS' 
		AND COLUMN_NAME = N'INSTRUCTION_LABEL')
BEGIN
	ALTER TABLE dbo.INSTRUCTIONS
		ADD INSTRUCTION_LABEL NVARCHAR(MAX)
END
GO
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.EnterArticleType' WHERE ASP_ID = 1
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.EnterArticleTitle' WHERE ASP_ID = 2
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AddEditRemoveAuthors' WHERE ASP_ID = 3
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.FundingInformation' WHERE ASP_ID = 4
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.SelectSectionCategory' WHERE ASP_ID = 5
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.SubmitAbstract' WHERE ASP_ID = 6
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.EnterKeywords' WHERE ASP_ID = 7
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.SelectClassifications' WHERE ASP_ID = 8
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AdditionalInformation' WHERE ASP_ID = 9
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.EnterComments' WHERE ASP_ID = 10
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.SuggestReviewers' WHERE ASP_ID = 11
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.OpposeReviewers' WHERE ASP_ID = 12
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.RespondToReviewers' WHERE ASP_ID = 13
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.RequestEditor' WHERE ASP_ID = 14
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.SelectRegionOfOrigin' WHERE ASP_ID = 15
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AttachFileGeneralInstructions' WHERE ASP_ID = 16
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AttachFileRevisionFileSelection' WHERE ASP_ID = 17
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AttachFileItemsForThisSubmissionPriorInstructions' WHERE ASP_ID = 18
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AttachFileItemsForThisSubmissionInstructions' WHERE ASP_ID = 19
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AttachFilesOrderPage' WHERE ASP_ID = 20
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AttachFilesSummaryPage' WHERE ASP_ID = 21
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.BuildingPDFPage' WHERE ASP_ID = 22
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.SelectDocumentClassificationPopupWindow' WHERE ASP_ID = 23
UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.AddEditAuthorsPopupWindow' WHERE ASP_ID = 24

UPDATE dbo.INSTRUCTIONS SET INSTRUCTION_LABEL = 'Common.SubmissionSteps.FundingInfoReqCheckbox' WHERE ASP_ID = 29

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES
	   WHERE ROUTINE_NAME  = N'usp_SelectPeopleByGlobalUserId'
	   AND ROUTINE_TYPE = N'PROCEDURE')
BEGIN
    DROP PROCEDURE dbo.usp_SelectPeopleByGlobalUserId;
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'PEOPLE' 
		AND COLUMN_NAME = N'EXCLUDE_FROM_BATCH_EMAILS')
BEGIN
	ALTER TABLE dbo.PEOPLE
		ADD EXCLUDE_FROM_BATCH_EMAILS SMALLINT NOT NULL
		CONSTRAINT DF_PEOPLE_EXCLUDE_FROM_BATCH_EMAILS DEFAULT 0
END

IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'PERSON_INFO_AUDIT_TRAIL')
BEGIN
	CREATE TABLE [dbo].PERSON_INFO_AUDIT_TRAIL
	(
		PERSON_INFO_AUDIT_TRAIL_ID INT IDENTITY(1,1) NOT NULL,
		OPERATOR_ID INT NOT NULL,
		PROXY_OPERATOR_ID INT NULL,
		UPDATED_PEOPLE_ID INT NOT NULL,
		OPERATOR_ROLE_NAME NVARCHAR(40),
		UPDATED_DATA XML NOT NULL
		CONSTRAINT [PK_PERSON_INFO_AUDIT_TRAIL] PRIMARY KEY CLUSTERED (PERSON_INFO_AUDIT_TRAIL_ID ASC)
	)
	
	ALTER TABLE [dbo].PERSON_INFO_AUDIT_TRAIL  WITH NOCHECK ADD CONSTRAINT [FK_PERSON_INFO_AUDIT_TRAIL_PEOPLE_OPERATOR_ID] FOREIGN KEY(OPERATOR_ID)
	REFERENCES [dbo].PEOPLE (PEOPLEID)
	ON DELETE CASCADE
	
	ALTER TABLE [dbo].PERSON_INFO_AUDIT_TRAIL  WITH NOCHECK ADD CONSTRAINT [FK_PERSON_INFO_AUDIT_TRAIL_PEOPLE_PROXY_OPERATOR_ID] FOREIGN KEY(PROXY_OPERATOR_ID)
	REFERENCES [dbo].PEOPLE (PEOPLEID)
	
	ALTER TABLE [dbo].PERSON_INFO_AUDIT_TRAIL  WITH NOCHECK ADD CONSTRAINT [FK_PERSON_INFO_AUDIT_TRAIL_UPDATED_PEOPLE_ID] FOREIGN KEY(UPDATED_PEOPLE_ID)
	REFERENCES [dbo].PEOPLE (PEOPLEID)
END
GO

-- an instance of the static trigger rebuild just for the person info audit trail
/*----------------------------------------------------------------------------
 * Copyright © 2000-Present Aries Systems Corporation. All Rights Reserved.
 * Copying, reverse engineering, adaptation or any other derivative use
 * prohibited.  This material is proprietary and confidential information
 * of Aries Systems Corporation.
 *
 * Name: 6.0-39StaticTriggerReBuild.sql
 * Date Created: 20080305
 * Version Introduced: 6.1
 * Bug #: Fixes 6.0-39 implementation
 *
 * Implements 6.0-39 functionality:
 * Adds Row_LastModified_TimeStamp where necessary.
 * Creates a static RowLastUpdateTimeStamp trigger, bound by primary key columns, for each table
 * that has primary keys.
 *
 * IMPORTANT:
 * This script should be run when first deployed, as well as AT EACH HOTFIX (in case tables
 * have been added or primary keys have been changed).
 * 
 * ******* Spec 9.0-23 *********
 * 20120606	GBS
 * Revised @triggerOrderSQL = "@order=N''LAST''" from first. UDB Triggers must run first.
 * ---------------------------------------------------------------------------*/

SET QUOTED_IDENTIFIER OFF
SET ANSI_NULLS OFF
SET NOCOUNT ON
GO

--****************************************************************************
-- First main block:
--          Drop all RowLastUpdateTimeStamp triggers
--          Add Row_LastModified_TimeStamp columns where appropriate
--****************************************************************************

--******************************
-- Initialize variables
--******************************

DECLARE @numTables INT
        -- number of tables being processed
DECLARE @cnt INT
        -- current table name index
DECLARE @tableName VARCHAR(100)
           -- name of the table being processed
DECLARE @triggerName VARCHAR(200)
         -- name of the trigger being processed / searched for
DECLARE @addColSQL VARCHAR(1000)
          -- SQL to add the Row_LastModified_TimeStamp field

SELECT  @cnt = 1,
        @tableName = '',
        @triggerName = ''

-- This table variable will store the names of all the tables in the DB
-- (using 'EM_' makes it harder to confuse with TABLE_NAME columns)
DECLARE @EM_TABLE_NAMES TABLE
    (
      TABLE_NAME VARCHAR(100),
      TABLE_NAME_INDEX INT
    )

-- Store all table names into this table variable
INSERT  INTO @EM_TABLE_NAMES
        (
          TABLE_NAME,
          TABLE_NAME_INDEX
            
        )
        SELECT  'PERSON_INFO_AUDIT_TRAIL', 1

SET @numTables = @@ROWCOUNT


--******************************
-- Perform algorithm:
--          Drop all RowLastUpdateTimeStamp triggers
--          Add Row_LastModified_TimeStamp columns where appropriate
--******************************
WHILE @cnt <= @numTables  
    BEGIN
      -- Get the name of the current table
        SELECT  @tableName = TABLE_NAME
        FROM    @EM_TABLE_NAMES
        WHERE   TABLE_NAME_INDEX = @cnt
        ORDER BY TABLE_NAME

      -- Drop the trigger, if one exists

        SET @triggerName = N'[TRG_' + @tableName + '_RowLastUpdateTimeStamp]'

        IF EXISTS ( SELECT  1
                    FROM    dbo.sysobjects
                    WHERE   ( id = OBJECT_ID(@triggerName) )
                            AND ( OBJECTPROPERTY(id, N'IsTrigger') = 1 ) ) 
            EXEC ( 'DROP TRIGGER [dbo].' + @triggerName )

      -- Add a Row_LastModified_TimeStamp column, if it does not already exist
      -- and the table has a primary key
        IF NOT EXISTS ( SELECT  1
                        FROM    INFORMATION_SCHEMA.COLUMNS
                        WHERE   ( TABLE_NAME = @tableName )
                                AND ( COLUMN_NAME = 'Row_LastModified_TimeStamp' ) )
            AND EXISTS ( SELECT 1
                         FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk
                         WHERE  ( TABLE_NAME = @tableName )
                                AND ( CONSTRAINT_TYPE = 'PRIMARY KEY' ) ) 
            BEGIN
                SET @addColSQL = 'ALTER TABLE [dbo].[' + @tableName
                    + '] ADD [Row_LastModified_TimeStamp] DATETIME NOT NULL '
                    + 'CONSTRAINT [DF_' + @tableName
                    + '_Row_LastModified_TimeStamp] DEFAULT GETDATE()'
                EXEC ( @addColSQL )
            END

        SET @cnt = @cnt + 1
    END
GO


--****************************************************************************
-- Second main block:
--          Create triggers for all tables that have primary keys
--****************************************************************************

--******************************
-- Initialize variables
--******************************


DECLARE @numTables INT
        -- number of tables being processed
DECLARE @cnt INT
        -- current table name index
DECLARE @tableName VARCHAR(100)
           -- name of the table being processed
DECLARE @triggerSQL VARCHAR(1000)
         -- SQL content of the trigger we are creating (i.e. excluding "CREATE TRIGGER...")
DECLARE @pkColName VARCHAR(100)
           -- name of the current primary key column
DECLARE @numPKs INT
           -- total number of primary keys in the current table
DECLARE @pkCnt INT
            -- current primary key name index
DECLARE @updateJoinCriteriaSQL VARCHAR(1000)
          -- the criteria for the "JOIN...ON..." part of the trigger SQL content
DECLARE @triggerOrderSQL VARCHAR(1000)
          -- SQL to set the order in which triggers should be executed

SELECT  @cnt = 1,
        @tableName = ''

-- Declare temp memory table to hold primary key names
DECLARE @PK_COLUMNTBL TABLE
    (
      PK_COLNAME VARCHAR(60),
      PK_COLNAME_INDEX INT
    )

-- This table variable will store the names of all the tables in the DB that have primary keys
DECLARE @PK_TABLE_NAMES TABLE
    (
      TABLE_NAME VARCHAR(100),
      TABLE_NAME_INDEX INT
    )

-- Store all names of all table with primary keys into this table variable
INSERT  INTO @PK_TABLE_NAMES
        (
          TABLE_NAME,
          TABLE_NAME_INDEX
            
        )
        SELECT 'PERSON_INFO_AUDIT_TRAIL', 1

SET @numTables = @@ROWCOUNT


--******************************
-- Perform algorithm:
--          Create triggers for all tables that have primary keys
--******************************
WHILE @cnt <= @numTables  
    BEGIN
        SELECT  @tableName = TABLE_NAME
        FROM    @PK_TABLE_NAMES
        WHERE   TABLE_NAME_INDEX = @cnt
        ORDER BY TABLE_NAME

      -- Select the names of all the primary keys of the current table
        INSERT  INTO @PK_COLUMNTBL
                (
                  PK_COLNAME,
                  PK_COLNAME_INDEX
                  
                )
                SELECT  c.COLUMN_NAME,
                        ROW_NUMBER() OVER ( ORDER BY c.COLUMN_NAME )
                FROM    INFORMATION_SCHEMA.KEY_COLUMN_USAGE c ( nolock )
                        JOIN ( SELECT   TABLE_NAME,
                                        CONSTRAINT_NAME
                               FROM     INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ( nolock )
                               WHERE    pk.TABLE_NAME = @tableName
                                        AND CONSTRAINT_TYPE = 'PRIMARY KEY'
                             ) AS k ON c.TABLE_NAME = k.TABLE_NAME
                                       AND c.CONSTRAINT_NAME = k.CONSTRAINT_NAME

      -- Construst the criteria SQL for the JOIN ON clause of the trigger SQL content

        SET @numPKs = @@ROWCOUNT -- get the count of pk columns
        SET @pkCnt = 1
        SET @updateJoinCriteriaSQL = ''

      -- Loop through the primary keys, adding " AND INSERTED.colName = tableName.pkColName" for each one
        WHILE ( @pkCnt <= @numPKs )
            BEGIN
                SELECT  @pkColName = [PK_COLNAME]
                FROM    @PK_COLUMNTBL
                WHERE   [PK_COLNAME_INDEX] = @pkCnt

                SET @updateJoinCriteriaSQL = @updateJoinCriteriaSQL
                    + ' AND INSERTED.[' + @pkColName + '] = [' + @tableName
                    + '].[' + @pkColName + ']'

                SET @pkCnt = @pkCnt + 1
            END

      -- Remove the initial " AND " of the criteria SQL
        SET @updateJoinCriteriaSQL = SUBSTRING(@updateJoinCriteriaSQL, 6,
                                               LEN(@updateJoinCriteriaSQL))

        SET @triggerSQL = 'SET NOCOUNT ON IF TRIGGER_NESTLEVEL() = 1 BEGIN UPDATE [dbo].['
            + @tableName
            + '] SET [ROW_LASTMODIFIED_TIMESTAMP] = GETDATE() FROM ['
            + @tableName + '] JOIN INSERTED ON ' + @updateJoinCriteriaSQL
            + ' END'

     
        EXEC
            ( 'CREATE TRIGGER TRG_' + @tableName
              + '_RowLastUpdateTimeStamp ON [dbo].[' + @tableName
              + '] AFTER UPDATE AS ' + @triggerSQL )

    --PRINT 'CREATE TRIGGER TRG_' + @tableName + '_RowLastUpdateTimeStamp ON [dbo].[' + @tableName + '] AFTER UPDATE AS ' + @triggerSQL

      --This sets the Trigger firing order, currently we are setting it to last        
        SET @triggerOrderSQL = 'sp_settriggerorder @triggername=N''[dbo].[TRG_'
            + @tableName
            + '_RowLastUpdateTimeStamp]'', @order=N''LAST'', @stmttype=N''UPDATE'''
        EXEC ( @triggerOrderSQL )

	  --PRINT @triggerOrderSQL

        SET @cnt = @cnt + 1    
    END
GO

-- Bug #23132
-- SESSIONTABLE trigger needs to be disabled if it is available and enabled
IF EXISTS (SELECT 1 FROM [sys].[triggers] WHERE [NAME] = N'TRG_SESSIONTABLE_RowLastUpdateTimeStamp' AND IS_DISABLED = 0) 
BEGIN
	DISABLE TRIGGER [dbo].[TRG_SESSIONTABLE_RowLastUpdateTimeStamp] ON [dbo].[SESSIONTABLE]
END

IF EXISTS (SELECT 1 FROM [sys].[triggers] WHERE [NAME] = N'TRG_VIEWSTATE_CACHE_RowLastUpdateTimeStamp' AND IS_DISABLED = 0) 
BEGIN
	DISABLE TRIGGER [dbo].[TRG_VIEWSTATE_CACHE_RowLastUpdateTimeStamp] ON [dbo].[VIEWSTATE_CACHE]
END

-- Refresh the views of the database
EXEC usp_RefreshAllViews
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SCHEDULE_GROUP_FAMILY')
begin
	-- SCHEDULE_GROUP_FAMILY
	create table SCHEDULE_GROUP_FAMILY (
		SCHEDULE_GROUP_FAMILY_ID int not null
			constraint PK_SCHEDULE_GROUP_FAMILY_SCHEDULE_GROUP_FAMILY_ID primary key,
		NAME nvarchar(80) not null
	);
	
	insert into SCHEDULE_GROUP_FAMILY(SCHEDULE_GROUP_FAMILY_ID, NAME)
		values (0, 'Issue Schedule Group'), (1, 'Book Schedule Group');
end
GO

	-- DETAILS_PAGE_LAYOUT_ITEMS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DETAILS_PAGE_LAYOUT_ITEMS' AND COLUMN_NAME = 'BOOK_RELATED')
BEGIN
	alter table DETAILS_PAGE_LAYOUT_ITEMS
	add BOOK_RELATED bit not null
		constraint DF_DETAILS_PAGE_LAYOUT_ITEMS_BOOK_RELATED default 0;
END
	
	-- DCATEGOR
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS	WHERE TABLE_NAME = 'DCATEGOR' AND COLUMN_NAME = 'BOOK_RELATED')
BEGIN
	alter table DCATEGOR add
	BOOK_RELATED bit not null
		constraint DF_DCATEGOR_BOOK_RELATED default 0,
	ASSIGN_TO_SCHEDULE_GROUP tinyint not null
		constraint DF_DCATEGOR_ASSIGN_TO_SCHEDULE_GROUP default 2
		constraint CHK_DCATEGOR_ASSIGN_TO_SCHEDULE_GROUP check (ASSIGN_TO_SCHEDULE_GROUP in (0, 1, 2));
END
		
	-- SCHEDULE_GROUP_TOC_HEADERS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS	WHERE TABLE_NAME = 'SCHEDULE_GROUP_TOC_HEADERS' AND COLUMN_NAME = 'DOCUMENTID')
BEGIN
	alter table SCHEDULE_GROUP_TOC_HEADERS add
	DOCUMENTID int null
		constraint FK_SCHEDULE_GROUP_TOC_HEADERS_DOCUMENTID foreign key references DOCUMENT(DOCUMENTID);
END
	
	-- SCHEDULE_GROUPS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS	WHERE TABLE_NAME = 'SCHEDULE_GROUPS' AND COLUMN_NAME = 'SCHEDULE_GROUP_FAMILY_ID')
BEGIN
	alter table SCHEDULE_GROUPS add
	SCHEDULE_GROUP_FAMILY_ID int not null
		constraint DF_SCHEDULE_GROUPS_SCHEDULE_GROUP_FAMILY_ID default 0
		constraint FK_SCHEDULE_GROUPS_SCHEDULE_GROUP_FAMILY_ID foreign key 
			references SCHEDULE_GROUP_FAMILY(SCHEDULE_GROUP_FAMILY_ID),
	TITLE nvarchar(MAX) null,
	ISBN nvarchar(256) null,
	EDITION nvarchar(256) null,
	AUTHORS_EDITORS nvarchar(MAX) null,
	DOPPLER_BW_BUDGET INT NULL,
	DOPPLER_COLOR_BUDGET INT NULL,
	CHAR_COUNT_TEXT INT NULL,
	TEXT_MANUSCRIPT_PAGES INT NULL,
	ESTIMATED_TEXT_PAGES INT NULL,
	NUM_REFERENCES INT NULL,
	ESTIMATED_REFERENCE_PAGES INT NULL,
	NUM_TABLES INT NULL,
	ESTIMATED_TABLE_PAGES INT NULL,
	NUM_FIGURES INT NULL,
	ESTIMATED_FIGURE_PAGES INT NULL,
	ESTIMATED_PRINTED_PAGES INT NULL,
	PREVIOUS_EDITION_PAGES INT NULL;
END
	
	-- TARGET
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TARGET' AND COLUMN_NAME = 'BOOK_RELATED')
BEGIN
	alter table TARGET add
	BOOK_RELATED bit not null
		constraint DF_TARGET_BOOK_RELATED default 0
END
GO

IF NOT EXISTS(SELECT 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'SUBMISSION_PRODUCTION' AND COLUMN_NAME = 'CHAR_COUNT_TEXT')
BEGIN
	ALTER TABLE dbo.SUBMISSION_PRODUCTION ADD 
	CHAR_COUNT_TEXT INT NULL,
	TEXT_MANUSCRIPT_PAGES INT NULL,
	ESTIMATED_TEXT_PAGES INT NULL,
	NUM_REFERENCES INT NULL,
	ESTIMATED_REFERENCE_PAGES INT NULL,
	NUM_TABLES INT NULL,
	ESTIMATED_TABLE_PAGES INT NULL,
	NUM_FIGURES INT NULL,
	ESTIMATED_FIGURE_PAGES INT NULL,
	ESTIMATED_PRINTED_PAGES INT NULL,
	PREVIOUS_EDITION_CHAPTER NVARCHAR(256) NULL,
	PREVIOUS_EDITION_PAGES INT NULL,
	DOPPLER_BW_COUNT INT NULL,
	DOPPLER_COLOR_COUNT INT NULL;
END	
GO

if not exists (select 1 from MASTER_CONFIG where CONFIG_ID = 311)
begin
	update ADMINACCESSFUNCTIONS
	set ITEMORDER = ITEMORDER + 1
	where PAGEID = 4 and SECTIONID = 15 and GROUPID = 17 and ITEMORDER >= 4;
	
	-- ADMINACCESSFUNCTIONS
	insert into ADMINACCESSFUNCTIONS (
		PAGEID, 
		SECTIONID, 
		GROUPID, 
		ITEMORDER, 
		PRODUCTID, 
		ITEMTEXT, 
		WEBPAGENAME,
		ACTIVE, 
		POLICYDISPLAYRULES, 
		RESOURCEID
	) values (
		4, 
		15, 
		17, 
		4, 
		2, 
		'Configure Book Processing', 
		'ConfigureBookProcessing.aspx',
		1, 
		16, --Production Tracking enabled
		'Pages.Admin.PolicyManager.LinkConfigureBookProcessing'
	);
	
	-- MASTER_CONFIG
	insert into MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	values (311, 'Book Processing Enabled', 'False', getdate()),
		   (312, 'Create new Schedule Groups in Book Schedule Group Family', 'False', getdate());
	
	-- DETAILS_PAGE_LAYOUTS
	declare @DefaultBooksLayoutID int
	insert into DETAILS_PAGE_LAYOUTS (
		LAYOUT_NAME,
		IS_PRODUCTION_LAYOUT,
		CONTEXT_AVAILABILITY,
		IS_DEFAULT,
		DEFAULT_LAYOUT_TYPE
	) values (
		'Default Books',
		1,
		2, --Production
		1,
		6
	)
	set @DefaultBooksLayoutID = SCOPE_IDENTITY();

	-- DETAILS_PAGE_LAYOUT_HEADERS
	IF NOT EXISTS (SELECT HEADER_ID FROM dbo.DETAILS_PAGE_LAYOUT_HEADERS WHERE RESOURCE_ID = 'Common.PageLayout.ItemName.LabelEditors')
	BEGIN
		INSERT INTO dbo.DETAILS_PAGE_LAYOUT_HEADERS (HEADER_NAME, RESOURCE_ID)
			VALUES ('Editors', 'Common.PageLayout.ItemName.LabelEditors')
	END
	IF NOT EXISTS (SELECT HEADER_ID FROM dbo.DETAILS_PAGE_LAYOUT_HEADERS WHERE RESOURCE_ID = 'Common.PageLayout.ItemName.LabelProductionTasks')
	BEGIN
		INSERT INTO dbo.DETAILS_PAGE_LAYOUT_HEADERS (HEADER_NAME, RESOURCE_ID)
			VALUES ('Production Tasks', 'Common.PageLayout.ItemName.LabelProductionTasks')
	END
	IF NOT EXISTS (SELECT HEADER_ID FROM dbo.DETAILS_PAGE_LAYOUT_HEADERS WHERE RESOURCE_ID = 'Common.PageLayout.HeaderName.ScheduleGroupInformation')
	BEGIN
		INSERT INTO dbo.DETAILS_PAGE_LAYOUT_HEADERS (HEADER_NAME, RESOURCE_ID)
			VALUES ('Schedule Group Information', 'Common.PageLayout.HeaderName.ScheduleGroupInformation')
	END
	
	-- DETAILS_PAGE_LAYOUT_ITEMS
	update DETAILS_PAGE_LAYOUT_ITEMS
	set SORT_ORDER = SORT_ORDER + 
		(CASE WHEN SORT_ORDER < 12 THEN 4
		      WHEN SORT_ORDER = 12 THEN 5
			  WHEN SORT_ORDER > 12 THEN 6 END)
	where CATEGORY_ID = 7 and SORT_ORDER >=3;
	
	SET IDENTITY_INSERT dbo.DETAILS_PAGE_LAYOUT_ITEMS ON;
	insert into DETAILS_PAGE_LAYOUT_ITEMS (
		ITEM_ID,
		HAS_ADDITIONAL_PERMISSIONS, 
		IS_PRODUCTION_ITEM, 
		IS_SECTION_HEADING, 
		CATEGORY_ID, 
		SORT_ORDER, 
		DETAILS_LABEL, 
		CONTEXT_AVAILABILITY, 
		ITEM_NAME_RESOURCE_ID, 
		DETAILS_LABEL_RESOURCE_ID,
		BOOK_RELATED)
	values
		(108, 0, 1, 0, 7, 3, 'Schedule Group Title', 3, 
			'Common.PageLayout.ItemName.LabelScheduleGroupTitle', 
			'Common.SubmissionDetails.ScheduleGroupTitle', 1),
		(109, 0, 1, 0, 7, 4, 'Schedule Group ISBN', 3,
			'Common.PageLayout.ItemName.LabelScheduleGroupISBN',
			'Common.SubmissionDetails.ScheduleGroupISBN', 1),
		(110, 0, 1, 0, 7, 5, 'Schedule Group Edition', 3,
			'Common.PageLayout.ItemName.LabelScheduleGroupEdition',
			'Common.SubmissionDetails.ScheduleGroupEdition', 1),
		(111, 0, 1, 0, 7, 6, 'Schedule Group Authors/Volume Editors', 3,
			'Common.PageLayout.ItemName.LabelScheduleGroupAuthors',
			'Common.SubmissionDetails.ScheduleGroupAuthors', 1),
		(112, 0, 1, 0, 7, 16, 'Doppler Black and White Count', 3,
			'Common.PageLayout.ItemName.LabelDopplerBlackAndWhiteCount',
			'Common.SubmissionDetails.DopplerBlackAndWhiteCount', 1),
		(113, 0, 1, 0, 7, 18, 'Doppler Color Count', 3,
			'Common.PageLayout.ItemName.LabelDopplerColorCount',
			'Common.SubmissionDetails.DopplerColorCount', 1),
		(114, 0, 1, 0, 7, 33, 'Previous Edition Chapter', 3,
			'Common.PageLayout.ItemName.LabelPreviousEditionChapter',
			'Common.SubmissionDetails.PreviousEditionChapter', 1),
		(115, 0, 1, 0, 7, 34, 'Previous Edition pp', 3,
			'Common.PageLayout.ItemName.LabelPreviousEditionPages',
			'Common.SubmissionDetails.PreviousEditionPages', 1),
		(116, 0, 1, 0, 7, 35, 'Char Count Text', 3,
			'Common.PageLayout.ItemName.LabelCharCountText',
			'Common.SubmissionDetails.CharCountText', 1),
		(117, 0, 1, 0, 7, 36, 'Text (ms pp)', 3,
			'Common.PageLayout.ItemName.LabelTextManuscriptPages',
			'Common.SubmissionDetails.TextManuscriptPages', 1),
		(118, 0, 1, 0, 7, 37, 'Estimated Text pp', 3,
			'Common.PageLayout.ItemName.LabelEstimatedTextPages',
			'Common.SubmissionDetails.EstimatedTextPages', 1),
		(119, 0, 1, 0, 7, 38, 'References (#)', 3,
			'Common.PageLayout.ItemName.LabelReferences',
			'Common.SubmissionDetails.References', 1),
		(120, 0, 1, 0, 7, 39, 'Estimated Reference pp', 3,
			'Common.PageLayout.ItemName.LabelEstimatedReferencePages',
			'Common.SubmissionDetails.EstimatedReferencePages', 1),
		(121, 0, 1, 0, 7, 40, 'Tables (#)', 3,
			'Common.PageLayout.ItemName.LabelTables',
			'Common.SubmissionDetails.Tables', 1),
		(122, 0, 1, 0, 7, 41, 'Estimated Table pp', 3,
			'Common.PageLayout.ItemName.LabelEstimatedTablePages',
			'Common.SubmissionDetails.EstimatedTablePages', 1),
		(123, 0, 1, 0, 7, 42, 'FIGS Total # of parts', 3,
			'Common.PageLayout.ItemName.LabelFigsTotalNumberOfParts',
			'Common.SubmissionDetails.FigsTotalNumberOfParts', 1),
		(124, 0, 1, 0, 7, 43, 'Estimated Figure pp', 3,
			'Common.PageLayout.ItemName.LabelEstimatedFigurePages',
			'Common.SubmissionDetails.EstimatedFigurePages', 1),
		(125, 0, 1, 0, 7, 44, 'Estimated Printed pp', 3,
			'Common.PageLayout.ItemName.LabelEstimatedPrintedPages',
			'Common.SubmissionDetails.EstimatedPrintedPages', 1);

			SET IDENTITY_INSERT dbo.DETAILS_PAGE_LAYOUT_ITEMS OFF;
	
	-- DETAILS_PAGE_LAYOUT_ITEMS_LIST
	insert into DETAILS_PAGE_LAYOUT_ITEMS_LIST (LAYOUT_ID, ITEM_ID, SHOW_LINK, SORT_ORDER, ITEM_TYPE_ID)
	values (@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Additional Manuscript Details'), 
			1, 1, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Full Title'), 
			0, 2, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Short Title'), 
			0, 3, 1),
			(@DefaultBooksLayoutID, 
			(SELECT HEADER_ID FROM dbo.DETAILS_PAGE_LAYOUT_HEADERS WHERE RESOURCE_ID = 'Common.PageLayout.ItemName.LabelEditors'), 
			1, 4, 3),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Corresponding Editor'), 
			0, 5, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Editors'), 
			0, 6, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Corresponding Author'), 
			0, 7, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Corresponding Author E-Mail'), 
			0, 8, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Invitation Notes to Author'), 
			0, 9, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Author Comments'), 
			0, 10, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Other Authors'), 
			0, 11, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Author Questionnaire Summary'), 
			0, 12, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Article Type'), 
			0, 13, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Keywords'), 
			0, 14, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Classifications'), 
			0, 15, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Technical Check'), 
			0, 16, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Editorial Status Date'), 
			0, 17, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Current Editorial Status'), 
			0, 18, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Production Status'), 
			0, 19, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Corresponding Production Editor'), 
			0, 20, 1),
			(@DefaultBooksLayoutID, 
			(SELECT HEADER_ID FROM dbo.DETAILS_PAGE_LAYOUT_HEADERS WHERE RESOURCE_ID = 'Common.PageLayout.HeaderName.ScheduleGroupInformation'), 
			1, 21, 3),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Schedule Group'), 
			0, 22, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Schedule Group Title'), 
			0, 23, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Schedule Group ISBN'), 
			0, 24, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Schedule Group Edition'), 
			0, 25, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Schedule Group Authors/Volume Editors'), 
			0, 26, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Schedule Group Target Publication Date'), 
			0, 27, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Schedule Group Target Volume'), 
			0, 28, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Position in Schedule Group Contents'), 
			0, 29, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Target Number of Pages'), 
			0, 30, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Target Start Page'), 
			0, 31, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Target End Page'), 
			0, 32, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Black and White Image Count'), 
			0, 33, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Doppler Black and White Count'), 
			0, 34, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Color Image Count'), 
			0, 35, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Doppler Color Count'), 
			0, 36, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Target Publication Date'), 
			0, 37, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Target Volume'), 
			0, 38, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Actual Number of Pages'), 
			0, 39, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Actual Start Page'), 
			0, 40, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Actual End Page'), 
			0, 41, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Actual Volume Number '), 
			0, 42, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Actual TOC Position'), 
			0, 43, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Previous Edition Chapter'), 
			0, 44, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Previous Edition pp'), 
			0, 45, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Char Count Text'), 
			0, 46, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Text (ms pp)'), 
			0, 47, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Estimated Text pp'), 
			0, 48, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'References (#)'), 
			0, 49, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Estimated Reference pp'), 
			0, 50, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Tables (#)'), 
			0, 51, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Estimated Table pp'), 
			0, 52, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'FIGS Total # of parts'), 
			0, 53, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Estimated Figure pp'), 
			0, 54, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Estimated Printed pp'), 
			0, 55, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Publish Information'), 
			0, 56, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'File Inventory'), 
			0, 57, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Production Notes'), 
			0, 58, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Transmittal Form'), 
			0, 59, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Discussion Forum'), 
			0, 60, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Submission Flags'), 
			0, 61, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Select Submissions Flags'), 
			0, 62, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Final Decision Term'), 
			0, 63, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Abstract'), 
			0, 64, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Manuscript Notes'), 
			0, 65, 1),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Additional Information'), 
			0, 66, 1),
			(@DefaultBooksLayoutID, 
			(SELECT HEADER_ID FROM dbo.DETAILS_PAGE_LAYOUT_HEADERS WHERE RESOURCE_ID = 'Common.PageLayout.ItemName.LabelProductionTasks'), 
			1, 67, 3),
			(@DefaultBooksLayoutID, 
			(SELECT ITEM_ID FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Production Tasks'), 
			0, 68, 1)

END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SCHEDULE_GROUP_TOC_HEADERS' AND COLUMN_NAME = 'HIDDEN')
BEGIN
	alter table SCHEDULE_GROUP_TOC_HEADERS
	add HIDDEN bit not null
		constraint DF_SCHEDULE_GROUP_TOC_HEADERS_HIDDEN default 0;
END

IF NOT EXISTS (SELECT 1 from APP_PAGES where PAGE_NAME = 'AddEditScheduleGroup.aspx')
BEGIN
	EXEC SP_INTERNAL_addSortPage @pageName = 'AddEditScheduleGroup.aspx', @folderName = ''
END


-- an instance of the static trigger rebuild just for the schedule group family
/*----------------------------------------------------------------------------
 * Copyright © 2000-Present Aries Systems Corporation. All Rights Reserved.
 * Copying, reverse engineering, adaptation or any other derivative use
 * prohibited.  This material is proprietary and confidential information
 * of Aries Systems Corporation.
 *
 * Name: 6.0-39StaticTriggerReBuild.sql
 * Date Created: 20080305
 * Version Introduced: 6.1
 * Bug #: Fixes 6.0-39 implementation
 *
 * Implements 6.0-39 functionality:
 * Adds Row_LastModified_TimeStamp where necessary.
 * Creates a static RowLastUpdateTimeStamp trigger, bound by primary key columns, for each table
 * that has primary keys.
 *
 * IMPORTANT:
 * This script should be run when first deployed, as well as AT EACH HOTFIX (in case tables
 * have been added or primary keys have been changed).
 * 
 * ******* Spec 9.0-23 *********
 * 20120606	GBS
 * Revised @triggerOrderSQL = "@order=N''LAST''" from first. UDB Triggers must run first.
 * ---------------------------------------------------------------------------*/

SET QUOTED_IDENTIFIER OFF
SET ANSI_NULLS OFF
SET NOCOUNT ON
GO

--****************************************************************************
-- First main block:
--          Drop all RowLastUpdateTimeStamp triggers
--          Add Row_LastModified_TimeStamp columns where appropriate
--****************************************************************************

--******************************
-- Initialize variables
--******************************

DECLARE @numTables INT
        -- number of tables being processed
DECLARE @cnt INT
        -- current table name index
DECLARE @tableName VARCHAR(100)
           -- name of the table being processed
DECLARE @triggerName VARCHAR(200)
         -- name of the trigger being processed / searched for
DECLARE @addColSQL VARCHAR(1000)
          -- SQL to add the Row_LastModified_TimeStamp field

SELECT  @cnt = 1,
        @tableName = '',
        @triggerName = ''

-- This table variable will store the names of all the tables in the DB
-- (using 'EM_' makes it harder to confuse with TABLE_NAME columns)
DECLARE @EM_TABLE_NAMES TABLE
    (
      TABLE_NAME VARCHAR(100),
      TABLE_NAME_INDEX INT
    )

-- Store all table names into this table variable
INSERT  INTO @EM_TABLE_NAMES
        (
          TABLE_NAME,
          TABLE_NAME_INDEX
            
        )
        SELECT  'SCHEDULE_GROUP_FAMILY', 1

SET @numTables = @@ROWCOUNT


--******************************
-- Perform algorithm:
--          Drop all RowLastUpdateTimeStamp triggers
--          Add Row_LastModified_TimeStamp columns where appropriate
--******************************
WHILE @cnt <= @numTables  
    BEGIN
      -- Get the name of the current table
        SELECT  @tableName = TABLE_NAME
        FROM    @EM_TABLE_NAMES
        WHERE   TABLE_NAME_INDEX = @cnt
        ORDER BY TABLE_NAME

      -- Drop the trigger, if one exists

        SET @triggerName = N'[TRG_' + @tableName + '_RowLastUpdateTimeStamp]'

        IF EXISTS ( SELECT  1
                    FROM    dbo.sysobjects
                    WHERE   ( id = OBJECT_ID(@triggerName) )
                            AND ( OBJECTPROPERTY(id, N'IsTrigger') = 1 ) ) 
            EXEC ( 'DROP TRIGGER [dbo].' + @triggerName )

      -- Add a Row_LastModified_TimeStamp column, if it does not already exist
      -- and the table has a primary key
        IF NOT EXISTS ( SELECT  1
                        FROM    INFORMATION_SCHEMA.COLUMNS
                        WHERE   ( TABLE_NAME = @tableName )
                                AND ( COLUMN_NAME = 'Row_LastModified_TimeStamp' ) )
            AND EXISTS ( SELECT 1
                         FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk
                         WHERE  ( TABLE_NAME = @tableName )
                                AND ( CONSTRAINT_TYPE = 'PRIMARY KEY' ) ) 
            BEGIN
                SET @addColSQL = 'ALTER TABLE [dbo].[' + @tableName
                    + '] ADD [Row_LastModified_TimeStamp] DATETIME NOT NULL '
                    + 'CONSTRAINT [DF_' + @tableName
                    + '_Row_LastModified_TimeStamp] DEFAULT GETDATE()'
                EXEC ( @addColSQL )
            END

        SET @cnt = @cnt + 1
    END
GO


--****************************************************************************
-- Second main block:
--          Create triggers for all tables that have primary keys
--****************************************************************************

--******************************
-- Initialize variables
--******************************


DECLARE @numTables INT
        -- number of tables being processed
DECLARE @cnt INT
        -- current table name index
DECLARE @tableName VARCHAR(100)
           -- name of the table being processed
DECLARE @triggerSQL VARCHAR(1000)
         -- SQL content of the trigger we are creating (i.e. excluding "CREATE TRIGGER...")
DECLARE @pkColName VARCHAR(100)
           -- name of the current primary key column
DECLARE @numPKs INT
           -- total number of primary keys in the current table
DECLARE @pkCnt INT
            -- current primary key name index
DECLARE @updateJoinCriteriaSQL VARCHAR(1000)
          -- the criteria for the "JOIN...ON..." part of the trigger SQL content
DECLARE @triggerOrderSQL VARCHAR(1000)
          -- SQL to set the order in which triggers should be executed

SELECT  @cnt = 1,
        @tableName = ''

-- Declare temp memory table to hold primary key names
DECLARE @PK_COLUMNTBL TABLE
    (
      PK_COLNAME VARCHAR(60),
      PK_COLNAME_INDEX INT
    )

-- This table variable will store the names of all the tables in the DB that have primary keys
DECLARE @PK_TABLE_NAMES TABLE
    (
      TABLE_NAME VARCHAR(100),
      TABLE_NAME_INDEX INT
    )

-- Store all names of all table with primary keys into this table variable
INSERT  INTO @PK_TABLE_NAMES
        (
          TABLE_NAME,
          TABLE_NAME_INDEX
            
        )
        SELECT 'SCHEDULE_GROUP_FAMILY', 1

SET @numTables = @@ROWCOUNT


--******************************
-- Perform algorithm:
--          Create triggers for all tables that have primary keys
--******************************
WHILE @cnt <= @numTables  
    BEGIN
        SELECT  @tableName = TABLE_NAME
        FROM    @PK_TABLE_NAMES
        WHERE   TABLE_NAME_INDEX = @cnt
        ORDER BY TABLE_NAME

      -- Select the names of all the primary keys of the current table
        INSERT  INTO @PK_COLUMNTBL
                (
                  PK_COLNAME,
                  PK_COLNAME_INDEX
                  
                )
                SELECT  c.COLUMN_NAME,
                        ROW_NUMBER() OVER ( ORDER BY c.COLUMN_NAME )
                FROM    INFORMATION_SCHEMA.KEY_COLUMN_USAGE c ( nolock )
                        JOIN ( SELECT   TABLE_NAME,
                                        CONSTRAINT_NAME
                               FROM     INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ( nolock )
                               WHERE    pk.TABLE_NAME = @tableName
                                        AND CONSTRAINT_TYPE = 'PRIMARY KEY'
                             ) AS k ON c.TABLE_NAME = k.TABLE_NAME
                                       AND c.CONSTRAINT_NAME = k.CONSTRAINT_NAME

      -- Construst the criteria SQL for the JOIN ON clause of the trigger SQL content

        SET @numPKs = @@ROWCOUNT -- get the count of pk columns
        SET @pkCnt = 1
        SET @updateJoinCriteriaSQL = ''

      -- Loop through the primary keys, adding " AND INSERTED.colName = tableName.pkColName" for each one
        WHILE ( @pkCnt <= @numPKs )
            BEGIN
                SELECT  @pkColName = [PK_COLNAME]
                FROM    @PK_COLUMNTBL
                WHERE   [PK_COLNAME_INDEX] = @pkCnt

                SET @updateJoinCriteriaSQL = @updateJoinCriteriaSQL
                    + ' AND INSERTED.[' + @pkColName + '] = [' + @tableName
                    + '].[' + @pkColName + ']'

                SET @pkCnt = @pkCnt + 1
            END

      -- Remove the initial " AND " of the criteria SQL
        SET @updateJoinCriteriaSQL = SUBSTRING(@updateJoinCriteriaSQL, 6,
                                               LEN(@updateJoinCriteriaSQL))

        SET @triggerSQL = 'SET NOCOUNT ON IF TRIGGER_NESTLEVEL() = 1 BEGIN UPDATE [dbo].['
            + @tableName
            + '] SET [ROW_LASTMODIFIED_TIMESTAMP] = GETDATE() FROM ['
            + @tableName + '] JOIN INSERTED ON ' + @updateJoinCriteriaSQL
            + ' END'

     
        EXEC
            ( 'CREATE TRIGGER TRG_' + @tableName
              + '_RowLastUpdateTimeStamp ON [dbo].[' + @tableName
              + '] AFTER UPDATE AS ' + @triggerSQL )

    --PRINT 'CREATE TRIGGER TRG_' + @tableName + '_RowLastUpdateTimeStamp ON [dbo].[' + @tableName + '] AFTER UPDATE AS ' + @triggerSQL

      --This sets the Trigger firing order, currently we are setting it to last        
        SET @triggerOrderSQL = 'sp_settriggerorder @triggername=N''[dbo].[TRG_'
            + @tableName
            + '_RowLastUpdateTimeStamp]'', @order=N''LAST'', @stmttype=N''UPDATE'''
        EXEC ( @triggerOrderSQL )

	  --PRINT @triggerOrderSQL

        SET @cnt = @cnt + 1    
    END
GO

-- Bug #23132
-- SESSIONTABLE trigger needs to be disabled if it is available and enabled
IF EXISTS (SELECT 1 FROM [sys].[triggers] WHERE [NAME] = N'TRG_SESSIONTABLE_RowLastUpdateTimeStamp' AND IS_DISABLED = 0) 
BEGIN
	DISABLE TRIGGER [dbo].[TRG_SESSIONTABLE_RowLastUpdateTimeStamp] ON [dbo].[SESSIONTABLE]
END

IF EXISTS (SELECT 1 FROM [sys].[triggers] WHERE [NAME] = N'TRG_VIEWSTATE_CACHE_RowLastUpdateTimeStamp' AND IS_DISABLED = 0) 
BEGIN
	DISABLE TRIGGER [dbo].[TRG_VIEWSTATE_CACHE_RowLastUpdateTimeStamp] ON [dbo].[VIEWSTATE_CACHE]
END

-- Refresh the views of the database
EXEC usp_RefreshAllViews
GO

--Spec 13.0-31
--DCATEGOR
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'EDITOR_CAN_SET_SUBMISSION_TITLE')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD [EDITOR_CAN_SET_SUBMISSION_TITLE] SMALLINT NOT NULL CONSTRAINT [DF_DCATEGOR_EDITOR_CAN_SET_SUBMISSION_TITLE]  DEFAULT ((0));
END

--DOCUMENT
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DOCUMENT' 
		AND COLUMN_NAME = N'TITLES_LOCKED')
BEGIN
	ALTER TABLE dbo.DOCUMENT
		ADD [TITLES_LOCKED]  SMALLINT NOT NULL CONSTRAINT [DF_DOCUMENT_TITLES_LOCKED]  DEFAULT ((0));
END

--EDITORROLE
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'EDITORROLE' 
		AND COLUMN_NAME = N'CAN_LOCK_UNLOCK_ARTICLE_TITLE')
BEGIN
	ALTER TABLE dbo.EDITORROLE 
		ADD [CAN_LOCK_UNLOCK_ARTICLE_TITLE] BIT  NOT NULL CONSTRAINT [DF_EDITORROLE_CAN_LOCK_UNLOCK_ARTICLE_TITLE]  DEFAULT ((0));
END

--INVITED_AUTHORS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'INVITED_AUTHORS' 
		AND COLUMN_NAME = N'EDITOR_PROPOSAL_TITLE')
BEGIN
	ALTER TABLE dbo.INVITED_AUTHORS 
		ADD [EDITOR_PROPOSAL_TITLE] NVARCHAR(MAX);
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'INVITED_AUTHORS' 
		AND COLUMN_NAME = N'EDITOR_SECONDARY_TITLE')
BEGIN
	ALTER TABLE dbo.INVITED_AUTHORS 
		ADD [EDITOR_SECONDARY_TITLE] NVARCHAR(MAX);
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'INVITED_AUTHORS' 
		AND COLUMN_NAME = N'EDITOR_SHORT_TITLE')
BEGIN
	ALTER TABLE dbo.INVITED_AUTHORS 
		ADD [EDITOR_SHORT_TITLE] NVARCHAR(MAX);
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'INVITED_AUTHORS' 
		AND COLUMN_NAME = N'EDITOR_SECONDARY_SHORT_TITLE')
BEGIN
	ALTER TABLE dbo.INVITED_AUTHORS 
		ADD [EDITOR_SECONDARY_SHORT_TITLE] NVARCHAR(MAX);
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'INVITED_AUTHORS' 
		AND COLUMN_NAME = N'LOCK_TITLES_FOR_AUTHOR')
BEGIN
	ALTER TABLE dbo.INVITED_AUTHORS 
		ADD [LOCK_TITLES_FOR_AUTHOR]  SMALLINT NOT NULL CONSTRAINT [DF_INVITED_AUTHORS_LOCK_TITLES_FOR_AUTHOR]  DEFAULT ((0));
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DOCUMENT' 
		AND COLUMN_NAME = N'SELECT_REGION')
BEGIN
	ALTER TABLE dbo.document
	ADD SELECT_REGION int NOT NULL
	CONSTRAINT DF_DOCUMENT_SELECT_REGION DEFAULT 0
END
GO
DECLARE @default_constraint_name  NVARCHAR(256)
DECLARE @dropStatement NVARCHAR(1024)  

IF EXISTS (SELECT 1
FROM INFORMATION_SCHEMA.COLUMNS     
WHERE COLUMN_NAME = 'ENTER_ARTICLE_TITLE'     
and TABLE_NAME = 'document' and DATA_TYPE= 'bit')
BEGIN

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'ENTER_ARTICLE_TITLE' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN ENTER_ARTICLE_TITLE TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_ENTER_ARTICLE_TITLE DEFAULT 0 FOR ENTER_ARTICLE_TITLE

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'SELECT_ARTICLE_TYPE' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN SELECT_ARTICLE_TYPE TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_SELECT_ARTICLE_TYPE DEFAULT 0 FOR SELECT_ARTICLE_TYPE


	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'ADD_EDIT_REMOVE_AUTHORS' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document 
	ALTER COLUMN ADD_EDIT_REMOVE_AUTHORS TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_ADD_EDIT_REMOVE_AUTHORS DEFAULT 0 FOR ADD_EDIT_REMOVE_AUTHORS

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'SELECT_SECTION_CATEGORY' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN SELECT_SECTION_CATEGORY TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_SELECT_SECTION_CATEGORY DEFAULT 0 FOR SELECT_SECTION_CATEGORY


	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'FUNDING_INFORMATION_STEP_COMPLETE' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN FUNDING_INFORMATION_STEP_COMPLETE TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_FUNDING_INFORMATION_STEP_COMPLETE DEFAULT 0 FOR FUNDING_INFORMATION_STEP_COMPLETE

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'SUBMIT_ABSTRACT' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN SUBMIT_ABSTRACT TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_SUBMIT_ABSTRACT DEFAULT 0 FOR SUBMIT_ABSTRACT


	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'ENTER_KEYWORDS' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN ENTER_KEYWORDS TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_ENTER_KEYWORDS DEFAULT 0 FOR ENTER_KEYWORDS

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'SELECT_CLASSIFICATIONS' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN SELECT_CLASSIFICATIONS TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_SELECT_CLASSIFICATIONS DEFAULT 0 FOR SELECT_CLASSIFICATIONS

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'ADDITIONAL_INFORMATION' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN ADDITIONAL_INFORMATION TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_ADDITIONAL_INFORMATION DEFAULT 0 FOR ADDITIONAL_INFORMATION

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'ENTER_COMMENTS' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END
	ALTER TABLE dbo.document
	ALTER COLUMN ENTER_COMMENTS TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_ENTER_COMMENTS DEFAULT 0 FOR ENTER_COMMENTS


	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'REQUEST_EDITOR' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN REQUEST_EDITOR TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_REQUEST_EDITOR DEFAULT 0 FOR REQUEST_EDITOR

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'ATTACH_FILES' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN ATTACH_FILES TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_ATTACH_FILES DEFAULT 0 FOR ATTACH_FILES

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'SUGGEST_REVIEWERS' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN SUGGEST_REVIEWERS TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_SUGGEST_REVIEWERS DEFAULT 0 FOR SUGGEST_REVIEWERS

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'OPPOSE_REVIEWERS' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN OPPOSE_REVIEWERS TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_OPPOSE_REVIEWERS DEFAULT 0 FOR OPPOSE_REVIEWERS

	SELECT @default_constraint_name = dc.[name] 
		  FROM sys.[columns] c 
		  INNER JOIN sys.default_constraints dc  ON c.default_object_id = dc.[object_id]
		  WHERE c.[name] = N'RESPOND_TO_REVIEWERS' AND c.[object_id] = OBJECT_ID(N'document') 

	IF (@default_constraint_name IS NOT NULL)
	BEGIN 
		  SELECT @dropStatement = 'ALTER TABLE document DROP CONSTRAINT ' + @default_constraint_name
		  exec sp_executesql @dropStatement
	END

	ALTER TABLE dbo.document
	ALTER COLUMN RESPOND_TO_REVIEWERS TinyInt NOT NULL

	ALTER TABLE dbo.document
	ADD CONSTRAINT DF_DOCUMENT_RESPOND_TO_REVIEWERS DEFAULT 0 FOR RESPOND_TO_REVIEWERS

	UPDATE dbo.Document
	SET SELECT_REGION = CASE WHEN (ISO_REGION_CODE IS NULL AND CUSTOM_REGION_ID IS NULL) THEN 0 ELSE 1 END
END

/*******************************************************************
* 
*	Start Spec 13.0-38
* 
*******************************************************************/
 -- Add new column AUTO_PROMOTE_ALT_REVIEWERS_ONLY_MATCH to DCATEGOR.
 --	Set the value to True for existing Article Types that currently 
 --	Auto-promote Alt Reviewers. 

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'AUTO_PROMOTE_ALT_REVIEWERS_ONLY_MATCH')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD AUTO_PROMOTE_ALT_REVIEWERS_ONLY_MATCH BIT NOT NULL CONSTRAINT DF_DCATEGOR_AUTO_PROMOTE_ALT_REVIEWERS_ONLY_MATCH DEFAULT 0	
END
GO

UPDATE DCATEGOR SET AUTO_PROMOTE_ALT_REVIEWERS_ONLY_MATCH = 1 WHERE AUTO_PROMOTE_ALTERNATE_REVIEWERS <> 0
GO

/*******************************************************************
* 
*	Start Spec 13.0-43
* 
*******************************************************************/
 -- Create new table, REPORT_AUDIT 
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'REPORT_AUDIT')
BEGIN


CREATE TABLE [dbo].[REPORT_AUDIT](
	[AUDITID] [int] IDENTITY(1,1) NOT NULL,
	[OPERATORID] [int] NOT NULL,
	[PROXYOPERATORID] [int] NULL,
	[IP_ADDRESS] [varchar](16) NULL,
	[GMT_TIMESTAMP] [datetime] NOT NULL,
	[REPORT_NAME] [varchar](255) NOT NULL,
	[REPORT_TYPE] [varchar] (255) NOT NULL,
	[SQL_COMMAND] [nvarchar](max) NULL,
	[OTHER] [nvarchar](max) NULL,	
 CONSTRAINT [PK_REPORT_AUDIT] PRIMARY KEY CLUSTERED 
(
	[AUDITID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[REPORT_AUDIT] ADD  CONSTRAINT [DF_REPORT_AUDIT_UPDATE_TIMESTAMP]  DEFAULT (getutcdate()) FOR [GMT_TIMESTAMP]

	
END
GO




--Spec 13.0-25
IF NOT EXISTS (SELECT 1 FROM REG_CONFIG WHERE ITEM = 66)
	BEGIN
	DECLARE @rank int

	SELECT @rank = reg.[RANK]
		FROM dbo.REG_CONFIG reg
		WHERE reg.ITEM=61

	UPDATE dbo.REG_CONFIG
	SET [RANK] = ([RANK]+1)
	WHERE [RANK] > @rank

	INSERT INTO dbo.REG_CONFIG
		([ITEM]
		,[REQUIRED]
		,[EM_REQUIRED]
		,[NAME]
		,[EXPEDITED_REV_REQUIRED]
		,[RANK]
		,[PROXY_REQUIRED]
		,[REGISTRATION_SUBSECTION]
		,[IS_LIMIT_CONTACT_INFO_FIELD_PROXY_REG])
	VALUES
		(66
		,0	-- Optional
		,3	-- None
		,'Common.Text.RegisterWithOrcid'
		,2	-- Hidden
		,@rank + 1
		,3	-- Hidden
		,0
		,0)
	END		
GO

UPDATE [dbo].[REG_INSTRUCTIONS]
  SET DEFAULT_INSTRUCTION = 'To register to use the Editorial Manager system, please enter the requested information or use your ORCID record if this option is available. Upon successful registration, you will be sent an e-mail with instructions to verify your registration.'
  where INSTRUCTIONID = 3

GO
IF NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'EXTERNAL_API_ACCESS')
BEGIN
	CREATE TABLE [dbo].EXTERNAL_API_ACCESS
	(
		ID INT IDENTITY(1,1) NOT NULL,
		PEOPLEID INT NOT NULL,
		EXTERNAL_API INT NOT NULL,
		ACCESS_LEVEL INT NOT NULL,
		ACCESS_TOKEN NVARCHAR(MAX) NOT NULL,
		CONSTRAINT [PK_EXTERNAL_API_ACCESS_ID] PRIMARY KEY CLUSTERED (ID ASC)
	)
	
	ALTER TABLE [dbo].EXTERNAL_API_ACCESS WITH NOCHECK ADD CONSTRAINT [FK_PEOPLE_EXTERNAL_API_ACCESS] FOREIGN KEY(PEOPLEID)
	REFERENCES [dbo].PEOPLE (PEOPLEID)
	ON DELETE CASCADE
	
END
GO

-- Spec 13.0-44  2016-03-03 MVK

-- Add Record To [MASTER_CONFIG]Table

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 318)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG
	(
		CONFIG_ID,
		[DESCRIPTION],
		[VALUE],
		LAST_UPDATE,
		Row_LastModified_TimeStamp
	)
	VALUES
	(
		318,
		'Display Cross Pub Restriction Level Alert',
		'False',
		GETDATE(),
		GETDATE()
	) 
END
GO

if not exists (select 1 from CUSTOM_INSTRUCTIONS where CUSTOM_INSTRUCTION_ID = 53)
begin
	insert into CUSTOM_INSTRUCTIONS 
		(DEFAULT_INSTRUCTIONS, 
		 INSTRUCTION_LABEL_1, 
		 RANK, 
		 CUSTOM_INSTRUCTION_TYPE_ID, 
		 LAST_UPDATE, 
		 HAS_DEFAULT_INSTRUCTIONS)
		values ('', '', 2, 18, getdate(), 1),
			   ('', '', 3, 18, getdate(), 1),
			   ('', '', 4, 18, getdate(), 1);
			   
	update CUSTOM_INSTRUCTIONS set RANK = 5
	where CUSTOM_INSTRUCTION_ID = 38;
end
GO

-- Change Webpage name for 'Manage preferred method of Contact'
UPDATE dbo.ADMINACCESSFUNCTIONS
SET WEBPAGENAME='ManagePMOC.aspx'
WHERE WEBPAGENAME = 'nonEmailPrefAddress.asp'

-- Add row to MASTER_CONFIG
IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 330)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG ([CONFIG_ID],[DESCRIPTION], [VALUE], [LAST_UPDATE]) VALUES(330, 'Hide Preferred Method of Contact', 'False', GETDATE())
END


IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'LETTERS' 
		AND COLUMN_NAME = N'PROCESS_CONTEXT_TYPE')
BEGIN
	ALTER TABLE dbo.LETTERS 
	ADD	PROCESS_CONTEXT_TYPE tinyint NOT NULL 
	CONSTRAINT DF_LETTERS_PROCESS_CONTEXT_TYPE DEFAULT 0
END
GO
--Spec 13.0-27 Section 10

--Letter Family Type
DECLARE @LETTER_FAMILY_REVIEWER_INVITATION int = 10

--Events
DECLARE @ReviewerInvited int = 7
DECLARE @ReviewerAgreeToReview int = 19
DECLARE @ReviewerAssignedNotInvited int = 106
DECLARE @EditorPromoteReviewer int = 39

--Process Context Types
DECLARE @OriginalSubReviewerInvitedFirstTime tinyint = 1
DECLARE @RevisedReviewerReInvited tinyint = 3
DECLARE @RevisedReviewerInvitedFirstTime tinyint = 2

--Role Family type
DECLARE @Reviewer tinyint = 2

--Family Letter Type
DECLARE @ReviewerInvitation int = 10

DECLARE @FirstLetterAplhabetically int

DECLARE @ProcessContextTypesRecords TABLE
(	
	PctId int, eventId int, RoleFamilyId int
)
DECLARE @Events TABLE
(	
	EventId int
)

INSERT INTO @Events(eventId) VALUES (@ReviewerInvited)
INSERT INTO @Events(eventId) VALUES (@EditorPromoteReviewer)
INSERT INTO @Events(eventId) VALUES (@ReviewerAssignedNotInvited)
INSERT INTO @Events(eventId) VALUES (@ReviewerAgreeToReview)

INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerInvited, @Reviewer, @OriginalSubReviewerInvitedFirstTime)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerInvited, @Reviewer, @RevisedReviewerReInvited)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerInvited, @Reviewer, @RevisedReviewerInvitedFirstTime)

INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerAssignedNotInvited, @Reviewer, @OriginalSubReviewerInvitedFirstTime)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerAssignedNotInvited, @Reviewer, @RevisedReviewerReInvited)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerAssignedNotInvited, @Reviewer, @RevisedReviewerInvitedFirstTime)

INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@EditorPromoteReviewer, @Reviewer, @OriginalSubReviewerInvitedFirstTime)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@EditorPromoteReviewer, @Reviewer, @RevisedReviewerReInvited)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@EditorPromoteReviewer, @Reviewer, @RevisedReviewerInvitedFirstTime)

INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerAgreeToReview, @Reviewer, @OriginalSubReviewerInvitedFirstTime)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerAgreeToReview, @Reviewer, @RevisedReviewerReInvited)
INSERT INTO @ProcessContextTypesRecords(eventId, RoleFamilyId, PctId) VALUES (@ReviewerAgreeToReview, @Reviewer, @RevisedReviewerInvitedFirstTime)

--Get the family list of letters
SET @FirstLetterAplhabetically = null

--in alphabetical order get the very first family letter in the list
SELECT TOP 1 @FirstLetterAplhabetically = LetterID FROM Letter WHERE LETTER_FAMILY_ID = @ReviewerInvitation AND Hidden=0 ORDER BY PURPOSE

--insert all the new process context types
INSERT INTO [dbo].[LETTERS]([EVENTID],[ROLEFAMILY],[ROLEID],[LREMINDINT],[NOCORRHIST],[ROLEFAMILYID],[PROCESS_CONTEXT_TYPE], LETTERID)
SELECT a.[EVENTID], a.[ROLEFAMILY], a.[ROLEID],a.[LREMINDINT],a.[NOCORRHIST],a.[ROLEFAMILYID], b.PctId,
LetterId = CASE WHEN a.EVENTID = @ReviewerAgreeToReview THEN A.LetterId
				ELSE  COALESCE (d.LetterId, @FirstLetterAplhabetically)
				END
FROM Letters a
INNER JOIN @ProcessContextTypesRecords b ON a.EVENTID = b.eventId AND a.ROLEFAMILYID = @Reviewer
INNER JOIN @Events c ON c.EventId = b.eventId
LEFT JOIN Letter d ON d.LETTERID = a.LETTERID AND d.LETTER_FAMILY_ID = @ReviewerInvitation AND d.Hidden=0
WHERE ((
		((d.LetterId IS NULL AND @FirstLetterAplhabetically IS NOT NULL) OR  d.LetterId IS NOT NULL) AND a.EVENTID <> @ReviewerAgreeToReview
	  ) 
	  OR (
		a.EVENTID = @ReviewerAgreeToReview
	  ))
	  AND a.PROCESS_CONTEXT_TYPE=0

--delete all the old saved records that did not have a process context types assigned to them for these events.
DELETE FROM Letters WHERE EventId in (@ReviewerAssignedNotInvited,@EditorPromoteReviewer,@ReviewerInvited,@ReviewerAgreeToReview) AND  ROLEFAMILYID = @Reviewer AND PROCESS_CONTEXT_TYPE=0




DECLARE @Em2EmExportXSD NVARCHAR(MAX) = '<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xs:element name="Submission">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Journal"/>
				<xs:element ref="DocumentID"/>
				<xs:element ref="Title"/>
				<xs:element ref="ShortTitle" minOccurs="0"/>
				<xs:element ref="Notes" minOccurs="0"/>
				<xs:element ref="ArticleTypeName" minOccurs="0"/>
				<xs:element ref="ReceivedDate"/>
				<xs:element ref="Revision"/>
				<xs:element ref="OriginalStartDate"/>
				<xs:element ref="ManuscriptNumber" minOccurs="0"/>
				<xs:element ref="SubmissionNumber"/>
				<xs:element ref="Abstract" minOccurs="0"/>
				<xs:element ref="FinalDecisionDate" minOccurs="0"/>
				<xs:element ref="FinalDispositionDate" minOccurs="0"/>
				<xs:element ref="Section" minOccurs="0"/>
				<xs:element ref="DisplayManuscriptNotesFlag" minOccurs="0"/>
				<xs:element ref="FinalDecisionEditor" minOccurs="0"/>
				<xs:element ref="DiscussionClosingDate" minOccurs="0"/>
				<xs:element ref="ShortTitleLimitCount" minOccurs="0"/>
				<xs:element ref="AbstractLimitCount" minOccurs="0"/>
				<xs:element ref="TransferredFromSiteID" minOccurs="0"/>
				<xs:element ref="TransferredFromJournal" minOccurs="0"/>
				<xs:element ref="TransferredFromDocumentID" minOccurs="0"/>
				<xs:element ref="FundingInformationNotAvailable" minOccurs="0"/>
				<xs:element ref="ContributorRolesTaxonomyVersion" minOccurs="0"/>
				<xs:element ref="CustomRegionOfOriginID" minOccurs="0"/>
				<xs:element ref="ISORegionOfOriginCode" minOccurs="0"/>
				<xs:element ref="RevisionHistory"/>
				<xs:element ref="AuthorAssignment"/>
				<xs:element ref="Authors"/>
				<xs:element ref="AuthorVerifications" minOccurs="0"/>
				<xs:element ref="AssignedEditors" minOccurs="0"/>
				<xs:element ref="PeopleDetails"/>
				<xs:element ref="EditorAssignments" minOccurs="0"/>
				<xs:element ref="AuthorInfo"/>
				<xs:element ref="ProductionInformation" minOccurs="0"/>
				<xs:element ref="FundingInformation" minOccurs="0"/>
				<xs:element ref="Classifications" minOccurs="0"/>
				<xs:element ref="ClassificationHierarchy" minOccurs="0"/>
				<xs:element ref="Keywords" minOccurs="0"/>
				<xs:element ref="GeneralMetadata" minOccurs="0"/>
				<xs:element ref="AdditionalManuscriptMetadata" minOccurs="0"/>
				<xs:element ref="ManuscriptMetadata" minOccurs="0"/>
				<xs:element ref="TransmittalTracking" minOccurs="0"/>
				<xs:element ref="Questionnaire" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="SubmissionFiles" minOccurs="0"/>
				<xs:element ref="FileMetadata" minOccurs="0"/>
				<xs:element ref="ReviewerAttachment" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="InclusionList" minOccurs="0"/>
				<xs:element ref="TransferInfo" minOccurs="0"/>
				<xs:element ref="APC" minOccurs="0"/>
				<xs:element ref="ReviewerAssignments" minOccurs="0"/>
				<xs:element ref="ReviewerAnswers" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="ReviewerManuscriptRatings" maxOccurs="unbounded"/>
				<xs:element ref="AuthorTransferOffer" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="TransferLetter" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Journal">
		<xs:complexType>
			<xs:simpleContent>
				<xs:extension base="xs:string">
					<xs:attribute name="id" type="xs:string" use="required"/>
					<xs:attribute name="issn" type="xs:string" use="required"/>
					<xs:attribute name="fulltitle" type="xs:string" use="required"/>
					<xs:attribute name="journal-email" type="xs:string" use="required"/>
					<xs:attribute name="JournalID" type="xs:string" use="required"/>
				</xs:extension>
			</xs:simpleContent>
		</xs:complexType>
	</xs:element>
	<xs:element name="DocumentID">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="1"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="Title" type="xs:string"/>
	<xs:element name="ShortTitle" type="xs:string"/>
	<xs:element name="Notes" type="xs:string"/>
	<xs:element name="EditorAssignments">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EditorInfo" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="EditorInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EditorAssignmentStart"/>
				<xs:element ref="EditorAssignmentStop" minOccurs="0"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
				<xs:element ref="DaysWithEditor" minOccurs="0"/>
				<xs:element ref="CommentsToEditor" minOccurs="0"/>
				<xs:element ref="CommentsToAuthor" minOccurs="0"/>
				<xs:element ref="PeopleId" minOccurs="0"/>
				<xs:element ref="DocRating" minOccurs="0"/>
				<xs:element ref="Editor"/>
				<xs:element ref="Chain" minOccurs="0"/>
				<xs:element ref="Accept" minOccurs="0"/>
				<xs:element ref="AcceptDate" minOccurs="0"/>
				<xs:element ref="CommunicatedToAuthor" minOccurs="0"/>
				<xs:element ref="DecisionFamily" minOccurs="0"/>
				<xs:element ref="DecisionTerm" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Editor">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="AlternateAddress" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
				<xs:element ref="AssignmentEditorRole" minOccurs="0"/>
				<xs:element ref="Decision" minOccurs="0"/>
				<xs:element ref="ImportPeopleID" minOccurs="0"/>
				<xs:element ref="PeopleID" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="Revision" use="optional">
				<xs:simpleType>
					<xs:restriction base="xs:byte">
						<xs:minInclusive value="0"/>
						<xs:maxInclusive value="100"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="ImportPeopleID" type="xs:integer"/>
	<xs:element name="id" type="xs:integer"/>
	<xs:element name="APC">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="StatusCode"/>
				<xs:element ref="Status" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Fax" type="xs:string"/>
	<xs:element name="City" type="xs:string"/>
	<xs:element name="Item">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PeopleID"/>
				<xs:element ref="Value" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Rank" type="xs:integer"/>
	<xs:element name="Text" type="xs:string"/>
	<xs:element name="Chain" type="xs:integer"/>
	<xs:element name="Email" type="xs:string"/>
	<xs:element name="State" type="xs:string"/>
	<xs:element name="DisplayManuscriptNotesFlag" type="xs:boolean"/>
	<xs:element name="ShortTitleLimitCount" type="xs:integer"/>
	<xs:element name="AbstractLimitCount" type="xs:integer"/>
	<xs:element name="TransferredFromSiteID" type="xs:integer"/>
	<xs:element name="TransferredFromJournal" type="xs:string"/>
	<xs:element name="TransferredFromDocumentID" type="xs:integer"/>
	<xs:element name="FundingInformationNotAvailable" type="xs:boolean"/>
	<xs:element name="ReceivedDate" type="xs:dateTime"/>
	<xs:element name="Value" type="xs:string"/>
	<xs:element name="TransmittalCustomIdentifier" type="xs:string"/>
	<xs:element name="Answer">
		<xs:complexType>
			<xs:simpleContent>
				<xs:extension base="xs:string">
					<xs:attribute name="AnswerId" type="xs:integer"/>
				</xs:extension>
			</xs:simpleContent>
		</xs:complexType>
	</xs:element>
	<xs:element name="Degree" type="xs:string"/>
	<xs:element name="Hidden" type="xs:boolean"/>
	<xs:element name="GrantRecepient">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Affiliation" minOccurs="0"/>
				<xs:element ref="Revision" minOccurs="0"/>
				<xs:element ref="AuthorType"/>
				<xs:element ref="Person" minOccurs="0"/>
				<xs:element ref="PeopleID" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="Address1" minOccurs="0"/>
				<xs:element ref="Address2" minOccurs="0"/>
				<xs:element ref="Address3" minOccurs="0"/>
				<xs:element ref="Address4" minOccurs="0"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="Rank" minOccurs="0"/>
				<xs:element ref="RevisionIndependentID" minOccurs="0"/>
				<xs:element ref="IsDeceased" minOccurs="0"/>
				<xs:element ref="IsEqualContributor" minOccurs="0"/>
				<xs:element ref="IsPostPubCorrAuthor" minOccurs="0"/>
				<xs:element ref="InstituteID" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Person">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Phone1" type="xs:string"/>
	<xs:element name="Status">
		<xs:complexType/>
	</xs:element>
	<xs:element name="Authors">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Author" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Author">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:choice>
					<xs:sequence>
						<xs:element ref="FirstName"/>
						<xs:element ref="MiddleName" minOccurs="0"/>
						<xs:element ref="LastName"/>
						<xs:element ref="Affiliation" minOccurs="0"/>
						<xs:element ref="Revision" minOccurs="0"/>
						<xs:element ref="AuthorType" minOccurs="0"/>
						<xs:element ref="Person" minOccurs="0"/>
						<xs:element ref="PeopleID" minOccurs="0"/>
						<xs:element ref="Degree" minOccurs="0"/>
						<xs:element ref="Email"/>
						<xs:element ref="Title" minOccurs="0"/>
						<xs:element ref="Position" minOccurs="0"/>
						<xs:element ref="Department" minOccurs="0"/>
						<xs:element ref="Institute" minOccurs="0"/>
						<xs:element ref="Address1" minOccurs="0"/>
						<xs:element ref="Address2" minOccurs="0"/>
						<xs:element ref="Address3" minOccurs="0"/>
						<xs:element ref="Address4" minOccurs="0"/>
						<xs:element ref="City" minOccurs="0"/>
						<xs:element ref="State" minOccurs="0"/>
						<xs:element ref="Zipcode" minOccurs="0"/>
						<xs:element ref="Country" minOccurs="0"/>
						<xs:element ref="Rank" minOccurs="0"/>
						<xs:element ref="RevisionIndependentID" minOccurs="0"/>
						<xs:element ref="IsDeceased" minOccurs="0"/>
						<xs:element ref="IsEqualContributor" minOccurs="0"/>
						<xs:element ref="IsPostPubCorrAuthor" minOccurs="0"/>
						<xs:element ref="InstituteID" minOccurs="0"/>
					</xs:sequence>
					<xs:sequence>
						<xs:element ref="IdentityValue"/>
						<xs:element ref="FirstName"/>
						<xs:element ref="MiddleName" minOccurs="0"/>
						<xs:element ref="LastName"/>
						<xs:element ref="Title" minOccurs="0"/>
						<xs:element ref="Degree" minOccurs="0"/>
						<xs:element ref="AuthorRole" minOccurs="0"/>
						<xs:element ref="EditorRole" minOccurs="0"/>
						<xs:element ref="ReviewerRole" minOccurs="0"/>
						<xs:element ref="PublisherRole" minOccurs="0"/>
						<xs:element ref="IjrsGUID" minOccurs="0"/>
						<xs:element ref="ActiveAddress" minOccurs="0"/>
						<xs:element ref="Email"/>
						<xs:element ref="PersonalKeywords" minOccurs="0"/>
						<xs:element ref="PersonalClassifications" minOccurs="0"/>
						<xs:element ref="Phone1" minOccurs="0"/>
						<xs:element ref="CountryCode" minOccurs="0"/>
						<xs:element ref="Zipcode" minOccurs="0"/>
						<xs:element ref="Country" minOccurs="0"/>
					</xs:sequence>
				</xs:choice>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AuthorVerifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="AuthorVerification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AuthorVerification">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RevisionIndependentAuthorID" minOccurs="0"/>
				<xs:element ref="VerificationStatus" minOccurs="0"/>
				<xs:element ref="StatusDate" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="RevisionIndependentAuthorID" type="xs:string"/>
	<xs:element name="VerificationStatus" type="xs:string"/>
	<xs:element name="StatusDate" type="xs:dateTime"/>
	<xs:element name="Country" type="xs:string"/>
	<xs:element name="EndDate" type="xs:dateTime"/>
	<xs:element name="Zipcode" type="xs:string"/>
	<xs:element name="Affiliation" type="xs:string"/>
	<xs:element name="Address1" type="xs:string"/>
	<xs:element name="Address2" type="xs:string"/>
	<xs:element name="Address3" type="xs:string"/>
	<xs:element name="Address4" type="xs:string"/>
	<xs:element name="Contents" type="xs:string"/>
	<xs:element name="CorrDate" type="xs:dateTime"/>
	<xs:element name="Decision">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EditorAssignmentStart"/>
				<xs:element ref="EditorAssignmentStop" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
				<xs:element ref="DaysWithEditor" minOccurs="0"/>
				<xs:element ref="CommentsToEditor" minOccurs="0"/>
				<xs:element ref="CommentsToAuthor" minOccurs="0"/>
				<xs:element ref="PeopleId" minOccurs="0"/>
				<xs:element ref="DocRating" minOccurs="0"/>
				<xs:element ref="Editor"/>
				<xs:element ref="Chain"/>
				<xs:element ref="Accept" minOccurs="0"/>
				<xs:element ref="AcceptDate" minOccurs="0"/>
				<xs:element ref="CommunicatedToAuthor"/>
				<xs:element ref="DecisionFamily"/>
				<xs:element ref="DecisionTerm"/>
				<xs:element ref="FinalDecisionFamily" minOccurs="0"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="DaysWithEditor" type="xs:integer"/>
	<xs:element name="DocRating" type="xs:integer"/>
	<xs:element name="Accept" type="xs:boolean"/>
	<xs:element name="AcceptDate" type="xs:dateTime"/>
	<xs:element name="Keywords">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Keyword" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="LastName" type="xs:string"/>
	<xs:element name="IjrsGUID" type="xs:string"/>
	<xs:element name="PeopleID">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="0"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="Position" type="xs:string"/>
	<xs:element name="Question">
		<xs:complexType >
			<xs:choice>
				<xs:sequence>
					<xs:element ref="QuestionText"/>
					<xs:element ref="AdditionalQuestionText" minOccurs="0"/>
					<xs:element ref="Revision" minOccurs="0"/>
					<xs:element ref="DataType" minOccurs="0"/>
					<xs:element ref="Rank"/>
					<xs:element ref="Answer" minOccurs="0" maxOccurs="unbounded"/>
					<xs:element ref="Question" minOccurs="0" maxOccurs="unbounded"/>
				</xs:sequence>
				<xs:sequence>
					<xs:element ref="HiddenTransmittal"/>
					<xs:element ref="LastUpdate"/>
					<xs:element ref="ControlType"/>
					<xs:element ref="DataType"/>
					<xs:element ref="Text"/>
					<xs:element ref="TransmittalCustomIdentifier" minOccurs="0" maxOccurs="1"/>
					<xs:element ref="Revision"/>
					<xs:element ref="RevisionIndependentID" minOccurs="0"/>
					<xs:element ref="QuestionID"/>
					<xs:element ref="ParentQuestionID" minOccurs="0"/>
					<xs:element ref="IsCorrespondingAuthor"/>
					<xs:element ref="TransmitAsAuthorNote"/>
					<xs:element ref="Answer" minOccurs="0" maxOccurs="unbounded"/>
					<xs:element ref="Question" minOccurs="0" maxOccurs="unbounded"/>
				</xs:sequence>
			</xs:choice>
			<xs:attribute name="QuestionID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="ParentQuestionID" type="xs:integer"/>
	<xs:element name="IsCorrespondingAuthor" type="xs:boolean"/>
	<xs:element name="Reviewer">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="AlternateAddress" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Revision">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="0"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="RoleName" type="xs:string"/>
	<xs:element name="ClassCode" type="xs:decimal"/>
	<xs:element name="FirstName" type="xs:string"/>
	<xs:element name="Institute" type="xs:string"/>
	<xs:element name="InstituteID" type="xs:integer"/>
	<xs:element name="StartDate" type="xs:dateTime"/>
	<xs:element name="DiscussionClosingDate" type="xs:dateTime"/>
	<!--ASSIGNMENT START-->
	<xs:element name="Assignment">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="Address1" minOccurs="0"/>
				<xs:element ref="Address2" minOccurs="0"/>
				<xs:element ref="Address3" minOccurs="0"/>
				<xs:element ref="Address4" minOccurs="0"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="Fax" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="ActiveAddress"/>
				<xs:element ref="Email"/>
				<xs:element ref="AlternateAddress" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
				<xs:element ref="AssignmentEditorRole" minOccurs="0"/>
				<xs:element ref="Decision" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="Revision" use="required">
				<xs:simpleType>
					<xs:restriction base="xs:byte">
						<xs:minInclusive value="0"/>
						<xs:maxInclusive value="100"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<!--ASSIGNMENT END-->
	<xs:element name="AuthorInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="FirstAuthorFirstName"/>
				<xs:element ref="FirstAuthorMiddleName" minOccurs="0"/>
				<xs:element ref="FirstAuthorLastName"/>
				<xs:element ref="FirstAuthordegree" minOccurs="0"/>
				<xs:element ref="AllAuthorsText"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="FunderName" type="xs:string"/>
	<xs:element name="FunderID" type="xs:string"/>
	<xs:element name="GrantNumber" type="xs:string"/>
	<xs:element name="AuthorType" type="xs:string"/>
	<xs:element name="Department" type="xs:string"/>
	<xs:element name="EditorRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="PublisherRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Section">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="SectionID"/>
				<xs:element ref="SectionName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="SectionID" type="xs:integer"/>
	<xs:element name="SectionName" type="xs:string"/>
	<xs:element name="IsDeceased" type="xs:boolean"/>
	<xs:element name="LastUpdate" type="xs:dateTime"/>
	<xs:element name="LetterBody" type="xs:string"/>
	<xs:element name="MiddleName" type="xs:string"/>
	<xs:element name="QuestionID" type="xs:integer"/>
	<xs:element name="StatusCode" type="xs:integer"/>
	<xs:element name="ContributorRolesTaxonomyVersion" type="xs:integer"/>
	<xs:element name="ReviewerManuscriptRatings">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Rating" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
			<xs:attribute name="ReviewerID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="Rating">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="QuestionText"/>
				<xs:element ref="QuestionID"/>
				<xs:element ref="ScaleLow"/>
				<xs:element ref="ScaleHigh"/>
				<xs:element ref="Rank"/>
			</xs:sequence>
			<xs:attribute name="ReviewerID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="QuestionText" type="xs:string"/>
	<xs:element name="ScaleLow" type="xs:string"/>
	<xs:element name="ScaleHigh" type="xs:string"/>
	<xs:element name="FileMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="File" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="ReviewerAttachment" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="File">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="FileName"/>
				<xs:element ref="FileFamilyType"/>
				<xs:element ref="FileDescription"/>
				<xs:element name="ForPublisher" type="xs:string"/>
				<xs:element ref="Rank" minOccurs="0"/>
				<xs:element name="Metadata" minOccurs="0" maxOccurs="unbounded">
					<xs:complexType>
						<xs:sequence>
							<xs:element ref="Description" minOccurs="0"/>
							<xs:element ref="Value" minOccurs="0"/>
						</xs:sequence>
					</xs:complexType>
				</xs:element>
			</xs:sequence>
			<xs:attribute name="IsTransmittalFile" type="xs:boolean"/>
			<xs:attribute name="AmendedFile" type="xs:boolean" use="optional"/>
			<xs:attribute name="IsCompanionFile" type="xs:boolean" use="optional"/>
			<xs:attribute name="Revision" type="xs:byte"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="FileName" type="xs:string"/>
	<xs:element name="FileFamilyType" type="xs:string"/>
	<xs:element name="FileDescription" type="xs:string"/>
	<xs:element name="FinalDecisionEditor">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
				<xs:element ref="CommunicatedToAuthor" minOccurs="0"/>
				<xs:element ref="DecisionFamily" minOccurs="0"/>
				<xs:element ref="DecisionTerm" minOccurs="0"/>
				<xs:element ref="Chain" minOccurs="0"/>
				<xs:element ref="EditorAssignmentStart" minOccurs="0"/>
				<xs:element ref="EditorAssignmentStop" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="EditorDecision" minOccurs="0"/>
				<xs:element ref="FinalDecisionFamily" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AdditionalManuscriptMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="GeneralMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ManuscriptMetadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="TransmittalTracking">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Metadata" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Metadata">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Value" minOccurs="0"/>
				<xs:element ref="HiddenTransmittalForm" minOccurs="0"/>
				 <xs:element ref="TransmittalCustomIdentifier" minOccurs="0" maxOccurs="1"/>
				<xs:element ref="Hidden" minOccurs="0"/>
				<xs:element ref="DefinitionID" minOccurs="0"/>
				<xs:element ref="Description" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="CustomRegionOfOriginID" type="xs:string"/>
	<xs:element name="ISORegionOfOriginCode" type="xs:string"/>
	<xs:element name="ControlType" type="xs:string"/>
	<xs:element name="CountryCode" type="xs:string"/>
	<xs:element name="Description" type="xs:string"/>
	<xs:element name="RevisedDate" type="xs:dateTime"/>
	<xs:element name="DecisionTerm" type="xs:string"/>
	<xs:element name="DefinitionID">
		<xs:simpleType>
			<xs:restriction base="xs:integer">
				<xs:minInclusive value="1"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<!--ROLES START-->
	<xs:element name="AuthorRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="RoleName" type="xs:string"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<!--ROLES END-->
	<xs:element name="ActiveAddress">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="EndDate" minOccurs="0"/>
				<xs:element ref="StartDate" minOccurs="0"/>
				<xs:element ref="Fax" minOccurs="0"/>
				<xs:element ref="Email"/>
				<xs:element ref="Phone1" minOccurs="0"/>
				<xs:element ref="Address1" minOccurs="0"/>
				<xs:element ref="Address2" minOccurs="0"/>
				<xs:element ref="Address3" minOccurs="0"/>
				<xs:element ref="Address4" minOccurs="0"/>
				<xs:element ref="City" minOccurs="0"/>
				<xs:element ref="State" minOccurs="0"/>
				<xs:element ref="Zipcode" minOccurs="0"/>
				<xs:element ref="Country" minOccurs="0"/>
				<xs:element ref="CountryCode" minOccurs="0"/>
				<xs:element ref="Position" minOccurs="0"/>
				<xs:element ref="Department" minOccurs="0"/>
				<xs:element ref="Institute" minOccurs="0"/>
				<xs:element ref="InstituteID" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="id" use="required">
				<xs:simpleType>
					<xs:restriction base="xs:integer">
						<xs:minInclusive value="1"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="IdentityValue" type="xs:integer"/>
	<xs:element name="InclusionList">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="id" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="LetterSubject" type="xs:string"/>
	<xs:element name="PeopleDetails">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Item" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Questionnaire">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Question" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
			<xs:attribute name="QuestionnaireTypeDefinition">
				<xs:simpleType>
					<xs:restriction base="xs:string">
						<xs:enumeration value="Submission"/>
						<xs:enumeration value="Author"/>
						<xs:enumeration value="ProductionTask"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
			<xs:attribute name="IsCorrespondingAuthor" type="xs:boolean"/>
			<xs:attribute name="UniqueId" type="xs:string"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="AllAuthorsText" type="xs:string"/>
	<xs:element name="AdditionalQuestionText" type="xs:string"/>
	<xs:element name="DataType" type="xs:string"/>
	<xs:element name="AuthorNotified" type="xs:boolean"/>
	<xs:element name="Classification">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ClassCode"/>
				<xs:element ref="Description"/>
				<xs:element ref="ChildClassifications" minOccurs="0"/>
			</xs:sequence>
			<xs:attribute name="isTop">
				<xs:simpleType>
					<xs:restriction base="xs:boolean">
						<xs:pattern value="true"/>
						<xs:pattern value="false"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
			<xs:attribute name="isSelected">
				<xs:simpleType>
					<xs:restriction base="xs:boolean">
						<xs:pattern value="true"/>
						<xs:pattern value="false"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
			<xs:attribute name="hasChildGroup">
				<xs:simpleType>
					<xs:restriction base="xs:boolean">
						<xs:pattern value="true"/>
						<xs:pattern value="false"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
			<xs:attribute name="hierarchyLevel">
				<xs:simpleType>
					<xs:restriction base="xs:string">
						<xs:pattern value="([0-9])*"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="ChildClassifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<!--ROLES END-->
	<xs:element name="DecisionFamily" type="xs:string"/>
	<xs:element name="DecisionLetter">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="CorrDate"/>
				<xs:element ref="BlindedLetterContents"/>
				<xs:element ref="BlindedLetterBody" minOccurs="0"/>
				<xs:element ref="BlindedLetterSubject" minOccurs="0"/>
				<xs:element ref="IsFullyBlinded" minOccurs="0"/>
				<xs:element ref="CCList" minOccurs="0"/>
				<xs:element ref="LetterSubject" minOccurs="0"/>
				<xs:element ref="LetterBody" minOccurs="0"/>
				<xs:element ref="Contents" minOccurs="0"/>
				<xs:element ref="Revision" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="EditorDecision" type="xs:string"/>
	<!--DECISIONSS END-->
	<xs:element name="IsFullyBlinded" type="xs:boolean"/>
	<xs:element name="ReviewerRating" type="xs:integer"/>
	<xs:element name="ArticleTypeName" type="xs:string"/>
	<xs:element name="AssignedEditors">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Assignment" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Classifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ColorImageCount" type="xs:integer"/>
	<xs:element name="ReviewerAnswers">
		<xs:complexType>
			<xs:sequence minOccurs="0">
				<xs:element ref="AllowPersonalInfoTransferLastRevision" minOccurs="0"/>
				<xs:element ref="AllowReviewTransfer" minOccurs="0"/>
				<xs:element ref="AllowPersonalInfoTransfer" minOccurs="0"/>
				<xs:element ref="AllowReviewPublication" minOccurs="0"/>
				<xs:element ref="Question" maxOccurs="unbounded"/>
			</xs:sequence>
			<xs:attribute name="RoleID" type="xs:integer"/>
		</xs:complexType>
	</xs:element>
	<xs:element name="RevisionHistory">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="SubmissionRevision" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="SubmissionFiles">
		<xs:complexType/>
	</xs:element>
	<xs:element name="ReviewerAttachment">
		<xs:complexType>
			<xs:sequence minOccurs="0">
				<xs:element ref="FileName" minOccurs="0"/>
				<xs:element name="OriginalFileName" type="xs:string"/>
				<xs:element ref="Revision" minOccurs="0"/>
				<xs:element ref="Submitter" minOccurs="0"/>
				<xs:element ref="ReviewerNumber" minOccurs="0"/>
				<xs:element ref="AttachmentType" minOccurs="0"/>
				<xs:element ref="Description" maxOccurs="unbounded"/>
				<xs:element name="VisibleToAuthor" type="xs:string"/>
				<xs:element name="VisibleToReviewer" type="xs:string"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AlternateAddress">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Address1"/>
				<xs:choice>
					<xs:sequence>
						<xs:element ref="Email"/>
						<xs:element ref="City"/>
						<xs:element ref="State"/>
						<xs:element ref="Zipcode"/>
						<xs:element ref="Institute"/>
						<xs:element ref="Department"/>
						<xs:element ref="Position"/>
						<xs:element ref="Phone1"/>
					</xs:sequence>
					<xs:sequence>
						<xs:element ref="Address2"/>
						<xs:element ref="Email"/>
						<xs:element ref="City"/>
						<xs:element ref="State"/>
						<xs:element ref="Zipcode"/>
						<xs:element ref="Institute"/>
						<xs:element ref="Department"/>
						<xs:element ref="Position"/>
						<xs:element ref="Phone1"/>
						<xs:element ref="Fax"/>
					</xs:sequence>
				</xs:choice>
				<xs:element ref="CountryCode"/>
				<xs:element ref="Country"/>
				<xs:element ref="StartDate"/>
				<xs:element ref="EndDate"/>
			</xs:sequence>
			<xs:attribute name="id" use="required">
				<xs:simpleType>
					<xs:restriction base="xs:byte">
						<xs:enumeration value="3"/>
						<xs:enumeration value="4"/>
					</xs:restriction>
				</xs:simpleType>
			</xs:attribute>
		</xs:complexType>
	</xs:element>
	<xs:element name="AuthorAssignment">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="CorrespondingAuthor"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="CommentsToAuthor" type="xs:string"/>
	<xs:element name="CommentsToEditor" type="xs:string"/>
	<xs:element name="ManuscriptNumber" type="xs:string"/>
	<xs:element name="SubmissionNumber" type="xs:string"/>
	<xs:element name="Abstract" type="xs:string"/>
	<xs:element name="ReviewerNumber" type="xs:string"/>
	<xs:element name="AttachmentType" type="xs:string"/>
	<xs:element name="PersonalKeywords">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Keyword" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Keyword">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Rank"/>
				<xs:element ref="Word"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Word" type="xs:string"/>
	<xs:element name="BlindedLetterBody" type="xs:string"/>
	<xs:element name="CCList" type="xs:string"/>
	<xs:element name="HiddenTransmittal" type="xs:boolean"/>
	<xs:element name="OriginalStartDate" type="xs:dateTime"/>
	<xs:element name="FundingInformation">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Funding" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="IsEqualContributor" type="xs:boolean"/>
	<xs:element name="ReviewerAssignment">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="IdentityValue"/>
				<xs:element ref="Revision"/>
				<xs:element ref="ReviewerAssignmentStart"/>
				<xs:element ref="ReviewerAssignmentStop"/>
				<xs:element ref="ReviewerRecommendation"/>
				<xs:element ref="CommentsToEditor"/>
				<xs:element ref="CommentsToAuthor"/>
				<xs:element ref="Rank"/>
				<xs:element ref="ReviewerRating"/>
				<xs:element ref="Reviewer"/>
				<xs:element ref="AllowPersonalInfoTransferLastRevision"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="SubmissionRevision">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Revision"/>
				<xs:element ref="RevisedDate"/>
				<xs:element ref="AuthorNotified"/>
				<xs:element ref="DecisionLetter" minOccurs="0"/>
				<xs:element ref="TechnicalCheckCompleteDate" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="AllowReviewTransfer" type="xs:boolean"/>
	<xs:element name="CorrespondingAuthor">
		<xs:complexType>
			<xs:sequence minOccurs="0">
				<xs:element ref="PeopleID" minOccurs="0"/>
				<xs:element ref="StartDate" minOccurs="0"/>
				<xs:element ref="EndDate" minOccurs="0"/>
				<xs:element ref="Author"/>
				<xs:element ref="Revision"/>
				<xs:element ref="Comments" minOccurs="0"/>
				<xs:element ref="RevisionAssignedDate" minOccurs="0"/>
				<xs:element ref="ResponseToReviewers" minOccurs="0"/>
				<xs:element ref="AllAuthorsText"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Comments" type="xs:string"/>
	<xs:element name="RevisionAssignedDate" type="xs:dateTime"/>
	<xs:element name="ResponseToReviewers" type="xs:string"/>
	<xs:element name="FinalDecisionFamily">
		<xs:complexType/>
	</xs:element>
	<xs:element name="FirstAuthorMiddleName" type="xs:string"/>
	<xs:element name="FirstAuthorLastName" type="xs:string"/>
	<xs:element name="FirstAuthordegree" type="xs:string"/>
	<xs:element name="IsPostPubCorrAuthor" type="xs:boolean"/>
	<xs:element name="PersonalIdentifiers">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ISNI" minOccurs="0"/>
				<xs:element ref="ORCID" minOccurs="0"/>
				<xs:element ref="PubMedAuthorID" minOccurs="0"/>
				<xs:element ref="ResearcherID" minOccurs="0"/>
				<xs:element ref="ScopusAuthorID" minOccurs="0"/>
				<xs:element ref="OrcidAuthenticated" minOccurs="0" maxOccurs="2"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerAssignments">
		<xs:complexType>
			<xs:choice>
				<xs:sequence>
					<xs:element ref="ReviewerAssignment" minOccurs="0"/>
				</xs:sequence>
				<xs:sequence>
					<xs:element ref="ReviewerInfo" minOccurs="0" maxOccurs="unbounded"/>
				</xs:sequence>
			</xs:choice>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PeopleId" minOccurs="0"/>
				<xs:element ref="OriginalReviewFormID" minOccurs="0"/>
				<xs:element ref="ReviewerAssignmentStart" minOccurs="0"/>
				<xs:element ref="ReviewerAssignmentStop" minOccurs="0"/>
				<xs:element ref="ReviewerRecommendation" minOccurs="0"/>
				<xs:element ref="CommentsToAuthor" minOccurs="0"/>
				<xs:element ref="ReviewerRating" minOccurs="0"/>
				<xs:element ref="Reviewer" minOccurs="0"/>
				<xs:element ref="Revision" minOccurs="0"/>
				<xs:element ref="RoleID"/>
				<xs:element ref="Rank"/>
				<xs:element ref="AllowReviewTransfer" minOccurs="0"/>
				<xs:element ref="AllowReviewPublication" minOccurs="0"/>
				<xs:element ref="AllowPersonalInfoTransferLastRevision" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="PeopleId" type="xs:integer"/>
	<xs:element name="RoleID" type="xs:integer"/>
	<xs:element name="DOI" type="xs:string"/>
	<xs:element name="TargetNumberOfPages" type="xs:integer"/>
	<xs:element name="OriginalReviewFormID" type="xs:integer"/>
	<xs:element name="AssignmentEditorRole">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="RoleName"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Funding">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Revision"/>
				<xs:element ref="RevisionIndependentID"/>
				<xs:element ref="FunderName"/>
				<xs:element ref="FunderID" minOccurs="0"/>
				<xs:element ref="GrantNumber"/>
				<xs:element ref="GrantRecepient"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ISNI" type="xs:string"/>
	<xs:element name="ORCID" type="xs:string"/>
	<xs:element name="PubMedAuthorID" type="xs:string"/>
	<xs:element name="ResearcherID" type="xs:string"/>
	<xs:element name="ScopusAuthorID" type="xs:string"/>
	<xs:element name="OrcidAuthenticated" type="xs:boolean"/>
	<xs:element name="BlindedLetterSubject" type="xs:string"/>
	<xs:element name="CommunicatedToAuthor" type="xs:string"/>
	<xs:element name="EditorAssignmentStop" type="xs:dateTime"/>
	<xs:element name="FinalDecisionDate" type="xs:dateTime"/>
	<xs:element name="FinalDispositionDate" type="xs:dateTime"/>
	<xs:element name="FirstAuthorFirstName" type="xs:string"/>
	<xs:element name="TransmitAsAuthorNote" type="xs:string"/>
	<xs:element name="BlindedLetterContents" type="xs:string"/>
	<xs:element name="EditorAssignmentStart" type="xs:dateTime"/>
	<xs:element name="HiddenTransmittalForm" type="xs:boolean"/>
	<xs:element name="ProductionInformation">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ProductionNotes" minOccurs="0"/>
				<xs:element ref="DOI" minOccurs="0"/>
				<xs:element ref="TargetNumberOfPages" minOccurs="0"/>
				<xs:element ref="BlackAndWhiteImageCount" minOccurs="0"/>
				<xs:element ref="ColorImageCount" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="RevisionIndependentID">
		<xs:simpleType>
			<xs:restriction base="xs:string">
				<xs:pattern value="[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"/>
			</xs:restriction>
		</xs:simpleType>
	</xs:element>
	<xs:element name="AllowReviewPublication" type="xs:boolean"/>
	<xs:element name="ReviewerAssignmentStop" type="xs:dateTime"/>
	<xs:element name="ReviewerRecommendation" type="xs:string"/>
	<xs:element name="BlackAndWhiteImageCount" type="xs:integer"/>
	<xs:element name="ClassificationHierarchy">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="PersonalClassifications">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Classification" minOccurs="0" maxOccurs="unbounded"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ReviewerAssignmentStart" type="xs:dateTime"/>
	<xs:element name="AllowPersonalInfoTransfer">
		<xs:complexType/>
	</xs:element>
	<xs:element name="TechnicalCheckCompleteDate" type="xs:dateTime"/>
	<xs:element name="AllowPersonalInfoTransferLastRevision" type="xs:string"/>
	<xs:element name="TransferInfo">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="ReviewerAssignments" minOccurs="0"/>
				<xs:element ref="ReviewerAnswers" minOccurs="0"/>
				<xs:element name="Journal" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Submitter">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="PersonalIdentifiers" minOccurs="0" maxOccurs="unbounded"/>
				<xs:element ref="IdentityValue" minOccurs="0"/>
				<xs:element ref="FirstName" minOccurs="0"/>
				<xs:element ref="MiddleName" minOccurs="0"/>
				<xs:element ref="LastName" minOccurs="0"/>
				<xs:element ref="Title" minOccurs="0"/>
				<xs:element ref="Degree" minOccurs="0"/>
				<xs:element ref="AuthorRole" minOccurs="0"/>
				<xs:element ref="EditorRole" minOccurs="0"/>
				<xs:element ref="ReviewerRole" minOccurs="0"/>
				<xs:element ref="PublisherRole" minOccurs="0"/>
				<xs:element ref="IjrsGUID" minOccurs="0"/>
				<xs:element ref="ActiveAddress" minOccurs="0"/>
				<xs:element ref="Email" minOccurs="0"/>
				<xs:element ref="PersonalKeywords" minOccurs="0"/>
				<xs:element ref="PersonalClassifications" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Issn" type="xs:string"/>
	<xs:element name="ContactUs" type="xs:string"/>
	<xs:element name="EMail" type="xs:string"/>
	<xs:element name="AuthorTransferOffer">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="TriggeringRoleFamily" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="ProductionNotes" type="xs:string"/>
	<xs:element name="TransferLetter">
		<xs:complexType>
			<xs:sequence>
				<xs:element ref="Contents" minOccurs="0"/>
				<xs:element ref="Description" minOccurs="0"/>
				<xs:element ref="Subject" minOccurs="0"/>
				<xs:element ref="UserEnteredDate" minOccurs="0"/>
				<xs:element ref="Sender" minOccurs="0"/>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
	<xs:element name="Subject" type="xs:string"/>
	<xs:element name="UserEnteredDate" type="xs:string"/>
	<xs:element name="Sender" type="xs:string"/>
</xs:schema>
';


DECLARE @Em2EmImportXSL NVARCHAR(MAX) = 
	'<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" doctype-system="test.dtd"/>
	<xsl:variable name="unavailableDateCount" select="count(/metadata/corrunavailabilityinfo/unavail-start-date)"/>
	<xsl:variable name="finalRevision">
		<xsl:choose>
			<xsl:when test="/Submission/Revision/text()">
				<xsl:value-of select="/Submission/Revision/text()"/>
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:template name="SubmissionRevision">
		<xsl:param name="revision" select="0"/>
		<xsl:if test="$revision &lt;= $finalRevision">
			<SubmissionRevision>
				<Revision>
					<xsl:value-of select="$revision"/>
				</Revision>
				<xsl:if test="$revision = 0">
					<xsl:if test="/Submission/RevisionHistory/SubmissionRevision/RevisedDate">
						<RevisedDate>
							<xsl:value-of select="/Submission/RevisionHistory/SubmissionRevision/RevisedDate"/>
						</RevisedDate>
						<AuthorNotified>False</AuthorNotified>
					</xsl:if>
				</xsl:if>
				<xsl:if test="$finalRevision != 0 and $revision = $finalRevision">
					<xsl:if test="/Submission/RevisionHistory/SubmissionRevision/RevisedDate">
						<RevisedDate>
							<xsl:value-of select="/Submission/RevisionHistory/SubmissionRevision/RevisedDate"/>
						</RevisedDate>
						<AuthorNotified>True</AuthorNotified>
					</xsl:if>
				</xsl:if>
			</SubmissionRevision>
			<xsl:call-template name="SubmissionRevision">
				<xsl:with-param name="revision" select="$revision + 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="FileFamilyType">
		<xsl:choose>
			<xsl:when test="FileFamilyType/text() = ''Default''">
				<FamilyTypeID>1</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Figure''">
				<FamilyTypeID>2</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Document''">
				<FamilyTypeID>3</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Supplemental''">
				<FamilyTypeID>4</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''Table''">
				<FamilyTypeID>5</FamilyTypeID>
			</xsl:when>
			<xsl:when test="FileFamilyType/text() = ''TransferredFile''">
				<FamilyTypeID>7</FamilyTypeID>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="/">
		<Manuscript>
			<Submission>
				<xsl:if test="/Submission/Title/text()">
					<Title>
						<xsl:value-of select="/Submission/Title"/>
					</Title>
					<ShortTitle>
						<xsl:value-of select="/Submission/ShortTitle"/>
					</ShortTitle>
				</xsl:if>
				<xsl:if test="/Submission/Abstract/text()">
					<Abstract>
						<xsl:value-of select="/Submission/Abstract"/>
					</Abstract>
				</xsl:if>
				<Section>
					<xsl:copy-of select="/Submission/Section/node()"/>
				</Section>
				<xsl:if test="/Submission/DisplayManuscriptNotesFlag/text()">
					<DisplayManuscriptNotesFlag>
						<xsl:value-of select="/Submission/DisplayManuscriptNotesFlag"/>
					</DisplayManuscriptNotesFlag>
				</xsl:if>
				<xsl:if test="/Submission/ShortTitleLimitCount/text()">
					<ShortTitleLimitCount>
						<xsl:value-of select="/Submission/ShortTitleLimitCount"/>
					</ShortTitleLimitCount>
				</xsl:if>
				<xsl:if test="/Submission/AbstractLimitCount/text()">
					<AbstractLimitCount>
						<xsl:value-of select="/Submission/AbstractLimitCount"/>
					</AbstractLimitCount>
				</xsl:if>
				<xsl:if test="/Submission/TransferredFromSiteID/text()">
					<TransferredFromSiteID>
						<xsl:value-of select="/Submission/TransferredFromSiteID"/>
					</TransferredFromSiteID>
				</xsl:if>
				<xsl:if test="/Submission/TransferredFromJournal/text()">
					<TransferredFromJournal>
						<xsl:value-of select="/Submission/TransferredFromJournal"/>
					</TransferredFromJournal>
				</xsl:if>
				<xsl:if test="/Submission/TransferredFromDocumentID/text()">
					<TransferredFromDocumentID>
						<xsl:value-of select="/Submission/TransferredFromDocumentID"/>
					</TransferredFromDocumentID>
				</xsl:if>
				<xsl:if test="/Submission/FundingInformationNotAvailable/text()">
					<FundingInformationNotAvailable>
						<xsl:value-of select="/Submission/FundingInformationNotAvailable"/>
					</FundingInformationNotAvailable>
				</xsl:if>
				<xsl:if test="/Submission/ContributorRolesTaxonomyVersion/text()">
					<ContributorRolesTaxonomyVersion>
						<xsl:value-of select="/Submission/ContributorRolesTaxonomyVersion"/>
					</ContributorRolesTaxonomyVersion>
				</xsl:if>
				<xsl:choose>
					<xsl:when test="/Submission/Revision/text()">
						<Revision>
							<xsl:value-of select="/Submission/Revision"/>
						</Revision>
					</xsl:when>
					<xsl:otherwise>
						<Revision>0</Revision>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="/Submission/ReceivedDate">
					<ReceivedDate>
						<xsl:value-of select="/Submission/ReceivedDate"/>
					</ReceivedDate>
					<OriginalStartDate>
						<xsl:value-of select="/Submission/OriginalStartDate"/>
					</OriginalStartDate>
				</xsl:if>
				<AuthoritativeVersion>2</AuthoritativeVersion>
				<EditSubmissionStatus>0</EditSubmissionStatus>
				<ArticleTypeName>
					<xsl:value-of select="/Submission/ArticleTypeName"/>
				</ArticleTypeName>
			</Submission>
			<xsl:for-each select="/Submission/Keywords/Keyword/Word">
				<SubmissionKeyword>
					<Keyword>
						<Word>
							<xsl:value-of select="text()"/>
						</Word>
					</Keyword>
				</SubmissionKeyword>
			</xsl:for-each>
			<SubmissionRevisions>
				<xsl:call-template name="SubmissionRevision">
					<xsl:with-param name="revision" select="0"/>
				</xsl:call-template>
			</SubmissionRevisions>
			<AdditionalManuscriptMetadata>
				<xsl:if test="/metadata/articleinfo/manuscript-editor">
					<metadata name="Manuscript Editor" value="{/metadata/articleinfo/manuscript-editor/text()}"/>
				</xsl:if>
				<xsl:if test="/metadata/history/copyright-received-date">
					<metadata name="Copyright Received Date" value="{/metadata/history/copyright-received-date/@year}/{/metadata/history/copyright-received-date/@month}-{/metadata/history/copyright-received-date/@day}"/>
				</xsl:if>
				<xsl:if test="/metadata/history/colour-authorisation-received-date">
					<metadata name="Color Authorization Received Date|Colour Authorisation Received Date" value="{/metadata/history/colour-authorisation-received-date/@year}-{/metadata/history/colour-authorisation-received-date/@month}-{/metadata/history/colour-authorisation-received-date/@day}"/>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/number-of-tables/text()">
					<metadata name="Number of Tables" value="{/metadata/billinfo/number-of-tables}"/>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/number-of-coloronline/text()">
					<metadata name="Number of Color Online Figures|Number of Colour Online Figures" value="{/metadata/billinfo/number-of-coloronline}"/>
				</xsl:if>
				<xsl:if test="/metadata/digitalinfo/digital-files-submitted/text()">
					<metadata name="Digital Files Submitted" value="{/metadata/digitalinfo/digital-files-submitted}"/>
				</xsl:if>
				<xsl:if test="/metadata/digitalinfo/hard-copy-figures-available/text()">
					<metadata name="Hard Copy Figures Available" value="{/metadata/digitalinfo/hard-copy-figures-available}"/>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/web-si-comments/text()">
					<metadata name="Web SI Comments" value="{/metadata/billinfo/web-si-comments}"/>
				</xsl:if>
				<xsl:if test="/metadata/linkedfiles/@required">
					<metadata name="Linked Files Required" value="{/metadata/linkedfiles/@required}"/>
				</xsl:if>
				<xsl:if test="count(/metadata/linkedfiles/linked[@number != '''']) > 0">
					<xsl:element name="metadata">
						<xsl:attribute name="name">Linked Number</xsl:attribute>
						<xsl:attribute name="value"><xsl:for-each select="/metadata/linkedfiles/linked[@number != '''']"><xsl:value-of select="@number"/><xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if></xsl:for-each></xsl:attribute>
					</xsl:element>
				</xsl:if>
				<xsl:if test="count(/metadata/linkedfiles/linked[@msid != '''']) > 0">
					<xsl:element name="metadata">
						<xsl:attribute name="name">Linked ID</xsl:attribute>
						<xsl:attribute name="value"><xsl:for-each select="/metadata/linkedfiles/linked[@msid != '''']"><xsl:value-of select="@msid"/><xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if></xsl:for-each></xsl:attribute>
					</xsl:element>
				</xsl:if>
				<xsl:if test="/metadata/billinfo/supp-info/@available">
					<metadata name="Supplemental Information Available" value="{/metadata/billinfo/supp-info/@available}"/>
				</xsl:if>
				<xsl:for-each select="/metadata/articleinfo/additional-manuscript-details/additional-manuscript-detail">
					<metadata name="{amd-description}" value="{amd-value}" flagstate="{amd-flag-state}"/>
				</xsl:for-each>
			</AdditionalManuscriptMetadata>
			<CorrespondingAuthor>
				<Person>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/FirstName/text()">
						<FirstName>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/FirstName"/>
						</FirstName>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/MiddleName/text()">
						<MiddleName>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/MiddleName"/>
						</MiddleName>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/LastName/text()">
						<LastName>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/LastName"/>
						</LastName>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Title/text()">
						<Title>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Title"/>
						</Title>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue/text()">
						<ImportPeopleID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
						</ImportPeopleID>
						<PeopleID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
						</PeopleID>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IjrsGUID/text()">
						<IjrsGUID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IjrsGUID"/>
						</IjrsGUID>
					</xsl:if>					
				</Person>
				<Address>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address1/text()">
						<Address1>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address1"/>
						</Address1>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address2">
						<Address2>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Address2"/>
						</Address2>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/City/text()">
						<City>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/City"/>
						</City>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Country/text()">
						<Country>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Country"/>
						</Country>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Department/text()">
						<Department>
							<xsl:value-of select="/Submission/AuthorAssignments/AuthorAssignment/Author/Department"/>
						</Department>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Email/text()">
						<Email>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Email"/>
						</Email>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Fax/text()">
						<Fax>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Fax"/>
						</Fax>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Institute/text()">
						<Institute>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Institute"/>
						</Institute>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Phone1/text()">
						<Phone1>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Phone1"/>
						</Phone1>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/State/text()">
						<State>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/State"/>
						</State>
					</xsl:if>
					<xsl:if test="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Zip/text()">
						<Zipcode>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/Zip"/>
						</Zipcode>
					</xsl:if>
					<Primary>true</Primary>
				</Address>
				<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-address-1/text() 
				or /metadata/corralternateinfo/corresponding-author-alternate-address-2/text() 
				or         /metadata/corralternateinfo/corresponding-author-alternate-city/text() 
				or         /metadata/corralternateinfo/corresponding-author-alternate-country/text() 
				or         /metadata/corralternateinfo/corresponding-author-alternate-department/text() 
				or         /metadata/corralternateinfo/corresponding-author-alternate-email/text() 
				or         /metadata/corralternateinfo/corresponding-author-alternate-fax/text() 
				or        /metadata/corralternateinfo/corresponding-author-alternate-institution/text() 
				or        /metadata/corralternateinfo/corresponding-author-alternate-phone/text() 
				or        /metadata/corralternateinfo/corresponding-author-alternate-state/text() 
				or        /metadata/corralternateinfo/corresponding-author-alternate-zipcode/text()">
					<Address>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-address-1/text()">
							<Address1>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-address-1"/>
							</Address1>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-address-2/text()">
							<Address2>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-address-2"/>
							</Address2>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-city/text()">
							<City>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-city"/>
							</City>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-country/text()">
							<Country>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-country"/>
							</Country>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-department/text()">
							<Department>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-department"/>
							</Department>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-email/text()">
							<Email>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-email"/>
							</Email>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-fax/text()">
							<Fax>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-fax"/>
							</Fax>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-institution/text()">
							<Institute>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-institution"/>
							</Institute>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-phone/text()">
							<Phone1>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-phone"/>
							</Phone1>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-state/text()">
							<State>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-state"/>
							</State>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/corresponding-author-alternate-zipcode/text()">
							<Zipcode>
								<xsl:value-of select="/metadata/corralternateinfo/corresponding-author-alternate-zipcode"/>
							</Zipcode>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/alt-address-start-date">
							<StartDate>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-start-date/@year"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-start-date/@month"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-start-date/@day"/>
							</StartDate>
						</xsl:if>
						<xsl:if test="/metadata/corralternateinfo/alt-address-end-date">
							<EndDate>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-end-date/@year"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-end-date/@month"/>
								<xsl:text>-</xsl:text>
								<xsl:value-of select="/metadata/corralternateinfo/alt-address-end-date/@day"/>
							</EndDate>
						</xsl:if>
						<Primary>false</Primary>
					</Address>
				</xsl:if>
			</CorrespondingAuthor>
			<AuthorAssignments>
				<xsl:for-each select="/Submission/AuthorAssignment/CorrespondingAuthor/Author">
					<AuthorAssignment>
						<PeopleID>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
						</PeopleID>
						<StartDate>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/StartDate"/>
						</StartDate>
						<EndDate>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/EndDate"/>
						</EndDate>
						<xsl:for-each select="/Submission/AuthorAssignment/CorrespondingAuthor/Author">
							<Author>
								<xsl:if test="name() = ''IdentityValue''">
									<PeopleID>
										<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Author/IdentityValue"/>
									</PeopleID>
								</xsl:if>
								<xsl:if test="name() != ''IdentityValue'' or name() != ''Author''">
									<xsl:copy-of select="node()"/>
								</xsl:if>
								<AuthorType>1</AuthorType>
							</Author>
						</xsl:for-each>
						<Revision>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Revision"/>
						</Revision>
						<Comments>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/Comments"/>
						</Comments>
						<RevisionAssignedDate>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/RevisionAssignedDate"/>
						</RevisionAssignedDate>
						<ResponseToReviewers>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/ResponseToReviewers"/>
						</ResponseToReviewers>
						<AllAuthorsText>
							<xsl:value-of select="/Submission/AuthorAssignment/CorrespondingAuthor/AllAuthorsText"/>
						</AllAuthorsText>
					</AuthorAssignment>
				</xsl:for-each>
			</AuthorAssignments>
			<xsl:if test="count(/Submission/Authors/Author) > 0">
				<CoAuthors>
					<xsl:for-each select="/Submission/Authors/Author">
						<xsl:if test="AuthorType/text() != ''CorrespondingAuthor'' and Revision/text() = ''0''">
							<CoAuthor>
								<Person>
									<xsl:if test="FirstName/text()">
										<FirstName>
											<xsl:value-of select="FirstName"/>
										</FirstName>
									</xsl:if>
									<xsl:if test="MiddleName/text()">
										<MiddleName>
											<xsl:value-of select="MiddleName"/>
										</MiddleName>
									</xsl:if>
									<xsl:if test="LastName/text()">
										<LastName>
											<xsl:value-of select="LastName"/>
										</LastName>
									</xsl:if>
									<xsl:if test="Title/text()">
										<Title>
											<xsl:value-of select="Title"/>
										</Title>
									</xsl:if>
									<xsl:if test="Degree/text()">
										<Degree>
											<xsl:value-of select="Degree"/>
										</Degree>
									</xsl:if>
									<xsl:if test="IdentityValue/text()">
										<ImportPeopleID>
											<xsl:value-of select="Submission/Journal/@id"/>
											<xsl:value-of select="IdentityValue"/>
										</ImportPeopleID>
									</xsl:if>
								</Person>
								<Address>
									<xsl:if test="Address1/text()">
										<Address1>
											<xsl:value-of select="Address1"/>
										</Address1>
									</xsl:if>
									<xsl:if test="Address2/text()">
										<Address2>
											<xsl:value-of select="Address2"/>
										</Address2>
									</xsl:if>
									<xsl:if test="Address3/text()">
										<Address3>
											<xsl:value-of select="Address3"/>
										</Address3>
									</xsl:if>
									<xsl:if test="Address4/text()">
										<Address4>
											<xsl:value-of select="Address4"/>
										</Address4>
									</xsl:if>
									<xsl:if test="City/text()">
										<City>
											<xsl:value-of select="City"/>
										</City>
									</xsl:if>
									<xsl:if test="State/text()">
										<State>
											<xsl:value-of select="State"/>
										</State>
									</xsl:if>
									<xsl:if test="Zipcode/text()">
										<Zipcode>
											<xsl:value-of select="Zipcode"/>
										</Zipcode>
									</xsl:if>
									<xsl:if test="Country/text()">
										<Country>
											<xsl:value-of select="Country"/>
										</Country>
									</xsl:if>
									<xsl:if test="CountryCode/text()">
										<CountryCode>
											<xsl:value-of select="CountryCode"/>
										</CountryCode>
									</xsl:if>
									<xsl:if test="Position/text()">
										<Position>
											<xsl:value-of select="Position"/>
										</Position>
									</xsl:if>
									<xsl:if test="Department/text()">
										<Department>
											<xsl:value-of select="Department"/>
										</Department>
									</xsl:if>
									<xsl:if test="Institute/text()">
										<Institute>
											<xsl:value-of select="Institute"/>
										</Institute>
									</xsl:if>
									<xsl:if test="Email/text()">
										<Email>
											<xsl:value-of select="Email"/>
										</Email>
										<Primary>true</Primary>
									</xsl:if>
								</Address>
							</CoAuthor>
						</xsl:if>
					</xsl:for-each>
				</CoAuthors>
			</xsl:if>
			<Authors>
				<xsl:copy-of select="Submission/Authors/node()"/>
			</Authors>
			<xsl:if test="count(Submission/FundingInformation/Funding) > 0">
			<Funders>
			<xsl:for-each select="Submission/FundingInformation/Funding">
				<FundingInformation>
					<xsl:copy-of select="node()"></xsl:copy-of>
				</FundingInformation>
			</xsl:for-each>
			</Funders>
			</xsl:if>
			<xsl:if test="count(Submission/AuthorVerifications/AuthorVerification) > 0">
				<xsl:copy-of select="Submission/AuthorVerifications"></xsl:copy-of>
			</xsl:if>
			<EditorAssignments>
				<xsl:for-each select="/Submission/EditorAssignments/EditorInfo">
					<EditorAssignment>
						<xsl:if test="EditorAssignmentStart/text()">
							<EditorAssignmentStart>
								<xsl:value-of select="EditorAssignmentStart"/>
							</EditorAssignmentStart>
						</xsl:if>
						<xsl:if test="EditorAssignmentStop/text()">
							<EditorAssignmentStop>
								<xsl:value-of select="EditorAssignmentStop"/>
							</EditorAssignmentStop>
						</xsl:if>
						<xsl:if test="EditorDecision/text()">
							<EditorDecision>
								<xsl:value-of select="EditorDecision"/>
							</EditorDecision>
						</xsl:if>
						<xsl:if test="DaysWithEditor/text()">
							<DaysWithEditor>
								<xsl:value-of select="DaysWithEditor"/>
							</DaysWithEditor>
						</xsl:if>
						<xsl:if test="CommentsToEditor/text()">
							<CommentsToEditor>
								<xsl:value-of select="CommentsToEditor"/>
							</CommentsToEditor>
						</xsl:if>
						<xsl:if test="PeopleId/text()">
							<PeopleId>
								<xsl:value-of select="PeopleId"/>
							</PeopleId>
						</xsl:if>
						<xsl:if test="DocRating/text()">
							<DocRating>
								<xsl:value-of select="DocRating"/>
							</DocRating>
						</xsl:if>
						<Editor>
							<xsl:attribute name="IndentityReference"><xsl:value-of select="Editor/IdentityValue"/></xsl:attribute>
							<xsl:copy-of select="Editor/node()"/>
							<ImportPeopleID>
								<xsl:value-of select="Editor/IdentityValue"/>
							</ImportPeopleID>
						</Editor>
						<xsl:if test="Chain/text()">
							<Chain>
								<xsl:value-of select="Chain"/>
							</Chain>
						</xsl:if>
						<xsl:if test="AcceptDate/text()">
							<AcceptDate>
								<xsl:value-of select="AcceptDate"/>
							</AcceptDate>
						</xsl:if>
						<xsl:if test="CommunicatedToAuthor/text()">
							<CommunicatedToAuthor>
								<xsl:value-of select="CommunicatedToAuthor"/>
							</CommunicatedToAuthor>
						</xsl:if>
						<xsl:if test="DecisionFamily/text()">
							<DecisionFamily>
								<xsl:value-of select="DecisionFamily"/>
							</DecisionFamily>
						</xsl:if>
						<xsl:if test="DecisionTerm/text()">
							<DecisionTerm>
								<xsl:value-of select="DecisionTerm"/>
							</DecisionTerm>
						</xsl:if>
					</EditorAssignment>
				</xsl:for-each>
			</EditorAssignments>
			<SubmissionClassifications>
				<xsl:for-each select="/Submission/Classifications/Classification">
				<SubmissionClassification>
					<Classification>
						<ClassCode>
							<xsl:value-of select="ClassCode"/>
						</ClassCode>
						<Description>
							<xsl:value-of select="Description"/>
						</Description>
					</Classification>
				</SubmissionClassification>
				</xsl:for-each>
			</SubmissionClassifications>
			<Files>
				<xsl:for-each select="/Submission/FileMetadata/File">
					<xsl:choose>
						<xsl:when test="@IsCompanionFile">
						<companionfile>
							<xsl:if test="/Submission/FileMetadata/File/@AmendedFile">
								<xsl:attribute name="AmendedFile">true</xsl:attribute>
							</xsl:if>
							<filename>
								<xsl:value-of select="FileName"/>
							</filename>
							<description>
									<xsl:value-of select="FileDescription"/>
								</description>
							<typename>
								 <xsl:text>Transferred File</xsl:text>
							</typename>
							<xsl:call-template name="FileFamilyType"/>
							<revision>
								<xsl:value-of select="@Revision"/>
							</revision>							
						</companionfile>						
						</xsl:when>
						<xsl:otherwise>
							<submissionfile>
								<filename>
									<xsl:value-of select="FileName"/>
								</filename>
								<description>
									<xsl:value-of select="FileDescription"/>
								</description>
								<typename>
									<xsl:value-of select="FileFamilyType"/>
								</typename>
								<xsl:call-template name="FileFamilyType"/>
								<revision>
									<xsl:value-of select="@Revision"/>
								</revision>
							</submissionfile>						
						</xsl:otherwise>  
					</xsl:choose>
				</xsl:for-each>
				<xsl:for-each select="/Submission/ReviewerAttachment">
					<reviewerattachment>
						<xsl:if test="FileName/text()">
							<filename>
								<xsl:value-of select="FileName"/>
							</filename>
						</xsl:if>
						<xsl:if test="Description/text()">
							<description>
								<xsl:value-of select="Description"/>
							</description>
						</xsl:if>
						<xsl:if test="AttachmentType/text()">
							<typename>
								<xsl:value-of select="AttachmentType"/>
							</typename>
						</xsl:if>
					<xsl:if test="Submitter/IdentityValue/text()">
							<submittedby>
								<xsl:value-of select="Submitter/IdentityValue"/>
							</submittedby>
						</xsl:if>
											<xsl:if test="Revision/text()">
							<revision>
								<xsl:value-of select="Revision"/>
							</revision>
						</xsl:if>	
					</reviewerattachment>
				</xsl:for-each>
			</Files>
			<ReviewerAssignments>
				<xsl:for-each select="/Submission/ReviewerAssignments/ReviewerInfo">
					<ReviewerAssignment>
						<PeopleId>
							<xsl:value-of select="PeopleId"/>
						</PeopleId>
						<Revision>
							<xsl:value-of select="Revision"/>
						</Revision>
						<ReviewerAssignmentStart>
							<xsl:value-of select="ReviewerAssignmentStart"/>
						</ReviewerAssignmentStart>
						<ReviewerAssignmentStop>
							<xsl:value-of select="ReviewerAssignmentStop"/>
						</ReviewerAssignmentStop>
						<ReviewerRecommendation>
							<xsl:value-of select="ReviewerRecommendation"/>
						</ReviewerRecommendation>
						<CommentsToAuthor>
							<xsl:value-of select="CommentsToAuthor"/>
						</CommentsToAuthor>
						<Rank>
							<xsl:value-of select="Rank/text()"/>
						</Rank>
						<ReviewerRating>
							<xsl:value-of select="ReviewerRating"/>
						</ReviewerRating>
						<RoleID>
							<xsl:value-of select="RoleID/text()"/>
						</RoleID>
						<AllowReviewTransfer>
							<xsl:value-of select="AllowReviewTransfer/text()"/>
						</AllowReviewTransfer>
						<AllowReviewPublication>
							<xsl:value-of select="AllowReviewPublication/text()"/>
						</AllowReviewPublication>
						<AllowPersonalInfoTransferLastRevision>
							<xsl:value-of select="AllowPersonalInfoTransferLastRevision/text()"/>
						</AllowPersonalInfoTransferLastRevision>
						<Reviewer>
							<xsl:attribute name="IndentityReference"><xsl:value-of select="PeopleId"/></xsl:attribute>
							<xsl:copy-of select="Reviewer/node()"/>
							<ImportPeopleID>
								<xsl:value-of select="PeopleId"/>
							</ImportPeopleID>
						</Reviewer>
					</ReviewerAssignment>
				</xsl:for-each>
			</ReviewerAssignments>
			<ReviewerManuscriptRatings>
				<xsl:for-each select="/Submission/ReviewerManuscriptRatings/node()">
					<xsl:copy-of select="current()"/>
				</xsl:for-each>
			</ReviewerManuscriptRatings>
			<ReviewerAnswers>
				<xsl:for-each select="/Submission/ReviewerAnswers/node()">
					<xsl:if test="name() = ''Question''">
						<Question>
							<xsl:attribute name="RoleID"><xsl:value-of select="/Submission/ReviewerAnswers/@RoleID"/></xsl:attribute>
							<xsl:copy-of select="node()"/>
						</Question>
					</xsl:if>
				</xsl:for-each>
			</ReviewerAnswers>
			<AuthorTransferOffer>
				<xsl:copy-of select="/Submission/AuthorTransferOffer/node()"/>
			</AuthorTransferOffer>
			<TransferLetter>
				<xsl:copy-of select="/Submission/TransferLetter/node()"/>
			</TransferLetter>
						<xsl:for-each select="/Submission/Questionnaire">
				<xsl:copy-of select="current()"/>
			</xsl:for-each>
		</Manuscript>
	</xsl:template>
</xsl:stylesheet> 
';

-- Update the Export Transform schema by adding TransmittalCustomIdentifier element to AdditionalManuscriptMetadata Metadata as an optional item.
UPDATE dbo.FILE_RESOURCES
SET CONTENTS = @Em2EmExportXSD 
WHERE RESOURCE_GUID IN ('6EF76940-C7E1-421C-B7AF-E33797830165','D1466F7D-9CC3-429B-B82D-B2B690D87638')

	UPDATE	FILE_RESOURCES SET CONTENTS = @Em2EmImportXSL
		WHERE RESOURCE_GUID = 'BA4DA770-F333-4CED-949C-9DEFA5C86DC6';



-------------------------------------------------------------------------------------------------------------
-- Spec 13.0-35: Add the new Policy Manager item, 'Configure Predictive Bibliometrics' to the Submission Policies section,
-- preceeding the 'Configure Office 2007' item.
-------------------------------------------------------------------------------------------------------------

IF NOT EXISTS(
       SELECT 1
       FROM   [dbo].[ADMINACCESSFUNCTIONS]
       WHERE  PAGEID             = 4
              AND SECTIONID      = 3
              AND GROUPID        = 3
              AND [ITEMTEXT]     = 'Configure Predictive Bibliometrics'
   )
BEGIN
    -- Get the position of the 'Configure checkCIF'
    DECLARE @itemPosition       INT = (
                SELECT [ITEMORDER] + 1
                FROM   [dbo].[ADMINACCESSFUNCTIONS]
                WHERE  PAGEID             = 4
                       AND SECTIONID      = 3
                       AND GROUPID        = 3
                       AND [ITEMTEXT]     = 'Configure checkCIF'
            )
    
    
    -- Increment the order number of all items equal to or greater 
    -- than the @itemOrder value
    BEGIN
    	UPDATE [dbo].ADMINACCESSFUNCTIONS
    	SET    ITEMORDER = (ITEMORDER + 1)
    	WHERE  ITEMORDER >= @itemPosition
    	       AND SECTIONID = 3
    	       AND GROUPID = 3
    	       AND PAGEID = 4
    	
    END
    
    -- Insert new policy manager link, position will be directly after Select Author's Reviewer Preferences
    INSERT INTO [dbo].[ADMINACCESSFUNCTIONS]
      (
        [PAGEID],
        [SECTIONID],
        [GROUPID],
        [ITEMORDER],
        [PRODUCTID],
        [ITEMTEXT],
        [WEBPAGENAME],
        [ACTIVE],
        [ADMINRESTRICTEDACTIVE],
        [ELIGIBLEADMINACCESS],
        [POLICYDISPLAYRULES],
        [RESOURCEID]
      )
    VALUES
      (
        4,
        3,
        3,
        @itemPosition,
        1,
        'Configure Predictive Bibliometrics',
        'ConfigurePredictiveBibliometrics.aspx',
        1,
        0,
        1,
        65536,
        'Pages.Admin.PolicyManager.ConfigurePredictiveBibliometrics'
      )
END
GO

 -- Add new column PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_TRANSFER_COMPLETE to DCATEGOR.
 --	Set the value to False for existing Article Types
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_TRANSFER_COMPLETE')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_TRANSFER_COMPLETE BIT NOT NULL CONSTRAINT DF_DCATEGOR_PREDICTIVE_TRIGGER_WHEN_TRANSFER_COMPLETE DEFAULT 0	
END
GO

 -- Add new column PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_NEW_SUBMISSION_RECEIVED to DCATEGOR.
 --	Set the value to False for existing Article Types
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_NEW_SUBMISSION_RECEIVED')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_NEW_SUBMISSION_RECEIVED BIT NOT NULL CONSTRAINT DF_DCATEGOR_PREDICTIVE_TRIGGER_WHEN_NEW_SUBMISSION_RECEIVED DEFAULT 0	
END
GO

 -- Add new column PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_TECH_CHECK_COMPLETE to DCATEGOR.
 --	Set the value to False for existing Article Types
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_TECH_CHECK_COMPLETE')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD PREDICTIVE_BIBLIOMETRICS_TRIGGERED_WHEN_TECH_CHECK_COMPLETE BIT NOT NULL CONSTRAINT DF_DCATEGOR_PREDICTIVE_TRIGGER_WHEN_TECH_CHECK_COMPLETE DEFAULT 0	
END
GO

 -- Add new column PREDICTIVE_BIBLIOMETRICS_TRIGGERED_AT_FIRST_EDITOR_ASSIGNMENT to DCATEGOR.
 --	Set the value to False for existing Article Types
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'PREDICTIVE_BIBLIOMETRICS_TRIGGERED_AT_FIRST_EDITOR_ASSIGNMENT')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD PREDICTIVE_BIBLIOMETRICS_TRIGGERED_AT_FIRST_EDITOR_ASSIGNMENT BIT NOT NULL CONSTRAINT DF_DCATEGOR_PREDICTIVE_TRIGGER_AT_FIRST_EDITOR_ASSIGNMENT DEFAULT 0	
END
GO

 -- Add new column PREDICTIVE_BIBLIOMETRICS_TRIGGERED_AT_FIRST_REVISION to DCATEGOR.
 --	Set the value to False for existing Article Types
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'PREDICTIVE_BIBLIOMETRICS_TRIGGERED_AT_FIRST_REVISION')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD PREDICTIVE_BIBLIOMETRICS_TRIGGERED_AT_FIRST_REVISION BIT NOT NULL CONSTRAINT DF_DCATEGOR_PREDICTIVE_TRIGGER_AT_FIRST_REVISION DEFAULT 0	
END
GO

IF NOT EXISTS (
	SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'AUTHORROLE' AND COLUMN_NAME = 'CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS'
	)
	BEGIN
		ALTER TABLE dbo.AUTHORROLE 
		ADD CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS bit NOT NULL CONSTRAINT [DF_AUTHORROLE_CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS] DEFAULT(0)
	END
GO

	
IF NOT EXISTS (
	SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'EDITORROLE' AND COLUMN_NAME = 'CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS'
	)
	BEGIN
		ALTER TABLE dbo.EDITORROLE 
		ADD CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS bit NOT NULL CONSTRAINT [DF_EDITORROLE_CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS] DEFAULT(0)
	END
GO

IF NOT EXISTS (
	SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'EDITORROLE' AND COLUMN_NAME = 'CAN_INITIATE_PRED_BIBLIOMETRIC_ANALYSIS'
	)
	BEGIN
		ALTER TABLE dbo.EDITORROLE 
		ADD CAN_INITIATE_PRED_BIBLIOMETRIC_ANALYSIS bit NOT NULL CONSTRAINT [DF_EDITORROLE_CAN_INITIATE_PRED_BIBLIOMETRIC_ANALYSIS] DEFAULT(0)
	END
GO

IF NOT EXISTS (
	SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'REVIEWERROLE' AND COLUMN_NAME = 'CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS'
	)
	BEGIN
		ALTER TABLE dbo.REVIEWERROLE 
		ADD CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS bit NOT NULL CONSTRAINT [DF_REVIEWERROLE_CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS] DEFAULT(0)
	END
GO

IF NOT EXISTS (
	SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'REVIEWERROLE' AND COLUMN_NAME = 'CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS'
	)
	BEGIN
		ALTER TABLE dbo.REVIEWERROLE 
		ADD CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS bit NOT NULL CONSTRAINT [DF_REVIEWERROLE_CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS] DEFAULT(0)
	END
GO

IF NOT EXISTS (
	SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'PUBLISHERROLE' AND COLUMN_NAME = 'CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS'
	)
	BEGIN
		ALTER TABLE dbo.PUBLISHERROLE 
		ADD CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS bit NOT NULL CONSTRAINT [DF_PUBLISHERROLE_CAN_VIEW_PRED_BIBLIOMETRIC_RESULTS] DEFAULT(0)
	END

IF NOT EXISTS (
	SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'PUBLISHERROLE' AND COLUMN_NAME = 'CAN_INITIATE_PRED_BIBLIOMETRIC_ANALYSIS'
	)
	BEGIN
		ALTER TABLE dbo.PUBLISHERROLE 
		ADD CAN_INITIATE_PRED_BIBLIOMETRIC_ANALYSIS bit NOT NULL CONSTRAINT [DF_PUBLISHERROLE_CAN_INITIATE_PRED_BIBLIOMETRIC_ANALYSIS] DEFAULT(0)
	END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 319)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (319, 'Enable highlight article trajectory scores less than configured value', 'false', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 320)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (320, 'Highlight article trajectory scores less  or equal to this value', '25', GETDATE())
END
GO


IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 321)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (321, 'Color code used to highlight article trajectory scores less than configured', '0', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 322)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (322, 'Enable highlight article trajectory scores greater than configured value', 'False', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 323)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (323, 'Highlight article trajectory scores greater than  or equal to this value', '75', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 324)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (324, 'Color code used to highlight article trajectory scores greater than configured', '0', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 325)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (325, 'Enable highlight publication match scores less than configured value', 'False', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 326)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (326, 'Highlight publication match scores less  or equal to this value', '25', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 327)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (327, 'Color code used to highlight publication match scores less than configured', '0', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 328)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (328, 'Enable highlight publication match scores greater than configured value', 'False', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 329)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (329, 'Highlight publication match scores greater than  or equal to this value', '75', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 331)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (331, 'Color code used to highlight publication match scores greater than configured', '0', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 332)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG (CONFIG_ID, DESCRIPTION, VALUE, LAST_UPDATE)
	VALUES (332, 'Enable predictive bibliometrics', 'True', GETDATE())
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'API_TYPES')
	BEGIN
		CREATE TABLE [dbo].[API_TYPES](
			[API_TYPE] [int] IDENTITY(1,1) NOT NULL,
			[API_TYPE_DESCRIPTION] [nvarchar](100) NOT NULL,
		 CONSTRAINT [PK_API_TYPES] PRIMARY KEY CLUSTERED 
		(
			[API_TYPE] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
		) ON [PRIMARY]

	END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.API_TYPES WHERE API_TYPE_DESCRIPTION = 'Predictive Bibliometrics')
	BEGIN
		SET IDENTITY_INSERT [API_TYPES] ON;

		INSERT INTO dbo.API_TYPES (API_TYPE, API_TYPE_DESCRIPTION)
		VALUES (1, 'Predictive Bibliometrics')

		SET IDENTITY_INSERT [API_TYPES] OFF;
	END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'API_FILE_TRAFFIC_LOG')
	BEGIN
		CREATE TABLE [dbo].[API_FILE_TRAFFIC_LOG](
			[TRAFFIC_LOG_ID] [bigint] IDENTITY(1, 1) NOT NULL,
			[DOCUMENTID] INT NOT NULL,
			[DATE_BEGIN] [datetime] NOT NULL,
			[DATE_END] [datetime] NOT NULL,
			[UPLOAD_COUNT] INT NOT NULL,
			[RECEIVE_COUNT] INT NOT NULL,
			[UPLOAD_BYTES] [float] NOT NULL,
			[DOWNLOAD_BYTES] [float] NOT NULL,
			[API_TYPE] [int] NOT NULL,
		 CONSTRAINT [PK_API_FILE_TRAFFIC_LOG] PRIMARY KEY CLUSTERED 
		(
			[TRAFFIC_LOG_ID] ASC
		)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
		) ON [PRIMARY]


		ALTER TABLE [dbo].[API_FILE_TRAFFIC_LOG]  WITH CHECK ADD  CONSTRAINT [FK_API_FILE_TRAFFIC_LOG_API_TYPES] FOREIGN KEY([API_TYPE])
		REFERENCES [dbo].[API_TYPES] ([API_TYPE])


		ALTER TABLE [dbo].[API_FILE_TRAFFIC_LOG] CHECK CONSTRAINT [FK_API_FILE_TRAFFIC_LOG_API_TYPES]
	END
GO


IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'API_RESULTS')
	BEGIN
		CREATE TABLE [dbo].API_RESULTS(
			API_RESULTS_ID [int] IDENTITY(1,1) NOT NULL,
			API_TYPE [smallint] NOT NULL,
			DOCUMENTID [int] NULL,
			SOURCE_FILE_CATALOGUE_ID [bigint] NULL,
			RESULT_FILE_CATALOGUE_ID [bigint] NULL,
			[RESULT_FILE_GUID] nvarchar(100)  NULL,
			SUBMISSION_TOKEN nvarchar(100)  NULL,
			STATUS [smallint] NOT NULL,
			RESULTS nvarchar(max) NULL)
		
			ALTER TABLE dbo.API_RESULTS ADD CONSTRAINT PK_API_RESULTS_ID PRIMARY KEY CLUSTERED (API_RESULTS_ID);
			
			ALTER TABLE [dbo].API_RESULTS  WITH CHECK ADD  CONSTRAINT [FK_API_RESULTS_SOURCE_FILE_CATALOGUE_ID_FILE_CATALOGUE_ID] FOREIGN KEY(SOURCE_FILE_CATALOGUE_ID)
			REFERENCES [dbo].FILE_CATALOGUE (FILE_CATALOGUE_ID) 
			ON DELETE CASCADE
			
			ALTER TABLE [dbo].API_RESULTS  WITH CHECK ADD  CONSTRAINT [FK_API_RESULTS_RESULT_FILE_CATALOGUE_ID_FILE_CATALOGUE_ID] FOREIGN KEY(RESULT_FILE_CATALOGUE_ID)
			REFERENCES [dbo].FILE_CATALOGUE (FILE_CATALOGUE_ID)
			ON DELETE NO ACTION 
 	END		
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DETAILS_PAGE_LAYOUT_ITEMS WHERE DETAILS_LABEL = 'Predictive Bibliometrics Results')
BEGIN

	
	INSERT INTO DETAILS_PAGE_LAYOUT_ITEMS
	(
		
		HAS_ADDITIONAL_PERMISSIONS,
		IS_PRODUCTION_ITEM,
		IS_SECTION_HEADING,
		CATEGORY_ID,
		DETAILS_LABEL,
		ACTIVE,
		CONTEXT_AVAILABILITY,
		ITEM_NAME_RESOURCE_ID,
		DETAILS_LABEL_RESOURCE_ID,
		SORT_ORDER,
		BOOK_RELATED
	)
	VALUES
	(
		
		1,
		0,
		0,
		1,
		'Predictive Bibliometrics Results',
		1,
		3,
		'Common.PageLayout.ItemName.LabelPredictiveBibliometricsResults',
		'Pages.Editorial.Details.LabelPredictiveBibliometricsResults',
		17,
		0
	)
	
	
END
GO

--  •	Asterisk added to “checkCIF Results’ in this spec.
UPDATE dbo.DETAILS_PAGE_LAYOUT_ITEMS SET HAS_ADDITIONAL_PERMISSIONS=1 WHERE DETAILS_LABEL='checkCIF Results' AND HAS_ADDITIONAL_PERMISSIONS=0

if not exists (select 1 from dbo.FILE_CATALOGUE_SECTIONS where SECTION_ID = 16)
begin
	set identity_insert FILE_CATALOGUE_SECTIONS ON

	insert into FILE_CATALOGUE_SECTIONS (SECTION_ID, SECTION_TABLE)
	values (16, 'API_RESULT_FILES')
	
	set identity_insert FILE_CATALOGUE_SECTIONS OFF
end

----------------------------------------------------------------------
-- Add new metadata rows to DEEPLINK_TYPE 
----------------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM [dbo].[DEEPLINK_TYPE] WHERE [DEEPLINK_TYPE_ID] = 42)
BEGIN
 	SET IDENTITY_INSERT DEEPLINK_TYPE ON
	INSERT INTO [dbo].[DEEPLINK_TYPE] (DEEPLINK_TYPE_ID,[LINK_TEXT], [DAYS], CLICKS)
	VALUES (42, 'View Predictive Bibliometrics Results', NULL, NULL);
SET IDENTITY_INSERT DEEPLINK_TYPE OFF	
END
GO

IF NOT EXISTS (SELECT 1 FROM ACTION_LINKS WHERE ID = 26)
BEGIN
	UPDATE [dbo].ACTION_LINK_PAGE SET [RANK] = [RANK]+1 WHERE [RANK] > 1

	SET IDENTITY_INSERT [dbo].ACTION_LINKS ON;
	INSERT INTO ACTION_LINKS
	(
		ID,
		DESCRIPTION
	)
	VALUES
	(
		26,
		'Predictive Bibliometrics Results'
	)
	SET IDENTITY_INSERT [dbo].ACTION_LINKS OFF;
	
	INSERT INTO ACTION_LINK_PAGE
	(
		PAGE_ID,
		ACTION_LINK_ID,
		RANK
	)
	VALUES
	(
		(SELECT TOP 1 PAGE_ID FROM APP_PAGES WHERE PAGE_NAME = 'editorNewSubmissionsTechCheck.asp'),
		26,
		2
	)
END
GO

IF EXISTS(SELECT TOP 1 1 FROM [dbo].[INSTRUCTIONS] WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] <> 30)
BEGIN
	UPDATE [dbo].[INSTRUCTIONS]
	SET [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = 30
	WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = 25
END
GO
IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[INSTRUCTIONS] WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = 25)
BEGIN
INSERT INTO [dbo].[INSTRUCTIONS]
           ([NEW_DEFAULT],[REVISED_DEFAULT],[NEW_CUSTOM],[REVISED_CUSTOM],[LAST_UPDATE_DATE],[EDIT_INSTRUCTIONS_DISPLAY_ORDER]
           ,[ASP_ID],[Row_LastModified_TimeStamp],[NEW_DEFAULT_RESOURCE_ID],[REVISED_DEFAULT_RESOURCE_ID],[SUPPRESS_DISPLAY]
           ,[INSTRUCTION_LABEL])
     VALUES
           (null,null,null,null,GETDATE(),25
           ,30,GETDATE(),'Pages.Editorial.BuildPDF.WarningSubmissionWaitingAuthorApproval','Pages.Editorial.BuildPDF.WarningRevisionWaitingAuthorApproval', 0
           ,'Common.SubmissionSteps.BuildingPDFPage.ForAuthor')
END
IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[INSTRUCTIONS] WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = 26)
BEGIN
INSERT INTO [dbo].[INSTRUCTIONS]
           ([NEW_DEFAULT],[REVISED_DEFAULT],[NEW_CUSTOM],[REVISED_CUSTOM],[LAST_UPDATE_DATE],[EDIT_INSTRUCTIONS_DISPLAY_ORDER]
           ,[ASP_ID],[Row_LastModified_TimeStamp],[NEW_DEFAULT_RESOURCE_ID],[REVISED_DEFAULT_RESOURCE_ID],[SUPPRESS_DISPLAY]
           ,[INSTRUCTION_LABEL])
     VALUES
           (null,null,null,null,GETDATE(),26
           ,31,GETDATE(),'Pages.Editorial.BuildPDF.WarningRebuiltWaitingEditorApproval','Pages.Editorial.BuildPDF.WarningRevisionWaitingEditorApproval', 0, 'Common.SubmissionSteps.BuildingPDFPage.ForEditorEditing')
END
IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[INSTRUCTIONS] WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = 27)
BEGIN
INSERT INTO [dbo].[INSTRUCTIONS]
           ([NEW_DEFAULT],[REVISED_DEFAULT],[NEW_CUSTOM],[REVISED_CUSTOM],[LAST_UPDATE_DATE],[EDIT_INSTRUCTIONS_DISPLAY_ORDER]
           ,[ASP_ID],[Row_LastModified_TimeStamp],[NEW_DEFAULT_RESOURCE_ID],[REVISED_DEFAULT_RESOURCE_ID],[SUPPRESS_DISPLAY]
           ,[INSTRUCTION_LABEL])
     VALUES
           (null,null,null,null,GETDATE(),27
           ,32,GETDATE(),'Pages.Editorial.BuildPDF.WarningRebuiltWaitingPublisherApproval','Pages.Editorial.BuildPDF.WarningRevisionWaitingPublisherApproval', 0, 'Common.SubmissionSteps.BuildingPDFPage.ForPublisherEditing')
END
IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[INSTRUCTIONS] WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = 28)
BEGIN
INSERT INTO [dbo].[INSTRUCTIONS]
           ([NEW_DEFAULT],[REVISED_DEFAULT],[NEW_CUSTOM],[REVISED_CUSTOM],[LAST_UPDATE_DATE],[EDIT_INSTRUCTIONS_DISPLAY_ORDER]
           ,[ASP_ID],[Row_LastModified_TimeStamp],[NEW_DEFAULT_RESOURCE_ID],[REVISED_DEFAULT_RESOURCE_ID],[SUPPRESS_DISPLAY],[INSTRUCTION_LABEL])
     VALUES
           (null,null,null,null,GETDATE(),28
           ,33,GETDATE(),'Pages.Editorial.BuildPDF.WarningPDFForEditorSubmission',null, 0,'Common.SubmissionSteps.BuildingPDFPage.ForEditorAsAuthor')
END
IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[INSTRUCTIONS] WHERE [EDIT_INSTRUCTIONS_DISPLAY_ORDER] = 29)
BEGIN
INSERT INTO [dbo].[INSTRUCTIONS]
           ([NEW_DEFAULT],[REVISED_DEFAULT],[NEW_CUSTOM],[REVISED_CUSTOM],[LAST_UPDATE_DATE],[EDIT_INSTRUCTIONS_DISPLAY_ORDER]
           ,[ASP_ID],[Row_LastModified_TimeStamp],[NEW_DEFAULT_RESOURCE_ID],[REVISED_DEFAULT_RESOURCE_ID],[SUPPRESS_DISPLAY]
           ,[INSTRUCTION_LABEL])
     VALUES
           (null,null,null,null,GETDATE(),29
           ,34,GETDATE(),'Pages.Editorial.BuildPDF.WarningPDFForProposalCreation',null, 0, 'Common.SubmissionSteps.BuildingPDFPage.ForEditorProposal')
END

/********************************** Add Assign Authors Editor Permission **********************************/
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'EDITORROLE' 
		AND COLUMN_NAME = N'CAN_ASSIGN_AUTHORS')
BEGIN
	ALTER TABLE dbo.EDITORROLE
	ADD CAN_ASSIGN_AUTHORS bit NOT NULL
	CONSTRAINT DF_EDITORROLE_CAN_ASSIGN_AUTHORS DEFAULT 0
END
GO

/********************************** Add InviteType to INVITED_AUTHORS table *******************************/
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'INVITED_AUTHORS' 
		AND COLUMN_NAME = N'INVITETYPE')
BEGIN
	ALTER TABLE dbo.INVITED_AUTHORS
	ADD INVITETYPE smallint NOT NULL
	CONSTRAINT DF_INVITEDAUTHORS_INVITETYPE DEFAULT 0
END
GO


/******************************************* Add Necessary Events *****************************************/
DECLARE @parent_eventid int = 1011
DECLARE @authorAssignedNotInvitedForProposal int = 113
DECLARE @authorAssignedNotInvitedForCommentary int = 114
DECLARE @authorUnassignedAfterAcceptingInvite int = 115
DECLARE @authorUnassignedAfterAssignment int = 116

/* Author Assigned Not Invited For Proposal */
IF NOT EXISTS (SELECT * FROM dbo.EVENT WHERE EVENTID = @authorAssignedNotInvitedForProposal)
	BEGIN					
		SET IDENTITY_INSERT dbo.EVENT ON
		
		INSERT INTO dbo.EVENT
		(
			DISPLAYORDER,
			DSTATUSID,
			EVENTID,
			RESID,
			PARENT,
			RESOURCEID,
			NAME
		)
		VALUES
		(
			3,
			0,
			@authorAssignedNotInvitedForProposal,
			NULL,
			@parent_eventid,
			'Common.Events.AuthorAssignedNotInvitedForProposal',
			'Author Assigned (Not Invited) for Proposal'
		)
		
		SET IDENTITY_INSERT dbo.EVENT OFF
	END
	
/* Author Assigned Not Invited For Commentary */
IF NOT EXISTS (SELECT * FROM dbo.EVENT WHERE EVENTID = @authorAssignedNotInvitedForCommentary)
	BEGIN					
		SET IDENTITY_INSERT dbo.EVENT ON
		
		INSERT INTO dbo.EVENT
		(
			DISPLAYORDER,
			DSTATUSID,
			EVENTID,
			RESID,
			PARENT,
			RESOURCEID,
			NAME
		)
		VALUES
		(
			5,
			0,
			@authorAssignedNotInvitedForCommentary,
			0,
			@parent_eventid,
			'Common.Events.AuthorAssignedNotInvitedForCommentary',
			'Author Assigned (Not Invited) for Commentary'
		)
		
		SET IDENTITY_INSERT dbo.EVENT OFF
	END
	
/* Author Unassigned after Accepting Invitation */
IF NOT EXISTS (SELECT * FROM dbo.EVENT WHERE EVENTID = @authorUnassignedAfterAcceptingInvite)
	BEGIN					
		SET IDENTITY_INSERT dbo.EVENT ON
		
		INSERT INTO dbo.EVENT
		(
			DISPLAYORDER,
			DSTATUSID,
			EVENTID,
			RESID,
			PARENT,
			RESOURCEID,
			NAME
		)
		VALUES
		(
			8,
			0,
			@authorUnassignedAfterAcceptingInvite,
			0,
			@parent_eventid,
			'Common.Events.AuthorUnassignedAfterAcceptingInvite',
			'Author Unassigned after Accepting Invitation'
		)
		
		SET IDENTITY_INSERT dbo.EVENT OFF
	END
		
/* Author Unassigned after Assignment */
IF NOT EXISTS (SELECT * FROM dbo.EVENT WHERE EVENTID = @authorUnassignedAfterAssignment)
	BEGIN					
		SET IDENTITY_INSERT dbo.EVENT ON
		
		INSERT INTO dbo.EVENT
		(
			DISPLAYORDER,
			DSTATUSID,
			EVENTID,
			RESID,
			PARENT,
			RESOURCEID,
			NAME
		)
		VALUES
		(
			9,
			0,
			@authorUnassignedAfterAssignment,
			0,
			@parent_eventid,
			'Common.Events.AuthorUnassignedAfterAssignment',
			'Author Unassigned after Assignment'
		)
		
		SET IDENTITY_INSERT dbo.EVENT OFF
	END

UPDATE dbo.EVENT SET DISPLAYORDER = 4 WHERE EVENTID = 66
UPDATE dbo.EVENT SET DISPLAYORDER = 6 WHERE EVENTID = 104 
UPDATE dbo.EVENT SET DISPLAYORDER = 7 WHERE EVENTID = 67
UPDATE dbo.EVENT SET DISPLAYORDER = 10 WHERE EVENTID = 94
UPDATE dbo.EVENT SET DISPLAYORDER = 11 WHERE EVENTID = 68
UPDATE dbo.EVENT SET DISPLAYORDER = 12 WHERE EVENTID = 69
GO

DECLARE @PAGE_ID INT
DECLARE @PREF_ID INT

IF NOT EXISTS(SELECT 1 FROM dbo.APP_PAGES WHERE PAGE_NAME = N'SearchAuthors.aspx' )
BEGIN

INSERT	INTO dbo.[APP_PAGES]
				([PAGE_NAME]
				,[FOLDER_NAME])
			VALUES
				(N'SearchAuthors.aspx'
				,N'')

	SET @PAGE_ID = SCOPE_IDENTITY()
END
ELSE
BEGIN

	SET @PAGE_ID = (SELECT PAGE_ID FROM dbo.[APP_PAGES] WHERE PAGE_NAME = N'SearchAuthors.aspx')
END

SET @PREF_ID = (SELECT PREF_ID FROM dbo.[PREFERENCE] WHERE PREF_NAME = N'pref_PageSize')

IF NOT EXISTS (SELECT 1 FROM dbo.[PAGE_PREFS] WHERE PAGE_ID = @PAGE_ID AND PREF_ID = 1)
BEGIN
	INSERT INTO dbo.[PAGE_PREFS]
			   ([PAGE_ID]
			   ,[PREF_ID])
		 VALUES
			   (@PAGE_ID,
				@PREF_ID
			   )
END
GO

--Spec 13.0-32
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'DCATEGOR' 
		AND COLUMN_NAME = N'USE_PERSISTENT_PROPOSAL_NUMBERING')
BEGIN
	ALTER TABLE dbo.DCATEGOR
		ADD USE_PERSISTENT_PROPOSAL_NUMBERING BIT NOT NULL CONSTRAINT DF_DCATEGOR_USE_PERSISTENT_PROPOSAL_NUMBERING DEFAULT 0
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = N'TARGET' 
		AND COLUMN_NAME = N'MANUSCRIPT_NUM_PREFIX')
BEGIN
	ALTER TABLE dbo.TARGET
		ADD MANUSCRIPT_NUM_PREFIX NVARCHAR(50) NULL,
			MANUSCRIPT_STARTING_NUM INT NULL,
			MANUSCRIPT_MIN_DIGITS INT NULL,
			NEXT_MANUSCRIPT_NUM INT NULL
END
GO
		



/*******************************************************************
* 
*	Start Spec 13.0-39
* 
*******************************************************************/

IF NOT EXISTS (SELECT 1 FROM ADMINACCESSFUNCTIONS WHERE WEBPAGENAME = 'DefineCustomMetadataID.aspx')
BEGIN
	INSERT INTO dbo.ADMINACCESSFUNCTIONS
	(
		PAGEID,
		SECTIONID,
		GROUPID,
		ITEMORDER,
		PRODUCTID,
		ITEMTEXT,
		WEBPAGENAME,
		ACTIVE,
		POLICYDISPLAYRULES,
		RESOURCEID
	)
	VALUES
		(4,
		10, -- General Policies
		12,
		27,
		1,
		'Define Custom Metadata ID',
		'DefineCustomMetadataID.aspx',
		1,
		0,
		'Pages.Admin.PolicyManager.LinkDefineCustomMetadataID');
END;

-- DCATEGOR
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DCATEGOR' AND COLUMN_NAME = 'TRANSMITTAL_CUSTOM_ID')
BEGIN
ALTER TABLE dbo.DCATEGOR
	ADD TRANSMITTAL_CUSTOM_ID INT NULL
		CONSTRAINT FK_DCATEGOR_TRANSMITTAL_CUSTOM_IDENTIFIER FOREIGN KEY REFERENCES TRANSMITTAL_CUSTOM_IDENTIFIER(TRANSMITTAL_CUSTOM_ID) 
		ON DELETE CASCADE;
END;


-- Create CUSTOM_METADATA_ID_TYPE and populate it.

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CUSTOM_METADATA_ID_TYPE')
BEGIN
CREATE TABLE dbo.CUSTOM_METADATA_ID_TYPE
(
			 CUSTOM_METADATA_ID_TYPE_ID TINYINT NOT NULL
												CONSTRAINT PK_CUSTOM_METADATA_ID_TYPE PRIMARY KEY,
			 RESOURCE_ID NVARCHAR(400) NOT NULL
);
	INSERT INTO dbo.CUSTOM_METADATA_ID_TYPE
		(CUSTOM_METADATA_ID_TYPE_ID, RESOURCE_ID)
	VALUES
			(0, 'Common.CustomMetadataIDType.None'),
			(1, 'Common.CustomMetadataIDType.AdditionalManuscriptDetail'),
			(2, 'Common.CustomMetadataIDType.CustomQuestion'),
			(3, 'Common.CustomMetadataIDType.ArticleType');
END;

-- Add columns to TRANSMITTAL_CUSTOM_IDENTIFIER. These are initially defined as nullable and without any foreign keys or constraints. Once
-- the columns are populated by the script, that is changed.
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS	WHERE TABLE_NAME = 'TRANSMITTAL_CUSTOM_IDENTIFIER' AND COLUMN_NAME = 'DESCRIPTION')
BEGIN
	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER
	ADD DESCRIPTION NVARCHAR(75),
		ID_TYPE     TINYINT,
		IN_USE      BIT,
		HIDDEN      BIT,
		[RANK]      INT;
END
GO

IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc WHERE rc.CONSTRAINT_NAME='FK_TRANSMITTAL_CUSTOM_IDENTIFIER_CUSTOM_METADATA_ID_TYPE')
BEGIN
	-- There are two update statements on TRANSMITTAL_CUSTOM_IDENTIFIER. Disable the Row Last Update trigger 
	-- for the first update since all rows will be updated by the second update.
	DISABLE TRIGGER dbo.TRG_TRANSMITTAL_CUSTOM_IDENTIFIER_RowLastUpdateTimeStamp ON [dbo].[TRANSMITTAL_CUSTOM_IDENTIFIER];

	WITH UpdateRow
		 AS (SELECT TRANSMITTAL_CUSTOM_ID,
					-- Determine the type of the ID.
					CASE
						WHEN EXISTS
								   (
									   SELECT *
									   FROM dbo.ADDITIONAL_MANUSCRIPT_DETAIL_FIELDS amdf
									   WHERE amdf.TRANSMITTAL_CUSTOM_ID = tci.TRANSMITTAL_CUSTOM_ID
								   )
						THEN 1 -- AMD
						WHEN EXISTS
								   (
									   SELECT *
									   FROM dbo.SUBMISSION_QUESTION_DEFINITION sqd
									   WHERE sqd.TRANSMITTAL_CUSTOM_ID = tci.TRANSMITTAL_CUSTOM_ID
								   )
						THEN 2 -- Question
						ELSE 0 -- unknown
					END AS IDTYPE,
					-- Determine whether the ID is hidden.
					CASE
						WHEN EXISTS
								   (
									   SELECT *
									   FROM dbo.ADDITIONAL_MANUSCRIPT_DETAIL_FIELDS amdf
									   WHERE amdf.TRANSMITTAL_CUSTOM_ID = tci.TRANSMITTAL_CUSTOM_ID
								   )
						THEN
							(
								SELECT TOP 1 AMD_HIDE
								FROM dbo.ADDITIONAL_MANUSCRIPT_DETAIL_FIELDS amdf
								WHERE amdf.TRANSMITTAL_CUSTOM_ID = tci.TRANSMITTAL_CUSTOM_ID
							)
						WHEN EXISTS
								   (
									   SELECT *
									   FROM dbo.SUBMISSION_QUESTION_DEFINITION sqd
									   WHERE sqd.TRANSMITTAL_CUSTOM_ID = tci.TRANSMITTAL_CUSTOM_ID
								   )
						THEN
							(
								SELECT TOP 1 HIDDEN
								FROM dbo.SUBMISSION_QUESTION_DEFINITION sqd
								WHERE sqd.TRANSMITTAL_CUSTOM_ID = tci.TRANSMITTAL_CUSTOM_ID
							)
						ELSE
							(
								SELECT 0
							)
					END AS HIDDEN,
					-- Set the RANK column based on the current order, i.e., the row number.
					ROW_NUMBER() OVER(ORDER BY TRANSMITTAL_CUSTOM_ID) AS ROWNUM
			 FROM dbo.TRANSMITTAL_CUSTOM_IDENTIFIER tci)
		 UPDATE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER
		   SET
			   ID_TYPE = ur.IDTYPE,
			   HIDDEN = ur.HIDDEN,
			   [RANK] = ur.ROWNUM
		 FROM dbo.TRANSMITTAL_CUSTOM_IDENTIFIER tci
			  INNER JOIN UpdateRow ur ON tci.TRANSMITTAL_CUSTOM_ID = ur.TRANSMITTAL_CUSTOM_ID;

	ENABLE TRIGGER dbo.TRG_TRANSMITTAL_CUSTOM_IDENTIFIER_RowLastUpdateTimeStamp ON [dbo].[TRANSMITTAL_CUSTOM_IDENTIFIER];

	-- Set the IN_USE column based on the value of the ID_TYPE column. This is much more efficient than figuring it out in the above CTE.
	UPDATE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER
	  SET
		  IN_USE = CASE
					   WHEN ID_TYPE > 0
					   THEN 1
					   ELSE 0
				   END;

	-- Now that the RANSMITTAL_CUSTOM_IDENTIFIER data has been added, add the new column attributes.
	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER ALTER COLUMN ID_TYPE TINYINT NOT NULL;

	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER
	ADD CONSTRAINT FK_TRANSMITTAL_CUSTOM_IDENTIFIER_CUSTOM_METADATA_ID_TYPE FOREIGN KEY(ID_TYPE) REFERENCES CUSTOM_METADATA_ID_TYPE(CUSTOM_METADATA_ID_TYPE_ID);

	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER ALTER COLUMN IN_USE BIT NOT NULL;

	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER
	ADD CONSTRAINT DF_TRANSMITTAL_CUSTOM_IDENTIFIER_IN_USE DEFAULT(0) FOR IN_USE;

	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER ALTER COLUMN HIDDEN BIT NOT NULL;

	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER
	ADD CONSTRAINT DF_TRANSMITTAL_CUSTOM_IDENTIFIER_HIDDEN DEFAULT(0) FOR HIDDEN;

	ALTER TABLE dbo.TRANSMITTAL_CUSTOM_IDENTIFIER ALTER COLUMN [RANK] INT NOT NULL;
END
GO

IF EXISTS (SELECT 1 FROM sys.triggers WHERE [NAME] = 'TRIG_AMD_FIELDS_DELETE_TRANSMITTAL_CUSTOM_IDENTIFIER')
BEGIN
	DROP TRIGGER [dbo].[TRIG_AMD_FIELDS_DELETE_TRANSMITTAL_CUSTOM_IDENTIFIER];
END
GO

IF EXISTS (SELECT 1 FROM sys.triggers WHERE [NAME] = 'TRIG_SUBMISSION_QUESTION_DEFINITION_DEL_TRANS_CUST_ID')
BEGIN
	DROP TRIGGER [dbo].[TRIG_SUBMISSION_QUESTION_DEFINITION_DEL_TRANS_CUST_ID];
END
GO

-----------------------------------------------------------------------------------------------------------------
-- Create Page Preference for DefineCustomMetadataID.aspx.
-----------------------------------------------------------------------------------------------------------------

EXEC SP_INTERNAL_addSortPage
       @pageName = 'DefineCustomMetadataID.aspx',
       @folderName = 'admin'

/*******************************************************************
* 
*	End Spec 13.0-39
* 
*******************************************************************/


-- *******************************************************************************************
-- NOTE: It is not necessary to include the rest of this script in the version upgrade script
-- as long as the upgrade .xml file includes 6.0-39StaticTriggerReBuild.sql. It is included
-- here to speed up the incremental upgrade so the incremental 13.0-39.xml doesn't have to
-- include 6.0-39StaticTriggerReBuild.sql.
-- *******************************************************************************************

-- An instance of the static trigger rebuild just for the custom metadata ID type.

/*----------------------------------------------------------------------------
 * Copyright © 2000-Present Aries Systems Corporation. All Rights Reserved.
 * Copying, reverse engineering, adaptation or any other derivative use
 * prohibited.  This material is proprietary and confidential information
 * of Aries Systems Corporation.
 *
 * Name: 6.0-39StaticTriggerReBuild.sql
 * Date Created: 20080305
 * Version Introduced: 6.1
 * Bug #: Fixes 6.0-39 implementation
 *
 * Implements 6.0-39 functionality:
 * Adds Row_LastModified_TimeStamp where necessary.
 * Creates a static RowLastUpdateTimeStamp trigger, bound by primary key columns, for each table
 * that has primary keys.
 *
 * IMPORTANT:
 * This script should be run when first deployed, as well as AT EACH HOTFIX (in case tables
 * have been added or primary keys have been changed).
 * 
 * ******* Spec 9.0-23 *********
 * 20120606	GBS
 * Revised @triggerOrderSQL = "@order=N''LAST''" from first. UDB Triggers must run first.
 * ---------------------------------------------------------------------------*/

SET QUOTED_IDENTIFIER OFF;
SET ANSI_NULLS OFF;
SET NOCOUNT ON;
GO
--****************************************************************************
-- First main block:
--          Drop all RowLastUpdateTimeStamp triggers
--          Add Row_LastModified_TimeStamp columns where appropriate
--****************************************************************************

--******************************
-- Initialize variables
--******************************

DECLARE @numTables INT
        -- number of tables being processed
DECLARE @cnt INT
        -- current table name index
DECLARE @tableName VARCHAR(100)
           -- name of the table being processed
DECLARE @triggerName VARCHAR(200)
         -- name of the trigger being processed / searched for
DECLARE @addColSQL VARCHAR(1000)
          -- SQL to add the Row_LastModified_TimeStamp field

SELECT  @cnt = 1,
        @tableName = '',
        @triggerName = ''

-- This table variable will store the names of all the tables in the DB
-- (using 'EM_' makes it harder to confuse with TABLE_NAME columns)
DECLARE @EM_TABLE_NAMES TABLE
    (
      TABLE_NAME VARCHAR(100),
      TABLE_NAME_INDEX INT
    )

-- Store all table names into this table variable
INSERT  INTO @EM_TABLE_NAMES
        (
          TABLE_NAME,
          TABLE_NAME_INDEX
            
        )
        SELECT  'CUSTOM_METADATA_ID_TYPE', 1

SET @numTables = @@ROWCOUNT


--******************************
-- Perform algorithm:
--          Drop all RowLastUpdateTimeStamp triggers
--          Add Row_LastModified_TimeStamp columns where appropriate
--******************************
WHILE @cnt <= @numTables  
    BEGIN
      -- Get the name of the current table
        SELECT  @tableName = TABLE_NAME
        FROM    @EM_TABLE_NAMES
        WHERE   TABLE_NAME_INDEX = @cnt
        ORDER BY TABLE_NAME

      -- Drop the trigger, if one exists

        SET @triggerName = N'[TRG_' + @tableName + '_RowLastUpdateTimeStamp]'

        IF EXISTS ( SELECT  1
                    FROM    dbo.sysobjects
                    WHERE   ( id = OBJECT_ID(@triggerName) )
                            AND ( OBJECTPROPERTY(id, N'IsTrigger') = 1 ) ) 
            EXEC ( 'DROP TRIGGER [dbo].' + @triggerName )

      -- Add a Row_LastModified_TimeStamp column, if it does not already exist
      -- and the table has a primary key
        IF NOT EXISTS ( SELECT  1
                        FROM    INFORMATION_SCHEMA.COLUMNS
                        WHERE   ( TABLE_NAME = @tableName )
                                AND ( COLUMN_NAME = 'Row_LastModified_TimeStamp' ) )
            AND EXISTS ( SELECT 1
                         FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk
                         WHERE  ( TABLE_NAME = @tableName )
                                AND ( CONSTRAINT_TYPE = 'PRIMARY KEY' ) ) 
            BEGIN
                SET @addColSQL = 'ALTER TABLE [dbo].[' + @tableName
                    + '] ADD [Row_LastModified_TimeStamp] DATETIME NOT NULL '
                    + 'CONSTRAINT [DF_' + @tableName
                    + '_Row_LastModified_TimeStamp] DEFAULT GETDATE()'
                EXEC ( @addColSQL )
            END

        SET @cnt = @cnt + 1
    END
GO


--****************************************************************************
-- Second main block:
--          Create triggers for all tables that have primary keys
--****************************************************************************

--******************************
-- Initialize variables
--******************************


DECLARE @numTables INT
        -- number of tables being processed
DECLARE @cnt INT
        -- current table name index
DECLARE @tableName VARCHAR(100)
           -- name of the table being processed
DECLARE @triggerSQL VARCHAR(1000)
         -- SQL content of the trigger we are creating (i.e. excluding "CREATE TRIGGER...")
DECLARE @pkColName VARCHAR(100)
           -- name of the current primary key column
DECLARE @numPKs INT
           -- total number of primary keys in the current table
DECLARE @pkCnt INT
            -- current primary key name index
DECLARE @updateJoinCriteriaSQL VARCHAR(1000)
          -- the criteria for the "JOIN...ON..." part of the trigger SQL content
DECLARE @triggerOrderSQL VARCHAR(1000)
          -- SQL to set the order in which triggers should be executed

SELECT  @cnt = 1,
        @tableName = ''

-- Declare temp memory table to hold primary key names
DECLARE @PK_COLUMNTBL TABLE
    (
      PK_COLNAME VARCHAR(60),
      PK_COLNAME_INDEX INT
    )

-- This table variable will store the names of all the tables in the DB that have primary keys
DECLARE @PK_TABLE_NAMES TABLE
    (
      TABLE_NAME VARCHAR(100),
      TABLE_NAME_INDEX INT
    )

-- Store all names of all table with primary keys into this table variable
INSERT  INTO @PK_TABLE_NAMES
        (
          TABLE_NAME,
          TABLE_NAME_INDEX
            
        )
        SELECT 'CUSTOM_METADATA_ID_TYPE', 1

SET @numTables = @@ROWCOUNT


--******************************
-- Perform algorithm:
--          Create triggers for all tables that have primary keys
--******************************
WHILE @cnt <= @numTables  
    BEGIN
        SELECT  @tableName = TABLE_NAME
        FROM    @PK_TABLE_NAMES
        WHERE   TABLE_NAME_INDEX = @cnt
        ORDER BY TABLE_NAME

      -- Select the names of all the primary keys of the current table
        INSERT  INTO @PK_COLUMNTBL
                (
                  PK_COLNAME,
                  PK_COLNAME_INDEX
                  
                )
                SELECT  c.COLUMN_NAME,
                        ROW_NUMBER() OVER ( ORDER BY c.COLUMN_NAME )
                FROM    INFORMATION_SCHEMA.KEY_COLUMN_USAGE c ( nolock )
                        JOIN ( SELECT   TABLE_NAME,
                                        CONSTRAINT_NAME
                               FROM     INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ( nolock )
                               WHERE    pk.TABLE_NAME = @tableName
                                        AND CONSTRAINT_TYPE = 'PRIMARY KEY'
                             ) AS k ON c.TABLE_NAME = k.TABLE_NAME
                                       AND c.CONSTRAINT_NAME = k.CONSTRAINT_NAME

      -- Construst the criteria SQL for the JOIN ON clause of the trigger SQL content

        SET @numPKs = @@ROWCOUNT -- get the count of pk columns
        SET @pkCnt = 1
        SET @updateJoinCriteriaSQL = ''

      -- Loop through the primary keys, adding " AND INSERTED.colName = tableName.pkColName" for each one
        WHILE ( @pkCnt <= @numPKs )
            BEGIN
                SELECT  @pkColName = [PK_COLNAME]
                FROM    @PK_COLUMNTBL
                WHERE   [PK_COLNAME_INDEX] = @pkCnt

                SET @updateJoinCriteriaSQL = @updateJoinCriteriaSQL
                    + ' AND INSERTED.[' + @pkColName + '] = [' + @tableName
                    + '].[' + @pkColName + ']'

                SET @pkCnt = @pkCnt + 1
            END

      -- Remove the initial " AND " of the criteria SQL
        SET @updateJoinCriteriaSQL = SUBSTRING(@updateJoinCriteriaSQL, 6,
                                               LEN(@updateJoinCriteriaSQL))

        SET @triggerSQL = 'SET NOCOUNT ON IF TRIGGER_NESTLEVEL() = 1 BEGIN UPDATE [dbo].['
            + @tableName
            + '] SET [ROW_LASTMODIFIED_TIMESTAMP] = GETDATE() FROM ['
            + @tableName + '] JOIN INSERTED ON ' + @updateJoinCriteriaSQL
            + ' END'

     
        EXEC
            ( 'CREATE TRIGGER TRG_' + @tableName
              + '_RowLastUpdateTimeStamp ON [dbo].[' + @tableName
              + '] AFTER UPDATE AS ' + @triggerSQL )

    --PRINT 'CREATE TRIGGER TRG_' + @tableName + '_RowLastUpdateTimeStamp ON [dbo].[' + @tableName + '] AFTER UPDATE AS ' + @triggerSQL

      --This sets the Trigger firing order, currently we are setting it to last        
        SET @triggerOrderSQL = 'sp_settriggerorder @triggername=N''[dbo].[TRG_'
            + @tableName
            + '_RowLastUpdateTimeStamp]'', @order=N''LAST'', @stmttype=N''UPDATE'''
        EXEC ( @triggerOrderSQL )

	  --PRINT @triggerOrderSQL

        SET @cnt = @cnt + 1    
    END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE NAME = 'AUTHOR_WAIVER_REQUEST_STATUS')
BEGIN
	CREATE TABLE AUTHOR_WAIVER_REQUEST_STATUS
	(
		STATUS_ID INT NOT NULL CONSTRAINT PK_AUTHOR_WAIVER_REQUEST_STATUS PRIMARY KEY CLUSTERED,
		[STATUS] NVARCHAR(255) NOT NULL
	)
	
	INSERT INTO dbo.AUTHOR_WAIVER_REQUEST_STATUS(STATUS_ID, [STATUS])
	VALUES
	(1, 'Unsent'),
	(2, 'Pending'),
	(3, 'Denied'),
	(4, 'Granted')
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE NAME = 'AUTHOR_WAIVER_REQUEST')
BEGIN
	CREATE TABLE AUTHOR_WAIVER_REQUEST
	(
		AUTHOR_WAIVER_REQUEST_ID INT NOT NULL IDENTITY(1, 1) CONSTRAINT PK_AUTHOR_WAIVER_REQUEST PRIMARY KEY CLUSTERED,
		DOCUMENTID INT NOT NULL CONSTRAINT FK_AUTHOR_WAIVER_REQUEST_DOCUMENT REFERENCES dbo.DOCUMENT(DOCUMENTID),
		REASON NVARCHAR(MAX) NOT NULL,
		STATUSID INT NOT NULL CONSTRAINT FK_AUTHOR_WAIVER_REQUEST_AUTHOR_WAIVER_REQUEST_STATUS REFERENCES dbo.AUTHOR_WAIVER_REQUEST_STATUS(STATUS_ID),
		STATUS_DATE DATETIME NOT NULL
	)
END	
	GO
IF NOT EXISTS (SELECT 1 FROM dbo.ADMINACCESSFUNCTIONS WHERE RESOURCEID = 'Pages.Admin.PolicyManager.LinkConfigureWaiverRequest')
BEGIN
	INSERT INTO dbo.ADMINACCESSFUNCTIONS
	(
		PAGEID,
		SECTIONID,
		GROUPID,
		ITEMORDER,
		PRODUCTID,
		ITEMTEXT,
		WEBPAGENAME,
		[ACTIVE],
		ADMINRESTRICTEDACTIVE,
		ELIGIBLEADMINACCESS,
		POLICYDISPLAYRULES,
		Row_LastModified_TimeStamp,
		RESOURCEID
	)
	VALUES
	(
		4,
		9,
		11,
		5,
		1,
		'Configure Waiver Request',
		'ConfigureWaiverRequest.aspx',
		1,
		0,
		1,
		0,
		GETDATE(),
		'Pages.Admin.PolicyManager.LinkConfigureWaiverRequest'
	)
	
	UPDATE dbo.ADMINACCESSFUNCTIONS SET ITEMORDER = 6 WHERE RESOURCEID = 'Pages.Admin.PolicyManager.LinkConfigureEmailImport'
	UPDATE dbo.ADMINACCESSFUNCTIONS SET ITEMORDER = 7 WHERE RESOURCEID = 'Pages.Admin.PolicyManager.LinkSetNotifyAuthorBlindingPolicy'
	UPDATE dbo.ADMINACCESSFUNCTIONS SET ITEMORDER = 8 WHERE RESOURCEID = 'Pages.Admin.PolicyManager.LinkSetMergeFieldBlindingPolicy'
	UPDATE dbo.ADMINACCESSFUNCTIONS SET ITEMORDER = 9 WHERE RESOURCEID = 'Pages.Admin.PolicyManager.LinkNotifyEditorPreference'
END
GO
IF NOT EXISTS (SELECT 1 FROM dbo.INSTRUCTIONS WHERE NEW_DEFAULT_RESOURCE_ID = 'Common.SubmissionSteps.RequestWaiverOptions.NewDefaultInstructions')
BEGIN
	UPDATE dbo.INSTRUCTIONS
	SET EDIT_INSTRUCTIONS_DISPLAY_ORDER = EDIT_INSTRUCTIONS_DISPLAY_ORDER + 2
	WHERE EDIT_INSTRUCTIONS_DISPLAY_ORDER > 6
	
	UPDATE dbo.INSTRUCTIONS
	SET ASP_ID = ASP_ID + 1
	WHERE ASP_ID > 15
	
	INSERT INTO dbo.INSTRUCTIONS
	(
		NEW_DEFAULT,
		REVISED_DEFAULT,
		NEW_CUSTOM,
		REVISED_CUSTOM,
		LAST_UPDATE_DATE,
		EDIT_INSTRUCTIONS_DISPLAY_ORDER,
		ASP_ID,
		Row_LastModified_TimeStamp,
		NEW_DEFAULT_RESOURCE_ID,
		REVISED_DEFAULT_RESOURCE_ID,
		SUPPRESS_DISPLAY,
		INSTRUCTION_LABEL
	)
	VALUES
	(
		NULL,
		NULL,
		NULL,
		NULL,
		GETDATE(),
		7,
		16,
		GETDATE(),
		'Common.SubmissionSteps.RequestWaiver.NewDefaultInstructions',
		'Common.SubmissionSteps.RequestWaiver.RevisedDefaultInstructions',
		0,
		'Common.SubmissionSteps.RequestWaiverInstructions'
	)
	
	INSERT INTO dbo.INSTRUCTIONS
	(
		NEW_DEFAULT,
		REVISED_DEFAULT,
		NEW_CUSTOM,
		REVISED_CUSTOM,
		LAST_UPDATE_DATE,
		EDIT_INSTRUCTIONS_DISPLAY_ORDER,
		ASP_ID,
		Row_LastModified_TimeStamp,
		NEW_DEFAULT_RESOURCE_ID,
		REVISED_DEFAULT_RESOURCE_ID,
		SUPPRESS_DISPLAY,
		INSTRUCTION_LABEL
	)
	VALUES
	(
		NULL,
		NULL,
		NULL,
		NULL,
		GETDATE(),
		8,
		36,
		GETDATE(),
		'Common.SubmissionSteps.RequestWaiverOptions.NewDefaultInstructions',
		'Common.SubmissionSteps.RequestWaiverOptions.RevisedDefaultInstructions',
		0,
		'Common.SubmissionSteps.RequestWaiverOption'
	)
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[DCATEGOR]') AND name = 'REQUEST_WAIVER_PREFS_NEW')
BEGIN
	ALTER TABLE dbo.DCATEGOR
	ADD REQUEST_WAIVER_PREFS_NEW INT NOT NULL CONSTRAINT DF_DCATEGOR_REQUEST_WAIVER_PREFS_NEW DEFAULT 2
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[DCATEGOR]') AND name = 'REQUEST_WAIVER_PREFS_REV')
BEGIN
	ALTER TABLE dbo.DCATEGOR
	ADD REQUEST_WAIVER_PREFS_REV INT NOT NULL CONSTRAINT DF_DCATEGOR_REQUEST_WAIVER_PREFS_REV DEFAULT 2
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[DCATEGOR]') AND name = 'WAIVER_REASON_LIMIT_WORDS_OR_CHARS')
BEGIN
	ALTER TABLE dbo.DCATEGOR
	ADD WAIVER_REASON_LIMIT_WORDS_OR_CHARS BIT NOT NULL CONSTRAINT DF_DCATEGOR_WAIVER_REASON_LIMIT_WORDS_OR_CHARS DEFAULT 0
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[DCATEGOR]') AND name = 'WAIVER_REASON_LIMIT')
BEGIN
	ALTER TABLE dbo.DCATEGOR
	ADD WAIVER_REASON_LIMIT INT
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[LETTER_FAMILY]') AND name = 'SENDER_WAIVER_ADDRESS')
BEGIN
	ALTER TABLE dbo.LETTER_FAMILY
	ADD SENDER_WAIVER_ADDRESS BIT NOT NULL CONSTRAINT DF_LETTER_FAMILY_SENDER_WAIVER_ADDRESS DEFAULT 0
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[LETTER]') AND name = 'SENDER_WAIVER_ADDRESS')
BEGIN
	ALTER TABLE dbo.LETTER
	ADD SENDER_WAIVER_ADDRESS BIT NOT NULL CONSTRAINT DF_LETTER_SENDER_WAIVER_ADDRESS DEFAULT 0
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[METADATA_STATUS]') AND name = 'WAIVER_REQUEST_UPDATED')
BEGIN
	ALTER TABLE dbo.METADATA_STATUS
	ADD WAIVER_REQUEST_UPDATED BIT NOT NULL CONSTRAINT DF_METADATA_STATUS_WAIVER_REQUEST_UPDATED DEFAULT 0
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[METADATA_STATUS]') AND name = 'WAIVER_REQUEST_UPDATED_DATE')
BEGIN
	ALTER TABLE dbo.METADATA_STATUS
	ADD WAIVER_REQUEST_UPDATED_DATE DATETIME
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE  object_id = OBJECT_ID(N'[dbo].[DOCUMENT]') AND name = 'REQUEST_WAIVER')
BEGIN
	ALTER TABLE dbo.DOCUMENT
	ADD REQUEST_WAIVER TINYINT NOT NULL CONSTRAINT DF_DOCUMENT_REQUEST_WAIVER DEFAULT 0
END

GO

UPDATE dbo.LETTER_FAMILY
SET
	SENDER_WAIVER_ADDRESS = 1,
	DISPLAY_RECIPIENT_EMAIL_ADDRESSES = 1,
	USE_CORRESPONDING_AUTHOR_EMAIL = 1,
	RECIPIENT_CORRESPONDING_AUTHOR = 1,
	RECIPIENT_SENDER_EMAIL = 1
WHERE LETTER_FAMILY_ID = 25
GO
IF NOT EXISTS (SELECT 1 FROM dbo.DEEPLINK_TYPE WHERE DEEPLINK_TYPE_ID = 39)
BEGIN
	SET IDENTITY_INSERT dbo.DEEPLINK_TYPE ON
	
	INSERT INTO dbo.DEEPLINK_TYPE
	(
		DEEPLINK_TYPE_ID,
		LINK_TEXT,
		LINK_TEXT2,
		LINK_TEXT3,
		Row_LastModified_TimeStamp,
		DAYS,
		CLICKS
	)
	VALUES
	(
		39,
		'Grant Waiver Request',
		NULL,
		NULL,
		GETDATE(),
		NULL,
		NULL
	)
	
	INSERT INTO dbo.DEEPLINK_TYPE
	(
		DEEPLINK_TYPE_ID,
		LINK_TEXT,
		LINK_TEXT2,
		LINK_TEXT3,
		Row_LastModified_TimeStamp,
		DAYS,
		CLICKS
	)
	VALUES
	(
		40,
		'Deny Waiver Request',
		NULL,
		NULL,
		GETDATE(),
		NULL,
		NULL
	)
	
	SET IDENTITY_INSERT dbo.DEEPLINK_TYPE OFF
END
GO
IF NOT EXISTS (SELECT 1 FROM dbo.MASTER_CONFIG WHERE CONFIG_ID = 313)
BEGIN
	INSERT INTO dbo.MASTER_CONFIG
	(
		CONFIG_ID,
		[DESCRIPTION],
		[VALUE],
		LAST_UPDATE,
		Row_LastModified_TimeStamp
	)
	VALUES
	(
		313,
		'Author Waiver Author Requests Waiver Email ID',
		'0',
		GETDATE(),
		GETDATE()
	),
	(
		314,
		'Author Waiver Waiver Granted Email ID',
		'0',
		GETDATE(),
		GETDATE()
	),
	(
		315,
		'Author Waiver Waiver Denied Email ID',
		'0',
		GETDATE(),
		GETDATE()
	),
	(
		316,
		'Author Waiver From Email',
		(SELECT SENDEREMAILADDR FROM dbo.CONFIG),
		GETDATE(),
		GETDATE()
	),
	(
		317,
		'Author Waiver From Name',
		(SELECT SENDERNAME FROM dbo.CONFIG),
		GETDATE(),
		GETDATE()
	)
END
GO

/*******************************************************************
* 
*	DO NOT PUT in upgrade script.  This is only for fixing databases that have
*	already had the old 13.0-34 script applied to it.
* 
*******************************************************************/
IF EXISTS (SELECT 1 FROM dbo.INSTRUCTIONS WHERE NEW_DEFAULT_RESOURCE_ID = 'Common.SubmissionSteps.RequestWaiver.NewDefaultInstructions' AND ASP_ID = 35)
BEGIN

	UPDATE dbo.INSTRUCTIONS
	SET EDIT_INSTRUCTIONS_DISPLAY_ORDER = 5
	WHERE INSTRUCTION_LABEL = 'Common.SubmissionSteps.FundingInformation'
	UPDATE dbo.INSTRUCTIONS
	SET EDIT_INSTRUCTIONS_DISPLAY_ORDER = 6
	WHERE INSTRUCTION_LABEL = 'Common.SubmissionSteps.FundingInfoReqCheckbox'
	UPDATE dbo.INSTRUCTIONS
	SET EDIT_INSTRUCTIONS_DISPLAY_ORDER = 7
	WHERE INSTRUCTION_LABEL = 'Common.SubmissionSteps.RequestWaiverInstructions'
	UPDATE dbo.INSTRUCTIONS
	SET EDIT_INSTRUCTIONS_DISPLAY_ORDER = 8
	WHERE INSTRUCTION_LABEL = 'Common.SubmissionSteps.RequestWaiverOption'
	
	UPDATE dbo.INSTRUCTIONS
	SET ASP_ID = ASP_ID + 1
	WHERE ASP_ID > 15 AND ASP_ID < 35
	
	UPDATE dbo.INSTRUCTIONS
		SET ASP_ID = 16 WHERE INSTRUCTION_LABEL = 'Common.SubmissionSteps.RequestWaiverInstructions'
END
GO