/*
* Author: 			Bricoleur Technologies
* Created Date: 	August 3, 2021
* Description: 	Schedulable Class for Retrieving Xero Quotes
* Test Class: 		N/A
* History: 		August 3, 2021 - Creation
*/
global class XeroGetQuoteBatchSchedulable implements Schedulable {
    
    
    global void execute(SchedulableContext ctx) {
        XeroGetQuoteBatch batchObject = new XeroGetQuoteBatch();
        Id batchId = Database.executeBatch(batchObject, 100);
    }
}