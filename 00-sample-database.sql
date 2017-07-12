--
--使用下列 T-SQL 指令碼建立範例資料庫與資料表內容
--	請確認擁有足夠權限
--
CREATE DATABASE [RowversionSampleDb]
GO

USE [RowversionSampleDb]
GO

CREATE SCHEMA [Systems]
GO

CREATE SCHEMA [Products]
GO

--
--紀錄版本號碼的資料表
--
CREATE TABLE [Systems].[SystemRowVersion]
(
	[No]			TINYINT,
	[TableName]		NVARCHAR(250),
	[Version]		BINARY(8),

	CONSTRAINT [pk_SystemRowVersion] PRIMARY KEY ([No]),

	CONSTRAINT [un_SystemRowVersion_Version] UNIQUE ([Version])
)
GO

INSERT INTO [Systems].[SystemRowVersion] ([No],[TableName],[Version])
	VALUES (1,'Products.ProductStorages',0)
GO



--
--商品庫存資料表/沒有正規化
--
CREATE TABLE [Products].[ProductStorages]
(
	[No]		INT,
	[Code]		VARCHAR(20) NOT NULL,

	[Name]		NVARCHAR(50),
	[Size]		NVARCHAR(5),

	[Storage]	DECIMAL DEFAULT(0),
	[version]	ROWVERSION,

	CONSTRAINT [pk_ProductStorages] PRIMARY KEY CLUSTERED ([No]),

	CONSTRAINT [un_ProductStorages_Code] UNIQUE ([Code])
)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (1,'ACL045700',N'HTML5與CSS3響應式網頁設計-第二版',N'本',10)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (2,'B208378',N'CentOS Linux系統建置與實務',N'本',0)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (3,'B117097',N'Oracle 11g資料庫管理與維護手冊',N'本',2)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (4,'A151393',N'Oracle PL/SQL程式設計',N'本',1)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (5,'H10003759',N'ASP.NET MVC 4開發實戰',N'本',3)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (6,'F10015686',N'Microsoft Azure雲端程式設計 : 使用ASP.NET MVC開發',N'本',2)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (7,'BB0065372',N'ASP.NET MVC 5完全攻略',N'本',1)
GO

INSERT INTO [Products].[ProductStorages]([No],[Code],[Name],[Size],[Storage])
	VALUES (8,'B128642',N'Oracle管理之道 : 來自工作現場的DBA職人筆記',N'本',1)
GO

--取得當下 Products.ProductStorages 資料表最後一筆 ROWVERSION 資訊
DECLARE @Version BINARY(8)

SET @Version = (
	SELECT TOP (1) [version]
	FROM [Products].[ProductStorages]
	ORDER BY [version] DESC
)

UPDATE [Systems].[SystemRowVersion]
	SET [Version] = @Version
WHERE [TableName] = 'Products.ProductStorages'

GO

--
--存取此功能的使用者預存程序
--

--隨機進行更新庫存更新
CREATE PROCEDURE [Products].[UpdateProductStorageByRand]
AS
	DECLARE @top INT
	DECLARE @updateId TABLE
	(
		[No]	INT
	)

	SET @top = ABS(CAST(NEWID() AS binary(6)) % 10)+1

	INSERT INTO @updateId ([No])
		SELECT TOP(@top) a.[No]
		FROM [Products].[ProductStorages] a
		ORDER BY NEWID()

	SELECT b.[No] 
		,b.[Code]
		,b.[Name]
		,b.[Size]
		,b.[Storage]
	FROM @updateId a
		INNER JOIN [Products].[ProductStorages] b ON A.[No] = b.[No]

	UPDATE [Products].[ProductStorages] SET 
		[Storage] = ABS(CAST(NEWID() AS binary(6)) % 3)+1
	FROM [Products].[ProductStorages] a
		INNER JOIN @updateId b
		ON (a.[No] = b.[No])
GO

--取得有變更庫存資訊的清單
CREATE PROCEDURE [Products].[GetStorageUpdateRecently]
AS
	DECLARE @Version BINARY(8)
	DECLARE @NewVersion BINARY(8)

	--取得前次的更新戳記
	SET @Version = (
		SELECT [version]
		FROM [Systems].[SystemRowVersion]
		WHERE [TableName] = 'Products.ProductStorages'
	)
	--Products.ProductStorages 資料表最後一筆 ROWVERSION 資訊
	SET @NewVersion = (
		SELECT TOP (1) [version]
		FROM [Products].[ProductStorages]
		ORDER BY [version] DESC
	)

	--依戳記取得近期更新的庫存清單
	SELECT [No]
		,[Code]
		,[Name]
		,[Size]
		,[Storage]
	FROM [Products].[ProductStorages]
	WHERE [version] > @Version
	ORDER BY [version] ASC

	--更新系統資料表紀錄本次庫存最後的更新戳記
	UPDATE [Systems].[SystemRowVersion]
		SET [Version] = @NewVersion
	WHERE [TableName] = 'Products.ProductStorages'
GO

--取得有變更庫存資訊的清單-此預存程序不會更新紀錄戳記的資料表
CREATE PROCEDURE [Products].[GetStorageUpdateRecentlyNotUpdateVersion]
AS
	DECLARE @Version BINARY(8)
	DECLARE @NewVersion BINARY(8)

	--取得前次的更新戳記
	SET @Version = (
		SELECT [version]
		FROM [Systems].[SystemRowVersion]
		WHERE [TableName] = 'Products.ProductStorages'
	)

	--依戳記取得近期更新的庫存清單
	SELECT [No]
		,[Code]
		,[Name]
		,[Size]
		,[Storage]
	FROM [Products].[ProductStorages]
	WHERE [version] > @Version
	ORDER BY [version] ASC
GO