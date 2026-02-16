-- 會員表
CREATE TABLE Members
(
    MemberID INT PRIMARY KEY IDENTITY(1,1),
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    -- 加密後的長度通常較長
    Name NVARCHAR(50) NOT NULL,
    Address NVARCHAR(200),
    Phone VARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE()
);

-- 商品表 (3NF：若有重複的口味或類別，建議獨立出 Category 表，目前維持現狀以符合 MVP)
CREATE TABLE Products
(
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Price INT NOT NULL,
    Stock INT NOT NULL DEFAULT 0,
    Description NVARCHAR(MAX),
    ImageURL NVARCHAR(500),
    -- URL 有時會很長
    Flavor NVARCHAR(50)
);
-- 購物車表 (1對1：每個會員擁有一個啟用的購物車)
CREATE TABLE Cart
(
    CartID INT PRIMARY KEY IDENTITY(1,1),
    MemberID INT NOT NULL UNIQUE,
    -- 確保一個會員只有一個購物車紀錄
    UpdatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Cart_Member FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- 購物車明細 (多對多：連結購物車與商品)
CREATE TABLE CartItems
(
    CartItemID INT PRIMARY KEY IDENTITY(1,1),
    CartID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    -- 數量必須大於 0
    AddedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_CartItems_Cart FOREIGN KEY (CartID) REFERENCES Cart(CartID),
    CONSTRAINT FK_CartItems_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
-- 訂單主表
CREATE TABLE Orders
(
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    MemberID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount INT NOT NULL,
    Status NVARCHAR(20) DEFAULT N'待付款',
    ShippingAddress NVARCHAR(200) NOT NULL,
    -- 即使會員改地址，訂單地址應保留購買時的
    CONSTRAINT FK_Orders_Member FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- 訂單明細表
CREATE TABLE OrderDetails
(
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice INT NOT NULL,
    -- 紀錄交易時的價格 (符合 3NF 邏輯)
    CONSTRAINT FK_Details_Order FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_Details_Product FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);