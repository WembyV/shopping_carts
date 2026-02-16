-- =============================================
-- 1. 刪除購物車中的特定商品 (usp_RemoveFromCart)
-- =============================================
IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_RemoveFromCart')
    DROP PROCEDURE usp_RemoveFromCart;
GO

CREATE PROCEDURE usp_RemoveFromCart
    @MemberID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CartID INT;

    -- 1. 取得該會員的 CartID
    SELECT @CartID = CartID
    FROM Cart
    WHERE MemberID = @MemberID;

    -- 2. 檢查商品是否確實在購物車中
    IF EXISTS (SELECT 1
    FROM CartItems
    WHERE CartID = @CartID AND ProductID = @ProductID)
    BEGIN
        DELETE FROM CartItems 
        WHERE CartID = @CartID AND ProductID = @ProductID;

        PRINT N'商品已從購物車中移除。';
    END
    ELSE
    BEGIN
        PRINT N'提示：購物車中本來就沒有這項商品。';
    END
END;
GO

-- =============================================
-- 2. 清空整個購物車 (usp_ClearCart)
-- =============================================
IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_ClearCart')
    DROP PROCEDURE usp_ClearCart;
GO

CREATE PROCEDURE usp_ClearCart
    @MemberID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CartID INT;

    SELECT @CartID = CartID
    FROM Cart
    WHERE MemberID = @MemberID;

    DELETE FROM CartItems WHERE CartID = @CartID;

    PRINT N'購物車已全部清空。';
END;
GO