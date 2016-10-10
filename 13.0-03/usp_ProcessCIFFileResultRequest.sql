/*----------------------------------------------------------------------------
// Copyright © 2015-Present, Aries Systems Corporation.
// All Rights Reserved.
// Copying, reverse engineering, adaptation or any other derivative use is
// prohibited. This material is proprietary and confidential information
// of Aries Systems Corporation.
//
// Author: Jean Gelinas
// Date Created: 20150727
//
// Description: Handles record entry/update to CIF_FILE_TRAFFIC_LOG
// Added as part of SPEC 13.0-03
// History:
//
//----------------------------------------------------------------------------*/

IF EXISTS (SELECT * 
	   FROM dbo.sysobjects 
	   WHERE id = object_id(N'[usp_ProcessCIFFileResultRequest]') 
	   AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
    DROP PROCEDURE [dbo].[usp_ProcessCIFFileResultRequest]
GO

SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_ProcessCIFFileResultRequest]
	@trafficLogID		AS	BIGINT,
	@fileCatalogueID	AS	BIGINT,
	@startTime			AS	DATETIME,
	@endTime			AS	DATETIME, 
	@sentBytes			AS	FLOAT,
	@receiveBytes		AS 	FLOAT
	
AS
BEGIN
	SET NOCOUNT ON;
	

	/* Determine if a new record for "today's statistics" for a document needs to be created */
	IF NOT EXISTS(SELECT 1 FROM CIF_FILE_TRAFFIC_LOG WHERE TRAFFIC_LOG_ID = @trafficLogID)
		BEGIN
			INSERT INTO CIF_FILE_TRAFFIC_LOG
			(
				FILE_CATALOGUE_ID,
				START_TIME,
				END_TIME,
				SENT_BYTES,
				RECEIVE_BYTES
			)
			VALUES
			(
				@fileCatalogueID,
				@startTime,
				@endTime,
				@sentBytes,
				@receiveBytes
			)

			SET @trafficLogID = SCOPE_IDENTITY();
		END
	ELSE
		BEGIN
			UPDATE CIF_FILE_TRAFFIC_LOG
			SET
				START_TIME = ISNULL(@startTime,START_TIME),
				END_TIME = ISNULL(@endTime,END_TIME),
				SENT_BYTES = ISNULL(@sentBytes,SENT_BYTES),
				RECEIVE_BYTES = ISNULL(@receiveBytes,RECEIVE_BYTES)
			WHERE	
				TRAFFIC_LOG_ID = @trafficLogID
				
		END
END
GO