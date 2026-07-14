@isTest
public class UpdateBudgetNewMembersTest {
    @isTest
    static void testUpdateNewMembers() {
        // Create a Club record (referenced by AssociatedClub__c)
        Club__c testClub = new Club__c(Name = 'Bodyfit Shellharbour');
        insert testClub;
        System.debug('Created Club: ' + testClub);

        // Create a Budget for the club
        Budget__c testBudget = new Budget__c(
            Club__c = testClub.Id, // Link to the Club via the lookup
            Month_Start_Date__c = Date.newInstance(2023, 1, 1),
            Month_End_Date__c = Date.newInstance(2023, 1, 31),
            New_Member__c = 0
        );
        insert testBudget;
        System.debug('Created Budget: ' + testBudget);

        // Insert a Person Account (Member) within the budget's timeframe
        Account member1 = new Account(
            LastName = 'Doe', // Required for Person Accounts
            AssociatedClub__c = testClub.Id, // Link to the Club via the lookup
            Start_Date__pc = Date.newInstance(2023, 1, 15) // Relevant for logic
        );
        insert member1;
        System.debug('Inserted Account (Member1): ' + member1);

        // Insert another Person Account (Member) within the budget's timeframe
        Account member2 = new Account(
            LastName = 'Smith', // Required for Person Accounts
            AssociatedClub__c = testClub.Id, // Link to the Club via the lookup
            Start_Date__pc = Date.newInstance(2023, 1, 20) // Relevant for logic
        );
        insert member2;
        System.debug('Inserted Account (Member2): ' + member2);

        // Insert an Account (Member) outside the budget's timeframe
        Account member3 = new Account(
            LastName = 'Brown', // Required for Person Accounts
            AssociatedClub__c = testClub.Id, // Link to the Club via the lookup
            Start_Date__pc = Date.newInstance(2023, 2, 1) // Outside budget range
        );
        insert member3;
        System.debug('Inserted Account (Member3): ' + member3);

        // Query the updated budget to validate New_Member__c field
        Budget__c updatedBudget = [SELECT New_Member__c FROM Budget__c WHERE Id = :testBudget.Id];
        System.debug('Updated Budget: ' + updatedBudget);

        // Validate the New_Member__c field
        System.assertEquals(2, updatedBudget.New_Member__c, 'New Members count should be 2');
    }
}