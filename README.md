# AddressBook 地址簿資料庫專案

## 專案描述

這是一個基於 Microsoft SQL Server 的地址簿資料庫專案，包含使用者資訊、房屋地址、電話號碼、帳單記錄等功能。專案提供了完整的資料庫結構定義、範例資料以及 ER 圖說明。

## 功能特色

- **使用者管理**：儲存使用者基本資訊（帳號、中文姓名、生日、密碼）
- **房屋地址管理**：記錄房屋地址資訊
- **電話號碼管理**：管理家用電話號碼及其對應的裝機地址
- **帳單記錄**：追蹤電話帳單費用和日期
- **大頭照儲存**：支援使用者大頭照的二進位儲存
- **居住關聯**：支援多對多關係，使用者可居住於多個房屋
- **操作日誌**：記錄系統操作記錄

## 資料庫結構

本專案包含主要的資料表：使用者 (UserInfo)、房屋 (House)、電話 (Phone)、帳單 (Bill)、大頭照 (HeadPhoto)、居住關聯 (Live) 與操作日誌 (Log)。

詳細結構請參考 `docs/er.md`。


## 安裝與設定

### 環境需求

- Microsoft SQL Server 2016 或更新版本
- SQL Server Management Studio (SSMS) 或其他 SQL 客戶端工具

### 資料庫建立

1. 開啟 SQL Server Management Studio
2. 連接到您的 SQL Server 實例
3. 開啟 `src/mssql_AddressBook.sql` 檔案
4. 執行整個腳本以建立 AddressBook 資料庫和所有資料表

腳本將會：
- 建立 AddressBook 資料庫（使用 Chinese_Taiwan_Stroke_90_CI_AI 排序規則）
- 建立所有資料表和約束
- 插入範例資料
- 設定外鍵約束和預設值

### 驗證安裝

執行以下查詢來驗證資料庫是否正確建立：

```sql
USE AddressBook;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
```

## 使用說明

### 基本查詢範例

**查詢所有使用者資訊：**
```sql
SELECT uid, cname, birthday FROM UserInfo;
```

**查詢特定使用者的居住地址：**
```sql
SELECT u.cname, h.address
FROM UserInfo u
JOIN Live l ON u.uid = l.uid
JOIN House h ON l.hid = h.hid
WHERE u.uid = 'A01';
```

**查詢電話帳單記錄：**
```sql
SELECT p.tel, b.dd, b.fee, h.address
FROM Phone p
JOIN Bill b ON p.tel = b.tel
JOIN House h ON b.hid = h.hid
ORDER BY b.dd DESC;
```

## 專案結構

```
sql/
├── README.md                 # 專案說明文件
├── test.sql                  # 測試查詢檔案（目前為空）
├── docs/
│   └── er.md                 # ER 圖和資料表詳細說明
├── src/
│   └── mssql_AddressBook.sql # 資料庫建立腳本
└── log/                      # 日誌目錄（用於存放操作記錄）
```

## 安全注意事項

- 密碼欄位應使用安全的雜湊演算法（如 SHA-256）儲存，切勿儲存明文密碼
- 所有 nvarchar 欄位使用 Unicode 編碼，確保中文文字正確顯示
- 在插入 Unicode 字串時，請使用 N'...' 前綴

## 開發與測試

- 使用 `test.sql` 檔案撰寫和測試您的 SQL 查詢
- 參考 `docs/er.md` 了解完整的資料庫設計和關聯
- 所有變更應先在測試環境中驗證

## 授權

本專案僅供學習和參考使用。

## 貢獻

歡迎提交 Issue 和 Pull Request 來改進這個專案。