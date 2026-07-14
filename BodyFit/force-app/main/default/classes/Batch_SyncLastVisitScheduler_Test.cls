@isTest
public class Batch_SyncLastVisitScheduler_Test {

    @isTest
    static void testBatchSyncLastVisitOnMember() {
        Test.startTest();
        String jobId = System.schedule('Update Account Every 35th Min', '0 0 0 * * ?', new Batch_SyncLastVisitOnMemberScheduler());
        Test.stopTest();
    }
}