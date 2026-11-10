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
  join (SELECT TOP (5) [CustomerID],Max([TransactionAmount]) as [max Transaction Amount]    
          FROM [WideWorldImporters].[Sales].[CustomerTransactions]
         group by [CustomerID]
         order by 2 desc) as t on c.CustomerID = t.CustomerID
--cte
with cte1 as 
(
SELECT TOP (5) [CustomerID]     
      ,Max([TransactionAmount]) as [max Transaction Amount]    
  FROM [WideWorldImporters].[Sales].[CustomerTransactions]
  group by [CustomerID]
  order by 2 desc
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

TODO: напишите здесь свое решение

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

-- --

TODO: напишите здесь свое решение
