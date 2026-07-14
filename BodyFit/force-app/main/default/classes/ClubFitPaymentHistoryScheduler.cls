global class ClubFitPaymentHistoryScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Run the batch job; adjust batch size if needed.
        Database.executeBatch(new ClubFitPaymentHistoryBatch(), 1);
    }
}