global class updateMemberNameBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    // This method is called at the start of the batch process
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Member_ID__c 
            FROM Visitation__c 
            WHERE Member__c = NULL AND Member_ID__c != NULL
        ]);
    }
    
    // This method processes each batch of records
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Visitation__c> visitsToUpdate = new List<Visitation__c>();
        List<Visitation__c> visitList = (List<Visitation__c>)scope;
        
        // Collect member numbers from Visitation records
        Set<String> memberNumbers = new Set<String>();
        for (Visitation__c visit : visitList) {
            memberNumbers.add(visit.Member_ID__c);
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
        for (Visitation__c visit : visitList) {
            if (memberMap.containsKey(visit.Member_ID__c)) {
                visit.Member__c = memberMap.get(visit.Member_ID__c);
                visitsToUpdate.add(visit);
            }
        }
        
        if (!visitsToUpdate.isEmpty()) {
            update visitsToUpdate;
        }
    }
    
    // This method is called after all batches are processed
    global void finish(Database.BatchableContext BC) {
        
    }
}