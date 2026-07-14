/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc: !IMPORTANT NOTE
	   To Stop the JOB.   Go to Clubfit Custom Settings and Tick the Active checkbox.
@History:
[1] CLAZARRA 11-Feb-26 : Created
[2] CLAZARRA 11-Feb-26 : BOD-67 - added status to the filter to fix retrieve issue
*/


public class ClubfitGetMembersBatch implements Database.Batchable<RestResponseCollectionClubfitMembers.data>,Database.AllowsCallouts, Database.Stateful{
    public Map<String,String> params;
    public Datetime paramStartDateTime;
    public String nextQuery;
    public String currentClubId;
    public Set<String> processedMemberIds;
    public Map<String, String> memberClubNamesById;
    
    public ClubfitGetMembersBatch(Map<String,String> clubApiKeyMap, DateTime startDateTime, String next){
        this(clubApiKeyMap, startDateTime, next, null, null);
    }
    
    public ClubfitGetMembersBatch(Map<String,String> clubApiKeyMap, DateTime startDateTime, String next, String clubId){
        this(clubApiKeyMap, startDateTime, next, clubId, null);
    }
    
    public ClubfitGetMembersBatch(Map<String,String> clubApiKeyMap, DateTime startDateTime, String next, String clubId, Set<String> memberIdsProcessed){
        
        params = clubApiKeyMap; 
        
        paramStartDateTime = startDateTime;
        
        nextQuery = next;
        currentClubId = clubId;
        processedMemberIds = memberIdsProcessed != null ? memberIdsProcessed : new Set<String>();
    }
    
    private String getMemberClubName(RestResponseCollectionClubfitMembers.data data) {
        if (data == null) {
            return null;
        }
        if (String.isNotBlank(data.Club)) {
            return data.Club;
        }
        if (memberClubNamesById != null && memberClubNamesById.containsKey(data.Number_x)) {
            return memberClubNamesById.get(data.Number_x);
        }
        return null;
    }
    
    private Map<String, String> extractMemberClubNames(String responseBodyString) {
        Map<String, String> clubNamesByMemberId = new Map<String, String>();
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBodyString);
        List<Object> dataList = (List<Object>) responseMap.get('data');
        if (dataList == null) {
            return clubNamesByMemberId;
        }
        
        for (Object item : dataList) {
            Map<String, Object> member = (Map<String, Object>) item;
            String memberId = (String) member.get('Number_x');
            if (String.isBlank(memberId)) {
                memberId = (String) member.get('Number');
            }
            String clubName = extractClubName(member.get('Club'));
            if (String.isNotBlank(memberId) && String.isNotBlank(clubName)) {
                clubNamesByMemberId.put(memberId, clubName);
            }
        }
        
        return clubNamesByMemberId;
    }
    
    private String extractClubName(Object clubValue) {
        if (clubValue == null) {
            return null;
        }
        if (clubValue instanceof String) {
            return (String) clubValue;
        }
        if (clubValue instanceof Map<String, Object>) {
            Map<String, Object> clubMap = (Map<String, Object>) clubValue;
            Object name = clubMap.get('Name');
            return name != null ? String.valueOf(name) : null;
        }
        return String.valueOf(clubValue);
    }
    
    private String resolveCurrentClubId() {
        if (String.isNotBlank(currentClubId) && params.containsKey(currentClubId)) {
            return currentClubId;
        }
        List<String> clubIds = new List<String>(params.keySet());
        clubIds.sort();
        return clubIds.isEmpty() ? null : clubIds[0];
    }
    
    public Iterable<RestResponseCollectionClubfitMembers.data> start(Database.BatchableContext context)
    {   
         system.debug('params: ' + params);
        List<RestResponseCollectionClubfitMembers.data> membersItems = new List<RestResponseCollectionClubfitMembers.data>();
        Clubfit_API_Settings__c apiSettings = Clubfit_API_Settings__c.getOrgDefaults();
        system.debug(apiSettings);
        String lastStatusSyncDateTime = apiSettings?.Members_Last_Sync_DateTime__c.addDays(-3).format('yyyy-MM-dd\'T\'HH:mm:ss');
 		String apiKey = '';
        String clubId = '';
        
      
        HttpResponse response = new HttpResponse();
        
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.Endpoint__c;
        system.debug('## nextQuery: ' + nextQuery);
        //Check the previous job if there were more than 500 records, then execute the remaningng
        if(nextQuery != null){
            endpoint = nextQuery + '&' + ClubfitConstants.INTEGRATION_CLUBFIT_UPDATE_DATE + lastStatusSyncDateTime;
            
        }else{
            endpoint = endpoint + ClubfitConstants.INTEGRATION_CLUBFIT_VERSION + ClubfitConstants.INTEGRATION_CLUBFIT_MEMBERS  + '?' + ClubfitConstants.INTEGRATION_CLUBFIT_UPDATE_DATE + lastStatusSyncDateTime
                + ClubfitConstants.CLUBFIT_FILTER_ALL_STATUS + '&limit=400&offset=0';
        }
        system.debug('## ENDPOINT: ' + endpoint);
        
        
        
        if(apiSettings == null || !isActive ) { 
            return new List<RestResponseCollectionClubfitMembers.data>();
        }else{ 
             
            HttpResponse tokenReponse = ClubfitGetAccessToken.getAccessToken();
            if(tokenReponse?.getStatusCode() == 200){
                
                //Get the next Club
                if (!params.isEmpty()) {
                    clubId = resolveCurrentClubId();
                    currentClubId = clubId;
                    apiKey = params.get(clubId);
                    
                }else{
                    return new List<RestResponseCollectionClubfitMembers.data>();
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
                    
                    return new List<RestResponseCollectionClubfitMembers.data>();
                    
                }
                
                if(responseBodyString.contains('Number')){
                    system.debug('Contains Number');
                    responseBodyString = responseBodyString.replaceAll('Number', 'Number_x');
                }
                
                
                RestResponseCollectionClubfitMembers responseBody = (RestResponseCollectionClubfitMembers)
                    JSON.deserialize(responseBodyString, RestResponseCollectionClubfitMembers.class);
                
                memberClubNamesById = extractMemberClubNames(responseBodyString);
                
                
                
				system.debug('responseBody: ' + responseBody);

                
                
                if(responseBody == NULL) {
                    
                    return new List<RestResponseCollectionClubfitMembers.data>();
                    
                }else if(responseBody != null ){
                    
                    nextQuery = responseBody.next != null ? responseBody.next : null;
                    system.debug('response NEXT: ' + nextQuery);
                    
                    
                    
                    if(responseBody.data?.size() > 0 ){
                        //paramString = myobInvoiceResponse.NextPageLink;
                        //paramString = paramString?.substringAfter('?');
                        membersItems =  responseBody.data;    
                      
                        
                    }else{
                        
                        return new List<RestResponseCollectionClubfitMembers.data>();
                        
                    }
                }
                
            }
        }
        return membersItems;  
    }
    
    public void execute(Database.BatchableContext context, List<RestResponseCollectionClubfitMembers.data> membersList)
    {
        
        system.debug('#EXECUTE');
        Set<String> clubfitProspectIds = new Set<String>();
        
        Map<String, String> userMap = Utilities.getUserMap();
        RecordType personRT = [SELECT Id FROM RecordType 
                               WHERE SobjectType = 'Account' 
                               AND IsPersonType = true 
                               LIMIT 1];
        
        List<Account> accountToUpsert = new List<Account>();
        for(RestResponseCollectionClubfitMembers.data data : membersList){
            
            if (String.isBlank(data.Number_x) || processedMemberIds.contains(data.Number_x)) {
                continue;
            }
            processedMemberIds.add(data.Number_x);
            
            if(data.Barcode == 'BODY129628'){
                system.debug('SAMEUL HEAR');
            }
            
            Account acc = new Account();
            
            acc.RecordTypeId = personRT.Id;
            
            acc.Clubfit_Member_Id__c = data.Number_x;
            acc.FirstName = data.FirstName != null && data.FirstName != '' ? data.FirstName : '(blank)';
            acc.LastName = data.LastName != null && data.LastName != '' ? data.LastName : '(blank)';
            acc.Gender__c = data.Gender != null && data.Gender != '' ? data.Gender : '';
            acc.Status__pc = data.Status != null && data.Status != '' ? data.Status : '';
            acc.Barcode__c = data.Barcode != null && data.Barcode != '' ? data.Barcode : '';
            
            acc.PersonHasOptedOutOfEmail = data.Contact?.OptOutEmail;
            acc.et4ae5__HasOptedOutOfMobile__pc = data.Contact?.OptOutSms;
            
            acc.PersonEmail = data.Contact.Email != null && data.Contact.Email != '' ? data.Contact?.Email : '';
            acc.PersonMobilePhone = data.Contact?.Mobile != null && data.Contact?.Mobile != '' ? data.Contact?.Mobile : '';
            
            acc.BillingStreet = data.Contact?.Address != null && data.Contact?.Address != '' ? data.Contact?.Address : '';
            acc.BillingCity = data.Contact?.Suburb != null && data.Contact?.Suburb != '' ? data.Contact?.Suburb : '';
            acc.BillingState = data.Contact?.State != null && data.Contact?.State != '' ? data.Contact?.State : ''; 
            acc.BillingPostalCode = data.Contact?.Postcode != null && data.Contact?.Postcode != '' ? data.Contact?.Postcode : '';
            
            acc.Membership_ID__pc =  data.Membership?.Id != null ? String.valueOf(data.Membership?.Id) : '';
            acc.Membership_Name__c = data.Membership?.Name != null && data.Membership?.Name != '' ? data.Membership?.Name : '';
            
            
            acc.Membership_Type__pc = data.Membership?.Type != null && data.Membership?.Type != '' ? data.Membership?.Type : '';
            acc.Membership_Type__c = data.Membership?.Type != null && data.Membership?.Type != '' ? data.Membership?.Type : '';
            
            acc.Fitness_Passport_Number__pc = data.FitnessPassportNumber != null && data.FitnessPassportNumber != '' ? data.FitnessPassportNumber : '';
            acc.Start_Date__pc = data.Membership?.StartDate != null ? Date.ValueOf(data.Membership?.StartDate) : null;
            acc.Expiry_Date__pc = data.Membership?.ExpiryDate != null ? Date.ValueOf(data.Membership?.ExpiryDate) : null;
            acc.Sale_Date__c = data.Membership?.SaleDate != null ? Date.ValueOf(data.Membership?.SaleDate) : null;
            acc.PersonBirthdate = data.DateOfBirth != null ? Date.ValueOf(data.DateOfBirth) : null;
            acc.Last_Updated_UTC_DateTime__c = data.LastUpdatedUtcDateTime != null ? (Datetime) JSON.deserialize('"' + data.LastUpdatedUtcDateTime + '"', Datetime.class) : null;
            
            
            if(data.Membership?.CancellationDate != null){
                acc.Cancellation_Date__c = data.Membership?.CancellationDate != null ? Date.ValueOf(data.Membership?.CancellationDate) : null;
                acc.Status__pc ='Archived';
            }
            
            
            Id memberClubId = Utilities.resolveClubId(getMemberClubName(data));
            acc.AssociatedClub__c = memberClubId != null ? memberClubId : currentClubId;
            
          	accountToUpsert.add(acc);
           
        }
        
        
        if(accountToUpsert.size() > 0){
            Database.UpsertResult[] results = Database.upsert(accountToUpsert, Account.Clubfit_Member_Id__c, false);
            
            // 5. Iterate through the results to check success/failure for each record
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                Account record = accountToUpsert[i];
                
                if (result.isSuccess()) {
                } else {
                    
                    for (Database.Error err : result.getErrors()) {
                        Utilities.CreateExceptionLog(err.getMessage(), 'Clubfit Members Integration -  Error Fields ' + err.getFields());
                        System.debug('Error: ' + err.getMessage() + ' on fields: ' + err.getFields());
                    }
                }
                
                
                
            }
        }
        
        
         
    }
     

    
    
    public void finish(Database.BatchableContext context) {
        
        system.debug('######################### FINISH');
        Clubfit_API_Settings__c apiSettings = Clubfit_API_Settings__c.getOrgDefaults();
        
        if(!apiSettings.Active__c){
            return;
            //stop the Job when the custom setting is Deactivated.
        }
        
        
        if(params.size() > 0) 
        {
            
            system.debug('NEXT: ' + nextQuery);
            
            if(nextQuery != null){
                 system.debug('NEXT: 1');
                 Database.executeBatch(new ClubfitGetMembersBatch(params, paramStartDateTime, nextQuery, currentClubId, processedMemberIds));
            }else{
                system.debug('NEXT: 2');
                params.remove(currentClubId); 
              Database.executeBatch(new ClubfitGetMembersBatch(params, paramStartDateTime, null, null, processedMemberIds));
            }
            
            
        }else{
            
             
            if(apiSettings != null){
                apiSettings.Members_Last_Sync_DateTime__c = paramStartDateTime;
                update apiSettings;
            }
         /*
            // Abort any existing scheduled job with same name
            for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :ClubfitConstants.CLUBFIT_ALL_CLUBS_PROSPECTS_SCHEDULER]) {
                System.abortJob(ct.Id);
            }
            
          
            if(!Test.isRunningTest()){
             new ClubfitProspectsScheduler().execute(null);
            }
            
            */
          
        }
        
      
    }
    

    
    
     
}