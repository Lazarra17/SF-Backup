/**
* @description Trigger handler for AT_OrderItemTrigger
* @author Bricoleur Technologies
* [1] JPS 11-Apr-2025 Apply trigger handler framework to this class
* [2] JPS 11-Apr-2025 Add NAO Calculate Order tax logic
*/

@NamespaceAccessible
public with sharing class AT_OrderItemTriggerHandler extends TriggerHandlerNAO {

    //[1] JPS 11-Apr-2025 Apply trigger handler framework to this class
    //START
    private Map<Id, OrderItem> newOrderItemMap;
    private Map<Id, OrderItem> oldOrderItemMap;

    public AT_OrderItemTriggerHandler() {
        this.newOrderItemMap = (Map<Id, OrderItem>) Trigger.newMap;
        this.oldOrderItemMap = (Map<Id, OrderItem>) Trigger.oldMap;
    }

    /**
     * @description After Insert method for OrderItemTrigger
     */
    public override void afterInsert() {
        //[2] JPS 11-Apr-2025 Add NAO Calculate Order tax logic
        CalculateTaxPerLineHelper.calcOrderTotalTax(newOrderItemMap, oldOrderItemMap, false);
    }

    /**
     * @description After Update method for OrderItemTrigger
     */
    public override void afterUpdate() {
        //[2] JPS 11-Apr-2025 Add NAO Calculate Order tax logic
        CalculateTaxPerLineHelper.calcOrderTotalTax(newOrderItemMap, oldOrderItemMap, false);
    }

    /**
     * @description After Delete method for OrderItemTrigger
     */
    public override void afterDelete() {
        //[2] JPS 11-Apr-2025 Add NAO Calculate Order tax logic
        CalculateTaxPerLineHelper.calcOrderTotalTax(null, oldOrderItemMap, true);        
    }
    //END

    /** 
    public static final Id SALESORDERRECORDTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
    public static final Id PURCHASEORDERRECORDTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    public static final Id STOCKTRANSFERRECORDTYPEID = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Stock_Transfer').getRecordTypeId();
    
    
     * @description After Insert method for OrderItemTrigger
     * @param priorOrderItems
     * @param newOrderItems
     * @param newMapOrderItems
    */
    /*public static void onAfterInsert(List<OrderItem> priorOrderItems, List<OrderItem> newOrderItems, Map<Id,OrderItem> newMapOrderItems){     
        
        //createUpdateInventoryMovement(newOrderItems);
        //calculateAmounts(newOrderItems);
    }*/

    /** 
     * @description After Update method for OrderItemTrigger
     * @param priorOrderItems
     * @param newOrderItems
    */    
    /*public static void onAfterUpdate(List<OrderItem> priorOrderItems, List<OrderItem> newOrderItems){          
        
        //createUpdateInventoryMovement(newOrderItems);
        //calculateAmounts(newOrderItems);
    }*/
    
    /** 
     * @description After Delete method for OrderItemTrigger
     * @param priorOrderItems
    */
    /*public static void onAfterDelete(List<OrderItem> priorOrderItems){
        
        //calculateAmounts(priorOrderItems);
    }*/
     /*   
    public static void calculateAmounts(List<OrderItem> newOrderItems){
        
        Map<String,Location_Product__c> locationProductMap = new Map<String,Location_Product__c>();
        Map<String,Decimal> locationProductInStockMap = new Map<String,Decimal>();        
        Map<String,Decimal> locationProductSalesOrdersMap = new Map<String,Decimal>(); 
        Map<String,Set<Id>> locationProductSalesOrderIDsMap = new Map<String,Set<Id>>();      
        Map<String,Decimal> locationProductPurchaseOrdersMap = new Map<String,Decimal>(); 
        Map<String,Set<Id>> locationProductPurchaseOrderIDsMap = new Map<String,Set<Id>>();         
        Set<Id> prodIds = new Set<Id>();
        Set<Id> locIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        
        List<OrderItem> orderItemsToProcess = [SELECT Id, Order.Inventory_Location__c,Product2Id, OrderId, 
                                               Quantity,Order_Record_Type_bric__c
                                               FROM OrderItem
                                               WHERE Id IN: newOrderItems];   
        
        for(OrderItem ordItem : orderItemsToProcess){
            prodIds.add(ordItem.Product2Id);
            locIds.add(ordItem.Order.Inventory_Location__c);
        }
        
        for(Location_Product__c locProd : [SELECT Id, Location__c, Product__c FROM Location_Product__c
                                          WHERE Location__c IN: locIds AND Product__c IN: prodIds]){
            String key = locProd.Location__c + '-' + locProd.Product__c;
            locationProductMap.put(key,locProd);
        }
                
        //Calculate Total Sales Order field
        //(total number (amount) in orders linked to that Location (order line) where the order is a sales order
        List<OrderItem> orderItemList = [SELECT Id, Order.Inventory_Location__c,Product2Id, OrderId, Order_Record_Type_bric__c
                                         FROM OrderItem
                                         WHERE Order.Inventory_Location__c IN: locIDs AND Product2Id IN: prodIDs
                                        ];        
        
		for(OrderItem ordItem : orderItemList){
            String key = ordItem.Order.Inventory_Location__c + '-' + ordItem.Product2Id;
            
            //Add to Sales Orders
            if(ordItem.Order_Record_Type_bric__c == SALESORDERRECORDTYPEID){
                if(locationProductSalesOrderIDsMap.get(key) != null){
                    locationProductSalesOrderIDsMap.get(key).add(ordItem.OrderId);
                }else{
                    locationProductSalesOrderIDsMap.put(key,new Set<Id>{ordItem.OrderId});
                }
                
            //Add to Purchase Orders  
            }else if(ordItem.Order_Record_Type_bric__c == PURCHASEORDERRECORDTYPEID){
                if(locationProductPurchaseOrderIDsMap.get(key) != null){
                    locationProductPurchaseOrderIDsMap.get(key).add(ordItem.OrderId);
                }else{
                    locationProductPurchaseOrderIDsMap.put(key,new Set<Id>{ordItem.OrderId});
                }
            }
        }
        
        for(String locProdSalesOrderKey : locationProductSalesOrderIDsMap.keySet()){
            locationProductSalesOrdersMap.put(locProdSalesOrderKey, locationProductSalesOrderIDsMap.get(locProdSalesOrderKey).size());
        }
        
        //Calculate Total Purchase Orders
        //(total number (amount) in orders linked to that Location (order line) where the order is a purchase order
        
        for(String locProdPurchaseOrderKey : locationProductPurchaseOrderIDsMap.keySet()){
            locationProductPurchaseOrdersMap.put(locProdPurchaseOrderKey, locationProductPurchaseOrderIDsMap.get(locProdPurchaseOrderKey).size());
        }
                
        List<Location_Product__c> locProdToUpdateList = new  List<Location_Product__c>();
        
        for(OrderItem ordItem : orderItemsToProcess){
            Location_Product__c locProd = new Location_Product__c();
            String locProdKey = ordItem.Order.Inventory_Location__c +'-'+ ordItem.Product2Id;
            locProd.Id = locationProductMap.get(locProdKey)?.Id;
            locProd.Location__c = ordItem.Order.Inventory_Location__c;
            locProd.Product__c = ordItem.Product2Id;
            locProd.Total_Sales_Orders__c = locationProductSalesOrdersMap.get(locProdKey);
            locProd.Total_Purchase_Orders__c = locationProductPurchaseOrdersMap.get(locProdKey);
            locProdToUpdateList.add(locProd);
            
        }
        
		Database.upsert(locProdToUpdateList);   
    }
    */
    /*
    public static void createUpdateInventoryMovement(List<OrderItem> newOrderItems){
        
        List<OrderItem> orderItemsToProcess = [SELECT Id, Order.Inventory_Location__c,Product2Id, OrderId, 
                                               Quantity,Order_Record_Type_bric__c
                                               FROM OrderItem
                                               WHERE Id IN: newOrderItems]; 
        
        List<Inventory_Movement__c> invMovementList = [SELECT Id, As_At__c,Order__c,Order_Product__c,Movement__c,
                                                       Product__c,Location__c FROM Inventory_Movement__c
                                                       WHERE Order_Product__c IN: orderItemsToProcess
                                                       AND Order_Product__c != NULL];
        
        Map<Id,Inventory_Movement__c> invMovementToOrderProductMap = new  Map<Id,Inventory_Movement__c>();
        
        for(Inventory_Movement__c invMov : invMovementList){
            invMovementToOrderProductMap.put(invMov.Order_Product__c,invMov);
        }
        
        
        List<Inventory_Movement__c> invMovementListToUpsert = new List<Inventory_Movement__c>();
        for(OrderItem ordItem : orderItemsToProcess){
            Inventory_Movement__c inv = new Inventory_Movement__c();
            inv.Id = invMovementToOrderProductMap.get(ordItem.Id)?.Id;
            inv.As_At__c = DateTime.now();
            inv.Location__c = ordItem.Order.Inventory_Location__c;
            inv.Movement__c = ordItem.Quantity * -1;
            inv.Order__c = ordItem.OrderId;
            inv.Order_Product__c = ordItem.Id;
            inv.Product__c = ordItem.Product2Id;
            invMovementListToUpsert.add(inv);
        }

        system.debug('invMovementListToUpsert ' + invMovementListToUpsert);
        if(invMovementListToUpsert.size() > 0) Database.upsert(invMovementListToUpsert,false);
        
    }
	*/
}