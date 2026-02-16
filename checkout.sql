IF EXISTS (SELECT *
FROM sys.objects
WHERE type = 'P' AND name = 'usp_Checkout')
    DROP PROCEDURE usp_Checkout;
GO

CREATE PROCEDURE usp_Checkout
    @MemberID INT,
    @ShippingAddress NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CartID INT;
    DECLARE @TotalAmount INT = 0;
    DECLARE @NewOrderID INT;

    -- 1. 取得購物車編號
    SELECT @CartID = CartID
    FROM Cart
    WHERE MemberID = @MemberID;

    -- 2. 檢查購物車內是否有東西
    IF NOT EXISTS (SELECT 1
    FROM CartItems
    WHERE CartID = @CartID)
    BEGIN
        RAISERROR(N'購物車是空的，無法結帳。', 16, 1);
        RETURN;
    END

    -- 3. 開啟事務 (Transaction) - 確保所有動作要麼全成功，要麼全失敗
    BEGIN TRANSACTION;

    BEGIN TRY
        -- A. 檢查每一項商品的庫存是否足夠
        IF EXISTS (
            SELECT 1
    FROM CartItems CI
        JOIN Products P ON CI.ProductID = P.ProductID
    WHERE CI.CartID = @CartID AND P.Stock < CI.Quantity
        )
        BEGIN
        RAISERROR(N'結帳失敗：部分商品庫存不足。', 16, 1);
    END

        -- B. 計算訂單總金額
        SELECT @TotalAmount = SUM(P.Price * CI.Quantity)
    FROM CartItems CI
        JOIN Products P ON CI.ProductID = P.ProductID
    WHERE CI.CartID = @CartID;

        -- C. 建立訂單主表紀錄
        INSERT INTO Orders
        (MemberID, OrderDate, TotalAmount, Status, ShippingAddress)
    VALUES
        (@MemberID, GETDATE(), @TotalAmount, N'待付款', @ShippingAddress);
        
        SET @NewOrderID = SCOPE_IDENTITY(); -- 取得新產生的 OrderID

        -- D. 將購物車明細搬移到訂單明細 (符合 3NF，記錄交易當下單價)
        INSERT INTO OrderDetails
        (OrderID, ProductID, Quantity, UnitPrice)
    SELECT @NewOrderID, CI.ProductID, CI.Quantity, P.Price
    FROM CartItems CI
        JOIN Products P ON CI.ProductID = P.ProductID
    WHERE CI.CartID = @CartID;

        -- E. 扣除商品表中的庫存量
        UPDATE P
        SET P.Stock = P.Stock - CI.Quantity
        FROM Products P
        JOIN CartItems CI ON P.ProductID = CI.ProductID
        WHERE CI.CartID = @CartID;

        -- F. 清空該會員的購物車
        DELETE FROM CartItems WHERE CartID = @CartID;

        -- 如果到這裡都沒出錯，提交事務
        COMMIT TRANSACTION;
        
        PRINT N'結帳成功！訂單編號：' + CAST(@NewOrderID AS NVARCHAR(10));
        SELECT *
    FROM Orders
    WHERE OrderID = @NewOrderID; -- 回傳訂單結果
        
    END TRY
    BEGIN CATCH
        -- 若中途出錯，撤銷所有變更
        ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH
END;
GO

-- 關鍵邏輯拆解 (為何這樣寫？)
-- Transaction (事務)：這是結帳最重要的一環。如果搬移明細成功了，但扣庫存失敗，ROLLBACK 會把資料還原，防止數據失真。

-- 庫存扣除：使用 UPDATE FROM JOIN 語法，一次性根據購物車的數量更新所有商品庫存，效率最高。

-- 單價快照：在 INSERT INTO OrderDetails 時，我們從 Products 表撈取 Price 並寫入。這保證了未來如果商品漲價，這筆歷史訂單的價格依然維持當初購買的金額。

-- 地址快照：ShippingAddress 也是存入訂單表而不是關聯會員表，因為會員以後可能會搬家，但舊訂單的配送地址必須保留。