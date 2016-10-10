//----------------------------------------------------------------------------------------
//	Copyright 2015-Present Aries Systems Corporation. All Rights Reserved.
//	Copying, reverse engineering, adaptation or any other derivative use
//	prohibited.  This material is proprietary and confidential information
//	of Aries Systems Corporation.
//
//  Date Created: 20151012
//  Version Introduced: 13.0
//  Spec/Bug #: 13.0-18
//
//	Description: Parameter object to use in passing parameters to FindByEmailsAndNamesQuery
//----------------------------------------------------------------------------------------


using System;
using System.Xml.Serialization;

namespace Aries.EditorialManager.Framework.Journal.PeopleObjects.Person
{
    
        [XmlRoot("parameter")]
        public class NamesAndEmailsParameter
        {
            [XmlElement("firstname")]
            public string FirstName { get; set; }

            [XmlElement("lastname")]
            public string LastName { get; set; }

            [XmlElement("email")]
            public string Email { get; set; }
        }
}
