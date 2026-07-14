/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc: !IMPORTANT NOTE
	   To Stop the JOB.   Go to Clubfit Custom Settings and Tick the Active checkbox.
@History:
[1] CLAZARRA 12-Oct-25 : Created
[2] CLAZARRA 12-Dec-25 : Fixed Governor limit of 50k query rows
[3] CLAZARRA 29-Jan-26 : remove rerun of jobs 
*/
public class ClubfitGetProspectsBatch implements Database.Batchable<RestResponseCollectionClubfit.data>,Database.AllowsCallouts, Database.Stateful{
  public Map<String,String> params;
  public Datetime paramStartDateTime;
    
    public ClubfitGetProspectsBatch(Map<String,String> clubApiKeyMap, DateTime startDateTime){
        
        params = clubApiKeyMap; 
        
        paramStartDateTime = startDateTime;
    }
    
    public Iterable<RestResponseCollectionClubfit.data> start(Database.BatchableContext context)
    {   
         system.debug('params: ' + params);
        List<RestResponseCollectionClubfit.data> prospectItems = new List<RestResponseCollectionClubfit.data>();
        Clubfit_API_Settings__c apiSettings = Clubfit_API_Settings__c.getOrgDefaults();
        system.debug(apiSettings);
        String lastStatusSyncDateTime = apiSettings?.Last_Sync_DateTime__c.format('yyyy-MM-dd\'T\'HH:mm:ss');
 		String apiKey = '';
        String clubId = '';
        
      
        HttpResponse response = new HttpResponse();
        
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.Endpoint__c;
        endpoint = endpoint + Constants.INTEGRATION_CLUBFIT_VERSION + Constants.INTEGRATION_CLUBFIT_PROSPECTS  + '?' + Constants.INTEGRATION_CLUBFIT_FROM_DATE + lastStatusSyncDateTime;
        
        
        List<String> prospectStatuses = new List<String>();//apiSettings?.Prospect_Status__c.split(';');
        
  
        
        
        if(apiSettings == null || !isActive ) { 
            return new List<RestResponseCollectionClubfit.data>();
        }else{ 
             
            HttpResponse tokenReponse = ClubfitGetAccessToken.getAccessToken();
            if(tokenReponse?.getStatusCode() == 200){
                
             
               
                
                if (!params.isEmpty()) {
                    clubId = params.keySet().iterator().next();
                    apiKey = params.get(clubId);
                    
                    system.debug('clubId: ' + clubId);
                    system.debug('apiKey: ' + apiKey);
                    
                }else{
                    return new List<RestResponseCollectionClubfit.data>();
                }
                
                String responseTokenBodyString = tokenReponse?.getBody();
                
                RestResponseCollectionClubfit.AccessTokenResponse responseTokenBody = (RestResponseCollectionClubfit.AccessTokenResponse)
                    JSON.deserialize(responseTokenBodyString, RestResponseCollectionClubfit.AccessTokenResponse.class);
                
               
                Map<String , String> requestHeader = Utilities.ConstructClubfitProspectsRequestHeaders(apiKey, responseTokenBody.AccessToken);
                response = RestHandler.ExecuteRequest(requestHeader, endpoint, null, CONSTANTS.INTEGRATION_REST_METHOD_GET); 
                
                String responseBodyString = response?.getBody();
                system.debug('#responseBodyString: ' + responseBodyString);
                
                //Create Error Logs if invalid response
                if(!Utilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
                    RestHandler.ExceptionLogWrapper contactExLog = new RestHandler.ExceptionLogWrapper();
                    contactExLog.requestBody = null;
                    contactExLog.requestEndpoint =  endpoint;
                    contactExLog.responseBody = responseBodyString;
                    contactExLog.statusCode = String.valueOf(response?.getStatusCode());
                    Utilities.CreateExceptionLog(JSON.serialize(contactExLog), CONSTANTS.META_CONVERSIONS_API);   
                    
                    return new List<RestResponseCollectionClubfit.data>();
                    
                }
                
                if(responseBodyString.contains('Number')){
                    system.debug('Contains Number');
                    responseBodyString = responseBodyString.replaceAll('Number', 'Number_x');
                }
                
                
                RestResponseCollectionClubfit.ProspectsReponseBody responseBody = (RestResponseCollectionClubfit.ProspectsReponseBody)
                    JSON.deserialize(responseBodyString, RestResponseCollectionClubfit.ProspectsReponseBody.class);
                
                
                
				system.debug('responseBody: ' + responseBody);

                
                if(responseBody == NULL) {
                  
                    return new List<RestResponseCollectionClubfit.data>();
                    
                }
                else if(responseBody.data?.size() > 0 ){
                    //paramString = myobInvoiceResponse.NextPageLink;
                    //paramString = paramString?.substringAfter('?');
                    prospectItems =  responseBody.data;        
                    
                }else{
                  
                    return new List<RestResponseCollectionClubfit.data>();
                    
                }
                
                
            }
        }
        return prospectItems;  
    }
    
    public void execute(Database.BatchableContext context, List<RestResponseCollectionClubfit.data> prospectList)
    {
        
        system.debug('#EXECUTE');
        Set<String> clubfitProspectIds = new Set<String>();
        
        for(RestResponseCollectionClubfit.data data : prospectList){
            clubfitProspectIds.add(data.Number_x);
            
        }
        
        Map<String, String> userMap = Utilities.getUserMap();
        Map<String, String> leadMap = Utilities.getProspectLeadMap(clubfitProspectIds);
        
        List<Lead> leadsToUpsert = new List<Lead>();
        for(RestResponseCollectionClubfit.data data : prospectList){
            if(data.Status != 'Sale'){
                
                //Correct the value of Lead Status
                /*
                if(data.Status == 'Trial_Expired'){
                    data.Status = 'Trial Expired';
                    
                }else if(data.Status == 'NotInterested'){
                    data.Status = 'Not Interested';
                    
                }else if(data.Status == 'OnTrial'){
                    data.Status = '	On Trial';
                    
                }else if(data.Status == 'NoSaleReturn'){
                    data.Status = '	No Sale Return';
                    
                }else if(data.Status == 'DidNotShow'){
                    data.Status = 'Did Not Show';
                    
                }
                */
                
                Lead lead = new Lead();
                
                //Check if Prospect Lead exist
                if(leadMap.containsKey(data.Number_x)){
                    
                    system.debug('#LEAD EXIST: ' + lead.Id);
                    lead.Id = leadMap.get(data.Number_x);
                }
                
                Datetime createdDateUtc = (Datetime)JSON.deserialize('"' + data.CreatedDateUtc + '"', Datetime.class);
                //Cancel the creation of Online Signup Incomplete if not passed 30min.
                if(createdDateUtc.addMinutes(30) > system.now() && data.ContactMethod?.Name == 'Online Signup Incomplete'){
                    continue;
                }
                
                    lead.ProspectId__c = data.Number_x;
                    lead.FirstName = data?.FirstName != null ? data.FirstName : '(blank)';
                    lead.LastName = data?.LastName != null ? data.LastName : '(blank)';
                    lead.Clubfit_Lead_Status__c = data.Status;
                    lead.Date_of_Birth__c = data.DateOfBirth != null ? Date.ValueOf(data.DateOfBirth) : null;
                    lead.Trial_Start_Date__c = data.TrialStartDate != null ? Date.ValueOf(data.TrialStartDate) : null;
                    lead.Trial_End_Date__c = data.TrialEndDate != null ? Date.ValueOf(data.TrialEndDate) : null;
                    lead.Created_DateTime_UTC__c = data.CreatedDateUtc != null ? createdDateUtc : null;
                    lead.Contact_Method__c = data.ContactMethod?.Name;
                    lead.Clubfit_Channel_bric__c = data.Source?.Name;
                    lead.Email = data.Contact?.Email;
                    lead.MobilePhone = data.Contact?.Mobile;
                    lead.Street = data.Contact?.Address;
                    lead.City = data.Contact?.Suburb;
                    lead.State = data.Contact?.State;
                    lead.PostalCode = data.Contact?.PostCode;
                    lead.Postcode__c = data.Contact?.PostCode;
                    lead.Clubfit_Status_Code_bric__c = 200;
                    lead.Clubfit_Submitted_DateTime_bric__c = System.now();
                    
                    lead.Club__c = params?.keySet().iterator().next();  //get the First Key 
                    
                    if(userMap.containsKey(data.SalesPerson.Email)){
                        lead.Salesperson__c = userMap.get(data.SalesPerson.Email);
                    }
                    
                    leadsToUpsert.add(lead);
            
                
                
                
            }
            
            
        }
        
        
        system.debug(leadsToUpsert);
        if(leadsToUpsert.size() > 0){
            Database.UpsertResult[] results = Database.upsert(leadsToUpsert, false);
            
            // 5. Iterate through the results to check success/failure for each record
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                Lead record = leadsToUpsert[i];
                
                if (result.isSuccess()) {
                    String action = result.isCreated() ? 'INSERTED' : 'UPDATED';
                    System.debug('Action: ' + action + '. New/Updated ID: ' + result.getId());
                } else {
                    
                    for (Database.Error err : result.getErrors()) {
                        Utilities.CreateExceptionLog(err.getMessage(), 'Clubfit Prospect Integration -  Error Fields ' + err.getFields());
                        System.debug('Error: ' + err.getMessage() + ' on fields: ' + err.getFields());
                    }
                }
                
                
                
            }
        }
        
        
        
    }
     

    
    
    public void finish(Database.BatchableContext context) {
        
        
        Clubfit_API_Settings__c apiSettings = Clubfit_API_Settings__c.getOrgDefaults();
        
        if(!apiSettings.Active__c){
            return;
            //stop the Job when the custom setting is Deactivated.
        }
        
        
        if(params.size() > 0) 
        {
            params.remove(params?.keySet().iterator().next()); 
            
            Database.executeBatch(new ClubfitGetProspectsBatch(params, paramStartDateTime));
            
        }else{
            
            if(apiSettings != null){
                apiSettings.Last_Sync_DateTime__c = paramStartDateTime;
                update apiSettings;
            }
          
            
            // Abort any existing scheduled job with same name
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :Constants.CLUBFIT_ALL_CLUBS_PROSPECTS_SCHEDULER]) {
                System.abortJob(ct.Id);
            }
            
          
            if(!Test.isRunningTest()){
             new ClubfitProspectsScheduler().execute(null);
            }
          
        }
        
      
    }
    
    
    
    
     
}