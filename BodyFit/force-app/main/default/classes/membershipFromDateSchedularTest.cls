@isTest
public class membershipFromDateSchedularTest {
    
  @isTest
    static void testSchedulerExecution() {
       // Set up mock response
        Test.setMock(HttpCalloutMock.class, new MemberMockHttpResponseGenerator());

        // Create test APIKey record
        APIKeys__c apiKey = new APIKeys__c(
            Name = 'Test',
            Club__c = 'Fitness Club',
            Key__c = 'dummyAPIKey',
            Membership_Offset__c = 0,
            Membership_limit__c = 100
        );
        insert apiKey;

        // Create test record type for PersonAccount
        RecordType personAccountType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];

        // Schedule the batch job
        Test.startTest();
        // Schedule the job to run in the future (sample cron expression)
        String cronExp = '0 0 0 31 12 ? 2025';
        System.schedule('Test Membership Batch Job', cronExp, new membershipFromDateSchedular());
        Test.stopTest();
        
       
    }
}