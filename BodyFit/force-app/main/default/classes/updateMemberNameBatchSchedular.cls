global class updateMemberNameBatchSchedular implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        updateMemberNameBatch batch = new updateMemberNameBatch();
        // Execute the batch
        Database.executeBatch(batch,1000);
    }
}