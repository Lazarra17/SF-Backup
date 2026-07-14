global class visitBatchScheduler  implements Schedulable {
     global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        visitBatch batch = new visitBatch();
        
        // Execute the batch
        Database.executeBatch(batch,1);
    }

}