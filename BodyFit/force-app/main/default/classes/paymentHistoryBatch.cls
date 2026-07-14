global class paymentHistoryBatch  implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    global List<APIKeys__c> apiKeyList = new List<APIKeys__c>();
    global List<Payment_History__c> paymentListRecords = new List<Payment_History__c>();
    global List<Error_Log__c> errorList = new List<Error_Log__c>();
    
    // This method is called at the start of the batch process
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Querying the Api_Keys__mdt metadata
        return Database.getQueryLocator('Select id, Club__c, Key__c, Limit__c, Offset__c,Payment_Limit__c,Payment_Offset__c from APIKeys__c');
    }
    
    // This method processes each batch of records
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<APIKeys__c> apiKeys = (List<APIKeys__c>)scope;
        List<Payment_History__c> paymentList = new List<Payment_History__c>();
        List<Club__c> clubList = [Select Id , Name from Club__c];
        Map<String,Id> mapofclubNameandId = new Map<String,Id>();
        for(Club__c club :clubList){
            if(!mapofclubNameandId.containsKey(club.Name)){
                mapofclubNameandId.put(club.Name, club.Id);
            }
        }
        
        for (APIKeys__c apiKey : apiKeys) {
            // Extract values from the metadata records
            String key = apiKey.Key__c;
            Integer limits = Integer.valueOf(apiKey.Payment_Limit__c);
            Integer offset = Integer.valueOf(apiKey.Payment_Offset__c);
            
            // Call the method to get members, passing the extracted values
            paymentList = fetchPaymentData.getPaymentHistory(key, limits, offset, apiKey.Club__c, mapofclubNameandId);
            if(!paymentList.isEmpty()){
                paymentListRecords.addAll(paymentList);
                apiKey.Payment_Offset__c = apiKey.Payment_Offset__c + 500;
                apiKeyList.add(apiKey);
            }
            if(paymentList.isEmpty()){
                apiKey.Payment_Offset__c = 0;
                apiKeyList.add(apiKey);
            }
        }
    }
    
    // This method is called after all batches are processed
    global void finish(Database.BatchableContext BC) {
        // Any final processing can be done here
        if(!paymentListRecords.isEmpty()){
            // Upsert the records using the external ID field
            //Schema.SObjectField extId = Payment_History__c.Fields.Member_ID__c;
            List<Database.SaveResult> resultList = Database.insert(paymentListRecords, false);
            if(!errorList.isEmpty()){
                insert errorList;
            }
        }
        if(!apiKeyList.isEmpty()){
            update apiKeyList;
        }
    }
}