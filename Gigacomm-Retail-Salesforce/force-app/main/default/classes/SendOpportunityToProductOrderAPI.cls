public class SendOpportunityToProductOrderAPI {
   
    // Invocable method to be called from Flow
    @InvocableMethod(label='Send Opportunity Data to Product Order API')
    public static void SendOpportunityToProductOrderAPI(List<Id> opportunityIds) {
        // Check if the list contains any Opportunity Ids
        if (!opportunityIds.isEmpty()) {
            // Enqueue the job to process the Opportunity
            SendOpportunityToGigaAPIQueueable job = new SendOpportunityToGigaAPIQueueable(opportunityIds);
            System.enqueueJob(job);
        }
    }
}