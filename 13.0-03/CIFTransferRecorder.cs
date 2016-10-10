#region COMMENT_HEADER
/*----------------------------------------------------------------------------
 * Copyright © 2015-Present Aries Systems Corporation. All Rights Reserved.
 * Copying, reverse engineering, adaptation or any other derivative use
 * prohibited.  This material is proprietary and confidential information
 * of Aries Systems Corporation.
 *
 * Date Created: 20150724
 * Version Introduced: 13.0
 * Spec #:13.0-03
 * ---------------------------------------------------------------------------*/
#endregion

using System;
using System.Data;
using System.Collections.Generic;
using System.Data.SqlClient;
using Aries.Shared.Data;
using EMFile = Aries.EditorialManager.Framework.Journal.FileObjects.FileEntity;
using Aries.EditorialManager.Aries.EditorialManager.TransferRecorder;

namespace Aries.EditorialManager.TransferRecorders
{
	/// <summary>
	/// <para>To log bytes sent/received when sending a CIF file for verification.</para>
	/// <para>Receive should be a PDF file with results of the verification.</para>
	/// <para>Uses usp_ProcessCIFFileResultRequest.</para>
	/// <para>Updates/Enters record in JOURNAL.CIF_FILE_TRAFFIC_LOG.</para>
	/// </summary>
	/// <remarks>
	/// </remarks>
	public class CIFTransferRecorder
    {
        #region FIELDS

            /// <summary>
            /// Stored Procedure Name
            /// </summary>
            protected const string _storedProcName = "usp_ProcessCIFFileResultRequest";

            /// <summary>
            /// Connection string to the journal
            /// </summary>
            private readonly string _journalConnectionString;

        #endregion 


       #region CONSTRUCTORS

            /// <summary>
		    /// Constructor for SubmissionTransferRecorderFactory. This is private to force
		    /// users of the class to use the GetRecorder method instead.
		    /// </summary>
		    private CIFTransferRecorder(string journalConnectionString)
		    {
                _journalConnectionString = journalConnectionString;
		    }
            
		#endregion

		#region METHODS
       
            /// <summary>
            /// Processes the transfer information.  Any parameter value can be null.
            /// </summary>
            /// <returns>0 if successful update.  Traffic Log ID, if new record.</returns>
            /// <param name="trafficLogID">Traffic Log ID.  Null if new record.</param>
            /// <param name="fileCatalogueId">Catalogue id of CIF file for which result file request is being logged.</param>
            /// <param name="startTime">Date/Time result request started.</param>
            /// <param name="endTime">Date/Time result request ended.</param>
            /// <param name="sentBytes">Bytes sent to CIF result url.</param>
            /// <param name="receiveBytes">Bytes received from CIF result url.</param>
            public int LogCIFResultRequest(int? trafficLogID, int? fileCatalogueId, DateTime? startTime, 
                DateTime? endTime,float? sentBytes,float? receiveBytes)
            {
                var command = new SqlCommand
                {
                    CommandType = CommandType.StoredProcedure,
                    CommandText = _storedProcName,
                };

                var idParameter = new SqlParameter
                {
                    ParameterName = "@trafficLogID",
                    DbType = DbType.Int32,
                    Direction = ParameterDirection.InputOutput,
                    Value = trafficLogID
                };

                command.Parameters.Add(idParameter);
                command.Parameters.AddWithValue("@fileCatalogueID", fileCatalogueId);
                command.Parameters.AddWithValue("@startTime", startTime);
                command.Parameters.AddWithValue("@endTime", endTime);
                command.Parameters.AddWithValue("@sentBytes", sentBytes);
                command.Parameters.AddWithValue("@receiveBytes", receiveBytes);

                SqlDbHelper.ExecuteNonQuery(_journalConnectionString, command);

                return (int?) idParameter.Value ?? 0;
            }

		#endregion
	}
}