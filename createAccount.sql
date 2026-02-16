-- =============================================
-- 1. 建立帳號的 Stored Procedure
-- =============================================
IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_CreateMember')
    DROP PROCEDURE usp_CreateMember;
GO

CREATE PROCEDURE usp_CreateMember
    @Email NVARCHAR(100),
    @Password NVARCHAR(255),
    @Name NVARCHAR(50),
    @Address NVARCHAR(200) = NULL,
    @Phone VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 檢查 Email 是否已經存在
    IF EXISTS (SELECT 1
    FROM Members
    WHERE Email = @Email)
    BEGIN
        PRINT N'錯誤：該 Email 已被註冊。';
        RETURN -1;
    -- 傳回失敗代碼
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 插入會員資料
        INSERT INTO Members
        (Email, Password, Name, Address, Phone)
    VALUES
        (@Email, @Password, @Name, @Address, @Phone);

        -- 獲取新產生的 MemberID
        DECLARE @NewMemberID INT = SCOPE_IDENTITY();

        -- 【符合 3NF】自動為新會員建立一個空的購物車
        INSERT INTO Cart
        (MemberID)
    VALUES
        (@NewMemberID);

        COMMIT TRANSACTION;
        PRINT N'帳號建立成功！已同步配置購物車。';
        SELECT *
    FROM Members
    WHERE MemberID = @NewMemberID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

-- =============================================
-- 2. 確認帳號是否存在的 Stored Procedure
-- =============================================
IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_CheckMemberStatus')
    DROP PROCEDURE usp_CheckMemberStatus;
GO

CREATE PROCEDURE usp_CheckMemberStatus
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
    FROM Members
    WHERE Email = @Email)
    BEGIN
        -- 如果存在，回傳詳細資訊與帳號年資
        SELECT
            MemberID,
            Name,
            Email,
            CreatedAt,
            DATEDIFF(DAY, CreatedAt, GETDATE()) AS MemberDays
        FROM Members
        WHERE Email = @Email;
    END
    ELSE
    BEGIN
        PRINT N'找不到該帳號：' + @Email;
    END
END;
GO