global class updateMemberNameOnPaymentBatchSchedular implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        updateMemberNameOnPaymentBatch batch = new updateMemberNameOnPaymentBatch();
        // Execute the batch
        Database.executeBatch(batch,1000);
    }
}