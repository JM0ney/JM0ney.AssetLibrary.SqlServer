
CREATE TABLE [maintenance].[SchemaUpdates](
	[Identity] [uniqueidentifier] NOT NULL CONSTRAINT [PK_SchemaUpdates] PRIMARY KEY CLUSTERED,
	[ExecutionTimestamp] [datetime] NOT NULL CONSTRAINT [DF_SchemaUpdates_ExecutionTimestamp]  DEFAULT GetDate()	 
)

GO