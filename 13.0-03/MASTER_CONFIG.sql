IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 195 AND DESCRIPTION = 'Enable CIF Check'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			195,
			'Enable CIF Check',
			'True',
			GETDATE()
		)
	END
	
IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 196 AND DESCRIPTION = 'CIF Check Trigger - Original PDF Building By Author'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			196,
			'CIF Check Trigger - Original PDF Building By Author',
			'False',
			GETDATE()
		)
	END
	
IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 197 AND DESCRIPTION = 'CIF Check Trigger - Original PDF Building By Editor'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			197,
			'CIF Check Trigger - Original PDF Building By Editor',
			'False',
			GETDATE()
		)
	END
	
IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 198 AND DESCRIPTION = 'CIF Check Trigger - First Reviewer Invited/Assigned'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			198,
			'CIF Check Trigger - First Reviewer Invited/Assigned',
			'False',
			GETDATE()
		)
	END
	
IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 199 AND DESCRIPTION = 'CIF Check Trigger – Revised PDF Building by Author'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			199,
			'CIF Check Trigger – Revised PDF Building by Author',
			'False',
			GETDATE()
		)
	END
	
IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 200 AND DESCRIPTION = 'CIF Check Trigger – Revised PDF Building by Editor'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			200,
			'CIF Check Trigger – Revised PDF Building by Editor',
			'False',
			GETDATE()
		)
	END
	
IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 201 AND DESCRIPTION = 'CIF Check Trigger – Author Notified of Accept'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			201,
			'CIF Check Trigger – Author Notified of Accept',
			'False',
			GETDATE()
		)
	END
	
IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 202 AND DESCRIPTION = 'CIF Check Trigger – Author Notified of Revise'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			202,
			'CIF Check Trigger – Author Notified of Revise',
			'False',
			GETDATE()
		)
	END

IF NOT EXISTS (
	SELECT 1 FROM MASTER_CONFIG 
	WHERE CONFIG_ID = 203 AND DESCRIPTION = 'CIF Check Trigger – Create Submission'
)	
	BEGIN		
		INSERT INTO MASTER_CONFIG
		(
			CONFIG_ID,
			DESCRIPTION,
			VALUE,
			LAST_UPDATE
		)
		VALUES
		(
			203,
			'CIF Check Trigger – Create Submission',
			'False',
			GETDATE()
		)
	END