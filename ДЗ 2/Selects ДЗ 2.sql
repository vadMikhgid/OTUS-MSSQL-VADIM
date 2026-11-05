/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
    StockItemID,
    StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%'
   OR StockItemName LIKE 'Animal%'
ORDER BY StockItemID

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT 
    s.SupplierID,
    s.SupplierName
FROM Purchasing.Suppliers AS s
LEFT JOIN Purchasing.PurchaseOrders AS po ON po.SupplierID = s.SupplierID
WHERE po.SupplierID IS NULL
ORDER BY s.SupplierID

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT 
    o.OrderID,
    FORMAT(o.OrderDate, 'dd.MM.yyyy')              AS OrderDate,
    DATENAME(MONTH, o.OrderDate)                   AS MonthName,
    DATEPART(QUARTER, o.OrderDate)                 AS QuarterNum,
    (MONTH(o.OrderDate) - 1) / 4 + 1               AS ThirdOfYear,
    c.CustomerName
FROM Sales.Orders AS o
JOIN Sales.Customers AS c  ON c.CustomerID = o.CustomerID
JOIN Sales.OrderLines AS l ON l.OrderID    = o.OrderID
WHERE (l.UnitPrice > 100 OR l.Quantity > 20) AND l.PickingCompletedWhen IS NOT NULL
GROUP BY 
    o.OrderID,
    o.OrderDate,
    c.CustomerName
ORDER BY 
    DATEPART(QUARTER, o.OrderDate) ASC,
    (MONTH(o.OrderDate) - 1) / 4 + 1 ASC,
    o.OrderDate ASC
OFFSET 1000 ROWS
FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
    dm.DeliveryMethodName,
    po.ExpectedDeliveryDate,
    s.SupplierName,
    p.FullName AS ContactPerson
FROM Purchasing.PurchaseOrders AS po
JOIN Purchasing.Suppliers AS s  ON s.SupplierID = po.SupplierID
JOIN Application.DeliveryMethods AS dm ON dm.DeliveryMethodID = po.DeliveryMethodID
JOIN Application.People AS p  ON p.PersonID = po.ContactPersonID
WHERE po.ExpectedDeliveryDate >= '2013-01-01'
  AND po.ExpectedDeliveryDate <  '2013-02-01'
  AND dm.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')
  AND po.IsOrderFinalized = 1
ORDER BY po.ExpectedDeliveryDate, dm.DeliveryMethodName

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP (10)
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    p.FullName AS SalespersonName
FROM Sales.Orders AS o
JOIN Sales.Customers AS c ON c.CustomerID = o.CustomerID
JOIN Application.People AS p ON p.PersonID = o.SalespersonPersonID
ORDER BY o.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT
    c.CustomerID,
    c.CustomerName,
    c.PhoneNumber
FROM Sales.Customers AS c
JOIN Sales.Orders AS o ON o.CustomerID = c.CustomerID
JOIN Sales.OrderLines AS l ON l.OrderID = o.OrderID
JOIN Warehouse.StockItems AS si ON si.StockItemID = l.StockItemID
WHERE si.StockItemName = 'Chocolate frogs 250g'
ORDER BY c.CustomerID
