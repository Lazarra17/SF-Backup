/**
* @description Utility for Clipper classes
* @author Bricoleur Technologies
* [1] JP Sulit Oct-14-2024 - Applied fix to getSupplierProductsMap function; Added Supplier_Product__c field in Product Query Clause
* [2] JP Sulit Oct-14-2024 - Added WITH SECURITY_ENFORCED keyword for every query clause
* [3] JP Sulit Oct-16-2024 - Added Security.stripInaccessible for DMLs that has ApexCRUDViolation in code scan
* [4] Chad Lazarra Oct-18-2024 - Removed WITH SECURITY_ENFORCED keyword for every query clause
* [5] JP Sulit Oct-29-2024 - Added reusable method to return records from SObjectAccessDecision function
*/
@NamespaceAccessible
public with sharing class ClipperSettingUtility {

    /**
    * @description gets Clipper Inventory Setting value
    * @return nao__Clipper_Inventory_Setting__mdt.nao__Record_Type_Developer_Name__c value
    */
    public static String getStockTransferRecordTypeDevName() {
        nao__Clipper_Inventory_Setting__mdt clipperSetting = [
            SELECT Id, nao__Stock_Transfer_Record_Type__c, nao__Record_Type_Developer_Name__c
            FROM nao__Clipper_Inventory_Setting__mdt
            WHERE nao__Stock_Transfer_Record_Type__c = TRUE
            WITH USER_MODE LIMIT 1
        ];
        return clipperSetting?.nao__Record_Type_Developer_Name__c;
    }

    /**
    * @description Returns date value from nao__Ignore_Orders_before_Activation_Date__c field in NAO ERP Custom Setting
    * @date Feb 12, 2024
    * @return nao__NAO_ERP_Custom_Settings__c
    */
    public static nao__NAO_ERP_Custom_Settings__c getOrderDateSettings() {
        nao__NAO_ERP_Custom_Settings__c naoErpDate = nao__NAO_ERP_Custom_Settings__c.getValues('Order Date Settings');
        return naoErpDate;
    }

    /**
    * @description Returns a unique list of Product Ids from GRN
    * @date Feb 7, 2024
    * @param grnList
    * @return Map<Id, Set<String>>
    */
    public static Map<Id, Set<String>> getCompletedGrnProducts(List<nao__Goods_Received_Notice_bric__c> grnList) {
        Map<Id, Set<String>> completedProductsMap = new Map<Id, Set<String>>();
        List<nao__Purchase_Order_Products_Received_bric__c> listGrnLine = new List<nao__Purchase_Order_Products_Received_bric__c>();

        Date naoErpDate = getOrderDateSettings()?.nao__Ignore_Purchase_Orders_Before_Activation__c;

        if (naoErpDate != null) {
            listGrnLine = (List<nao__Purchase_Order_Products_Received_bric__c>) getSecuredAccessRecords(
                (List<sObject>) [
                    SELECT Id, nao__Goods_Received_Notice_bric__c, nao__Product_Bric__c,
                           nao__Goods_Received_Notice_bric__r.nao__Order_Warehouse_Location__c
                    FROM nao__Purchase_Order_Products_Received_bric__c
                    WHERE nao__Goods_Received_Notice_bric__c IN :grnList
                    AND nao__Amount_Received__c > 0
                    AND nao__Goods_Received_Notice_bric__r.nao__Order_Bric__r.ActivatedDate >= :naoErpDate
                    AND nao__Product_bric__r.nao__Inventory_Status__c != 'Non-Stock Item'
                ]
            );
        } else {
            listGrnLine = (List<nao__Purchase_Order_Products_Received_bric__c>) getSecuredAccessRecords(
                (List<sObject>) [
                    SELECT Id, nao__Goods_Received_Notice_bric__c, nao__Product_Bric__c,
                           nao__Goods_Received_Notice_bric__r.nao__Order_Warehouse_Location__c
                    FROM nao__Purchase_Order_Products_Received_bric__c
                    WHERE nao__Goods_Received_Notice_bric__c IN :grnList
                    AND nao__Amount_Received__c > 0
                    AND nao__Product_bric__r.nao__Inventory_Status__c != 'Non-Stock Item'
                ]
            );
        }

        for (nao__Purchase_Order_Products_Received_bric__c grnLine : listGrnLine) {
            if (!completedProductsMap.containsKey(grnLine.nao__Goods_Received_Notice_bric__c)) {
                completedProductsMap.put(grnLine.nao__Goods_Received_Notice_bric__c, new Set<String>{ grnLine.nao__Product_Bric__c });
            } else {
                completedProductsMap.get(grnLine.nao__Goods_Received_Notice_bric__c).add(grnLine.nao__Product_Bric__c);
            }
        }
        return completedProductsMap;
    }

    /**
    * @description Returns a unique list of Product Ids from Completed Orders
    * @param orderIdSet
    * @return Map<Id, Set<String>>
    */
    public static Map<Id, Set<String>> getCompletedOrderProducts(Set<Id> orderIdSet) {
        Map<Id, Set<String>> completedProductsMap = new Map<Id, Set<String>>();
        List<OrderItem> listOi = (List<OrderItem>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, Quantity, OrderId, Product2Id, Order.nao__Inventory_Location__c
                FROM OrderItem
                WHERE OrderId IN :orderIdSet
            ]
        );

        for (OrderItem oi : listOi) {
            if (!completedProductsMap.containsKey(oi.OrderId)) {
                completedProductsMap.put(oi.OrderId, new Set<String>{ oi.Product2Id });
            } else {
                completedProductsMap.get(oi.OrderId).add(oi.Product2Id);
            }
        }
        return completedProductsMap;
    }

    /**
    * @description Returns map of conversion factors
    * @param completedProductsMap
    * @return Map<Id, Decimal>
    */
    public static Map<Id, Decimal> getStdProdIdMap(Map<Id, Set<String>> completedProductsMap) {
        Set<String> productIdSet = new Set<String>();
        Map<Id, Decimal> stdProductMap = new Map<Id, Decimal>();

        for (String key : completedProductsMap.keySet()) {
            productIdSet.addAll(completedProductsMap.get(key));
        }

        for (Product2 prod : (List<Product2>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Conversion_Factor__c FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
                AND nao__Supplier_Product__c IN :productIdSet
            ]
        )) {
            stdProductMap.put(prod.Id, prod.nao__Conversion_Factor__c);
        }

        for (nao__Product_Suppliers_bric__c ps : (List<nao__Product_Suppliers_bric__c>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT nao__Product_bric__c, nao__Conversion_Factor__c FROM nao__Product_Suppliers_bric__c
                WHERE nao__Supplier_Product_bric__c IN :productIdSet
            ]
        )) {
            if (!stdProductMap.containsKey(ps.nao__Product_bric__c)) {
                stdProductMap.put(ps.nao__Product_bric__c, ps.nao__Conversion_Factor__c);
            }
        }

        for (Product2 prod : (List<Product2>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Conversion_Factor__c FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
                AND Id IN :productIdSet
                AND nao__Use_This_Product_for_Re_order__c = true
            ]
        )) {
            if (!stdProductMap.containsKey(prod.Id)) {
                stdProductMap.put(prod.Id, 1);
            }
        }
        return stdProductMap;
    }

    /**
    * @description Returns map of supplier products
    * @param stdProductMap
    * @return Map<Id, Product2>
    */
    public static Map<Id, Product2> getSupplierProductsMap(Map<Id, Decimal> stdProductMap) {
        Map<Id, Product2> supplierProdMap = new Map<Id, Product2>();
        Map<Id, Product2> standardProdMap = new Map<Id, Product2>();

        for (Product2 prod : (List<Product2>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT nao__Supplier_Product__c, Id, nao__Conversion_Factor__c FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
                AND Id IN :stdProductMap.keySet()
            ]
        )) {
            supplierProdMap.put(prod.nao__Supplier_Product__c, prod);
            standardProdMap.put(prod.Id, prod);
        }

        for (nao__Product_Suppliers_bric__c ps : (List<nao__Product_Suppliers_bric__c>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT nao__Supplier_Product_bric__c, nao__Product_bric__c, nao__Conversion_Factor__c FROM nao__Product_Suppliers_bric__c
                WHERE nao__Product_bric__c IN :stdProductMap.keySet()
            ]
        )) {
            if (!supplierProdMap.containsKey(ps.nao__Supplier_Product_bric__c)) {
                supplierProdMap.put(ps.nao__Supplier_Product_bric__c, standardProdMap.get(ps.nao__Product_bric__c));
            }
        }

        for (Product2 prod : (List<Product2>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Conversion_Factor__c, nao__Supplier_Product__c FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
                AND Id IN :stdProductMap.keySet()
                AND nao__Use_This_Product_for_Re_order__c = true
            ]
        )) {
            if (!supplierProdMap.containsKey(prod.Id)) {
                supplierProdMap.put(prod.Id, prod);
            }
        }
        return supplierProdMap;
    }

    /**
    * @description Gets conversion factor from Product and Product Supplier
    * @date Feb 22, 2024
    * @param stdProductMap
    * @return Map<Id, Decimal>
    */
    public static Map<Id, Decimal> getSupProdConversionFactorMap(Map<Id, Decimal> stdProductMap) {
        Map<Id, Decimal> supplierProdMap = new Map<Id, Decimal>();
        Map<Id, Product2> standardProdMap = new Map<Id, Product2>();

        for (Product2 prod : (List<Product2>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT nao__Supplier_Product__c, Id, nao__Conversion_Factor__c FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
                AND Id IN :stdProductMap.keySet()
            ]
        )) {
            supplierProdMap.put(prod.nao__Supplier_Product__c, prod.nao__Conversion_Factor__c);
            standardProdMap.put(prod.Id, prod);
        }

        for (nao__Product_Suppliers_bric__c ps : (List<nao__Product_Suppliers_bric__c>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT nao__Supplier_Product_bric__c, nao__Product_bric__c, nao__Conversion_Factor__c FROM nao__Product_Suppliers_bric__c
                WHERE nao__Product_bric__c IN :stdProductMap.keySet()
            ]
        )) {
            if (!supplierProdMap.containsKey(ps.nao__Supplier_Product_bric__c)) {
                supplierProdMap.put(ps.nao__Supplier_Product_bric__c, ps.nao__Conversion_Factor__c);
            }
        }

        for (Product2 prod : (List<Product2>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Conversion_Factor__c FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
                AND Id IN :stdProductMap.keySet()
                AND nao__Use_This_Product_for_Re_order__c = true
            ]
        )) {
            if (!supplierProdMap.containsKey(prod.Id)) {
                supplierProdMap.put(prod.Id, 1);
            }
        }
        return supplierProdMap;
    }

    /**
    * @description Gets list of purchase order line items based on supplier products
    * @param supplierProdMap
    * @return Map<Id, List<OrderItem>>
    */
    public static Map<Id, List<OrderItem>> getPurchaseOrderLineMap(Map<Id, Product2> supplierProdMap) {
        Map<Id, List<OrderItem>> purchaseOrderLineMap = new Map<Id, List<OrderItem>>();
        List<OrderItem> listOi = new List<OrderItem>();

        Date naoErpDate = getOrderDateSettings()?.nao__Ignore_Purchase_Orders_Before_Activation__c;

        if (naoErpDate != null) {
            listOi = (List<OrderItem>) getSecuredAccessRecords(
                (List<sObject>) [
                    SELECT Product2Id, OrderId, Id, Quantity FROM OrderItem
                    WHERE Order.StatusCode = 'Activated'
                    AND Order.nao__Completed__c = FALSE
                    AND Product2Id IN :supplierProdMap.keySet()
                    AND Order.RecordType.DeveloperName = 'Purchase_Order'
                    AND Order.ActivatedDate >= :naoErpDate
                ]
            );
        } else {
            listOi = (List<OrderItem>) getSecuredAccessRecords(
                (List<sObject>) [
                    SELECT Product2Id, OrderId, Id, Quantity FROM OrderItem
                    WHERE Order.StatusCode = 'Activated'
                    AND Order.nao__Completed__c = FALSE
                    AND Product2Id IN :supplierProdMap.keySet()
                    AND Order.RecordType.DeveloperName = 'Purchase_Order'
                ]
            );
        }

        for (OrderItem oi : listOi) {
            if (!purchaseOrderLineMap.containsKey(oi.OrderId)) {
                purchaseOrderLineMap.put(oi.OrderId, new List<OrderItem>{ oi });
            } else {
                purchaseOrderLineMap.get(oi.OrderId).add(oi);
            }
        }
        return purchaseOrderLineMap;
    }

    /**
    * @description Gets list of GRN line items based on purchased orders
    * @param purchaseOrderLineMap
    * @return Map<Id, nao__Purchase_Order_Products_Received_bric__c>
    */
    public static Map<Id, nao__Purchase_Order_Products_Received_bric__c> getGrnLineRcvdMap(Map<Id, List<OrderItem>> purchaseOrderLineMap) {
        Set<String> orderProductIdSet = new Set<String>();

        for (String key : purchaseOrderLineMap.keySet()) {
            for (OrderItem oi : purchaseOrderLineMap.get(key)) {
                orderProductIdSet.add(oi.Id);
            }
        }

        Date naoErpDate = getOrderDateSettings()?.nao__Ignore_Purchase_Orders_Before_Activation__c;
        Map<Id, nao__Purchase_Order_Products_Received_bric__c> grnLineMap;

        if (naoErpDate != null) {
            grnLineMap = new Map<Id, nao__Purchase_Order_Products_Received_bric__c>(
                (List<nao__Purchase_Order_Products_Received_bric__c>) getSecuredAccessRecords(
                    (List<sObject>) [
                        SELECT nao__Order_Product_bric__c, nao__Product_bric__c, nao__Amount_Received__c
                        FROM nao__Purchase_Order_Products_Received_bric__c
                        WHERE nao__Order_Product_bric__c IN :orderProductIdSet
                        AND nao__Order_Product_bric__r.Order.ActivatedDate >= :naoErpDate
                    ]
                )
            );
        } else {
            grnLineMap = new Map<Id, nao__Purchase_Order_Products_Received_bric__c>(
                (List<nao__Purchase_Order_Products_Received_bric__c>) getSecuredAccessRecords(
                    (List<sObject>) [
                        SELECT nao__Order_Product_bric__c, nao__Product_bric__c, nao__Amount_Received__c
                        FROM nao__Purchase_Order_Products_Received_bric__c
                        WHERE nao__Order_Product_bric__c IN :orderProductIdSet
                    ]
                )
            );
        }
        return grnLineMap;
    }

    /**
    * @description Gets aggregate of purchase order product totals
    * @param supplierProdMap
    * @return Map<String, Decimal>
    */
    public static Map<String, Decimal> getPurchaseOrderProductTotals(Map<Id, Product2> supplierProdMap) {
        Map<String, Decimal> purchaseOrderProductTotalsMap = new Map<String, Decimal>();
        List<AggregateResult> arList = new List<AggregateResult>();
        Date naoErpDate = getOrderDateSettings()?.nao__Ignore_Purchase_Orders_Before_Activation__c;

        if (naoErpDate != null) {
            arList = [
                SELECT Product2Id, Order.nao__Inventory_Location__c locId, SUM(Quantity) totalQty
                FROM OrderItem
                WHERE Order.StatusCode = 'Activated'
                AND Order.nao__Completed__c = FALSE
                AND Product2Id IN :supplierProdMap.keySet()
                AND Order.RecordType.DeveloperName = 'Purchase_Order'
                AND Order.ActivatedDate >= :naoErpDate
                GROUP BY Product2Id, Order.nao__Inventory_Location__c
            ];
        } else {
            arList = [
                SELECT Product2Id, Order.nao__Inventory_Location__c locId, SUM(Quantity) totalQty
                FROM OrderItem
                WHERE Order.StatusCode = 'Activated'
                AND Order.nao__Completed__c = FALSE
                AND Product2Id IN :supplierProdMap.keySet()
                AND Order.RecordType.DeveloperName = 'Purchase_Order'
                GROUP BY Product2Id, Order.nao__Inventory_Location__c
            ];
        }

        for (AggregateResult ar : arList) {
            String prodId = (String) ar.get('Product2Id');
            String warehouseId = (String) ar.get('locId');
            purchaseOrderProductTotalsMap.put(warehouseId + ';' + prodId, (Decimal) ar.get('totalQty'));
        }
        return purchaseOrderProductTotalsMap;
    }

    /**
    * @description Gets aggregate of GRN line totals
    * @param purchaseOrderLineMap
    * @return Map<String, Decimal>
    */
    public static Map<String, Decimal> getGrnLineProductTotals(Map<Id, List<OrderItem>> purchaseOrderLineMap) {
        Map<String, Decimal> grnLineProductTotalsMap = new Map<String, Decimal>();
        Set<String> orderProductIdSet = new Set<String>();
        List<AggregateResult> arList = new List<AggregateResult>();

        for (String key : purchaseOrderLineMap.keySet()) {
            for (OrderItem oi : purchaseOrderLineMap.get(key)) {
                orderProductIdSet.add(oi.Id);
            }
        }

        Date naoErpDate = getOrderDateSettings()?.nao__Ignore_Purchase_Orders_Before_Activation__c;

        if (naoErpDate != null) {
            arList = [
                SELECT nao__Product_bric__c prod, nao__Goods_Received_Notice_bric__r.nao__Order_bric__r.nao__Inventory_Location__c locId,
                       SUM(nao__Amount_Received__c) totalAmtRcvd
                FROM nao__Purchase_Order_Products_Received_bric__c
                WHERE nao__Order_Product_bric__c IN :orderProductIdSet
                AND nao__Goods_Received_Notice_bric__r.nao__Status__c = 'Completed'
                AND nao__Order_Product_bric__r.Order.ActivatedDate >= :naoErpDate
                GROUP BY nao__Product_bric__c, nao__Goods_Received_Notice_bric__r.nao__Order_bric__r.nao__Inventory_Location__c
            ];
        } else {
            arList = [
                SELECT nao__Product_bric__c prod, nao__Goods_Received_Notice_bric__r.nao__Order_bric__r.nao__Inventory_Location__c locId,
                       SUM(nao__Amount_Received__c) totalAmtRcvd
                FROM nao__Purchase_Order_Products_Received_bric__c
                WHERE nao__Order_Product_bric__c IN :orderProductIdSet
                AND nao__Goods_Received_Notice_bric__r.nao__Status__c = 'Completed'
                GROUP BY nao__Product_bric__c, nao__Goods_Received_Notice_bric__r.nao__Order_bric__r.nao__Inventory_Location__c
            ];
        }

        for (AggregateResult ar : arList) {
            String prodId = (String) ar.get('prod');
            String warehouseId = (String) ar.get('locId');
            grnLineProductTotalsMap.put(warehouseId + ';' + prodId, (Decimal) ar.get('totalAmtRcvd'));
        }
        return grnLineProductTotalsMap;
    }

    /**
    * @description Gets location product keys
    * @date Feb 20, 2024
    * @param completedOrderProductsMap
    * @param supplierProductsMap
    * @return Set<String>
    */
    public static Set<String> getLocStdProd(Map<Id, Set<String>> completedOrderProductsMap, Map<Id, Product2> supplierProductsMap) {
        Set<String> locStdProdSet = new Set<String>();
        for (Order o : (List<Order>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT nao__Inventory_Location__c, (SELECT Product2Id FROM OrderItems)
                FROM Order WHERE Id IN :completedOrderProductsMap.keySet()
            ]
        )) {
            if (!o.OrderItems.isEmpty()) {
                for (OrderItem oi : o.OrderItems) {
                    if (supplierProductsMap.containsKey(oi.Product2Id) && supplierProductsMap.get(oi.Product2Id) != null) {
                        String key = o.nao__Inventory_Location__c + ';' + supplierProductsMap.get(oi.Product2Id).Id;
                        locStdProdSet.add(key);
                    }
                }
            }
        }
        return locStdProdSet;
    }

    /**
    * @description Calculates total purchase orders for Products and Location Products
    * @param completedOrderProductsMap
    */
    public static void calcTotalPurchaseOrders(Map<Id, Set<String>> completedOrderProductsMap) {
        Map<Id, Decimal> standardProductsMap = getStdProdIdMap(completedOrderProductsMap);
        Map<Id, Decimal> supProdConvFactorMap = getSupProdConversionFactorMap(standardProductsMap);
        Map<Id, Product2> supplierProductsMap = getSupplierProductsMap(standardProductsMap);
        Map<Id, List<OrderItem>> purchaseOrderLineMap = getPurchaseOrderLineMap(supplierProductsMap);
        Map<String, Decimal> purchaseOrderProductTotalsMap = getPurchaseOrderProductTotals(supplierProductsMap);
        Map<String, Decimal> grnLineProductTotalsMap = getGrnLineProductTotals(purchaseOrderLineMap);

        Map<String, Decimal> openPurchaseOrderTotalMap = new Map<String, Decimal>();
        Map<String, Decimal> openPurchaseOrderTotalStdMap = new Map<String, Decimal>();
        List<nao__Location_Product__c> locProductToUpdate = new List<nao__Location_Product__c>();

        Map<String, Product2> standardProductMapToUpdate = new Map<String, Product2>(
            (List<Product2>) getSecuredAccessRecords(
                (List<sObject>) [
                    SELECT Id, nao__Total_Purchase_Orders__c
                    FROM Product2 WHERE Id IN :standardProductsMap.keySet()
                ]
            )
        );

        for (String key : purchaseOrderProductTotalsMap.keySet()) {
            Decimal purchaseOrderTotal = 0;
            if (grnLineProductTotalsMap.containsKey(key)) {
                purchaseOrderTotal = purchaseOrderProductTotalsMap.get(key) - grnLineProductTotalsMap.get(key);
                openPurchaseOrderTotalMap.put(key, purchaseOrderTotal);
            } else {
                purchaseOrderTotal = purchaseOrderProductTotalsMap.get(key);
                openPurchaseOrderTotalMap.put(key, purchaseOrderTotal);
            }
        }

        for (String key : openPurchaseOrderTotalMap.keySet()) {
            String warehouseId = key.split(';')[0];
            String prodId = key.split(';')[1];

            if (supplierProductsMap.containsKey(prodId) && supProdConvFactorMap.containsKey(prodId)) {
                Decimal conversionFactor = supProdConvFactorMap.get(prodId);
                Id standardProductId = supplierProductsMap.get(prodId)?.Id;

                if (conversionFactor != null && standardProductId != null) {
                    openPurchaseOrderTotalStdMap.put(warehouseId + ';' + standardProductId, openPurchaseOrderTotalMap.get(key) * conversionFactor);
                }
            }
        }

        Set<String> locStdProdSet = getLocStdProd(completedOrderProductsMap, supplierProductsMap);
        for (String key : locStdProdSet) {
            if (!openPurchaseOrderTotalStdMap.containsKey(key)) {
                openPurchaseOrderTotalStdMap.put(key, 0);
            }
        }

        Set<String> locProdKeySet = new Set<String>();
        if (!openPurchaseOrderTotalStdMap.keySet().isEmpty()) {
            locProdKeySet.addAll(openPurchaseOrderTotalStdMap.keySet());
        } else {
            locProdKeySet.addAll(openPurchaseOrderTotalMap.keySet());
        }

        for (nao__Location_Product__c locProd : (List<nao__Location_Product__c>) getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Product__c, nao__Total_Purchase_Orders__c, nao__Location_Product_Key_Bric__c
                FROM nao__Location_Product__c
                WHERE nao__Location_Product_Key_Bric__c IN :locProdKeySet
            ]
        )) {
            Decimal totalPO = !openPurchaseOrderTotalStdMap.isEmpty()
                ? openPurchaseOrderTotalStdMap.get(locProd.nao__Location_Product_Key_Bric__c)
                : openPurchaseOrderTotalMap.get(locProd.nao__Location_Product_Key_Bric__c);

            locProd.nao__Total_Purchase_Orders__c = totalPO;
            locProductToUpdate.add(locProd);

            if (standardProductMapToUpdate.containsKey(locProd.nao__Product__c)) {
                 standardProductMapToUpdate.get(locProd.nao__Product__c).nao__Total_Purchase_Orders__c = openPurchaseOrderTotalStdMap.get(locProd.nao__Location_Product_Key_Bric__c);
            }
        }

        try {
            SObjectAccessDecision decLpUpdate = Security.stripInaccessible(AccessType.UPDATABLE, locProductToUpdate);
            Database.update(decLpUpdate.getRecords());

            SObjectAccessDecision decProdUpdate = Security.stripInaccessible(AccessType.UPDATABLE, standardProductMapToUpdate.values());
            Database.update(decProdUpdate.getRecords());
        } catch (Exception e) {
            Utilities.createExceptionLog(e, 'ClipperSettingUtility: calcTotalPurchaseOrders');
        }
    }

    /**
    * @description Added reusable method to return records from SObjectAccessDecision function
    * @param sObjectList
    * @return securityDecision.getRecords
    */
    public static List<sObject> getSecuredAccessRecords(List<sObject> sObjectList) {
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, sObjectList);
        return (List<sObject>) securityDecision.getRecords();
    }
}