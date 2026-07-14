trigger UpdateBudgetTotalVisitations on Visitation__c (after insert) {
    System.debug('Trigger Execution Started: UpdateBudgetTotalVisitations');

    // Map to track budgets and visitation counts
    Map<Id, Integer> budgetVisitations = new Map<Id, Integer>();

    // Collect clubs and visitation dates from the new visitation records
    Set<Id> clubIds = new Set<Id>();
    Set<Date> visitationDates = new Set<Date>();

    for (Visitation__c visitation : Trigger.new) {
        if (visitation.Club__c != null && visitation.Date_Time__c != null) {
            clubIds.add(visitation.Club__c);
            visitationDates.add(visitation.Date_Time__c.date());
        }
    }

    System.debug('Club IDs: ' + clubIds);
    System.debug('Visitation Dates: ' + visitationDates);

    // Extract a single date (assuming all records share the same date)
    Date visitDate;
    if (!visitationDates.isEmpty()) {
        visitDate = visitationDates.iterator().next();
    } else {
        visitDate = Date.today();
    }

    // Query budgets for the relevant clubs and the visitation date
    Map<Id, Budget__c> budgets = new Map<Id, Budget__c>();
    for (Budget__c budget : [
        SELECT Id, Club__c, Month_Start_Date__c, Month_End_Date__c, Total_Visitations__c
        FROM Budget__c
        WHERE Club__c IN :clubIds
        AND Month_Start_Date__c <= :visitDate
        AND Month_End_Date__c >= :visitDate
    ]) {
        budgets.put(budget.Id, budget);
        budgetVisitations.put(budget.Id, 0);
    }

    System.debug('Budgets Retrieved: ' + budgets.keySet());

    // Increment visitation count for relevant budgets
    for (Visitation__c visitation : Trigger.new) {
        if (visitation.Club__c != null && visitation.Date_Time__c != null) {
            for (Budget__c budget : budgets.values()) {
                if (budget.Club__c == visitation.Club__c &&
                    visitation.Date_Time__c.date() >= budget.Month_Start_Date__c &&
                    visitation.Date_Time__c.date() <= budget.Month_End_Date__c) {

                    // Increment visitation count for the budget
                    budgetVisitations.put(budget.Id, budgetVisitations.get(budget.Id) + 1);
                    System.debug('Visitation Added to Budget: ' + budget.Id);
                }
            }
        }
    }

    // Update budgets with the new visitation totals
    List<Budget__c> budgetsToUpdate = new List<Budget__c>();
    for (Id budgetId : budgetVisitations.keySet()) {
        if (budgetVisitations.get(budgetId) > 0) {
            Budget__c budgetToUpdate = budgets.get(budgetId);
            budgetToUpdate.Total_Visitations__c = (budgetToUpdate.Total_Visitations__c == null ? 0 : budgetToUpdate.Total_Visitations__c)
                + budgetVisitations.get(budgetId);
            budgetsToUpdate.add(budgetToUpdate);
            System.debug('Budget Updated: ' + budgetToUpdate);
        }
    }

    if (!budgetsToUpdate.isEmpty()) {
        update budgetsToUpdate;
    }

    System.debug('Trigger Execution Ended: UpdateBudgetTotalVisitations');
}