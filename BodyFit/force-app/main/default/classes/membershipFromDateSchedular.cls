global class membershipFromDateSchedular  implements Schedulable {
     global void execute(SchedulableContext sc) {
        // Instantiate the batch class
        membershipUsingFromDateBatch batch = new membershipUsingFromDateBatch();
        
        // Execute the batch
        Database.executeBatch(batch,1);
    }

}