/*
* @Author: Bricoleur Technology
* @Date: March 5, 2026
* @Desc:
*
*/
global class MYOB_InvoiceBatchSchedulable implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new MYOB_GetInvoicesBatch(''));
    }


}