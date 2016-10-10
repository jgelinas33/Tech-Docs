/* ----------------------------------------------------------------------------
 * Copyright © 2007-Present Aries Systems Corporation. All Rights Reserved.
 * Copying, reverse engineering, adaptation or any other derivative use
 * prohibited.  This material is proprietary and confidential information
 * of Aries Systems Corporation.
 * 
 * Date Created: 20070713
 * Version Introduced: EM 7.0
 * Spec #: 7.0-05
 * 
 * Description: Generic functionality for an author-invitation process
 *				confirm and customize letters page.
 * --------------------------------------------------------------------------*/
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web.UI.WebControls;
using System.Xml;
using Aries.EditorialManager.Framework.Journal.ArticleTypeObjects.ArticleType;
using Aries.EditorialManager.Web.Controls.FGrid;
using Aries.Shared;
using Aries.Shared.Framework;
using Aries.Shared.Web;
using Aries.EditorialManager.Framework.Journal;
using PeopleObjects = Aries.EditorialManager.Framework.Journal.PeopleObjects;
using PersonMapper = Aries.EditorialManager.Framework.Journal.PeopleObjects.Person.Database.Mapper;
using EditorRoleEntity = Aries.EditorialManager.Framework.Journal.RoleManager.EditorRolePermissions.Entity;
using SubmissionEntity = Aries.EditorialManager.Framework.Journal.SubmissionObjects.Submission.Entity;
using ArticleTypeEntity = Aries.EditorialManager.Framework.Journal.ArticleTypeObjects.ArticleType.Entity;
using LetterEntity = Aries.EditorialManager.Framework.Journal.LetterObjects.Letter.Entity; 
using EventLetterEntity = Aries.EditorialManager.Framework.Journal.LetterObjects.EventLetter.Entity;
using LetterCollection = Aries.EditorialManager.Framework.Journal.LetterObjects.Letter.Collection;
using SubmissionLinkedGroupMembershipMapper = 
    Aries.EditorialManager.Framework.Journal.LinkedSubmissionGroupObjects.SubmissionLinkedGroupMembership.Database.Mapper;
using SubmissionLinkedGroupMembershipEntity = 
    Aries.EditorialManager.Framework.Journal.LinkedSubmissionGroupObjects.SubmissionLinkedGroupMembership.Entity;
using PersonEntity = Aries.EditorialManager.Framework.Journal.PeopleObjects.Person.Entity;
using AuthorInvitation = Aries.EditorialManager.Framework.Journal.AuthorObjects.InvitedAuthor;
using TargetPub = Aries.EditorialManager.Framework.Journal.SubmissionObjects.TargetPublicationInfo;
using SubmissionProd = Aries.EditorialManager.Framework.Journal.SubmissionObjects.SubmissionProductionInfo;
using Aries.EditorialManager.Framework.Journal.ConfigObjects.ConfigItem;
using ConfigItemMapper = Aries.EditorialManager.Framework.Journal.ConfigObjects.ConfigItem.Database.Mapper;

using RoleFamilyType = Aries.EditorialManager.Framework.Journal.PeopleObjects.Person.RoleFamilyType;

namespace Aries.EditorialManager.Web
{
	/// <summary>
	/// This class encapsulates some functionality shared across the various "confirm and customize"
	/// authors pages.
	/// </summary>
    /// <remarks>
    /// ************************ 13.0-18 *************************************
    /// 20151027 JGG
    /// Add capture of authorSearchMode queryString in InitializeBaseObjects into _authorSearchMode
    /// 
    /// Want to populate hidden field values from _pageXml and CurrentSession if _authorSearchMode = 
    /// AUTHOR_SEARCH_MODE_UPLOAD_AUTHOR_LIST.
    /// 
    /// StoreSessionVariables -
    /// if _authorSearchMode = AUTHOR_SEARCH_MODE_UPLOAD_AUTHOR_LIST - no need to populate
    /// InvitedAuthorsXml of _pageXml since it will come in from 
    /// CurrentSession.CurrentPeopleSearchXML
    /// 
    /// Capture listing of people ids and related notes in ParseSelectedAuthorsXml to 
    /// _peopleNotes.  Use _peopleNotes in GetAuthorInvitationNotes, if it exists,
    /// to get a note value if none gathered from database.
    /// 
	/// ************************ TestTrack 23770 *************************************
	/// 20120614 swinter
	///
	/// If the fields are set to 0 for author invitiation response due and author submission due date 
	/// it is intended to mean that no dates should be automatically calculated.  Added 0 check 
	/// for author invite due date day offset and author submission due date day offset
	/// and if 0 it will not automatically calculate the dates to use.
	/// 
    /// ************************ TestTrack 19619 *************************************
    /// 20090603 ASM
    /// 
    /// Problem: In method generateDataCell, original code:inputControl.Width = Unit.Percentage(50.00) where
    /// a date textbox is being added to a tablecell. If other parts of the table widen,
    /// (ex. a long letter name in the letter name column), then
    /// the date textboxes are not wide enough to display the entire date.
    /// Solution: remove the width assignment. Dates can be seen entirely now.
    ///
    /// </remarks>
    public abstract class AuthorConfirmAndCustomizeEMPage : EMPage
    {
		#region Properties

       /// <summary>
		/// Flag indicating whether the site is configured
		/// to display the Invitation Notes To Author TextBox
		/// </summary>
		public bool HasAuthorInvitationNotesTextBox
		{
			get
			{
				return (AuthorInfoConfigItem.DisplayInvitationNotesToAuthorTextBox && ! this.OverRideAuthorInvitationNotesConfig);	
			}
		}

		private ConfigAuthorInvitationInfo _authorInfoConfigItem;

		/// <summary>
		/// Retrieves an instance of the ConfigAuthorInvitationInfo
		/// object.  This provides an interface to the master 
		/// configuration settings for the Author Invitation items.
		/// </summary>
		public ConfigAuthorInvitationInfo AuthorInfoConfigItem
		{
			get
			{
				if (_authorInfoConfigItem == null)
				{
					ConfigSettingFactory configSettingFactory = new ConfigSettingFactory(this.Journal, this.ConnectionString);
					_authorInfoConfigItem = configSettingFactory.CreateConfigSetting<ConfigAuthorInvitationInfo>();
				}
				return _authorInfoConfigItem;
			}
		}
		
		/// <summary>
		/// For certain pages, the "Invitation Notes To Author"
		/// TextBox will not be displayed, even if the site is
		/// configured for such.
		/// </summary>
		public bool OverRideAuthorInvitationNotesConfig
		{
			get
			{
				switch(this.PageName.ToUpper())
				{
					case "CONFIRMANDCUSTOMIZEUNINVITEDAUTHORS.ASPX":
						return true;
					default:
						return false;
				}
				
			}
		}

		
		#endregion Properties

		#region Members

		#region Protected Members

		/// <summary>
		/// Register all client scripts for the page
		/// </summary>
		/// <remarks>#25952 Alex 20131002</remarks>
		private void RegisterClientScripts()
		{
			if (!IsPostBack)
			{
				if (!Page.ClientScript.IsClientScriptIncludeRegistered("jQuery-ui-date"))
					Page.ClientScript.RegisterClientScriptInclude(GetType(), "jQuery-ui-date", "ClientScript/jquery-ui-date.aspx");

				if (!Page.ClientScript.IsStartupScriptRegistered("CalendarStartup"))
				{
					var sbCode = new StringBuilder();
					sbCode.Append("jQuery(document).ready(function(){jQuery('.em-datepicker').showDatepicker();" + "})");
					Page.ClientScript.RegisterStartupScript(GetType(), "CalendarStartup", sbCode.ToString(), true);
				}
			}
		}

		#region Constants

		/// <summary>
		/// Constant signifying an author invitation workflow.
		/// </summary>
		protected int AUTHOR_INVITATION = 0;

		/// <summary>
		/// Constant signifying an alternate author invitation workflow.
		/// </summary>
		protected int ALTERNATE_AUTHOR_INVITATION = 1;

		/// <summary>
		/// Constant signifying an alternate author promotion workflow.
		/// </summary>
		protected int ALTERNATE_AUTHOR_PROMOTION = 2;

		/// <summary>
		/// Constant signifying an author uninvitation workflow.
		/// </summary>
		protected int AUTHOR_UNINVITATION = 3;

		/// <summary>
		/// Constant signifying an existing alternate author letter customization workflow.
		/// </summary>
		protected int ALTERNATE_AUTHOR_LETTER_CUSTOMIZATION = 4;

        #endregion Constants

        /// <summary>
		/// Event letter manager object.
		/// </summary>
		protected AuthorEventLetterManager _ELM;

		/// <summary>
		/// Author invitation manager object.
		/// </summary>
		protected AuthorInvitationManager _authorInvitationManager;

		/// <summary>
		///used to generate the XML representing the state of the GUI
		/// </summary>
		protected XmlDocument _pageXml;

		/// <summary>
		/// which event we're confirming/customizing letters for
		/// </summary>
		protected EventType _currentEvent;

		/// <summary>
		//mapper for unavailable dates
		protected PeopleObjects.UnavailableDate.Database.Mapper _uvDateMapper;

		/// <summary>
		/// mapper for people objects, we might need to look them up
		/// </summary>
        protected PersonMapper _personMapper;

		/// <summary>
		///object containing role permissions for the user of this page
		/// </summary>
		protected EditorRoleEntity _roleManager;

		/// <summary>
		/// Whether there 
		/// </summary>
		protected bool _isLetterToTheEditor;

		/// <summary>
		/// specifies which of the workflows we're following (see const declarations above)
		/// </summary>
		protected int _workFlow;

		/// <summary>
		/// The document being dealt with. 
		/// </summary>
        protected SubmissionEntity _managedDoc;



		/// <summary>
		/// Object abstracting some of the invited authors XML.
		/// </summary>
		protected InvitedAuthorsXMLManager _xmlManager;

	    #region Hidden Fields

	    /// <summary>
		/// Hidden field declarations
		/// </summary>
		protected HiddenField hdnDocumentID = new HiddenField();
		protected HiddenField hdnEventID = new HiddenField();
		protected HiddenField hdnRevision = new HiddenField();
		protected HiddenField hdnAuthorSearchMode = new HiddenField();
		protected HiddenField hdnSelectedAuthors = new HiddenField();
		protected HiddenField hdnLetterID = new HiddenField();
		protected HiddenField hdnEventLetterIDs = new HiddenField();
		protected HiddenField hdnAuthorInvitationIDs = new HiddenField();
		protected HiddenField hdnWorkflowField = new HiddenField();

        #endregion Hidden Fields

        #endregion Protected Members

        #region Private Members

        protected ArticleTypeEntity _docType;
	    private AuthorSubDueDateType _authorSubDueDateType;

        //13.0-18 20151027 JGG
        /// <summary>
        /// Passed in via queryString (authorSearchMode)
        /// </summary>
        private string _authorSearchMode;

        /// <summary>
        /// Lookup list of peopleID, related notes.
        /// Populated at ParseSelectedAuthorsXml.
        /// To be used at GetAuthorInvitationNotes
        /// </summary>
        private static List<KeyValuePair<int,string>> _peopleNotes = null;

        #endregion Private Members

        #endregion Members

        #region Methods


        #region Protected Methods

        /// <summary>
	    /// Sets any other control properties. Specific to inheriting class.
	    /// </summary>
	    protected abstract void SetControls();

	    /// <summary>
		/// Initializes mappers, business layer objects used by all inheriting classes.
		/// </summary>
		/// <remarks>
		/// ********* Defect 24410 *********
		/// 20121015 swinter
		/// Verifying permission for editor role when InitializeBaseObjects is called to prevent 
		/// an error message if the page is navigated to from a browser that isn't logged in.
		/// </remarks>
		/// <returns></returns>
		protected bool InitializeBaseObjects()
		{
			VerifyPermission(Constants.editorPermission);

			//initialize mappers
			_uvDateMapper = MapperManager.UnavailableDateMapper;
			_personMapper = MapperManager.PersonMapper;

			//initialize rolemanager object
			RolePermissionsFactory factory = new RolePermissionsFactory(Journal);
			_roleManager = (EditorRoleEntity)factory.GetRolePermissions(RoleEnum.EditorRole, StateManager.EditorRoleID, StateManager.InProxyMode);

			_pageXml = new XmlDocument();
			_pageXml.LoadXml(CurrentSession.CurrentPeopleSearchXML);

			//the 'customize letter' and 'save letter' pages have an embedded "fromLetterCustomizationPage" request parameter
			//that other pages do not have. If this parameter isn't parseable then we came from a search results page.
			//Otherwise, we didn't (and don't do the things appropriate to that point of origin, such as clearing the event letters collection)
			//Also, don't clear letters on postbacks.
			bool fromSearchResultsPage = String.IsNullOrEmpty(Request["fromLetterCustomizationPage"]) && !Page.IsPostBack;
			
			//if we came from the search results page, we're coming back through here again
			//so we need to store some variables that are coming back to that page.
			//some session variables rely on all controls being in place on this page, so do this now rather than earlier.

            // 13.0-18 20151027 JGG
            // added capture here for determining how to store session variables and initialize hidden fields
	        _authorSearchMode = Request["authorSearchMode"] ?? "";

			if (fromSearchResultsPage)
			{
               StoreSessionVariables();
			}

            // 13.0-18 20151027 JGG
            // add check against authorSearchMode
            // if authorSearchMode == AUTHOR_SEARCH_MODE_UPLOAD_AUTHOR_LIST want 'false' passed as parameter so that hidden field values
            // are gathered from the xml document and NOT the request string
			InitializeHiddenFields(fromSearchResultsPage && Convert.ToInt32(_authorSearchMode) != Constants.AUTHOR_SEARCH_MODE_UPLOAD_AUTHOR_LIST);

			//initialize the "current event" variable based on the value retrieved from session / request object
			int parsedEventID;
			if (Int32.TryParse(hdnEventID.Value, out parsedEventID))
			{
				_currentEvent = (EventType)parsedEventID;
			}

			// load the document object being dealt with.
			_managedDoc = MapperManager.SubmissionMapper.FindSubmissionByDocID(Int32.Parse(hdnDocumentID.Value));
            _docType = _managedDoc.ArticleType;
	    	_authorSubDueDateType = _docType.AuthorSubDueDateType;

			// This field needs to be initialized after the "managedDoc" object has been initialized
			// otherwise it's always at the default value.
			// Generate a hidden field to pass "Author Submission Due Date Type" settings to the client JavaScript
			ClientScript.RegisterHiddenField("authorSubDueDateType", ((int)_authorSubDueDateType).ToString());

			_authorInvitationManager = new AuthorInvitationManager(Journal);

			// If the editor has 'View Linked Submissions' permission and the submission that the author
			// is being invited to comment on is a member of a Letter to the Editor submission group,
			// send the user to the Linked Submissions Notice page.
			// Is the referring submission a member of a Letter to the Editor group?
			SubmissionLinkedGroupMembershipMapper submissionLinkedGroupMembershipMapper = MapperManager.LinkedGroupMembershipMapper;
			SubmissionLinkedGroupMembershipEntity submissionLinkedGroupMembershipEntity = submissionLinkedGroupMembershipMapper.FindByDocID(_managedDoc.DocumentID);
			_isLetterToTheEditor = submissionLinkedGroupMembershipEntity.IsLetterToEditorGroupMember ?? false;

			SetControls();

			RegisterClientScripts();	// 25952 Alex 20130830 - register client scripts

			return fromSearchResultsPage;
		}

	    /// <summary>
		/// Event handler for the customize "button" click
		/// </summary>
		public void customizeButtonClick(Object sender, CommandEventArgs e)
		{
			// register any changes the user made on the page.
			updateEventLetters();

			int eventLetterID = Int32.Parse(((LinkButton)sender).CommandName);

			// get the specific event letter that we're going to be customizing
			EventLetterEntity target = _ELM.GetEventLetter(eventLetterID);

			StoreSessionVariables();

			//post to customize page
			ClientScript.RegisterStartupScript(GetType(),
				"postToCustomizePageScript",
				String.Format("postToCustomizePage({0}, {1}, {2}, '{3}');",
					((int)target.Letter),
					eventLetterID,
					target.PeopleID,
					target.RoleName),
				true);
		}

	    /// <summary>
		/// Helper function concerned with author invitations.
		/// Calculates various due dates and then calls AuthorInvitationManager's inviteAuthors method.
		/// Sets value of authorInvitationIDs hidden param.
		/// </summary>
		/// <param name="inviteType">The type of invitation to make</param
		/// <returns>A comma-separated string of the authors invited.</returns>
		protected string inviteAuthors(AuthorInvitation.AuthorInvitationType inviteType)
		{
			return _authorInvitationManager.inviteAuthors(_ELM.EventLetters,
											(int)CurrentSession.PeopleID,
											_xmlManager,
											inviteType);			
		}

	    /// <summary>
		/// This function updates the event letters contained in the Event Letter Manager's collection
		/// with selections that the user made on the page.
		/// Currently:
		///				- The default letter
		///				- Whether to actually send the letter
		/// </summary>
		protected void updateEventLetters()
		{
			//loops through all the 'letterList' drop down list controls and checks the letter selection there
			//against the Letter of the matching EventLetter object.

			//also loops through all the 'doNotInviteCheckBox' checkbox controls and checks the status of the box
			//against the SendLetter field of the matching EventLetter object

			foreach (EventLetterEntity let in _ELM.EventLetters)
			{
				// flag indicating whether selections for the letter have changed
				bool updateLetter = false;

				// examine the 'do not invite/send' checkbox for this eventLetter's row
				string checkBoxName = string.Format("doNotInviteCheckBox{0}", let.EventLetterID);
				CheckBox cbInvite = Page.FindControl(checkBoxName) as CheckBox;
				if (cbInvite != null && (let.SendLetter == cbInvite.Checked))
				{
					updateLetter = true;
					let.SendLetter = !cbInvite.Checked;
				}

				// examine the 'letter' drop-down list, if one exists, for this eventLetter's row
				string listName = string.Format("letterList{0}", let.EventLetterID);
				DropDownList ddList = Page.FindControl(listName) as DropDownList;

				//if the control we're examining is actually a drop down list for an invited author letter
				//as opposed to a literal for a letter not going out to an author ("Others Notified")
				if (ddList != null)
				{
					int selectedLetterID;

					//if the user has changed a letter selection
					if (Int32.TryParse(ddList.SelectedValue, out selectedLetterID) &&
						selectedLetterID != let.LetterID)
					{
						_ELM.changeEventLetterToNewDefaultLetter(let.EventLetterID, selectedLetterID);
						updateLetter = true;
					}
				}

				/*************************************************************************
				 * Spec 7.67	TimH	20090219
				 * Update the INVITED_AUTHORS.INVITED_AUTHOR_NOTES field,
				 * for the corresponding Event Letter(MULTIPLELETTERS) - if the INVITED_AUTHORS record
				 * currently exists.
				*************************************************************************/
				TextBox txtInvitationNotes = (TextBox)Page.FindControl(string.Format("txtInvitationNotes{0}", let.EventLetterID));
				if (txtInvitationNotes != null)
				{
				    _authorInvitationManager.UpdateInvitedAuthorNotes(let.DocumentID.Value, let.EventLetterID, txtInvitationNotes.Text);
				}

				// if the user has changed something, store those changes.
				if (updateLetter)
				{
					_ELM.UpdateEventLetter(let);
				}
					
			}
		}

	    /// <summary>
		/// Parses an xml string containing the selected authors
		/// </summary>
		protected static int[] ParseSelectedAuthorsXml(string xml)
		{
			XmlDocument authorsDoc = new XmlDocument();
			authorsDoc.LoadXml(xml);
            _peopleNotes = new List<KeyValuePair<int, string>>();

			foreach (XmlElement author in authorsDoc.SelectNodes("/PeopleSearchXml/InvitedAuthorsXml/author"))
			{
				int numLetters = Int32.Parse(author.GetElementsByTagName("numLetters")[0].InnerText);
				int authorID = Int32.Parse(author.GetElementsByTagName("id")[0].InnerText);
                string note = author.GetElementsByTagName("note")[0].InnerText;

				for (int x = 0; x < numLetters; x++)
				{
                    _peopleNotes.Add(new KeyValuePair<int, string>(authorID,note));
				}
			}

	        return _peopleNotes.Select(i => i.Key).ToArray();
		}

	    /// <summary>
		/// Retrieves the full name of the individual with this peopleID
		/// <summary>
		/// <param name="peopleID">The individual whose name to get.</param>
		/// <returns>The full name, or "" if the individual isn't there.</returns>
		protected string getFullName(int peopleID)
		{
			PeopleObjects.Person.Entity pe = _ELM.Recipients.FindByPeopleID(peopleID);

			//if we found it in the recipient collection, good
			if (pe != null)
				return pe.FullNameWithDegree;
			//otherwise, we have to go out to the database and get it
			else
				return _personMapper.FindByIdentity(new Identity<int>(peopleID)).FullNameWithDegree;
		}

	    /// <summary>
		/// Checks whether or not this individual is currently unavailable.
		/// An individual is unavailable if an unavailable period
		/// a) is scheduled to start within the next 30 days
		/// b) is scheduled to end within the next 30 days
		/// c) is scheduled to end more than 30 days from now and is currently active.
		/// <summary>
		/// <param name="peopleID">The individual for whom to check unavailability.</param>
		/// <returns>True if the individual is unavailable, false otherwise</returns>
		protected bool isUnavailable(int peopleID)
		{
			PeopleObjects.UnavailableDate.Collection udc = _uvDateMapper.FindByPeopleID(peopleID);

			DateTime fixedDate = DateTime.Now;
		    const int THIRTY_DAYS = 30;

			foreach (PeopleObjects.UnavailableDate.Entity ude in udc)
			{
			    //this logic lifted from selectReviewersGrid.asp SQL logic for displaying unavailable dates there
			    bool isUnavailable = ((ude.EndDate > fixedDate) && (ude.EndDate < fixedDate.AddDays(THIRTY_DAYS))) ||
			                         //the start date is less than 30 days in the future
			                         ((ude.StartDate > fixedDate) && (ude.StartDate < fixedDate.AddDays(THIRTY_DAYS))) ||
			                         //the stop date is more than 30 days in the future and the start date is in the past (user is currently unavailable)
			                         ((ude.EndDate > fixedDate.AddDays(THIRTY_DAYS)) && (ude.StartDate < fixedDate));

			    if (isUnavailable)
					return true;
			}

		    return false;
		}

	    /// <summary>
		/// Helper method to generate table headers for the invited authors/others tables
		/// <summary>
		/// <param name="tblInvitedAuthors">"Primary" recipients table.</param>
		/// <param name="doNotInviteResourceID">The resource id for text to show for the "Do Not Use" column. 
		/// If this is null, the column will not be displayed.</param>
		/// <param name="tblOtherRecipients">The "other" recipients table.</param>
		/// <param name="pnlOthersInvited">The panel containing the 'other recipients' table.</param>
		/// <param name="showDueDates">Whether to show the Due Date columns.</param>
		/// <param name="hasCustomizeColumn">Spec 7.0-37	TimH	20090213
		/// Indicates whether or not we generate the column for the Cusomize hyperlink.
		/// </param>
		protected void generateTableHeaders(Table tblInvitedAuthors, string doNotInviteResourceID, Table tblOtherRecipients, Panel pnlOthersInvited, bool showDueDates, bool hasCustomizeColumn)
		{
			TableHeaderRow invitedAuthorsRow = new TableHeaderRow();
			TableHeaderCell tCell;
            TranslationLiteral lHeader;

			lHeader = new TranslationLiteral();
			lHeader.ID = "invitedAuthorsNameHeader";
            lHeader.ResourceID = "Common.Grids.ColumnHeaders.Name";
			tCell = new TableHeaderCell();
			tCell.Controls.Add(lHeader);
			invitedAuthorsRow.Cells.Add(tCell);

            lHeader = new TranslationLiteral();
			lHeader.ID = "invitedAuthorsLetterHeader";

            lHeader.ResourceID = (HasAuthorInvitationNotesTextBox ? "Common.Grids.ColumnHeaders.LetterInvitationNotesToAuthor" : "Common.Grids.ColumnHeaders.Letter");
			tCell = new TableHeaderCell();
			tCell.Controls.Add(lHeader);
			invitedAuthorsRow.Cells.Add(tCell);

			if(hasCustomizeColumn)
			{
                lHeader = new TranslationLiteral();
				lHeader.ID = "invitedAuthorsCustomizeHeader";
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				invitedAuthorsRow.Cells.Add(tCell);
			}

	    	if (showDueDates)
			{
                lHeader = new TranslationLiteral();
				lHeader.ID = "invitedAuthorsResponseDueDateHeader";
                lHeader.ResourceID = "Common.Grids.ColumnHeaders.InvitedAuthorResponseDueDate";
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				invitedAuthorsRow.Cells.Add(tCell);

                lHeader = new TranslationLiteral();
				lHeader.ID = "invitedAuthorsSubmissionDueHeader";
                if (_managedDoc.ArticleType.Entity.AuthorSubDueDateType ==
						AuthorSubDueDateType.NumDaysAfterAuthorAccepts)
				{
                    lHeader.ResourceID = "Common.Grids.ColumnHeaders.AuthorSubmissionDue";
				}
				else
				{
                    lHeader.ResourceID = "Common.Grids.ColumnHeaders.AuthorSubmissionDueDate";
				}
				
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				invitedAuthorsRow.Cells.Add(tCell);
			}

            if (doNotInviteResourceID != null)
			{
                lHeader = new TranslationLiteral();
				lHeader.ID = "invitedAuthorsDoNotInviteHeader";
                lHeader.ResourceID = doNotInviteResourceID;
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				invitedAuthorsRow.Cells.Add(tCell);
			}

			tblInvitedAuthors.Rows.Add(invitedAuthorsRow);

			if (tblOtherRecipients != null && pnlOthersInvited != null)
			{
				TableRow otherRecipientsRow = new TableRow();

                lHeader = new TranslationLiteral();
				lHeader.ID = "otherRecipientsNameHeader";
                lHeader.ResourceID = "Common.Grids.ColumnHeaders.Name";
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				otherRecipientsRow.Cells.Add(tCell);

                lHeader = new TranslationLiteral();
				lHeader.ID = "otherRecipientsLetterHeader";
                lHeader.ResourceID = "Common.Grids.ColumnHeaders.Letter";
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				otherRecipientsRow.Cells.Add(tCell);

                lHeader = new TranslationLiteral();
				lHeader.ID = "otherRecipientsCustomizeHeader";
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				otherRecipientsRow.Cells.Add(tCell);

                lHeader = new TranslationLiteral();
				lHeader.ID = "otherRecipientsDoNotInviteHeader";
                lHeader.ResourceID = "Common.Grids.ColumnHeaders.DoNotSend";
				tCell = new TableHeaderCell();
				tCell.Controls.Add(lHeader);
				otherRecipientsRow.Cells.Add(tCell);

				tblOtherRecipients.Rows.Add(otherRecipientsRow);

				pnlOthersInvited.Visible = true;
			}
		}

	    /// <summary>
	    /// Generates instructions displayed on a page. Instructions vary by inheriting class.
	    /// </summary>
	    protected abstract void generateInstructions();

	    /// <summary>
		/// Generates the list of email recipients, including people info, unavailable
		/// customize links, letter selection combo boxes and 'do not invite/send' check boxes.
		/// </summary>
		/// <param name="tblInvitedAuthors">The "invited authors" table.</param>
		/// <param name="tblOtherRecipients">The "other recipients" table</param>
		/// <param name="showDoNotUseColumn">Whether to show the 'do not use/send' column.</param>
		protected void generateRecipientListHTML(Table tblInvitedAuthors, Table tblOtherRecipients, bool showDoNotUseColumn)
		{
			generateRecipientListHTML(tblInvitedAuthors, tblOtherRecipients, showDoNotUseColumn, false, false);
		}



	    /// <summary>
		/// Generates the list of email recipients, including people info, unavailable
		/// customize links, letter selection combo boxes and 'do not invite/send' check boxes.
		/// <summary>
		/// <param name="tblInvitedAuthors">The "invited authors" table.</param>
		/// <param name="tblOtherRecipients">The "other recipients" table</param>
		/// <param name="showDoNotUseColumn">Whether to show the 'do not use/send' column.</param>
		/// <param name="showDateColumns">Whether to show the 'submission due dates' columns.</param>
		/// <param name="hasCustomizeColumn">Whether the "Customize" link is rendered in its
		/// own column or else rendered to the right of the Letters Dropdowns in that control's column.</param>
		protected void generateRecipientListHTML(Table tblInvitedAuthors
												,Table tblOtherRecipients
												,bool showDoNotUseColumn
												,bool showDateColumns
												,bool hasCustomizeColumn)
		{
			foreach (EventLetterEntity curLetter in _ELM.EventLetters)
			{
				//determine if this is an author we're sending to, or some other type of guy
				bool authorRow = (curLetter.RoleFamilyID == RoleFamilyType.Author);
                
				if (authorRow || (tblOtherRecipients != null))
				{
					TableRow tRow = new TableRow();
                    
					//author name column
					TableCell tCell = generateAuthorNameCell(curLetter, 
						authorRow && !(_workFlow == AUTHOR_UNINVITATION ||
										_workFlow == ALTERNATE_AUTHOR_PROMOTION));
					
					tRow.Cells.Add(tCell);

					// Spec 7.0-67	TimH	20090217
					// Build the TableCell control that will contain, if so configured,
					// the Letter DropDownList, "Customize" ButtonLink, "Insert Special Character" HyperLink,
					// and the "Invitation Notes To Author" TextBox
					tCell = GenerateLettersTableCell(curLetter, authorRow, true, hasCustomizeColumn);
					
					tRow.Cells.Add(tCell);

					// Spec 7.0-67	TimH	20090217
					// The customize ButtonLink will go in it's own column
					// in this case.  Otherwise it is folded into the set of
					// controls that are built by GenerateLettersTableCell() above.
					if ((hasCustomizeColumn && authorRow) || (! authorRow && (tblOtherRecipients != null)))
					{
						//customize letter link
						tCell = new TableCell();

						//The functionality of this particular link button depends on its name
						//so if you change the name, make sure to change the parsing routine in customizeButtonClick() to match the new name
						TranslationLinkButton customizeButton = new TranslationLinkButton();
						customizeButton.ID = string.Format("customizeLinkButton{0}", curLetter.EventLetterID);
						customizeButton.CommandName = curLetter.EventLetterID.ToString();
						customizeButton.Command += customizeButtonClick;
                        customizeButton.ResourceID = "Common.Grids.ColumnHeaders.Customize";
						tCell.Controls.Add(customizeButton);

						tRow.Cells.Add(tCell);	
					}
					

					if (authorRow && showDateColumns)
					{						
					    string recipientName = getFullName(curLetter.PeopleID.Value);

						//insert "Author Response Due Date" label or textbox
						string controlName = string.Format("txtResponseDueDate{0}", curLetter.EventLetterID);
						string controlText;					//this is the value of the textbox or hidden control
                        bool showCalendar;					//whether or not to show the calendar link
                        TranslationLiteral instructionalControl = new TranslationLiteral();

						TargetPub.Collection pubInfos = _managedDoc.TargetPubInfo;

						//assumption that there is at most one target pub info for a document, and if there
						//isn't, then it doesn't matter, because all other queries use the results from the
						//first row anyway.
						TargetPub.Entity targetPubInfo = null;
						if (pubInfos.Count > 0)
							targetPubInfo = pubInfos[0];


						//cases for Invited Author Response Due Date display:
						// 1. override privileges, no default, no user input				-> textbox value = empty, shown text = calendar + "(mm/dd/yyyy)"
						// 2. no override privileges, no default, no user input				-> hidden value = empty, shown text = "No Date Set"
						// 3. override privileges, default, no user input					-> textbox value = default, shown text = calendar + "(mm/dd/yyyy)"
						// 4. no override privileges, default, no user input				-> hidden value = default (formatted)

						// 5. override privileges, default/no default, user input			-> textbox value = user input, shown text = calendar + "(mm/dd/yyyy)"
						// 6. no override privileges, default/no default, user input		-> hidden value = "user input", shown text = user input, no instr. text

						//user input trumps four initial cases
						//if there's some user input or default values were already calculated, just use that
						if (_xmlManager.ResponseDueDates.ContainsKey(curLetter.EventLetterID))
						{
							controlText = _xmlManager.ResponseDueDates[curLetter.EventLetterID];
						}
						//otherwise, we have to calculate default, or just leave it as ""
						else if (targetPubInfo != null && targetPubInfo.InvitationDue != null && targetPubInfo.InvitationDue > 0)
						{
							DateTime responseDueDate = DateTime.Now;

							int invitationDue = (int)targetPubInfo.InvitationDue;
							if (JournalConfiguration.UseWorkingDays)
								responseDueDate = UtilFunctions.AddWorkingDays(DateTime.Now, invitationDue);
							else
								responseDueDate = responseDueDate.AddDays(invitationDue);

							controlText = responseDueDate.ToString("d", DateTimeFormatInfo.InvariantInfo);
						}
						//no user input, no default
						else
						{
							controlText = "";
						}

						//determine what to display for instructional text
						showCalendar = _roleManager.CanOverrideAuthorInvitedSubDueDates;
						if (showCalendar)
						{
                            instructionalControl.ResourceID = "Common.Calendar.LabelDateFormat";
						}
						else
						{
							if (controlText == "")
							{
                                instructionalControl.ResourceID = "Common.Text.NoDateSet";
							}
							else
							{
								//parse the control text into a date form, then format it. At this point, we know it's a valid date.
								DateTime responseDueDate = DateTime.Parse(controlText);
							    instructionalControl.ResourceID = "";   // clear the ResourceID so the text property is functional
                                instructionalControl.Text = AriesUtil.FormatDateUsingSQLFormatCode(responseDueDate, DateFormat);
							}
						}
						
                        tCell = generateDataCell(controlName, controlText, instructionalControl, showCalendar);
						

						tRow.Cells.Add(tCell);

						//cases for Author Submission Due/+Date display:
						//date display mode
						// 1. override privileges, no default, no user input				-> textbox value = empty, shown text = calendar + "(mm/dd/yyyy)"
						// 2. no override privileges, no default, no user input				-> hidden value = empty, shown text = "No Date Set"
						// 3. override privileges, default, no user input					-> textbox value = default, shown text = calendar + "(mm/dd/yyyy)"
						// 4. no override privileges, default, no user input				-> hidden value = default (formatted)

						// 5. override privileges, no default/default, user input			-> textbox value = user input, shown text = calendar + "(mm/dd/yyyy)"
						// 6. no override privileges, no default/default, user input		-> hidden value = "user input", shown text = user input, no instr. text

						//numeric display mode
						// 1a. override privileges, no default, no user input				-> textbox value = 0, shown text = "Days After Author Accepts"
						// 2a. no override privileges, no default, no user input			-> hidden value = 0, shown text = 0 + "Days After Author Accepts"
						// 3a. override privileges, default, no user input					-> textbox value = default, shown text = DEF + "Days After Author Accepts"
						// 4a. no override privileges, default, no user input				-> hidden value = default, shown text = DEF + "Days After Author Accepts"

						// 5a. override privileges, no default/default, user input			-> textbox value = user input, shown text = UI + "Days After Author Accepts"
						// 6a. no override privileges, no default/default, user input		-> hidden value = "user input", shown text = UI + "Days After Author Accepts"

						//
						//insert "Author Submission Due/Date" label or text box
						//if we're in days mode. we're displaying an int
                        if (_authorSubDueDateType == AuthorSubDueDateType.NumDaysAfterAuthorAccepts)
						{
							controlName = string.Format("txtDaysToSubmit{0}", curLetter.EventLetterID);

							//if the target pub info data exists, it's the default
							if (targetPubInfo != null && targetPubInfo.SubmissionDue != null && targetPubInfo.SubmissionDue > 0)
							{
								controlText = targetPubInfo.SubmissionDue.ToString();
							}
							//otherwise, just an empty string is fine.
							else
							{
								controlText = "";
							}

							//user entered data trumps target pub info data and default
							//attempt to retrieve a user entered value
							if (_xmlManager.DaysToSubmit.ContainsKey(curLetter.EventLetterID))
							{
								controlText = _xmlManager.DaysToSubmit[(int)curLetter.EventLetterID];
							}

                            instructionalControl.ResourceID = "Common.Text.DaysAfterAuthorAccepts";

						    string numDays = "";
                            //if there is going to be a textbox don't insert the number of days.
                            if (_roleManager.CanOverrideAuthorInvitedSubDueDates)
                            {
                                numDays = controlText;
                            }

                            instructionalControl.ReplacementValues.Add(numDays);
							showCalendar = false;														
						}
						// we're displaying a date
						else if (_authorSubDueDateType == AuthorSubDueDateType.NumDaysPriorToSubmission)
						{
							controlName = string.Format("txtSubmissionDueDate{0}", curLetter.EventLetterID);
							
							//user input trumps all other cases
							//having a hidden variable that's not user-modifiable counts as well
							if (_xmlManager.SubmissionDueDates.ContainsKey(curLetter.EventLetterID))
							{
								controlText = _xmlManager.SubmissionDueDates[curLetter.EventLetterID];
							}
							//otherwise, we have to calculate default, or just leave it as ""
							//here, default is dependent on the target pub date, which may not exist
							else if (targetPubInfo != null && 
									targetPubInfo.TargetPublicationDate != null &&
									targetPubInfo.SubmissionDue != null &&
									targetPubInfo.SubmissionDue > 0)
							{
								DateTime subDueDate = (DateTime) targetPubInfo.TargetPublicationDate;

								//number of days _prior_
								if (JournalConfiguration.UseWorkingDays)
									subDueDate = UtilFunctions.AddWorkingDays(subDueDate, - ((int) targetPubInfo.SubmissionDue));
								else
									subDueDate = subDueDate.AddDays(- ((int)targetPubInfo.SubmissionDue));

								controlText = subDueDate.ToString("d", DateTimeFormatInfo.InvariantInfo);
							}
							//no user input, no default
							else
							{
								controlText = "";
							}

							// 2012-06-11 - swinter - tt# 23793/23770
							// use a new control instance after it's been assigned to a cell
							// so the next time the same instance isn't accidentally re-used.
							instructionalControl = new TranslationLiteral();

							//determine what to display for instructional text
							showCalendar = _roleManager.CanOverrideAuthorInvitedSubDueDates;
							if (showCalendar)
							{
                                instructionalControl.ResourceID = "Common.Calendar.LabelDateFormat";
							}
							else
							{
								if (controlText == "")
								{
                                    instructionalControl.ResourceID = "Common.Text.NoDateSet";
								}
								else
								{
									//parse the control text into a date form, then format it. At this point, we know it's a valid date.
									DateTime subDueDate = DateTime.Parse(controlText);
								    instructionalControl.ResourceID = "";   // clear resourceid so that the text property is used
                                    instructionalControl.Text = AriesUtil.FormatDateUsingSQLFormatCode(subDueDate, DateFormat);
								}
							}
						}

                        tCell = generateDataCell(controlName, controlText, instructionalControl, showCalendar);
						tRow.Cells.Add(tCell);
                        
					}

					//checkbox controlling whether to invite the author/send the letter
					if (showDoNotUseColumn)
					{
						tCell = new TableCell();

						CheckBox doNotInviteBox = new CheckBox();
						doNotInviteBox.ID = string.Format("doNotInviteCheckBox{0}", curLetter.EventLetterID);
						doNotInviteBox.Checked = !curLetter.SendLetter;
						doNotInviteBox.InputAttributes.Add("value", curLetter.EventLetterID.ToString());

						tCell.Controls.Add(doNotInviteBox);
						tRow.Cells.Add(tCell);
					}

					//put the row in the correct table
					if (authorRow)
						tblInvitedAuthors.Rows.Add(tRow);
					else
						tblOtherRecipients.Rows.Add(tRow);
				}
			}
		}

	    /// <summary>
		/// Generates a text input control, its instructions, and the validator for it.
		/// </summary>
		/// <param name="controlName">The control's id.</param>
		/// <param name="controlValue">The initial value of the control.</param>
        /// <param name="instructionalControl">The control for the instructional text shown.</param>
		/// <param name="showCalendar">Whether or not to show a calendar link.</param>
		/// Identifies control in a user-friendly way to show in the error message in case of invalid user input.
		/// </param>
        protected TableCell generateDataCell(string controlName, string controlValue, 
			TranslationLiteral instructionalControl, 
			bool showCalendar)
		{
			//insert "Author Response Due Date" label or textbox
			TableCell tCell = new TableCell();
	    	tCell.HorizontalAlign = HorizontalAlign.Left;
			
			//Spec 7.0-67	TimH	20090217
			//We need a line break control
			Literal litLineBreak = new Literal();
	    	litLineBreak.Text = "<br/>";

			//if editor has appropriate permissions it's a textbox
			if (_roleManager.CanOverrideAuthorInvitedSubDueDates)
			{
				TextBox inputControl = new TextBox();
				inputControl.ID = controlName;
				inputControl.Text = controlValue;
				tCell.Controls.Add(inputControl);
			
				//things are done a little differently if this is a date field
				if (showCalendar)
				{
					inputControl.CssClass = "em-datepicker";	// #25952 Alex 20131002 - apply datepicker
				}

				//Spec 7.0-67	TimH	20090217
				//Wrap the Calendar Control and Date Format indicator.
				tCell.Controls.Add(litLineBreak);
			}
			//otherwise, it's just a label
			else
			{
				//add the hidden control, we still need to pass data along potentially.
				HiddenField controlHidden = new HiddenField();
				controlHidden.ID = controlName;
				controlHidden.Value = controlValue;
				tCell.Controls.Add(controlHidden);
			}
			tCell.Controls.Add(instructionalControl);

			return tCell;
		}

	    /// <summary>
		/// Event handler for the submit button click.
		///	Checks if the user changed any of the letters in the drop down boxes
		///	and applies the changes to the Event Letter Manager.
		/// </summary>
		protected void StoreAuthorInvitationInfo()
		{
			Dictionary<int, string> responseDueDates = new Dictionary<int, string>();
			Dictionary<int, string> subDueDates = new Dictionary<int, string>();
			Dictionary<int, string> daysToSubmit = new Dictionary<int, string>();
			Dictionary<int, string> invitationNotes = new Dictionary<int, string>();

			//for each event letter
			foreach (EventLetterEntity letter in _ELM.EventLetters)
			{
				//skip this event letter if we're not dealing with an author letter.
				if (letter.RoleFamilyID != PeopleObjects.Person.RoleFamilyType.Author)
					continue;

				string eventLetterID = letter.EventLetterID.ToString();
				//get the Response Due Date control
				string controlName = String.Format("txtResponseDueDate{0}", eventLetterID);
				string controlValue = Request[controlName];

				//add it to a dictionary
				responseDueDates[letter.EventLetterID] = controlValue ?? string.Empty;

				//get the Submission Due Date control
				controlName = String.Format("txtSubmissionDueDate{0}", eventLetterID);
				controlValue = Request[controlName];

				//if it exists, add it to a dictionary
				subDueDates[letter.EventLetterID] = controlValue ?? string.Empty;

				//get the Days To Submit control
				controlName = String.Format("txtDaysToSubmit{0}", eventLetterID);
				controlValue = Request[controlName];
				
				daysToSubmit[letter.EventLetterID] = controlValue ?? string.Empty;

				//get the Invitation Note To Author control
				controlName = String.Format("txtInvitationNotes{0}", eventLetterID);
				controlValue = Request[controlName];
				invitationNotes[letter.EventLetterID] = controlValue ?? string.Empty;
			}

			_xmlManager = new InvitedAuthorsXMLManager(responseDueDates, subDueDates, daysToSubmit, invitationNotes);
			CurrentSession.CurrentInviteAuthorsDataXML = _xmlManager.AuthorsXmlDocument.OuterXml;
		}

	    /// <summary>
		/// Generates the table cell containing the author name
		/// </summary>
		/// <param name="curLetter">Event Letter object used to generate this cell.</param>
		/// <param name="authorRow">Whether it's an author or an editor cell.</param>
		/// <returns>The generated table cell.</returns>
		protected TableCell generateAuthorNameCell(EventLetterEntity curLetter, bool authorRow)
		{
			TableCell tCell = new TableCell();

			int peopleID = curLetter.PeopleID.Value;
			
			//get the full name of this particular recipient
			String fullName = getFullName(peopleID);
			
			string isLetterModifiedText = "<br/>";
			if (curLetter.IsLetterModified)
				isLetterModifiedText = "&nbsp;*<br/>";

			//link to personal info and unavailable dates if it's an author
			if (authorRow)
			{
				//if current user has "search people" permission
				if (_roleManager.CanEditOtherPeoplesInfo)
				{
					HyperLink peopleInfoLink = new HyperLink();
					peopleInfoLink.ID = string.Format("nameLink{0}", curLetter.EventLetterID);
					peopleInfoLink.NavigateUrl = string.Format("javascript:showInfo({0}, {1}, '')", peopleID, _managedDoc.DocumentID);
					peopleInfoLink.Text = fullName;

					tCell.Controls.Add(peopleInfoLink);

					Literal letterMod = new Literal();
					letterMod.ID = string.Format("letterModLiteral{0}", curLetter.EventLetterID);
					letterMod.Text = isLetterModifiedText;
					tCell.Controls.Add(letterMod);
				}
				else
				{
					Literal peopleInfo = new Literal();
					peopleInfo.ID = string.Format("nameLiteral{0}", curLetter.EventLetterID);
					peopleInfo.Text = fullName + isLetterModifiedText;
					tCell.Controls.Add(peopleInfo);
				}

				//display unavailable link if this letter's recipient is unavailable
				if (isUnavailable(peopleID))
				{
                    TranslationHyperLink unavailableLink = new TranslationHyperLink();
					unavailableLink.ID = string.Format("unavailableLink{0}", curLetter.EventLetterID);
					unavailableLink.NavigateUrl = string.Format("javascript:popupUnavailableReason({0})", peopleID);
                    unavailableLink.ResourceID = "Common.Text.Unavailable";
					tCell.Controls.Add(unavailableLink);
				}
			}
			// name and role if not an author
			else
			{
                TranslationLiteral peopleInfo = new TranslationLiteral();
				peopleInfo.ID = string.Format("otherRecipientNameLiteral{0}", curLetter.EventLetterID);
			    peopleInfo.ResourceID = "Common.Text.OtherReceipientName";
                peopleInfo.ReplacementValues.Add(fullName);
                peopleInfo.ReplacementValues.Add(curLetter.RoleName);
                peopleInfo.ReplacementValues.Add(isLetterModifiedText);
				tCell.Controls.Add(peopleInfo);
			}

            // To avoid guesswork in the client JavaScript
            // which tag to use let us store author name in a hidden field.
            HiddenField authorNameHidden = new HiddenField();
	        authorNameHidden.Value = fullName;
            tCell.Controls.Add(authorNameHidden);

			return tCell;
		}

	    /// <summary>
		/// Loads the target publication info into the given table.
		/// </summary>
		/// <param name="targetTable">The table for which to generate text.</param>
		protected void generateTargetPubInfo(Table targetTable)
		{
			targetTable.Rows.Clear();
			TableRow tRow = new TableRow();
			TableCell tCell = new TableCell();

			//the actual target pub info
            TranslationLiteral targetPubText = new TranslationLiteral();
			SubmissionProd.Entity subProdEntity = MapperManager.SubmissionProductionInfoMapper.FindByDocID(_managedDoc.DocumentID);

			//if there's no target publication info, then it's just going to be 'unspecified'
            string pubDate = ResourceLoader.LoadUnformattedResource("Common.Text.Unspecified");
            string pubVolume = pubDate;
            string pubIssue = pubDate;

			if (subProdEntity != null)
			{
				if (subProdEntity.TargetPubDate != null)
				{
					pubDate = AriesUtil.FormatDateUsingSQLFormatCode(subProdEntity.TargetPubDate, DateFormat);
				}
				if (subProdEntity.TargetPubVolume != null && subProdEntity.TargetPubVolume.Trim() != "")
				{
					pubVolume = subProdEntity.TargetPubVolume;
				}
				if (subProdEntity.TargetPubIssue != null && subProdEntity.TargetPubIssue.Trim() != "")
				{
					pubIssue = subProdEntity.TargetPubIssue;
				}

                // We need hidden field with the value of "Submission Target Publication Date"
                // for comparison with other dates in the client JavaScript.
                ClientScript.RegisterHiddenField("TargetPubDate",
                    (subProdEntity.TargetPubDate.HasValue ? 
                    subProdEntity.TargetPubDate.Value.ToString("d", DateTimeFormatInfo.InvariantInfo) : 
                    string.Empty));

			}


	        targetPubText.ResourceID = "Common.Text.TargetPublicationInformation";
	        targetPubText.ReplacementValues.Add(pubDate);
	        targetPubText.ReplacementValues.Add(pubVolume);
	        targetPubText.ReplacementValues.Add(pubIssue);

			tCell.Controls.Add(targetPubText);
			tRow.Cells.Add(tCell);
			targetTable.Rows.Add(tRow);
            
		}

	    #endregion

	    #region Private Methods

	    /// <summary>
	    /// Generates an xml row element containing a list box representation.
	    /// Schema:
	    /// RowElement elementType="ListElement"
	    ///   ListElement selected="true|[nothing]"
	    ///		text/
	    ///		value/
	    /// /RowElement
	    /// </summary>
	    /// <param name="id">The element's id.</param>
	    /// <param name="letters">The lettercollection to turn into an XML list element.</param>
	    /// <param name="selectedItemID">Which element is selected</param>
	    /// <returns>An xml "RowElement"</returns>
	       /// <remarks>
        /// -------------
        /// Spec 12.0-10 20140811 GBS 
        /// Added element called hiddenElement, set to letter.hidden.
        /// </remarks>
        private XmlElement generateXmlListElement(string id, LetterCollection letters, int selectedItemID)
	    {
	        XmlElement cellElement = _pageXml.CreateElement("RowElement");

	        XmlAttribute cellTypeAttribute = _pageXml.CreateAttribute("elementType");
	        cellTypeAttribute.Value = "ListElement";
	        cellElement.Attributes.Append(cellTypeAttribute);
			
	        //generate the name/id of the listbox
	        XmlElement idElement = _pageXml.CreateElement("id");
	        idElement.AppendChild(_pageXml.CreateTextNode(id));
	        cellElement.AppendChild(idElement);

	        foreach (LetterEntity letter in letters)
	        {
	            XmlElement letterElement = _pageXml.CreateElement("ListElementItem");

	            //if it's the selected letter, represent that fact
	            if (letter.Identity== selectedItemID)
	            {
	                XmlAttribute selectedAttribute = _pageXml.CreateAttribute("selected");
	                selectedAttribute.Value = "true";
	                letterElement.Attributes.Append(selectedAttribute);
	            }

	            //the text is the letter purpose, in this case
	            XmlElement textElement = _pageXml.CreateElement("Text");
	            textElement.AppendChild(_pageXml.CreateTextNode(letter.Purpose));
	            letterElement.AppendChild(textElement);

	            //the value is the letter id
	            XmlElement valueElement = _pageXml.CreateElement("Value");
	            valueElement.AppendChild(_pageXml.CreateTextNode(letter.IdentityValue.ToString()));
	            letterElement.AppendChild(valueElement);
            
                //the value is if the letter is hidden
                XmlElement hiddenElement = _pageXml.CreateElement("Hidden");
                hiddenElement.AppendChild(_pageXml.CreateTextNode(letter.Hidden.ToString()));
                letterElement.AppendChild(hiddenElement);
	        
                cellElement.AppendChild(letterElement);
	        }

	        return cellElement;
	    }

	    /// <summary>
	    /// Loads the hidden fields on the page from the request object.
	    /// </summary>
	    private void InitializeHiddenFields(bool useRequestVariables)
	    {
	        hdnDocumentID.ID = "docid";
	        Form.Controls.Add(hdnDocumentID);

	        hdnEventID.ID = "eventID";
	        Form.Controls.Add(hdnEventID);

	        hdnRevision.ID = "rev";
	        Form.Controls.Add(hdnRevision);

	        hdnAuthorSearchMode.ID = "authorSearchMode";
	        Form.Controls.Add(hdnAuthorSearchMode);

	        hdnSelectedAuthors.ID = "selectedAuthors";
	        Form.Controls.Add(hdnSelectedAuthors);

	        hdnLetterID.ID = "letterID";
	        Form.Controls.Add(hdnLetterID);

	        hdnEventLetterIDs.ID = "eventLetterIDs";
	        Form.Controls.Add(hdnEventLetterIDs);

	        hdnAuthorInvitationIDs.ID = "authorInvitationIDs";
	        Form.Controls.Add(hdnAuthorInvitationIDs);

	        hdnWorkflowField.ID = "hdnWorkflow";
	        Form.Controls.Add(hdnWorkflowField);

            // 13.0-18 20151028 JGG
            // change to capture authorSearchMode at InitializeBaseObjects
            // so, no matter of the useRequestVariables passed in just
            // populate the hidden field from the initial capture
	        hdnAuthorSearchMode.Value = _authorSearchMode;
            
	        //load the values, from request objects or session variables
	        if (useRequestVariables)
	        {
	            hdnDocumentID.Value = Request["docid"];
	            hdnRevision.Value = Request["rev"];
	            hdnSelectedAuthors.Value = Request["selectedAuthors"];
	            hdnEventID.Value = Request["eventID"];
	            hdnAuthorInvitationIDs.Value = Request["authorInvitationIDs"];
	        }
	        else
	        {
	            hdnDocumentID.Value = CurrentSession.DocumentID.ToString();
	            hdnRevision.Value = CurrentSession.Revision.ToString();

	            hdnEventID.Value = _pageXml.SelectSingleNode("/PeopleSearchXml/eventID").InnerText;
	            hdnAuthorInvitationIDs.Value = _pageXml.SelectSingleNode("/PeopleSearchXml/authorInvitationIDs").InnerText;

	            //Please notice that selectedAuthors doesn't need to be set if we're here, because it's already been stored in the
	            //peopleSearchXML session variable.
	        }

	        /*
            * Hidden fields for client JavaScript only. 
            * There is no need to keep them as protected or private class variables.
            */

	        // Generate a hidden field to pass the Editor permissions: "CanOverrideAuthorInvitedSubDueDates"
	        // to a client JavaScript
	        ClientScript.RegisterHiddenField("CanOverrideAuthorInvitedSubDueDates", 
	                                         (_roleManager.CanOverrideAuthorInvitedSubDueDates ? "1" : "0"));
	    }

	    /// <summary>
	    /// Renders an XML Element that represents a drop-down list into a list object.
	    /// </summary>
	    /// <param name="cellElement">The element to render.</param>
	    /// <returns>The rendered DropDownList object</returns>
	    /// <remarks>
        /// -------------
        /// Spec 12.0-10 20140811 GBS 
        /// if hidden and not selected do not include.
        /// </remarks>
        private static DropDownList renderXmlListElement(XmlElement cellElement)
	    {
	        DropDownList ddl = new DropDownList();
	        ddl.ID = cellElement.SelectSingleNode("id").InnerText;

	        //parse the 'listElement' elements
	        foreach (XmlElement e in cellElement.SelectNodes("ListElementItem"))
            {
                XmlNode xmlHidden = e.SelectSingleNode("Hidden");
                if (e.Attributes["selected"] == null && xmlHidden.InnerText == "True")
                {
                    continue;
                }
	            ListItem li = new ListItem(e.SelectSingleNode("Text").InnerText, e.SelectSingleNode("Value").InnerText);
	            li.Selected = (e.Attributes["selected"] != null);
	            ddl.Items.Add(li);
	        }

	        return ddl;
	    }

	    /// <summary>
	    /// Stores any variables that need to be preserved when the user leaves the page
	    /// <param name="authorSearchMode">value passed in via query string</param>
	    /// </summary>
	    /// <example>
	    /// 	Example of what the XML looks like
	    /// 	<PeopleSearchXml>
	    ///		<SearchParameters> [contains search parameters from search results page] </SearchParameters>
	    ///
	    ///		-- List of invited authors and how many letters to send to each one
	    ///		&ltInvitedAuthorsXml&gt
	    ///			&ltauthor&gt
	    ///				&ltid&gt293&lt/id&gt
	    ///				&ltnumLetters&gt1&lt/numLetters&gt
	    ///			&lt/author&gt
	    ///		&lt/InvitedAuthorsXml&gt
	    ///
	    ///		-- number of days author has to respond, from the search results page
	    ///		&ltNumDaysToRespond&gt0&lt/NumDaysToRespond&gt
	    ///
	    ///		-- when the author has to get this done by, from the search results page
	    ///		&ltSubDueDate&gt11/03/1981&lt/SubDueDate&gt
	    ///
	    ///		-- which search results page we came from
	    ///		&ltAuthorSearchMode&gt1&lt/AuthorSearchMode>
	    ///
	    /// </example>
	    private void StoreSessionVariables()
	    {
	        //Example of what the XML looks like
	        // 	<PeopleSearchXml>
	        //		<SearchParameters> [contains search parameters from search results page] </SearchParameters>
	        //
	        //		-- List of invited authors and how many letters to send to each one
	        //		<InvitedAuthorsXml>
	        //			<author>
	        //				<id>293</id>
	        //				<numLetters>1</numLetters>
	        //			</author>
	        //		</InvitedAuthorsXml>
	        //
	        //		-- number of days author has to respond, from the search results page
	        //		<NumDaysToRespond>0</NumDaysToRespond>
	        //
	        //		-- when the author has to get this done by, from the search results page
	        //		<SubDueDate>11/03/1981</SubDueDate>
	        //
	        //		-- which search results page we came from
	        //		<AuthorSearchMode>1</AuthorSearchMode>
	        //	</PeopleSearchXml>


	        //special case: preserve the 'search variables' xml
	        //loop through all the child nodes and delete them, unless they're the SearchParameters node
            for (int x = 0; x < _pageXml.FirstChild.ChildNodes.Count; x++)
            {
                if (_pageXml.FirstChild.ChildNodes[x].Name != "SearchParameters")
                {
                    _pageXml.FirstChild.RemoveChild(_pageXml.FirstChild.ChildNodes[x]);
                    x--;
                }
            }

            // 13.0-18 20151027 JGG
            // change is that request could be coming from UploadedAuthorsSearchResults.aspx
            // in this case, the authorSearchMode from the query string will equal new value from
            // Constants.AUTHOR_SEARCH_MODE_UPLOAD_AUTHOR_LIST.
            // EventID by default, will be InviteAuthorsForProposal
            // The UploadedAuthorsSearchResults.aspx page will already have populated CurrentSession.CurrentPeopleSearchXML
            // with <InvitedAuthorsXml>, so, in this case, no need to recreate in _pageXml.

            XmlElement authorSearchModeNode = _pageXml.CreateElement("AuthorSearchMode");
            XmlElement eventIDNode = _pageXml.CreateElement("eventID");
            
	        if (Convert.ToInt32(_authorSearchMode) == Constants.AUTHOR_SEARCH_MODE_UPLOAD_AUTHOR_LIST)
	        {
	            eventIDNode.InnerXml = EventType.InviteAuthorsForProposal.ToString();
	        }
	        else
	        {
	            XmlElement newAuthorsNode = _pageXml.CreateElement("InvitedAuthorsXml");
	            newAuthorsNode.InnerXml = Request["selectedAuthors"];
	            _pageXml.FirstChild.AppendChild(newAuthorsNode);
	            
	            eventIDNode.InnerXml = (Request["eventID"] ?? "");
	        }

	        authorSearchModeNode.InnerXml = _authorSearchMode;
	        _pageXml.FirstChild.AppendChild(authorSearchModeNode); 
            
            _pageXml.FirstChild.AppendChild(eventIDNode);

	        XmlElement authorInvitationIDsNode = _pageXml.CreateElement("authorInvitationIDs");
	        authorInvitationIDsNode.InnerXml = (Request["authorInvitationIDs"] ?? "");
	        _pageXml.FirstChild.AppendChild(authorInvitationIDsNode);

	        CurrentSession.CurrentPeopleSearchXML = _pageXml.OuterXml;
        }
        
        /// <summary>
        /// Retrieves the Invitation Notes To Author string
        /// for a specified EventLetter object, if there is
        /// an existing corresponding INVITED_AUTHORS record
		/// and the INVITED_AUTHOR_NOTES field is populated.
        /// </summary>
		/// <param name="letter">EventLetter object</param>
		/// <returns>Invitation Notes To Author string
		/// for a specified EventLetter object</returns>
        private string GetAuthorInvitationNotes(EventLetterEntity letter)
        {
        	string sReturn = "";
        	AuthorInvitation.Entity invite =
        		_authorInvitationManager.GetInvitedAuthorForDocIDAndEventLetterID((int)letter.DocumentID, letter.EventLetterID);
        	
        	if(invite != null && ! String.IsNullOrEmpty(invite.AuthorInvitationNotes))
        	{
        		return invite.AuthorInvitationNotes;
        	}

            if (_peopleNotes != null)
            {
                // get the index of the first found note key value pair so we can remove it if found
                int foundNote =
                    _peopleNotes.Select((value, index) => new {value, index = index + 1})
                                .Where(n => n.value.Key == (letter.PeopleID ?? 0))
                                .Select(n => n.index)
                                .FirstOrDefault() - 1;
                if (foundNote > -1)
                {
                    var note = _peopleNotes[foundNote];
                    _peopleNotes.RemoveAt(foundNote);
                    return note.Value;
                }
            }

        	return "";
        }


		/// <summary>
		/// Generate the TableCell control that nests a Table control containing
		/// all possible Controls/Form elements for the "Letter / Invitation Notes To Author"
		/// column.
		/// </summary>
		/// <param name="eventLetter">EventLetter object</param>
		/// <param name="isAuthorRow">Indicates whether this </param>
		/// <param name="includeInsertSpecialCharsLink">Indicates whether we'er including the
		/// Insert Special Characters hyper Link</param>
		/// <param name="hasCustomizeColumn"></param>
		/// <returns></returns>
		private TableCell GenerateLettersTableCell(EventLetterEntity eventLetter, bool isAuthorRow, bool includeInsertSpecialCharsLink, bool hasCustomizeColumn)
		{
			TableCell rCell = new TableCell();
			rCell.Wrap = false;
			Table nestedTable = new Table();
			nestedTable.GridLines = GridLines.None;
			nestedTable.Width = Unit.Percentage(100.00);
			
			// Only use the nested table if we're displaying the
			// "Invitation Notes To Author" TextBox and associated other elements.
			if(this.HasAuthorInvitationNotesTextBox)
			{
				rCell.Controls.Add(nestedTable);	
			}

			TableRow rowLetters = new TableRow();

			// First add the Letter Control -
			// either a DropDownList of configured Letters for
			// inviting - or a read only Label displaying the the default letter.	
			if (isAuthorRow)
			{
				DropDownList ddlLetters = renderXmlListElement(generateXmlListElement(string.Format("letterList{0}", eventLetter.EventLetterID)
															, _ELM.LetterFamilyList
															, (int)eventLetter.LetterID));
				
				// Again, only use the nested table if we're displaying the
				// "Invitation Notes To Author" TextBox and associated other elements.
				if (this.HasAuthorInvitationNotesTextBox)
				{
					nestedTable.Rows.Add(rowLetters);
					TableCell cellLetters = new TableCell();
					cellLetters.VerticalAlign = VerticalAlign.Top;
					cellLetters.HorizontalAlign = HorizontalAlign.Left;
					cellLetters.BorderStyle = BorderStyle.None;
					rowLetters.Cells.Add(cellLetters);
					cellLetters.Controls.Add(ddlLetters);	
				}
				else
				{
					rCell.Controls.Add(ddlLetters);
				}
			}
			else
			{
				HiddenField letterID = new HiddenField();
				letterID.ID = string.Format("letterID{0}", eventLetter.EventLetterID);
				letterID.Value = eventLetter.LetterID.ToString();
				rCell.Controls.Add(letterID);

				Literal letterLiteral = new Literal();
				letterLiteral.ID = string.Format("letterLiteral{0}", eventLetter.EventLetterID);
				letterLiteral.Text = eventLetter.Purpose;
				rCell.Controls.Add(letterLiteral);
			}

			// This means that the Customize Button is to be replaced
			// directly to the right of the Letters DropDownList
			// in its own cell in the nested table and NOT in its own column
			if (!hasCustomizeColumn && isAuthorRow)
			{
                TranslationLinkButton customizeButton = new TranslationLinkButton();
				customizeButton.ID = string.Format("customizeLinkButton{0}", eventLetter.EventLetterID);
				customizeButton.CommandName = eventLetter.EventLetterID.ToString();
				customizeButton.Command += customizeButtonClick;
                customizeButton.ResourceID = "Common.Navigation.Buttons.Customize";
				
				if (this.HasAuthorInvitationNotesTextBox)
				{
					TableCell cellCustomizeLink = new TableCell();
					cellCustomizeLink.BorderStyle = BorderStyle.None;
					cellCustomizeLink.VerticalAlign = VerticalAlign.Top;
					rowLetters.Cells.Add(cellCustomizeLink);

					cellCustomizeLink.Controls.Add(customizeButton);
				}
				else
				{
					Literal litSpacer = new Literal();
					litSpacer.Text = "&nbsp;";
					rCell.Controls.Add(litSpacer);
					rCell.Controls.Add(customizeButton);
				}
			}

			// Here we add the row/cells for the "Insert Special Characters" hyperlink
			// and the "Author Invitation Notes" TextBox, if conditions are met.
			if (isAuthorRow && this.HasAuthorInvitationNotesTextBox)
			{
				
				TableRow rowSpecialCharsLink = new TableRow();
				nestedTable.Rows.Add(rowSpecialCharsLink);
				TableCell cellSpecialCharsLink = new TableCell();
				cellSpecialCharsLink.BorderStyle = BorderStyle.None;
				cellSpecialCharsLink.HorizontalAlign = HorizontalAlign.Left;

				cellSpecialCharsLink.ColumnSpan = (hasCustomizeColumn ? 1 : 2);

                //Create Insert Special Character Link
                TranslationHyperLink lnkSpecialChars = new TranslationHyperLink();
                lnkSpecialChars.ResourceID = "Common.Links.InsertSpecialCharacters";
			    lnkSpecialChars.NavigateUrl = "javascript:popup_specialChars()";

                //Add link to table cell controls collection
                cellSpecialCharsLink.Controls.Add(lnkSpecialChars);
                rowSpecialCharsLink.Cells.Add(cellSpecialCharsLink);

				TableRow rowInvitationNotes = new TableRow();
				nestedTable.Rows.Add(rowInvitationNotes);

				TableCell cellInvitationNotes = new TableCell();
				cellInvitationNotes.BorderStyle = BorderStyle.None;
				cellInvitationNotes.HorizontalAlign = HorizontalAlign.Left;
				cellInvitationNotes.ColumnSpan = (hasCustomizeColumn ? 1 : 2);
				rowInvitationNotes.Cells.Add(cellInvitationNotes);

				TextBox txtInvitationNotes = new TextBox();
				txtInvitationNotes.Attributes.Add("onFocus", "lastFocus=this");
				txtInvitationNotes.Attributes.Add("onSelect", "storeCaret(this)");
				txtInvitationNotes.Attributes.Add("onClick", "storeCaret(this)");
				txtInvitationNotes.Attributes.Add("onKeyUp", "storeCaret(this)");
				txtInvitationNotes.ID = string.Format("txtInvitationNotes{0}", eventLetter.EventLetterID);

				// User Input stored in the InvitedAuthorsXMLManager.InvitationNotes Dictionary
				// trumps retrieving previously saved values from the database
				if (_xmlManager.InvitationNotes.ContainsKey(eventLetter.EventLetterID))
				{
					txtInvitationNotes.Text = _xmlManager.InvitationNotes[eventLetter.EventLetterID];
				}
				else
				{
					txtInvitationNotes.Text = GetAuthorInvitationNotes(eventLetter);	
				}
				
				cellInvitationNotes.Controls.Add(txtInvitationNotes);

				txtInvitationNotes.TextMode = TextBoxMode.MultiLine;
				txtInvitationNotes.Width = Unit.Percentage(100.00);
				txtInvitationNotes.Rows = 3;
			}

			return rCell;
		}
        
        #endregion Private Methods

        #endregion Methods
    }
}
