trigger UpdateBudgetNewMembers on Account (after insert) {
    System.debug('Trigger Execution Started: UpdateBudgetNewMembers');

    // Map to track budgets and their new members
    Map<Id, Set<Id>> budgetNewMembers = new Map<Id, Set<Id>>();

    // Collect Start Dates and Clubs from the new accounts
    Set<Date> startDates = new Set<Date>();
    Set<Id> clubIds = new Set<Id>();

    for (Account account : Trigger.new) {
        // Use Start_Date__pc for Person Accounts and AssociatedClub__c for Club field
        if (account.Start_Date__pc != null && account.AssociatedClub__c != null) {
            startDates.add(account.Start_Date__pc);
            clubIds.add(account.AssociatedClub__c);
            System.debug('Added Start Date and Club to Sets');
        } else {
            System.debug('Missing Start_Date__pc or AssociatedClub__c for Account: ' + account.Id);
        }
        System.debug('Account: ' + account.Id + ', Start Date: ' + account.Start_Date__pc + ', Club: ' + account.AssociatedClub__c);
    }

    System.debug('Collected Start Dates: ' + startDates);
    System.debug('Collected Club IDs: ' + clubIds);

    // Proceed only if there are valid start dates and club IDs
    if (!startDates.isEmpty() && !clubIds.isEmpty()) {
        // Query budgets for the relevant clubs and timeframes
        Map<Id, Budget__c> budgets = new Map<Id, Budget__c>();
        for (Budget__c budget : [
            SELECT Id, Club__c, Month_Start_Date__c, Month_End_Date__c, New_Member__c
            FROM Budget__c
            WHERE Club__c IN :clubIds
            AND Month_Start_Date__c <= :startDates
            AND Month_End_Date__c >= :startDates
        ]) {
            budgets.put(budget.Id, budget);
            budgetNewMembers.put(budget.Id, new Set<Id>());
            System.debug('Retrieved Budget: ' + budget);
        }

        System.debug('Budgets Retrieved: ' + budgets.keySet());

        // Process Trigger.new accounts
        for (Account account : Trigger.new) {
            if (account.Start_Date__pc != null && account.AssociatedClub__c != null) {
                for (Budget__c budget : budgets.values()) {
                    if (budget.Club__c == account.AssociatedClub__c &&
                        account.Start_Date__pc >= budget.Month_Start_Date__c &&
                        account.Start_Date__pc <= budget.Month_End_Date__c) {

                        // Add the account to the set for this budget
                        budgetNewMembers.get(budget.Id).add(account.Id);
                        System.debug('New Member Added: ' + account.Id + ' to Budget: ' + budget.Id);
                    }
                }
            }
        }

        // Update budgets with the new member count
        List<Budget__c> budgetsToUpdate = new List<Budget__c>();
        for (Id budgetId : budgetNewMembers.keySet()) {
            if (!budgetNewMembers.get(budgetId).isEmpty()) {
                Budget__c budgetToUpdate = budgets.get(budgetId);
                budgetToUpdate.New_Member__c = (budgetToUpdate.New_Member__c == null ? 0 : budgetToUpdate.New_Member__c)
                    + budgetNewMembers.get(budgetId).size();
                budgetsToUpdate.add(budgetToUpdate);
                System.debug('Budget Updated: ' + budgetToUpdate);
            }
        }

        if (!budgetsToUpdate.isEmpty()) {
            update budgetsToUpdate;
        }
    } else {
        System.debug('No valid Start Dates or Club IDs found. Skipping Budget query.');
    }

    System.debug('Trigger Execution Ended: UpdateBudgetNewMembers');
}