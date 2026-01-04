IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Items]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Items] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [Text] NVARCHAR(500) NOT NULL,
        [CreatedAt] DATETIME2 DEFAULT GETDATE()
    )
END


