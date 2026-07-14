/**
* @description Utility Class for GoodsReceivedNoticeTriggerHandler
* @author Bricoleur Technologies
* [1] JP Sulit Oct-16-2024 - Added WITH SECURITY_ENFORCED keyword for every query clause
* [2] JP Sulit Oct-16-2024 - Added Security.stripInaccessible for DMLs that has ApexCRUDViolation in code scan
* [3] Chad Lazarra Oct-18-2024 - Removed WITH SECURITY_ENFORCED keyword for every query clause
* [4] CLAZARRA Oct-31-2024 - Added reusable method to return records from SObjectAccessDecision function
*/
public with sharing class GoodsReceivedNoticeTriggerHandlerHelper {

    public static final Id STOCKTRANSFERRECORDTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get(ClipperSettingUtility.getStockTransferRecordTypeDevName()).getRecordTypeId();

    /**
    * @description Upserts Inventory Movement record
    * @param grnList
    */
    public static void createUpdateInventoryMovement(List<nao__Goods_Received_Notice_bric__c> grnList) {
        List<nao__Purchase_Order_Products_Received_bric__c> poprList = (List<nao__Purchase_Order_Products_Received_bric__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Product_bric__c, nao__Last_Cost__c, nao__Amount_Received__c, nao__Order_Quantity__c,
                       nao__Goods_Received_Notice_bric__c, nao__Order_Product_bric__r.OrderId, nao__Order_Product_bric__c,
                       nao__Order_Product_bric__r.Order.nao__Inventory_Location__c, nao__Product_bric__r.RecordType.DeveloperName,
                       nao__Order_Product_bric__r.Order.nao__Delivery_Location__c, nao__Product_bric__r.nao__Inventory_Status__c,
                       nao__Order_Product_bric__r.Order.RecordTypeId, nao__Product_bric__r.nao__Conversion_Factor__c
                FROM nao__Purchase_Order_Products_Received_bric__c
                WHERE nao__Goods_Received_Notice_bric__c IN :grnList
                AND nao__Amount_Received__c > 0
                AND nao__Product_bric__r.nao__Inventory_Status__c != 'Non-Stock Item'
            ]
        );

        System.debug('jp bric poprList '+poprList);

        List<String> orderItemIds = new List<String>();
        List<String> prodIds = new List<String>();

        for (nao__Purchase_Order_Products_Received_bric__c popRec : poprList) {
            if (popRec.nao__Product_bric__c != null) {
                prodIds.add(popRec.nao__Product_bric__c);
            }
        }

        System.debug('jp bric prodIds '+prodIds);

        List<nao__Inventory_Movement__c> invMovementList = (List<nao__Inventory_Movement__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__As_At__c, nao__Order__c, nao__Goods_Received_Notice_Line_Item__c,
                       nao__Movement__c, nao__Product__c, nao__Location__c
                FROM nao__Inventory_Movement__c
                WHERE nao__Goods_Received_Notice_Line_Item__c IN :poprList
                AND nao__Goods_Received_Notice_Line_Item__c != NULL
            ]
        );

        System.debug('jp bric invMovementList '+invMovementList);

        List<Product2> standardProductList = (List<Product2>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, Name, nao__Conversion_Factor__c, nao__Supplier_Product__c
                FROM Product2
                WHERE RecordType.DeveloperName = 'Standard'
            ]
        );

        System.debug('jp bric standardProductList '+standardProductList);

        List<nao__Product_Suppliers_bric__c> productSupplierList = (List<nao__Product_Suppliers_bric__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Supplier_Product_bric__c, nao__Product_bric__c, nao__Conversion_Factor__c
                FROM nao__Product_Suppliers_bric__c
                WHERE nao__Supplier_Product_bric__c != NULL
                AND nao__Product_bric__c != NULL
                AND nao__Supplier_Product_bric__c IN :prodIds
            ]
        );

        System.debug('jp bric productSupplierList '+productSupplierList);

        Map<Id, Product2> supplierToStandardProduct = new Map<Id, Product2>();
        Map<Id, Product2> standardProdMap = new Map<Id, Product2>();
        Map<Id, Decimal> supplierConvFactor = new Map<Id, Decimal>();

        for (Product2 stdProd : standardProductList) {
            standardProdMap.put(stdProd.Id, stdProd);
            if (stdProd.nao__Supplier_Product__c != null) {
                supplierToStandardProduct.put(stdProd.nao__Supplier_Product__c, stdProd);
                supplierConvFactor.put(stdProd.nao__Supplier_Product__c, stdProd.nao__Conversion_Factor__c);
            }
        }

        System.debug('jp bric supplierToStandardProduct '+supplierToStandardProduct);
        System.debug('jp bric supplierConvFactor '+supplierConvFactor);

        if (!productSupplierList.isEmpty()) {
            for (nao__Product_Suppliers_bric__c prodSup : productSupplierList) {
                if (supplierToStandardProduct.get(prodSup.nao__Supplier_Product_bric__c) == NULL) {
                    supplierToStandardProduct.put(prodSup.nao__Supplier_Product_bric__c, standardProdMap.get(prodSup.nao__Product_bric__c));
                    supplierConvFactor.put(prodSup.nao__Supplier_Product_bric__c, prodSup.nao__Conversion_Factor__c);
                }
            }
        }

        System.debug('jp bric supplierToStandardProduct '+supplierToStandardProduct);
        System.debug('jp bric supplierConvFactor '+supplierConvFactor);

        Map<Id, nao__Inventory_Movement__c> invMovementToGRNLineMap = new Map<Id, nao__Inventory_Movement__c>();
        for (nao__Inventory_Movement__c invMov : invMovementList) {
            invMovementToGRNLineMap.put(invMov.nao__Goods_Received_Notice_Line_Item__c, invMov);
        }

        System.debug('jp bric invMovementToGRNLineMap '+invMovementToGRNLineMap);

        List<nao__Inventory_Movement__c> invMovementListToUpsert = new List<nao__Inventory_Movement__c>();
        for (nao__Purchase_Order_Products_Received_bric__c poprItem : poprList) {
            if (poprItem.nao__Order_Product_bric__c != null) {
                orderItemIds.add(poprItem.nao__Order_Product_bric__c);
            }

            Id locationId;
            if (poprItem.nao__Order_Product_bric__r.Order.RecordTypeId == STOCKTRANSFERRECORDTYPEID) {
                locationId = poprItem.nao__Order_Product_bric__r.Order.nao__Delivery_Location__c;
            } else {
                locationId = poprItem.nao__Order_Product_bric__r.Order.nao__Inventory_Location__c;
            }

            if (poprItem.nao__Product_bric__r.RecordType.DeveloperName == 'Supplier_Product') {
                if (supplierToStandardProduct.get(poprItem.nao__Product_bric__c) != NULL) {
                    nao__Inventory_Movement__c supInv = new nao__Inventory_Movement__c();
                    supInv.Id = invMovementToGRNLineMap.get(poprItem.Id)?.Id;
                    supInv.nao__As_At__c = DateTime.now();
                    supInv.nao__Location__c = locationId;

                    Decimal convFactor = supplierConvFactor.get(poprItem.nao__Product_bric__c) != null ? supplierConvFactor.get(poprItem.nao__Product_bric__c) : 1;
                    supInv.nao__Movement__c = poprItem.nao__Amount_Received__c * convFactor;
                    supInv.nao__Order__c = poprItem.nao__Order_Product_bric__r.OrderId;
                    supInv.nao__Order_Product__c = poprItem.nao__Order_Product_bric__c;
                    supInv.nao__Product__c = supplierToStandardProduct.get(poprItem.nao__Product_bric__c)?.Id;
                    supInv.nao__Goods_Received_Notice_Line_Item__c = poprItem.Id;
                    invMovementListToUpsert.add(supInv);
                }
            } else {
                nao__Inventory_Movement__c supInv = new nao__Inventory_Movement__c();
                supInv.Id = invMovementToGRNLineMap.get(poprItem.Id)?.Id;
                supInv.nao__As_At__c = DateTime.now();
                supInv.nao__Location__c = locationId;
                
                Decimal convFactor = poprItem.nao__Product_bric__r?.nao__Conversion_Factor__c != null ? poprItem.nao__Product_bric__r.nao__Conversion_Factor__c : 1;
                supInv.nao__Movement__c = poprItem.nao__Amount_Received__c * convFactor;
                supInv.nao__Order__c = poprItem.nao__Order_Product_bric__r.OrderId;
                supInv.nao__Order_Product__c = poprItem.nao__Order_Product_bric__c;
                supInv.nao__Product__c = poprItem.nao__Product_bric__c;
                supInv.nao__Goods_Received_Notice_Line_Item__c = poprItem.Id;
                invMovementListToUpsert.add(supInv);
            }
        }

        System.debug('jp bric invMovementListToUpsert '+invMovementListToUpsert);

        try {
            if (!invMovementListToUpsert.isEmpty()) {
                SObjectAccessDecision decInvUpsert = Security.stripInaccessible(AccessType.UPSERTABLE, invMovementListToUpsert);
                //Database.upsert(decInvUpsert.getRecords());
                // Your existing code to get the records to upsert
                List<nao__Inventory_Movement__c> recordsToUpsert = decInvUpsert.getRecords();

                // Check if there are records to process
                if (!recordsToUpsert.isEmpty()) {

                    // Perform the upsert with partial success allowed (allOrNone = false)
                    Database.UpsertResult[] results = Database.upsert(recordsToUpsert, false);

                    // Iterate through the results to find any errors 👨‍💻
                    for (Integer i = 0; i < results.size(); i++) {
                        if (!results[i].isSuccess()) {
                            // This record failed
                            System.debug('Error updating record at index ' + i + ':');

                            // Get the list of errors for this failed record
                            for (Database.Error err : results[i].getErrors()) {
                                // Log the error status code and message
                                System.debug('  Status Code: ' + err.getStatusCode());
                                System.debug('  Error Message: ' + err.getMessage());
                                
                                // You can also see which fields were affected
                                System.debug('  Affected Fields: ' + String.join(err.getFields(), ', '));
                            }

                            // You can also get the original record that failed
                            nao__Inventory_Movement__c failedRecord = recordsToUpsert[i];
                            System.debug('  Failed Record Details: ' + failedRecord);
                        }
                    }
                }
            }
            if (!orderItemIds.isEmpty()) {
                calculateAmountReceived(orderItemIds);
            }
        } catch (Exception e) {
            Utilities.createExceptionLog(e, 'GoodsReceivedNoticeTriggerHandler');
        }
    }

    /**
    * @description UPDATE Amount Received value on Order Product Record
    * @param orderItemIds
    */
    public static void calculateAmountReceived(List<String> orderItemIds) {
        List<OrderItem> ordItemList = new List<OrderItem>();
        List<nao__Purchase_Order_Products_Received_bric__c> poprList = (List<nao__Purchase_Order_Products_Received_bric__c>) ClipperSettingUtility.getSecuredAccessRecords(
            (List<sObject>) [
                SELECT Id, nao__Product_bric__c, nao__Last_Cost__c, nao__Amount_Received__c, nao__Order_Quantity__c,
                       nao__Goods_Received_Notice_bric__c, nao__Order_Product_bric__r.OrderId, nao__Order_Product_bric__c,
                       nao__Order_Product_bric__r.Order.nao__Inventory_Location__c, nao__Product_bric__r.RecordType.DeveloperName,
                       nao__Product_bric__r.nao__Conversion_Factor__c
                FROM nao__Purchase_Order_Products_Received_bric__c
                WHERE nao__Order_Product_bric__c IN :orderItemIds
                AND nao__Amount_Received__c > 0
            ]
        );

        Map<String, Decimal> ordProdReceived = new Map<String, Decimal>();
        for (nao__Purchase_Order_Products_Received_bric__c popRec : poprList) {
            if (popRec.nao__Order_Product_bric__c != null) {
                if (ordProdReceived.get(popRec.nao__Order_Product_bric__c) == NULL) {
                    ordProdReceived.put(popRec.nao__Order_Product_bric__c, popRec.nao__Amount_Received__c);
                } else {
                    Decimal amtRcvd = ordProdReceived.get(popRec.nao__Order_Product_bric__c);
                    amtRcvd += popRec.nao__Amount_Received__c;
                    ordProdReceived.put(popRec.nao__Order_Product_bric__c, amtRcvd);
                }
            }
        }

        for (String ordItemID : ordProdReceived.keySet()) {
            OrderItem ordItem = new OrderItem(
                Id = ordItemID,
                nao__Amount_Received__c = ordProdReceived.get(ordItemID)
            );
            ordItemList.add(ordItem);
        }

        try {
            if (!ordItemList.isEmpty()) {
                SObjectAccessDecision decOiUpsert = Security.stripInaccessible(AccessType.UPSERTABLE, ordItemList);
                Database.upsert(decOiUpsert.getRecords());
            }
        } catch (Exception e) {
            Utilities.createExceptionLog(e, 'GoodsReceivedNoticeTriggerHandler: calculateAmountReceived');
        }
    }
}