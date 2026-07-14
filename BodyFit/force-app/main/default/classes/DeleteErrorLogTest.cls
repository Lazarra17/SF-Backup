@isTest
public class DeleteErrorLogTest {
    
    @testSetup
    static void setupTestData() {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Error_Log__c log = new Error_Log__c(Name = 'Test Error Log ' + i);
            errorLogs.add(log);
        }
        insert errorLogs;

        for (Error_Log__c log : errorLogs) {
            Test.setCreatedDate(log.Id, Date.today().addDays(-31));
        }
    }
    
    @isTest
    static void testBatchExecution() {

        Test.startTest();
        DeleteErrorLog batchJob = new DeleteErrorLog();
        Database.executeBatch(batchJob);
        Test.stopTest();
    }
}