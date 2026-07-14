@isTest
public class UpdateBudgetTotalVisitationsTest {
    @isTest
    static void testUpdateTotalVisitations() {
        // Create a Club
        Club__c club = new Club__c(Name = 'Bodyfit Shellharbour');
        insert club;
        System.debug('Created Club: ' + club);

        // Create a Budget for the club
        Budget__c budget = new Budget__c(
            Club__c = club.Id,
            Month_Start_Date__c = Date.newInstance(2023, 1, 1),
            Month_End_Date__c = Date.newInstance(2023, 1, 31),
            Total_Visitations__c = 0
        );
        insert budget;
        System.debug('Created Budget: ' + budget);

        // Insert a Visitation within the budget's timeframe
        Visitation__c visitation1 = new Visitation__c(
            Club__c = club.Id,
            Date_Time__c = DateTime.newInstance(2023, 1, 15, 10, 0, 0) // Within budget's date range
        );
        insert visitation1;
        System.debug('Inserted Visitation (1): ' + visitation1);

        // Insert another Visitation within the budget's timeframe
        Visitation__c visitation2 = new Visitation__c(
            Club__c = club.Id,
            Date_Time__c = DateTime.newInstance(2023, 1, 20, 12, 0, 0) // Within budget's date range
        );
        insert visitation2;
        System.debug('Inserted Visitation (2): ' + visitation2);

        // Insert a Visitation outside the budget's timeframe
        Visitation__c visitation3 = new Visitation__c(
            Club__c = club.Id,
            Date_Time__c = DateTime.newInstance(2023, 2, 1, 9, 0, 0) // Outside budget's date range
        );
        insert visitation3;
        System.debug('Inserted Visitation (3): ' + visitation3);

        // Query the updated budget
        Budget__c updatedBudget = [SELECT Total_Visitations__c FROM Budget__c WHERE Id = :budget.Id];
        System.debug('Updated Budget: ' + updatedBudget);

        // Validate the Total_Visitations__c field
        System.assertEquals(2, updatedBudget.Total_Visitations__c, 'Total Visitations count should be 2');
    }
}