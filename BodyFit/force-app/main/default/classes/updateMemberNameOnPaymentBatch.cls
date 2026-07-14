global class updateMemberNameOnPaymentBatch implements Database.Batchable<SObject>, Database.Stateful {
     global List<Payment_History__c> paymentToUpdate = new List<Payment_History__c>();
    
    // This method is called at the start of the batch process
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Member_Id__c 
            FROM Payment_History__c 
            WHERE Member__c = NULL AND Member_Id__c != NULL
        ]);
    }
    
    // This method processes each batch of records
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Payment_History__c> paymentList = (List<Payment_History__c>)scope;
        
        // Collect member numbers from Visitation records
        Set<String> memberNumbers = new Set<String>();
        for (Payment_History__c payment : paymentList) {
            memberNumbers.add(payment.Member_ID__c);
        }
        
        // Query Person Accounts with matching Club Fit Member IDs
        Map<String, Id> memberMap = new Map<String, Id>();
        for (Account acc : [SELECT Id, Clubfit_Member_Id__c 
                             FROM Account 
                             WHERE Clubfit_Member_Id__c IN :memberNumbers 
                             AND IsPersonAccount = true]) {
            memberMap.put(acc.Clubfit_Member_Id__c, acc.Id);
        }
        
        // Update the Member Name on Visitation records where there's a match
        for (Payment_History__c payment : paymentList) {
            if (memberMap.containsKey(payment.Member_ID__c)) {
                payment.Member__c = memberMap.get(payment.Member_ID__c);
                paymentToUpdate.add(payment);
            }
        }
    }
    
    // This method is called after all batches are processed
    global void finish(Database.BatchableContext BC) {
        if (!paymentToUpdate.isEmpty()) {
            // Use Database.update for partial success handling
            Database.SaveResult[] saveResults = Database.update(paymentToUpdate, false);
        }
    }

}