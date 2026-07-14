global class MYOB_ContactBatchSchedulable implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new MYOB_GetContactsBatch(''));
    }


}