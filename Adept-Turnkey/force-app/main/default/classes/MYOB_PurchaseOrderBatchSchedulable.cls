/*
* @Author: Bricoleur Technology
* @Date: May 25, 2026
* @Desc:
*
*/
global class MYOB_PurchaseOrderBatchSchedulable implements Schedulable{
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new MYOB_GetOrdersBatch(''));
    }
    
    
}