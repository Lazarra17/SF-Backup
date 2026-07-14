/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	September 28, 2022
 * Description: 	Schedulable Class for Retrieving Xero PO
 * Test Class: 		N/A
 * History: 		September 28, 2022 - Creation
 */

global class XeroGetPurchaseOrderBatchSchedulable implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        RunXeroGetPOBatch();
    }
    
    @AuraEnabled
    public static void RunXeroGetPOBatch(){
        XeroPurchaseOrderSyncSetting__c xeroPurchaseOrderSettings = XeroPurchaseOrderSyncSetting__c.getOrgDefaults();
        XeroGetPurchaseOrderBatch batchObject = new XeroGetPurchaseOrderBatch();
        
        Integer batchSize = 200;
        if(xeroPurchaseOrderSettings?.Batch_Size__c > 0 && xeroPurchaseOrderSettings?.Batch_Size__c != null) batchSize = Integer.valueOf(xeroPurchaseOrderSettings?.Batch_Size__c);
        
        Id batchId = Database.executeBatch(batchObject, batchSize);
    }
    
}