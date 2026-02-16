-- =============================================
-- 1. 將商品加入購物車 (usp_AddToCart)
-- 邏輯：如果商品已存在，則增加數量；不存在則新增。
-- =============================================
IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_AddToCart')
    DROP PROCEDURE usp_AddToCart;
GO

CREATE PROCEDURE usp_AddToCart
    @MemberID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CartID INT;

    -- 1. 取得該會員的 CartID (之前在註冊時已預先建立)
    SELECT @CartID = CartID
    FROM Cart
    WHERE MemberID = @MemberID;

    -- 2. 檢查庫存是否足夠 (安全檢查)
    IF (SELECT Stock
    FROM Products
    WHERE ProductID = @ProductID) < @Quantity
    BEGIN
        RAISERROR(N'庫存不足，無法加入購物車。', 16, 1);
        RETURN;
    END

    -- 3. 判斷商品是否已在購物車內
    IF EXISTS (SELECT 1
    FROM CartItems
    WHERE CartID = @CartID AND ProductID = @ProductID)
    BEGIN
        -- 如果已存在，更新數量 (累加)
        UPDATE CartItems 
        SET Quantity = Quantity + @Quantity, 
            AddedDate = GETDATE()
        WHERE CartID = @CartID AND ProductID = @ProductID;
        PRINT N'商品數量已更新。';
    END
    ELSE
    BEGIN
        -- 如果不存在，插入新資料
        INSERT INTO CartItems
            (CartID, ProductID, Quantity)
        VALUES
            (@CartID, @ProductID, @Quantity);
        PRINT N'商品已成功加入購物車。';
    END
END;
GO

-- =============================================
-- 2. 查看個人購物車內容 (usp_GetCartDetails)
-- 邏輯：關聯商品表，計算各品項小計與總金額。
-- =============================================
IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_GetCartDetails')
    DROP PROCEDURE usp_GetCartDetails;
GO

CREATE PROCEDURE usp_GetCartDetails
    @MemberID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 回傳明細：品名、單價、數量、小計
    SELECT
        P.ProductID,
        P.Name AS ProductName,
        P.Price AS UnitPrice,
        CI.Quantity,
        (P.Price * CI.Quantity) AS SubTotal,
        CI.AddedDate
    FROM Cart C
        JOIN CartItems CI ON C.CartID = CI.CartID
        JOIN Products P ON CI.ProductID = P.ProductID
    WHERE C.MemberID = @MemberID
    ORDER BY CI.AddedDate DESC;

    -- (選用) 額外回傳一個總金額總計
    SELECT SUM(P.Price * CI.Quantity) AS TotalCartAmount
    FROM Cart C
        JOIN CartItems CI ON C.CartID = CI.CartID
        JOIN Products P ON CI.ProductID = P.ProductID
    WHERE C.MemberID = @MemberID;
END;
GO