DELETE FROM DBO.MASTER_CONFIG
WHERE CONFIG_ID = 334

INSERT INTO DBO.MASTER_CONFIG
(
	CONFIG_ID,
	DESCRIPTION,
	VALUE
)
VALUES
(
	334,
	'Display All Standard EAR Reports',
	'True'
)