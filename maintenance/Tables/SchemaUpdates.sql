--
--	Do you like this project? Do you find it helpful? Pay it forward by hiring me as a consultant!
--  https://jason-iverson.com
--
CREATE TABLE [maintenance].[SchemaUpdates](
	[Identity] [uniqueidentifier] NOT NULL CONSTRAINT [PK_SchemaUpdates] PRIMARY KEY CLUSTERED,
	[ExecutionTimestamp] [datetime] NOT NULL CONSTRAINT [DF_SchemaUpdates_ExecutionTimestamp]  DEFAULT GetDate()	 
)

GO