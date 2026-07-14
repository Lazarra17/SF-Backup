global class paymentBatchScheduler  implements Schedulable {
     global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        paymentHistoryBatch batch = new paymentHistoryBatch();
        
        // Execute the batch
        Database.executeBatch(batch,1);
    }

}