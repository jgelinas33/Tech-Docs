#region COMMENT_HEADER
/*----------------------------------------------------------------------------
 * Copyright © 2015-Present Aries Systems Corporation. All Rights Reserved.
 * Copying, reverse engineering, adaptation or any other derivative use
 * prohibited.  This material is proprietary and confidential information
 * of Aries Systems Corporation.
 *
 * Date Created: 20151012
 * Version Introduced:13.0
 * Spec# 13.0-18
 * ---------------------------------------------------------------------------*/
#endregion COMMENT_HEADER

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Xml;
using System.Text;
using System.IO;
using System.Xml.Serialization;

namespace Aries.EditorialManager.Framework.Journal.PeopleObjects.Person.Database
{
    /// <summary>
    /// Query object that will search PEOPLE based on matching email, firstname and lastname
    /// and return collection of Person entities.
    /// </summary>
    public class FindByEmailsAndNamesQuery : CollectionQuery
    {
        #region FIELDS

        /// <summary>
        /// Parameters in xml format.  Use NameAndEmailObject for each parameter.
        ///		<parameters>
        ///         <parameter>
        ///             <firstname>Jean</firstname>
        ///             <lastname>Gelinas</lastname>
        ///             <email>jgelinas@ariessys.com</email>
        ///         </parameter>
        ///		</parameters>
        /// </summary>
        private string _parameters;

        #endregion 


        #region CONSTANTS

        /// <summary>
        /// SQL to load a collection of entities
        /// </summary>
        private static readonly string LOAD_COLLECTION_SQL = "usp_SelectPeopleByNamesAndEmails";

        #endregion CONSTANTS


        #region CONSTRUCTORS

		/// <summary>
		/// Initalizing constructor.
		/// </summary>
		/// <param name="parameters">
        /// Parameters in xml format.  Use NamesAndEmailsParameter object for each parameter.
        ///		<parameters>
        ///         <parameter>
        ///             <firstname>Jean</firstname>
        ///             <lastname>Gelinas</lastname>
        ///             <email>jgelinas@ariessys.com</email>
        ///         </parameter>
        ///		</parameters>
		/// </param>
        public FindByEmailsAndNamesQuery(List<NamesAndEmailsParameter> parameters)
        {
            if (parameters == null || parameters.Count == 0)
            {
                throw new Exception("parameters listing must contain data.");
            }

            using (var memoryStream = new MemoryStream())
            {
                var xmlSettings = new XmlWriterSettings();
                xmlSettings.Encoding = Encoding.UTF8;
                xmlSettings.OmitXmlDeclaration = true;
                xmlSettings.Indent = true;

                using (XmlWriter writer = XmlWriter.Create(memoryStream, xmlSettings))
                {
                    writer.WriteStartElement("parameters");
                    var xmlSerializer = new XmlSerializer(typeof(NamesAndEmailsParameter));

                    foreach (NamesAndEmailsParameter parameter in parameters)
                    {
                        xmlSerializer.Serialize(writer, parameter);
                    }

                    writer.WriteEndDocument();
                    writer.Close();
                }

                memoryStream.Close();

                _parameters = Encoding.UTF8.GetString(memoryStream.ToArray());
            }
        }

        #endregion CONSTRUCTORS


        #region METHODS


        /// <summary>
        /// Creates and returns a SQL command which will load a collection of Person Entities.
        /// </summary>
        /// <returns>An initialized SQL command object</returns>
        public override SqlCommand CreateCollectionLoadCommand()
        {
			SqlCommand command = new SqlCommand();
			command.CommandText = LOAD_COLLECTION_SQL;
			command.CommandType = CommandType.StoredProcedure;
        	command.Parameters.Add(new SqlParameter("@parameters", SqlDbType.Xml)).Value = _parameters;
			return command;
        }

        #endregion METHODS

    }
}
