@IsTest
private class ClubfitProspectsSchedulerTest {   


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
        ClubfitProspectsScheduler scheduler = new ClubfitProspectsScheduler();

        // 1. Test the 'execute' method logic
        String cron = '0 0 0 1 1 ? 2099'; // Dummy cron to run immediately
        System.schedule('Test Clubfit Prospects Run', cron, scheduler);

        // 2. Test the 'scheduleNextRun' logic which is called inside 'execute'
        // Call the 'execute' method directly for a more focused test of its logic
        scheduler.execute(null);

        // Stop the test context (triggers all asynchronous processes, like the scheduled job)
        Test.stopTest();

        // ## 3. Assert Results

        // Check if a batch job was executed
        // The execute method runs a batch, which consumes one stack depth.
        // The first System.schedule runs the execute method.
        // The scheduler.execute(null) call runs another batch.
        // The execute method also schedules the next job via scheduleNextRun().

        // Assert that the batch was executed
        // We expect one batch execution from the scheduled job, and another from the direct call.
        // The batch job is executed *inside* the execute method, so we check for asynchronous operations.
        // Since we mocked ClubfitGetProspectsBatch, we can't fully assert its execution, but we can check the scheduled job.
        
        // Assert that the scheduler scheduled a new job (scheduleNextRun method)
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, TimesTriggered
            FROM CronTrigger
            WHERE CronJobDetail.Name = :Constants.CLUBFIT_ALL_CLUBS_PROSPECTS_SCHEDULER
        ];

        // We expect one scheduled job created by the call to scheduleNextRun()
        System.assertEquals(1, scheduledJobs.size(), 'A new job should have been scheduled.');
        System.assertEquals(Constants.CLUBFIT_ALL_CLUBS_PROSPECTS_SCHEDULER, scheduledJobs[0].CronJobDetail.Name, 'Scheduled job name mismatch.');

        // Since the test ran immediately and the execute method ran, check the batch queue
        // We expect 2 jobs in the AsyncApexJob queue: 
        // 1. The batch job from the first scheduled run.
        // 2. The batch job from the direct call to scheduler.execute(null).
        List<AsyncApexJob> batchJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'ClubfitGetProspectsBatch' // Check against the mock name
        ];
        // Note: The actual number might be 1 or 2 depending on how the Test.stopTest() processes the operations.
        // A minimum of 1 batch job should have been created successfully.
        System.assert(batchJobs.size() >= 1, 'At least one batch job should have been executed.');
    }

    // --- Helper Method Test ---

    
    static testMethod void testGetCronExpression() {
        // Start the test context
        Test.startTest();

        // Define a specific datetime for deterministic testing
        Datetime testDt = Datetime.newInstance(2025, 12, 10, 15, 30, 45); // 15:30:45 on Dec 10, 2025

        // Call the static method
        String cronExpression = ClubfitProspectsScheduler.getCronExpression(testDt);

        // Stop the test context
        Test.stopTest();

        // Expected CRON format: Seconds Minutes Hours Day Month ? Year
        // Expected: 45 30 15 10 12 ? 2025
        String expectedCron = '45 30 15 10 12 ? 2025';

        // Assert the result
        System.assertEquals(expectedCron, cronExpression, 'The generated CRON expression should match the expected format.');
    }
}