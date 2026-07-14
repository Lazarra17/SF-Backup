/*
* @Author: Bricoleur Technology
* @Date: June 19, 2026
* @Desc:
*
*/
global class MYOB_PaymentBatchSchedulable implements Schedulable {

    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new MYOB_GetPaymentsBatch(''));
    }

}
