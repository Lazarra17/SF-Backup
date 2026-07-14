/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	April 22, 2022
 * Description: 	Schedulable Class for Retrieving Xero Items
 * Test Class: 		N/A
 * History: 		April 22, 2022 - Creation
 */

global class XeroGetItemBatchSchedulable implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        RunXeroGetItemBatch();
    }
    
    @AuraEnabled
    public static void RunXeroGetItemBatch(){
        XeroProductSyncSetting__c xeroProductSettings = XeroProductSyncSetting__c.getInstance('Default');
        XeroGetItemBatch batchObject = new XeroGetItemBatch();
        
        Integer batchSize = 200;
        if(xeroProductSettings?.Batch_Size__c > 0 && xeroProductSettings?.Batch_Size__c != null) batchSize = Integer.valueOf(xeroProductSettings?.Batch_Size__c);
        
        Id batchId = Database.executeBatch(batchObject, batchSize);
    }
    
}