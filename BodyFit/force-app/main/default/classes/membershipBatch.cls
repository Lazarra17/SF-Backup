global class membershipBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    global List<APIKeys__c> apiKeyList = new List<APIKeys__c>();
    global List<Account> accountsListToInsert = new List<Account>();
    global List<Error_Log__c> errorList = new List<Error_Log__c>();
    
    // This method is called at the start of the batch process
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Querying the Api_Keys__mdt metadata
        return Database.getQueryLocator('Select id, Club__c, Key__c, Limit__c, Offset__c, Membership_Offset__c, Membership_limit__c from APIKeys__c');
    }
    
    // This method processes each batch of records
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<APIKeys__c> apiKeys = (List<APIKeys__c>)scope;
        List<Account> accList = new List<Account>();
        RecordType personAccountType = [SELECT Id FROM RecordType 
                                        WHERE SObjectType = 'Account' 
                                        AND DeveloperName = 'PersonAccount' 
                                        LIMIT 1];
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
            Integer limits = Integer.valueOf(apiKey.Membership_limit__c);
            Integer offset = Integer.valueOf(apiKey.Membership_Offset__c);
            // Call the method to get members, passing the extracted values
            accList = fetchMembershipData.getMembers(key, limits, offset, personAccountType.Id, apiKey.Club__c, mapofclubNameandId);
            if(!accList.isEmpty()){
                accountsListToInsert.addAll(accList);
                apiKey.Membership_Offset__c = apiKey.Membership_Offset__c + 100;
                apiKeyList.add(apiKey);
            }
            if(accList.isEmpty()){
                apiKey.Membership_Offset__c = 0;
                apiKeyList.add(apiKey);
            }
        }
    }
    
    // This method is called after all batches are processed
    global void finish(Database.BatchableContext BC) {
        // Any final processing can be done here
        if(!accountsListToInsert.isEmpty()){
            // Upsert the records using the external ID field
            Schema.SObjectField extId = Account.Fields.Clubfit_Member_Id__c;
            List<Database.upsertResult> resultList = Database.upsert(accountsListToInsert, extId, false);
            for(Database.upsertResult sr : resultList){
                if(sr.isSuccess()){
                    
                }else{
                    for(Database.Error er : sr.getErrors()){
                        system.debug('error '+er.getStatusCode()+ ' message ' + er.getMessage());
                        Error_Log__c err = new Error_Log__c();
                        err.Error_Message__c = er.getMessage();
                        err.Status_Code__c = String.valueOf(er.getStatusCode());
                        err.Source_Class__c = 'membershipBatch';
                        errorList.add(err);
                    }
                }
            }
            if(!errorList.isEmpty()){
                insert errorList;
            }
        }
        
        if(!apiKeyList.isEmpty()){
            update apiKeyList;
        }
    }
}