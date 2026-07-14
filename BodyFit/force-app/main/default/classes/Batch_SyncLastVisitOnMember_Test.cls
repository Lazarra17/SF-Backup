@isTest
public class Batch_SyncLastVisitOnMember_Test {

    @testSetup
    static void setupTestData() {
        
        RecordType objRecordType = [SELECT Id FROM RecordType WHERE Name = 'Person Account'];
        
        Account objAccount = new Account();
        objAccount.FirstName = 'Test';
        objAccount.LastName = 'Account';
        objAccount.RecordTypeId = objRecordType.Id;
        insert objAccount;
        
        Club__c club = new Club__c(Name = 'Bodyfit Shellharbour');
        insert club;

        Visitation__c objVisitation1 = new Visitation__c();
        objVisitation1.Member__c = objAccount.Id;
        objVisitation1.Date_Time__c = DateTime.now().addDays(-1);
        objVisitation1.Club__c = club.Id;
        insert objVisitation1;
        Test.setCreatedDate(objVisitation1.Id, Date.today().addDays(-1));
        
        Visitation__c objVisitation2 = new Visitation__c();
        objVisitation2.Member__c = objAccount.Id;
        objVisitation2.Date_Time__c = DateTime.now().addHours(-1);
        objVisitation2.Club__c = club.Id;
        insert objVisitation2;

        Budget__c budget = new Budget__c(
            Club__c = club.Id,
            Month_Start_Date__c = Date.newInstance(2024, 12, 1),
            Month_End_Date__c = Date.newInstance(2025, 2, 1),
            Total_Visitations__c = 0
        );
        insert budget;
    }

    @isTest
    static void testBatchExecution() {
        List<Account> accounts = [SELECT Id, Last_Visit__pc FROM Account];
        List<Club__c> clubs = [SELECT Id FROM Club__c];
        List<Budget__c> budgets = [SELECT Id, Club__c, Month_Start_Date__c, Month_End_Date__c, Total_Visitations__c FROM Budget__c];
        List<Visitation__c> visitation = [SELECT Id, Date_Time__c, Member__c FROM Visitation__c];
        
        Test.startTest();
        Batch_SyncLastVisitOnMember batch = new Batch_SyncLastVisitOnMember();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}