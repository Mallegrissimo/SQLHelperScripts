CREATE PROC util.InsertDefaultDimensionMember
    @DimensionName varchar(50),
    @DefaultDimensionKey INT,
    @DefaultAttributeValue NVARCHAR(7) = 'Unknown',
    @Schema varchar(50) = 'dim',
    @Database varchar(50) = 'EDW'

AS
BEGIN
SET NOCOUNT ON
   /*
    DECLARE @Dimension varchar(50) = 'Customer',
    @DefaultDimensionKey INT = -2,
    @Schema varchar(50) = 'Dim',
    @Database varchar(50) = 'EDW'
    --*/
    
    DECLARE @DefaultDimensionKeyString  NVARCHAR(3) = convert(NVARCHAR(3),@DefaultDimensionKey)
    DECLARE @qualifiedDimensionName varchar(100)
    SET @qualifiedDimensionName = @Database+ '.' + @Schema + '.' + @Dimension     

    DECLARE @columns AS TABLE
        (columnName NVARCHAR(50)
        ,dataType NVARCHAR(50)
        ,processed bit)
    
    DECLARE @SQL NVARCHAR(1000)
   SET @SQL='SELECT 
        c.COLUMN_NAME ,c.DATA_TYPE,0
        FROM ' + @Database + '.INFORMATION_SCHEMA.columns as c 
        WHERE
        c.TABLE_SCHEMA = ''' + @Schema + ''' and
        c.TABLE_NAME = ''' + @Dimension + ''' and
        c.COLUMN_NAME not like ''EtlModified%'''
    INSERT INTO @columns EXEC(@SQL)

    IF NOT EXISTS (SELECT 1 FROM @columns) raiserror('No columns not exist',16,16)

    DECLARE @keyColumn NVARCHAR(100) = @Dimension + 'Key';
    DECLARE @ValueList NVARCHAR(1000)
    DECLARE @columnList as NVARCHAR(max) = (
        SELECT CONVERT(varchar(200),'[' + columnName + '],')
        FROM @columns
        FOR XML PATH('')
    );
   SET @columnList = LEFT(@columnList, LEN(@columnList) - 1)
    
    DECLARE @columnName NVARCHAR(50),@dataType NVARCHAR(50), @tempValue NVARCHAR(50)

While (Select Count(*) From @columns Where processed = 0) > 0
Begin
    Select Top 1 @columnName = columnName, @dataType = dataType From @columns Where processed = 0
    --PRINT FormatMessage('processing  %s, type:%s', @columnName, @dataType)
   SET @tempValue =  case @dataType 
                when 'int' then @DefaultDimensionKeyString + ','   
                when 'varchar' then FormatMessage('''%s'',',@DefaultAttributeValue)  
                when 'NVARCHAR' then FormatMessage('''%s'',',@DefaultAttributeValue)
                when 'datetime' then 'GETDATE(),'
                when 'datetime2' then 'GETDATE(),'
                when 'datetimeoffset' then 'GETDATE(),' 
            end;
    --PRINT formatMessage('@tempValue:%s',@tempValue)
    set @ValueList = concat(@ValueList , @tempValue)
    --PRINT formatMessage('@@ValueList:%s',@ValueList) 
    Update @columnsSET Processed = 1 Where columnName = @columnName

End
    
   SET @ValueList = LEFT(@ValueList, LEN(@ValueList) - 1)
   

 SET @SQL= '
 SET NOCOUNT ON;
 if not exists (select 1 from ' + @qualifiedDimensionName + ' where ' + @Dimension + 'Key ' + ' = ' + @DefaultDimensionKeyString + ')  
begin   
        PRINT FormatMessage(''default key(%i, %s) does not exist, inesrting...'',' + @DefaultDimensionKeyString + ',''' + @DefaultAttributeValue + ''') 
       SET identity_insert ' + @qualifiedDimensionName + ' on  

        insert into ' + @qualifiedDimensionName + '
                (  ' + @columnList + ')  
        Values  
        (  ' + @ValueList  + ')  
       SET identity_insert ' + @qualifiedDimensionName + ' off  
END
ELSE 
BEGIN
        PRINT FormatMessage(''default key(%i, %s) exists'',' + @DefaultDimensionKeyString + ',''' + @DefaultAttributeValue + ''') 
END'
;
        EXEC sp_executesql @SQL
        --PRINT @SQL
  
END
