global class visitBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    global List<APIKeys__c> apiKeyList = new List<APIKeys__c>();
    global List<Visitation__c> visitationListRecords = new List<Visitation__c>();
    global List<Error_Log__c> errorList = new List<Error_Log__c>();
    
    // This method is called at the start of the batch process
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Querying the Api_Keys__mdt metadata
        return Database.getQueryLocator('Select id, Club__c, Key__c, Limit__c, Offset__c, Membership_Offset__c, Membership_limit__c from APIKeys__c');
    }
    
    // This method processes each batch of records
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<APIKeys__c> apiKeys = (List<APIKeys__c>)scope;
        List<Visitation__c> visitList = new List<Visitation__c>();
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
            Integer limits = Integer.valueOf(apiKey.Limit__c);
            Integer offset = Integer.valueOf(apiKey.Offset__c);
            
            // Call the method to get members, passing the extracted values
            visitList = fetchVisitData.getVisits(key, limits, offset, apiKey.Club__c, mapofclubNameandId);
            if(!visitList.isEmpty()){
                visitationListRecords.addAll(visitList);
                apiKey.Offset__c = apiKey.Offset__c + 500;
                apiKeyList.add(apiKey);
            }
            if(visitList.isEmpty()){
                apiKey.Offset__c = 0;
                apiKeyList.add(apiKey);
            }
        }
    }
    
    // This method is called after all batches are processed
    global void finish(Database.BatchableContext BC) {
        // Any final processing can be done here
        if(!visitationListRecords.isEmpty()){
            // Upsert the records using the external ID field
            //Schema.SObjectField extId = Visitation__c.Fields.Member_ID__c;
            List<Database.SaveResult> resultList = Database.insert(visitationListRecords, false);
            if(!errorList.isEmpty()){
                insert errorList;
            }
        }
        if(!apiKeyList.isEmpty()){
            update apiKeyList;
        }
    }
}