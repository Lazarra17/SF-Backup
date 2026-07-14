@isTest
public class paymentBatchSchedulerTest { 
     @isTest
    static void testVisitSchedulerExecution() {
       // Set up mock response
        Test.setMock(HttpCalloutMock.class, new paymentMockHttpResponseGenerator());

        // Create test APIKey record
        APIKeys__c apiKey = new APIKeys__c(
            Name = 'Test',
            Club__c = 'Fitness Club',
            Key__c = 'dummyAPIKey',
            Payment_Offset__c = 0,
            Payment_Limit__c = 500
        );
        insert apiKey;
       
        // Schedule the batch job
        Test.startTest();
        // Schedule the job to run in the future (sample cron expression)
        String cronExp = '0 0 0 31 12 ? 2024';
        System.schedule('Test Visit Batch Job', cronExp, new paymentBatchScheduler());
        Test.stopTest();
    }
}