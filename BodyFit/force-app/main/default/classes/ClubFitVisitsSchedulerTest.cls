@isTest
private class ClubFitVisitsSchedulerTest { 
    @isTest
    static void testSchedulerJobScheduling() {
        // Define a CRON expression to schedule the job. (For testing, the exact timing is irrelevant.)
        String cronExp = '0 0 0 ? * * *';
        
        // Schedule the job.
        String jobId = System.schedule('Test_ClubFitVisitsSchedulerJob', cronExp, new ClubFitVisitsScheduler());
        
        // Verify that a job ID was returned, which means the job was scheduled.
        System.assertNotEquals(null, jobId, 'The scheduler job should be scheduled successfully.');
    }
}