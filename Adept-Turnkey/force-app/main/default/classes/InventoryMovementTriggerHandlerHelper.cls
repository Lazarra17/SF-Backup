/**
 * @description Helper class for InventoryMovementTriggerHandler
 * @date Aug-19-2024
 * @author Bricoleur Technologies
 * [1] JP Sulit Oct-16-2024 - Added WITH SECURITY_ENFORCED keyword for every query clause
 * [2] JP Sulit Oct-16-2024 - Added Security.stripInaccessible for DMLs that has ApexCRUDViolation in code scan
 * [3] Chad Lazarra Oct-18-2024 - Removed WITH SECURITY_ENFORCED keyword for every query clause
 * [4] CLAZARRA Oct-31-2024 - Added reusable method to return records from SObjectAccessDecision function
 */
public with sharing class InventoryMovementTriggerHandlerHelper {

    /**
     * @description Executes calculateProductWeightedAverageCost & calculateInStockLocationProduct based on criteria
     * @param newInvMovements
     */
    public static void calculateProdWAStockLocation(List<nao__Inventory_Movement__c> newInvMovements) {
        Set<Id> productIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>();
        Set<Id> grnIds = new Set<Id>();
        Set<String> locProdKeys = new Set<String>();

        for (nao__Inventory_Movement__c inv : newInvMovements) {
            if (inv.nao__Product__c != NULL) {
                productIds.add(inv.nao__Product__c);
            }
            if (inv.nao__Location__c != NULL) {
                locIds.add(inv.nao__Location__c);
            }
            if (inv.nao__Product__c != NULL && inv.nao__Location__c != NULL) {
                locProdKeys.add(inv.nao__Location__c + '-' + inv.nao__Product__c);
            }
            if (inv.nao__Goods_Received_Notice_Line_Item__c != NULL) {
                grnIds.add(inv.nao__Goods_Received_Notice_Line_Item__c);
            }
        }

        if (grnIds.size() > 0) {
            calculateProductWeightedAverageCost(grnIds, productIds, newInvMovements, locIds);
        } else {
            calculateInStockLocationProduct(locIds, productIds, locProdKeys);
        }
    }

    /**
     * @description Calculates In Stock Location Product record
     * @param locIds
     * @param prodIds
     * @param locProdKeys
     */
    public static void calculateInStockLocationProduct(Set<Id> locIds, Set<Id> prodIds, Set<String> locProdKeys) {
        Map<String, nao__Location_Product__c> locationProductMap = new Map<String, nao__Location_Product__c>();
        Map<String, Decimal> locationProductInStockMap = new Map<String, Decimal>();
        Set<String> locProdKeysWithStocktake = new Set<String>();

        List<nao__Location_Product__c> locProductList = (List<nao__Location_Product__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>)[
                SELECT Id, nao__Location__c, nao__Product__c
                FROM nao__Location_Product__c
                WHERE nao__Location__c IN :locIds AND nao__Product__c IN :prodIds
            ]
        );

        for (nao__Location_Product__c locProd : locProductList) {
            String key = locProd.nao__Location__c + '-' + locProd.nao__Product__c;
            locationProductMap.put(key, locProd);
        }

        List<nao__Inventory_Movement__c> inventoryMovementList = (List<nao__Inventory_Movement__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>)[
                SELECT nao__Movement__c, nao__Product__c, nao__Location__c, nao__As_At__c, nao__Record_Type_Name_bric__c
                FROM nao__Inventory_Movement__c
                WHERE nao__Product__c != null
                AND nao__Location__c != null
                AND nao__Product__c IN :prodIds
                AND nao__Location__c IN :locIds
                ORDER BY nao__As_At__c DESC
            ]
        );

        for (nao__Inventory_Movement__c invMovement : inventoryMovementList) {
            String key = invMovement.nao__Location__c + '-' + invMovement.nao__Product__c;
            Decimal movementValue = invMovement.nao__Movement__c == null ? 0 : invMovement.nao__Movement__c;
            if (!locProdKeysWithStocktake.contains(key)) {
                if (invMovement.nao__Record_Type_Name_bric__c == 'Stocktake') {
                    locProdKeysWithStocktake.add(key);
                }

                if (locationProductInStockMap.get(key) != null) {
                    locationProductInStockMap.put(key, locationProductInStockMap.get(key) + movementValue);
                } else {
                    locationProductInStockMap.put(key, movementValue);
                }
            }
        }

        List<nao__Location_Product__c> locProdToUpdateList = new List<nao__Location_Product__c>();
        for (String locProdKey : locProdKeys) {
            nao__Location_Product__c locProd = new nao__Location_Product__c();
            locProd.Id = locationProductMap.get(locProdKey)?.Id;
            String[] locProdString = locProdKey.split('-');
            locProd.nao__Location__c = locProdString[0];
            locProd.nao__Product__c = locProdString[1];
            locProd.nao__In_Stock__c = locationProductInStockMap.get(locProdKey);
            locProdToUpdateList.add(locProd);
        }

        SObjectAccessDecision decLpUpsert = Security.stripInaccessible(AccessType.UPSERTABLE, locProdToUpdateList);
        List<Database.UpsertResult> dmlResults = Database.upsert(decLpUpsert.getRecords());

        for (Database.UpsertResult ur : dmlResults) {
            if (!ur.isSuccess()) {
                for (Database.Error err : ur.getErrors()) {
                    Utilities.createExceptionLog(null, err.getMessage() + ':::' + err.getFields());
                }
            }
        }

        calculateProductTotals(prodIds, locIds);
    }

    /**
     * @description Calculates Product Totals
     * @param productIds
     * @param locIds
     */
    public static void calculateProductTotals(Set<ID> productIds, Set<Id> locIds) {
        List<Product2> productList = (List<Product2>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>)[SELECT Id, nao__Weighted_Average_Cost__c, nao__Total_Stock__c FROM Product2 WHERE Id IN :productIds]
        );

        List<AggregateResult> totalInStockByProduct = [
            SELECT nao__Product__c, sum(nao__In_Stock__c) totalInStock
            FROM nao__Location_Product__c
            WHERE nao__Product__c IN :productIds
            GROUP BY nao__Product__c
        ];

        List<AggregateResult> totalAvailableByProduct = [
            SELECT nao__Product__c, sum(nao__Available_To_Promise__c) totalAvailable
            FROM nao__Location_Product__c
            WHERE nao__Product__c IN :productIds
            GROUP BY nao__Product__c
        ];

        Map<String, Decimal> sumByProductMap = new Map<String, Decimal>();
        Map<String, Decimal> sumAvailableByProductMap = new Map<String, Decimal>();
        Schema.DescribeFieldResult getLocProdField = nao__Location_Product__c.nao__Product__c.getDescribe();
        Schema.sObjectField locProdApiName = getLocProdField.getSObjectField();

        for (AggregateResult stock : totalInStockByProduct) {
            String prodId = '';
            if (stock.get(locProdApiName.toString()) != null) {
                prodId = (String) stock.get(locProdApiName.toString());
            }
            Decimal inStockTotal = 0;
            if (stock.get('totalInStock') != null && stock.get('totalInStock') != '') {
                inStockTotal = (Decimal) stock.get('totalInStock');
            }
            sumByProductMap.put(prodId, inStockTotal);
        }

        for (AggregateResult avail : totalAvailableByProduct) {
            String prodId = '';
            if (avail.get(locProdApiName.toString()) != null) {
                prodId = (String) avail.get(locProdApiName.toString());
            }
            Decimal availableTotal = 0;
            if (avail.get('totalAvailable') != null && avail.get('totalAvailable') != '') {
                availableTotal = (Decimal) avail.get('totalAvailable');
            }
            sumAvailableByProductMap.put(prodId, availableTotal);
        }

        for (Product2 prod : productList) {
            Decimal totalStock = 0;
            if (sumByProductMap.get(prod.Id) != null) {
                totalStock = sumByProductMap.get(prod.Id);
            }
            prod.nao__Total_Stock__c = totalStock;

            Decimal totalAvailable = 0;
            if (sumAvailableByProductMap.get(prod.Id) != null) {
                totalAvailable = sumAvailableByProductMap.get(prod.Id);
            }
            prod.nao__Total_Available__c = totalAvailable;
        }
        SObjectAccessDecision decProdUpdate = Security.stripInaccessible(AccessType.UPDATABLE, productList);
        Database.update(decProdUpdate.getRecords());
    }

    /**
     * @description Updates Weighted Average Cost
     * @param grnList
     * @param prodIds
     * @param newInvMovements
     * @param locIds
     */
    public static void calculateProductWeightedAverageCost(Set<Id> grnList, Set<Id> prodIds, List<nao__Inventory_Movement__c> newInvMovements, Set<Id> locIds) {
        List<Product2> standardProductList = (List<Product2>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>)[
                SELECT Id, Name, nao__Conversion_Factor__c, nao__Supplier_Product__c
                FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
            ]
        );

        List<nao__Product_Suppliers_bric__c> productSupplierList = (List<nao__Product_Suppliers_bric__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>)[
                SELECT Id, nao__Supplier_Product_bric__c, nao__Product_bric__c, nao__Conversion_Factor__c
                FROM nao__Product_Suppliers_bric__c
                WHERE nao__Supplier_Product_bric__c != NULL
                AND nao__Product_bric__c != NULL
                AND nao__Product_bric__c IN :prodIds
            ]
        );

        Map<Id, Product2> supplierTostandardProduct = new Map<Id, Product2>();
        Map<Id, Product2> standardProdMap = new Map<Id, Product2>();
        Map<Id, Decimal> supplierConvFactor = new Map<Id, Decimal>();

        for (Product2 stdProd : standardProductList) {
            standardProdMap.put(stdProd.Id, stdProd);
            if (stdProd.nao__Supplier_Product__c != null) {
                supplierTostandardProduct.put(stdProd.nao__Supplier_Product__c, stdProd);
                supplierConvFactor.put(stdProd.nao__Supplier_Product__c, stdProd.nao__Conversion_Factor__c);
            }
        }

        if (productSupplierList.size() > 0) {
            for (nao__Product_Suppliers_bric__c prodSup : productSupplierList) {
                if (supplierTostandardProduct.get(prodSup.nao__Supplier_Product_bric__c) == NULL) {
                    supplierTostandardProduct.put(prodSup.nao__Supplier_Product_bric__c, standardProdMap.get(prodSup.nao__Product_bric__c));
                    supplierConvFactor.put(prodSup.nao__Supplier_Product_bric__c, prodSup.nao__Conversion_Factor__c);
                }
            }
        }

        List<nao__Purchase_Order_Products_Received_bric__c> poprList = (List<nao__Purchase_Order_Products_Received_bric__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>)[
                SELECT Id, nao__Product_bric__c, nao__Last_Cost__c, nao__Amount_Received__c, nao__Order_Quantity__c,
                       nao__Goods_Received_Notice_bric__c, nao__Order_Product_bric__r.OrderId, nao__Order_Product_bric__c,
                       nao__Order_Product_bric__r.Order.nao__Inventory_Location__c, nao__Product_bric__r.RecordType.DeveloperName,
                       nao__Order_Product_bric__r.Order.RecordType.DeveloperName, nao__Product_bric__r.nao__Conversion_Factor__c,
                       nao__Order_Product_bric__r.Order.nao__Delivery_Location__c
                FROM nao__Purchase_Order_Products_Received_bric__c
                WHERE Id IN :grnList
            ]
        );
        List<Product2> productList = new List<Product2>();
        Map<Id, Product2> prodMap = new Map<Id, Product2>(
            (List<Product2>) ClipperSettingUtility.getSecuredAccessRecords(
                (List<sObject>)[SELECT Id, nao__Weighted_Average_Cost__c, nao__Total_Stock__c FROM Product2 WHERE Id IN :prodIds]
            )
        );
        Set<String> locProdKeys = new Set<String>();

        Map<Id, Id> grnLineItemToProduct = new Map<Id, Id>();
        for (nao__Inventory_Movement__c invMovement : newInvMovements) {
            if (invMovement.nao__Goods_Received_Notice_Line_Item__c != null) {
                grnLineItemToProduct.put(invMovement.nao__Goods_Received_Notice_Line_Item__c, invMovement.nao__Product__c);
            }
            if (invMovement.nao__Product__c != NULL && invMovement.nao__Location__c != NULL) {
                locProdKeys.add(invMovement.nao__Location__c + '-' + invMovement.nao__Product__c);
            }
        }

        Map<String, Boolean> rtToCalcWAC = new Map<String, Boolean>();
        List<nao__Clipper_Inventory_Setting__mdt> clipperSettingList = (List<nao__Clipper_Inventory_Setting__mdt>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>)[
                SELECT Id, nao__Calculate_Weighted_AverageCost__c, nao__Record_Type_Developer_Name__c
                FROM nao__Clipper_Inventory_Setting__mdt
            ]
        );
        for (nao__Clipper_Inventory_Setting__mdt clipperSetting : clipperSettingList) {
            rtToCalcWAC.put(clipperSetting.nao__Record_Type_Developer_Name__c, clipperSetting.nao__Calculate_Weighted_AverageCost__c);
        }
        System.debug('poprList sept 24 '+poprList);
System.debug('rtToCalcWAC sept 24 '+rtToCalcWAC);
        for (nao__Purchase_Order_Products_Received_bric__c poprItem : poprList) {
            Product2 prodItem = new Product2();
            prodItem.Id = grnLineItemToProduct.get(poprItem.Id);
            if (prodItem.Id != null) {
                Decimal weightedAvgCost = prodMap.get(prodItem.Id)?.nao__Weighted_Average_Cost__c == null ? 0 : prodMap.get(prodItem.Id)?.nao__Weighted_Average_Cost__c;
                Decimal totalStock = prodMap.get(prodItem.Id)?.nao__Total_Stock__c == null ? 0 : prodMap.get(prodItem.Id)?.nao__Total_Stock__c;
                Decimal convFactor = 1;

                if (supplierConvFactor.get(poprItem.nao__Product_bric__c) != null) {
                    convFactor = supplierConvFactor.get(poprItem.nao__Product_bric__c);
                }
                if (totalStock < 0) {
                    prodItem.nao__Weighted_Average_Cost__c = poprItem.nao__Last_Cost__c / convFactor;
                } else {
                    System.debug('poprItem.nao__Last_Cost__c sept 24 '+poprItem.nao__Last_Cost__c);
                    System.debug('poprItem.nao__Amount_Received__c sept 24 '+poprItem.nao__Amount_Received__c);
                    prodItem.nao__Weighted_Average_Cost__c =
                        ((weightedAvgCost * totalStock) + (poprItem.nao__Last_Cost__c * poprItem.nao__Amount_Received__c)) /
                        (totalStock + (poprItem.nao__Amount_Received__c * convFactor));
                }

System.debug('oprItem.nao__Order_Product_bric__r?.Order?.RecordType.DeveloperName sept 24 '+poprItem.nao__Order_Product_bric__r?.Order?.RecordType.DeveloperName);

                if (rtToCalcWAC.get(poprItem.nao__Order_Product_bric__r?.Order?.RecordType.DeveloperName)) {
                    productList.add(prodItem);
                }
            }
        }
        Map<Id, Product2> prodMapForUpdate = new Map<Id, Product2>();

        prodMapForUpdate.putall(productList);
        if (prodMapForUpdate.size() > 0) {
            update prodMapForUpdate.values();
        }

        calculateInStockLocationProduct(locIds, prodIds, locProdKeys);
    }
}