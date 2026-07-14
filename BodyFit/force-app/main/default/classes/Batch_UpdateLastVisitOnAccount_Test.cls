@isTest
public class Batch_UpdateLastVisitOnAccount_Test {

    @testSetup
    static void setupTestData() {
        
        RecordType objRecordType = [SELECT Id FROM RecordType WHERE Name = 'Person Account'];
        
        Account objAccount = new Account();
        objAccount.FirstName = 'Test';
        objAccount.LastName = 'Account';
        objAccount.RecordTypeId = objRecordType.Id;
        insert objAccount;

        Visitation__c objVisitation1 = new Visitation__c();
        objVisitation1.Member__c = objAccount.Id;
        objVisitation1.Date_Time__c = DateTime.now().addDays(-1);
        insert objVisitation1;
        
        Visitation__c objVisitation2 = new Visitation__c();
        objVisitation2.Member__c = objAccount.Id;
        objVisitation2.Date_Time__c = DateTime.now().addDays(-2);
        insert objVisitation2;
    }

    @isTest
    static void testBatchExecution() {
        List<Account> accounts = [SELECT Id, Last_Visit__pc FROM Account];
        system.debug('accounts: ' + accounts);
        
        Test.startTest();
        Batch_UpdateLastVisitOnAccount batch = new Batch_UpdateLastVisitOnAccount();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}