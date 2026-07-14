global class membershipBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        membershipBatch batch = new membershipBatch();
        
        // Execute the batch
        Database.executeBatch(batch,1);
    }

}