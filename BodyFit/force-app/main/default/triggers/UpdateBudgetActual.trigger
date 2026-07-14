trigger UpdateBudgetActual on Payment_History__c (after insert, after update) {
    // Map to store club and date range to corresponding budget records
    Map<Id, Budget__c> budgetMap = new Map<Id, Budget__c>();

    // Collect unique club IDs and payment dates from Trigger.new
    Set<Id> clubIds = new Set<Id>();
    Set<Date> paymentDates = new Set<Date>();

    for (Payment_History__c payment : Trigger.new) {
        clubIds.add(payment.Club__c);
        if (payment.Payment_Date__c != null) {
            paymentDates.add(payment.Payment_Date__c.date());
        }
    }

    // Query related Budget records for the clubs and date range
    List<Budget__c> budgets = [
        SELECT Id, Club__c, Month_Start_Date__c, Month_End_Date__c, Actual__c
        FROM Budget__c
        WHERE Club__c IN :clubIds
        AND Month_Start_Date__c <= :paymentDates
        AND Month_End_Date__c >= :paymentDates
    ];

    for (Budget__c budget : budgets) {
        budgetMap.put(budget.Id, budget);
    }

    // Aggregate payments by Budget
    Map<Id, Decimal> budgetTotals = new Map<Id, Decimal>();

    for (Payment_History__c payment : Trigger.new) {
        for (Budget__c budget : budgetMap.values()) {
            if (budget.Club__c == payment.Club__c &&
                payment.Payment_Date__c.date() >= budget.Month_Start_Date__c &&
                payment.Payment_Date__c.date() <= budget.Month_End_Date__c) {

                if (!budgetTotals.containsKey(budget.Id)) {
                    budgetTotals.put(budget.Id, 0);
                }
                // Sum up the amount field for each relevant budget
                budgetTotals.put(budget.Id, budgetTotals.get(budget.Id) + payment.Amount__c);
            }
        }
    }

    // Update Actual__c field for the relevant budgets
    List<Budget__c> budgetsToUpdate = new List<Budget__c>();

    for (Id budgetId : budgetTotals.keySet()) {
        Budget__c budgetToUpdate = budgetMap.get(budgetId);
        budgetToUpdate.Actual__c = budgetTotals.get(budgetId);
        budgetsToUpdate.add(budgetToUpdate);
    }

    if (!budgetsToUpdate.isEmpty()) {
        update budgetsToUpdate;
    }
}