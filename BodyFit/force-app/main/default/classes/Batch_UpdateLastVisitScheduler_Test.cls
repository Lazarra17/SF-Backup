@isTest
public class Batch_UpdateLastVisitScheduler_Test {

    @isTest
    static void testScheduleVaultReContactsBatch() {
        Test.startTest();
        String jobId = System.schedule('Update Account Every 35th Min', '0 0 0 * * ?', new Batch_UpdateLastVisitOnAccount_Scheduler());
        Test.stopTest();
    }
}