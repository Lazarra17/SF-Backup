global class Batch_UpdateLastVisitOnAccount_Scheduler implements Schedulable {

    global void execute(SchedulableContext SC) {
        Batch_UpdateLastVisitOnAccount batch = new Batch_UpdateLastVisitOnAccount();
        Database.executeBatch(batch);
    }
}