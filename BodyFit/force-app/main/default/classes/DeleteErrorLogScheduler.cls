global class DeleteErrorLogScheduler implements Schedulable {

    global void execute(SchedulableContext SC) {
        DeleteErrorLog batchJob = new DeleteErrorLog();
        Database.executeBatch(batchJob);
    }
}