@isTest
public class UpdateBudgetActualTest {
    @isTest
    static void testUpdateBudgetActual() {
        // Create a sample Club
        Club__c club = new Club__c(Name = 'Bodyfit Shellharbour');
        insert club;

        // Create Budget records
        Budget__c budget1 = new Budget__c(
            Club__c = club.Id,
            Month_Start_Date__c = Date.newInstance(2023, 1, 1),
            Month_End_Date__c = Date.newInstance(2023, 1, 31),
            Actual__c = 0
        );
        insert budget1;

        Budget__c budget2 = new Budget__c(
            Club__c = club.Id,
            Month_Start_Date__c = Date.newInstance(2023, 2, 1),
            Month_End_Date__c = Date.newInstance(2023, 2, 28),
            Actual__c = 0
        );
        insert budget2;

        // Create Payment History records
        Payment_History__c payment1 = new Payment_History__c(
            Club__c = club.Id,
            Payment_Date__c = DateTime.newInstance(2023, 1, 15, 12, 0, 0),
            Amount__c = 16.95
        );
        insert payment1;

        Payment_History__c payment2 = new Payment_History__c(
            Club__c = club.Id,
            Payment_Date__c = DateTime.newInstance(2023, 2, 15, 12, 0, 0),
            Amount__c = 20.00
        );
        insert payment2;

        // Validate Budget Actual values
        Budget__c updatedBudget1 = [SELECT Actual__c FROM Budget__c WHERE Id = :budget1.Id];
        Budget__c updatedBudget2 = [SELECT Actual__c FROM Budget__c WHERE Id = :budget2.Id];

        System.assertEquals(16.95, updatedBudget1.Actual__c, 'Budget1 Actual should be updated');
        System.assertEquals(20.00, updatedBudget2.Actual__c, 'Budget2 Actual should be updated');
    }
}