-- =============================================
-- 登入驗證的 Stored Procedure
-- =============================================
IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_LoginMember')
    DROP PROCEDURE usp_LoginMember;
GO

CREATE PROCEDURE usp_LoginMember
    @Email NVARCHAR(100),
    @Password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. 宣告變數來存儲查詢結果
    DECLARE @MemberID INT;

    -- 2. 嘗試比對帳號與密碼
    SELECT @MemberID = MemberID
    FROM Members
    WHERE Email = @Email AND Password = @Password;

    -- 3. 判斷是否登入成功
    IF @MemberID IS NOT NULL
    BEGIN
        -- 登入成功：回傳會員基本資訊與其購物車編號 (方便前端立即讀取購物車)
        SELECT
            M.MemberID,
            M.Name,
            M.Email,
            C.CartID,
            N'登入成功' AS Message
        FROM Members M
            LEFT JOIN Cart C ON M.MemberID = C.MemberID
        WHERE M.MemberID = @MemberID;

        RETURN 1;
    -- 成功回傳代碼 1
    END
    ELSE
    BEGIN
        -- 登入失敗：區分是「帳號不存在」還是「密碼錯誤」 (選用，為了安全性有時會統一回傳錯誤)
        IF NOT EXISTS (SELECT 1
        FROM Members
        WHERE Email = @Email)
            RAISERROR(N'此帳號尚未註冊。', 16, 1);
        ELSE
            RAISERROR(N'密碼輸入錯誤，請重新確認。', 16, 1);

        RETURN 0;
    -- 失敗回傳代碼 0
    END
END;
GO