-- 1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".

SELECT [StockItemID]
      ,[StockItemName]
      ,[SupplierID]
      ,[ColorID]
      ,[UnitPackageID]
      ,[OuterPackageID]
      ,[Brand]
      ,[Size]
      ,[LeadTimeDays]
      ,[QuantityPerOuter]
      ,[IsChillerStock]
      ,[Barcode]
      ,[TaxRate]
      ,[UnitPrice]
      ,[RecommendedRetailPrice]
      ,[TypicalWeightPerUnit]
      ,[MarketingComments]
      ,[InternalComments]
      ,[Photo]
      ,[CustomFields]
      ,[Tags]
      ,[SearchDetails]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [WideWorldImporters].[Warehouse].[StockItems]
  where StockItemName like '%urgent%' or StockItemName like 'Animal%'


  -- 2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).

  SELECT s.[SupplierID]
      ,[SupplierName]    
  FROM [Purchasing].[Suppliers] s
  left join [Purchasing].[PurchaseOrders] pp on pp.SupplierID = s.SupplierID
  where pp.SupplierID is null

  -- 3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ либо количеством единиц (Quantity) 
  --    товара более 20 штуки присутствующей датой комплектации всего заказа (PickingCompletedWhen).

