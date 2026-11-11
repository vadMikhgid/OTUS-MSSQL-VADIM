/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--CTE
;with 
cte1 as 
(
        SELECT [PersonID]
              ,[FullName]      
          FROM [WideWorldImporters].[Application].[People]
         where [IsSalesperson] = 1
),
cte2 as 
(
        SELECT [InvoiceID]                      
              ,[SalespersonPersonID]                      
              ,[InvoiceDate]                      
        FROM [WideWorldImporters].[Sales].[Invoices]
        where InvoiceDate = '2015-07-04'
)
select [PersonID] as [id Сорудника]
      ,[FullName] as [Полное имя]
from cte1
left join cte2 on cte1.PersonID = cte2.SalespersonPersonID
where cte2.[InvoiceID] is null

--подзапрос
 SELECT [PersonID]
       ,[FullName]      
   FROM [WideWorldImporters].[Application].[People]
  where [IsSalesperson] = 1 
    and [PersonID] not in (SELECT [SalespersonPersonID]                                           
                        FROM [WideWorldImporters].[Sales].[Invoices]
                        where InvoiceDate = '2015-07-04')


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
--подзапрос
SELECT 
    StockItemID,
    StockItemName,
    UnitPrice
FROM 
    [WideWorldImporters].[Warehouse].[StockItems]
WHERE 
    UnitPrice = (SELECT MIN(UnitPrice) FROM [WideWorldImporters].[Warehouse].[StockItems])
--подзапрос
SELECT 
    s.StockItemID,
    s.StockItemName,
    s.UnitPrice
FROM 
    [WideWorldImporters].[Warehouse].[StockItems] AS s
    JOIN (SELECT MIN(UnitPrice) AS MinPrice FROM [WideWorldImporters].[Warehouse].[StockItems]
    ) AS m ON s.UnitPrice = m.MinPrice;

--cte
WITH MinPrice AS (
    SELECT MIN(UnitPrice) AS MinUnitPrice
    FROM [WideWorldImporters].[Warehouse].[StockItems]
)
SELECT 
    s.StockItemID,
    s.StockItemName,
    s.UnitPrice
FROM 
    [WideWorldImporters].[Warehouse].[StockItems] AS s
    INNER JOIN MinPrice AS m ON s.UnitPrice = m.MinUnitPrice;

WITH MinPrice AS (
    SELECT MIN(UnitPrice) AS MinUnitPrice
    FROM [WideWorldImporters].[Warehouse].[StockItems]
)
SELECT 
    StockItemID,
    StockItemName,
    UnitPrice
FROM 
    [WideWorldImporters].[Warehouse].[StockItems]
WHERE 
    UnitPrice IN (SELECT MinUnitPrice FROM MinPrice);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

  SELECT c.[CustomerID]  
      ,t.[max Transaction Amount]
      ,[CustomerName]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
  FROM [WideWorldImporters].[Sales].[Customers] c
  join (SELECT TOP (5) [CustomerID],[TransactionAmount] as [max Transaction Amount]    
          FROM [WideWorldImporters].[Sales].[CustomerTransactions] ct
          join Application.TransactionTypes as at on at.TransactionTypeID = ct.TransactionTypeID
          WHERE TransactionTypeName = N'Customer Payment Received'         
         order by ABS(TransactionAmount) DESC) as t on c.CustomerID = t.CustomerID
   
--cte
;with cte1 as 
(
SELECT TOP (5) [CustomerID],[TransactionAmount] as [max Transaction Amount]    
          FROM [WideWorldImporters].[Sales].[CustomerTransactions] ct
          join Application.TransactionTypes as at on at.TransactionTypeID = ct.TransactionTypeID
          WHERE TransactionTypeName = N'Customer Payment Received'         
         order by ABS(TransactionAmount) DESC
  )
  SELECT c.[CustomerID]
      ,[max Transaction Amount]
      ,[CustomerName]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
  FROM [WideWorldImporters].[Sales].[Customers] c
  join cte1 on c.[CustomerID] = cte1.CustomerID
  

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--подзапрос
SELECT DISTINCT
    city.CityID,
    city.CityName,
    p.FullName AS PickedByPersonName
FROM (
    --3 самых дорогих товара
    SELECT TOP (3)
        StockItemID,
        StockItemName,
        UnitPrice
    FROM Warehouse.StockItems
    ORDER BY UnitPrice DESC
) AS top3
JOIN Sales.OrderLines AS ol
    ON ol.StockItemID = top3.StockItemID
JOIN Sales.Orders AS o
    ON o.OrderID = ol.OrderID
JOIN Sales.Customers AS c
    ON c.CustomerID = o.CustomerID
JOIN Application.Cities AS city
    ON city.CityID = c.DeliveryCityID
LEFT JOIN Application.People AS p
    ON p.PersonID = o.PickedByPersonID
ORDER BY city.CityName, p.FullName;

--CTE
WITH ct1 AS (
    SELECT TOP (3)
        StockItemID,
        StockItemName,
        UnitPrice
    FROM Warehouse.StockItems
    ORDER BY UnitPrice DESC
),
ct2 AS (
    SELECT DISTINCT
        city.CityID,
        city.CityName,
        p.FullName AS PickedByPersonName
    FROM Sales.OrderLines AS ol
    JOIN Sales.Orders AS o
        ON o.OrderID = ol.OrderID
    JOIN Sales.Customers AS c
        ON c.CustomerID = o.CustomerID
    JOIN Application.Cities AS city
        ON city.CityID = c.DeliveryCityID
    LEFT JOIN Application.People AS p
        ON p.PersonID = o.PickedByPersonID
    WHERE ol.StockItemID IN (SELECT StockItemID FROM ct1)
)
SELECT
    CityID,
    CityName,
    PickedByPersonName
FROM ct2
ORDER BY CityName, PickedByPersonName;

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

--Запрос возвращает список счетов с суммой больше 27 000, для каждого из которых показывает:
--Номер счёта, Дата выставления счёта, ФИО продавца, оформившего счёт, Сумма счёта (без налога), Сумма собранных позиций по заказу 

WITH InvoiceTotals AS (
    SELECT InvoiceID, SUM(Quantity * UnitPrice) AS TotalSumm
    FROM Sales.InvoiceLines
    GROUP BY InvoiceID
    HAVING SUM(Quantity * UnitPrice) > 27000
),
CompletedPickedTotals AS (
    -- Сначала отфильтровываем собранные заказы, затем агрегируем подобранное количество
    SELECT ol.OrderID, SUM(ol.PickedQuantity * ol.UnitPrice) AS TotalSummForPickedItems
    FROM Sales.OrderLines AS ol
    JOIN Sales.Orders AS o ON o.OrderID = ol.OrderID
    WHERE o.PickingCompletedWhen IS NOT NULL
    GROUP BY ol.OrderID
)
SELECT
    i.InvoiceID,
    i.InvoiceDate,
    p.FullName AS SalesPersonName,
    it.TotalSumm AS TotalSummByInvoice,
    cpt.TotalSummForPickedItems
FROM Sales.Invoices AS i
JOIN InvoiceTotals AS it ON it.InvoiceID = i.InvoiceID
LEFT JOIN Application.People AS p ON p.PersonID = i.SalespersonPersonID
LEFT JOIN CompletedPickedTotals AS cpt ON cpt.OrderID = i.OrderID
ORDER BY it.TotalSumm DESC;

--сравнивая планы запросов статистика практически не изменилась.