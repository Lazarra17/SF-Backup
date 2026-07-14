@isTest
public class ClubfitMembersSchedulerTest {
    
    

    static testMethod void testExecuteAndScheduleNextRun() {
        // ## 1. Setup Test Data

        // Create a test club record
        Club__c testClub = new Club__c(
            Name = 'Test Club One'
        );
        insert testClub;
        
        Clubfit_API_Settings__c clubfitApi = new Clubfit_API_Settings__c(
            Name = 'test',
            Last_Sync_DateTime__c = system.now(),
            Members_Last_Sync_DateTime__c = system.now(),
            Active__c = true
        );
        
        insert clubfitApi;

        // Create a test API Key record associated with the club name
        APIKeys__c testKey = new APIKeys__c(
            Name = 'API Key',
            Club__c = testClub.Name, // Match the Name field for the map lookup
            Key__c = 'TEST_API_KEY_123'
        );
        
        insert testKey;

        // ## 2. Execute the Test

        // Start the test context (limits reset, no calls to external systems)
        Test.startTest();

        // Instantiate the scheduler class
        ClubfitMembersScheduler scheduler = new ClubfitMembersScheduler();

        // 1. Test the 'execute' method logic
        String cron = '0 0 0 1 1 ? 2099'; // Dummy cron to run immediately
        System.schedule('Test Clubfit Prospects Run', cron, scheduler);

        // 2. Test the 'scheduleNextRun' logic which is called inside 'execute'
        // Call the 'execute' method directly for a more focused test of its logic
        scheduler.execute(null);

        // Stop the test context (triggers all asynchronous processes, like the scheduled job)
        Test.stopTest();


    }

    // --- Helper Method Test ---

    
    static testMethod void testGetCronExpression() {
        // Start the test context
        Test.startTest();

        // Define a specific datetime for deterministic testing
        Datetime testDt = Datetime.newInstance(2025, 12, 10, 15, 30, 45); // 15:30:45 on Dec 10, 2025

        // Call the static method
        String cronExpression = ClubfitMembersScheduler.getCronExpression(testDt);

        // Stop the test context
        Test.stopTest();

        // Expected CRON format: Seconds Minutes Hours Day Month ? Year
        // Expected: 45 30 15 10 12 ? 2025
        String expectedCron = '45 30 15 10 12 ? 2025';

        // Assert the result
        System.assertEquals(expectedCron, cronExpression, 'The generated CRON expression should match the expected format.');
    }

}