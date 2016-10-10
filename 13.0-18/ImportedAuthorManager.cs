//----------------------------------------------------------------------------------------
//	Copyright © 2015-Present Aries Systems Corporation. All Rights Reserved.
//	Copying, reverse engineering, adaptation or any other derivative use
//	prohibited.  This material is proprietary and confidential information
//	of Aries Systems Corporation.
//
//  Date Created:		20151012
//  Version Introduced:	13.0
//  Spec:   			13.0-18
//
//----------------------------------------------------------------------------------------

using System;
using System.Collections.Generic;
using System.Linq;
using PersonEntity = Aries.EditorialManager.Framework.Journal.PeopleObjects.Person.Entity;


namespace Aries.EditorialManager
{
    /// <summary>
    /// Manages potential proposal authors imported from file
    /// <remarks>
    /// </remarks>
    /// History:
    /// **********************************************************
    /// 
    /// </summary>
    public class ImportedAuthorManager
    {

        #region Private Fields

        private List<UploadedAuthorInfo> _uploadedAuthors = null;
        private List<AuthorCandidate> _processedAuthors = new List<AuthorCandidate>();
        private DatabaseMapperManager _mapper = null;
        private int _operatorID;

        #endregion


        #region Constructors

        /// <summary>
        /// Constructs new ImportedAuthorManager object which manages potential proposal authors imported from file
        /// </summary>
        /// <param name="mapper">Database Mapper Manager</param>
        /// <param name="uploadedAuthors">List of authors of type UploadedAuthorINfo</param>
        /// <param name="operatorID">Current operator id</param>
        public ImportedAuthorManager(DatabaseMapperManager mapper, List<UploadedAuthorInfo> uploadedAuthors,
                                     int operatorID)
        {
            _mapper = mapper;
            _uploadedAuthors = uploadedAuthors;
            _operatorID = operatorID;
        }

        #endregion

        #region Public Functionality

        /// <summary>
        /// Prunes uploaded authors list passed in constructor.
        /// Will try to match each given uploaded author with an existing author in the system.
        /// Will only return unique authors found - ie if upload includes same author several times, will
        /// return just one instance of AuthorCandidate for that author.
        /// Uploaded authors may have already have gone through matching process and will not be re-matched.
        /// </summary>
        /// <param name="startIndex">index in uploaded authors list at which to start return</param>
        /// <param name="endIndex">index in uploaded authors list at which to end return</param>
        /// <returns>List of AuthorCandidates or null if none were passed in at construction.</returns>
        //public List<AuthorCandidate> GetAuthorCandidates(int startIndex, int endIndex)
        //{
        //    return (_uploadedAuthors == null
        //        ? null
        //        : GetAuthorCandidates(_uploadedAuthors, startIndex, endIndex
        //            ));
        //}

        /// <summary>
        /// Prunes uploaded authors list.
        /// Will try to match each given uploaded author with an existing author in the system.
        /// Will only return unique authors found (ie if upload includes same author several times, will
        /// return just one instance of AuthorCandidate for that author.
        /// Uploaded authors may have already have gone through matching process and will not be re-matched.
        /// </summary>
        /// <param name="uploadedAuthors">list of UploadedAuthorInfo objects</param>
        /// <param name="startIndex">index in uploaded authors list at which to start return</param>
        /// <param name="endIndex">index in uploaded authors list at which to end return</param>
        /// <returns>List of AuthorCandidates</returns>
        //public List<AuthorCandidate> GetAuthorCandidates(List<UploadedAuthorInfo> uploadedAuthors, int startIndex,
        //                                                int endIndex)
        //{
            // Determining duplicates in the uploaded authors list is based on:
            //      FIRSTNAME, LASTNAME, EMAIL are matches.
            //      If there is an ORCID value, both the ORCID values match
            //      This will be held in a hash of the AuthorCandidate object.

            // Determining matches against existing EM person records is determined by:
            //      Authenticated ORCID match:
            //          If uploaded ORCID matches authenticated ORCID in EM system, records match
            //      
            //      Unauthenticated ORCID match:
            //          If uploaded ORCID matches un-authenticated ORCID in EM system
            //              must match LastName
            //              must match FirstNames
            //
            //      Primary email match:
            //          If uploaded email matches only one primary EM email, records match
            //      
            //          If email matches to more than one primary EM email
            //              must match LastName
            //              must match FirstName
            //
            //      Alternate email match:
            //          If uploaded email matches any of the alternate emails
            //              must match LastName
            //              must match FirstName
            //
            //      After all matching attempts, if more than one EM record potentially matches

            // key = hash of firstname, lastname, email, orcid
        //    var authORCIDMatches = new Dictionary<string, PersonEntity>();
        //    var unauthORCIDMatches = new Dictionary<string, PersonEntity>();
        //    var pureEmailMatches = new Dictionary<string, PersonEntity>();
        //    var emailLNFNMatches = new Dictionary<string, PersonEntity>();

        //    var orcids =
        //        (from author in uploadedAuthors where author.OrcID != null select author.OrcID).ToList<string>();
        //    var emails =
        //        (from author in uploadedAuthors where author.EmailAddress != null select author.EmailAddress)
        //            .ToList<string>();
        //    var emailsAndNames =
        //        (from author in uploadedAuthors where author.EmailAddress != null select author)
        //            .ToList<UploadedAuthorInfo>();

        //    var foundAuthOrcids = _mapper.PersonMapper.FindByPersonalIdentifiersORCIDs(orcids, true);
        //    var foundUnauthOrcids = _mapper.PersonMapper.FindByPersonalIdentifiersORCIDs(orcids, false);
        //    var foundEmailMatches = _mapper.PersonMapper.FindByEmailMatch(emails);
        //    //var foundEmailsLNFNMatches = _mapper.PersonMapper.

        //    // do the authenticated ORCID matching of passed in uploadedAuthors

        //    // do the unauthenticated ORCID matching of passed in uploadedAuthors

        //    // do the email matching of passed in uploaded authors

        //    // do the email, lastname, firstname matching of passed in uploaded authors

        //    //foreach (UploadedAuthorInfo uploadedAuthor in uploadedAuthors)
        //    //{

        //    //}

        //}

        #endregion


        #region Private Functionality



        #endregion



    }
}
