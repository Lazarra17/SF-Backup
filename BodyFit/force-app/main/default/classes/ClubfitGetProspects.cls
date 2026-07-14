/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc:
@History:
[1] CLAZARRA 12-Oct-27 : Created
*/
public class ClubfitGetProspects {
    
    
    public static HttpResponse getProspects(String apiKey, String clubId){
        Clubfit_API_Settings__c apiSettings = Clubfit_API_Settings__c.getOrgDefaults();
        HttpResponse response = new HttpResponse();
        Datetime now = System.now();
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.Endpoint__c;
        String lastStatusSyncDateTime = null;// apiSettings?.Last_Status_Sync_DateTime__c.format('yyyy-MM-dd\'T\'HH:mm:ss');
 
        
        endpoint = endpoint + Constants.INTEGRATION_CLUBFIT_VERSION + Constants.INTEGRATION_CLUBFIT_PROSPECTS  + '?' + Constants.INTEGRATION_CLUBFIT_FROM_DATE + lastStatusSyncDateTime;
        system.debug('endpoint: ' + endpoint);
        
        if(apiSettings == null || !isActive ) { 
            return response;
        }else{ 
            
            HttpResponse tokenReponse = ClubfitGetAccessToken.getAccessToken();
            if(tokenReponse?.getStatusCode() == 200){
                
               
                
                String responseTokenBodyString = tokenReponse?.getBody();
                
                RestResponseCollectionClubfit.AccessTokenResponse responseTokenBody = (RestResponseCollectionClubfit.AccessTokenResponse)
                    JSON.deserialize(responseTokenBodyString, RestResponseCollectionClubfit.AccessTokenResponse.class);
                
                
                Map<String , String> requestHeader = Utilities.ConstructClubfitProspectsRequestHeaders(apiKey, responseTokenBody.AccessToken);
                response = RestHandler.ExecuteRequest(requestHeader ,endpoint, null, CONSTANTS.INTEGRATION_REST_METHOD_GET); 
                
                String responseBodyString = response?.getBody();
               
                
                //Create Error Logs if invalid response
                if(!Utilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
                    RestHandler.ExceptionLogWrapper contactExLog = new RestHandler.ExceptionLogWrapper();
                    contactExLog.requestBody = null;
                    contactExLog.requestEndpoint =  endpoint;
                    contactExLog.responseBody = responseBodyString;
                    contactExLog.statusCode = String.valueOf(response?.getStatusCode());
                    Utilities.CreateExceptionLog(JSON.serialize(contactExLog), CONSTANTS.META_CONVERSIONS_API);   
                    
                    return response;
                }
                
                responseBodyString = responseBodyString.replaceAll('Number', 'Number_x');
                
                RestResponseCollectionClubfit.ProspectsReponseBody responseBody = (RestResponseCollectionClubfit.ProspectsReponseBody)
                    JSON.deserialize(responseBodyString, RestResponseCollectionClubfit.ProspectsReponseBody.class);
                
                
                system.debug('responseBody.data.size: ' + responseBody.data.size());
                //Capture All User in Map  Email and Id
                Map<String, String> userMap = getUserMap();
                Map<String, String> leadMap = getProspectLeadMap();
                
                List<Lead> leadsToUpsert = new List<Lead>();
                for(RestResponseCollectionClubfit.data data : responseBody.data){
                    if(data.Status != 'Sale'){
                        
                        //Correct the value of Lead Status
                        
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
                        
                        Lead lead = new Lead();
                        
                        //Check if Prospect Lead exist
                        if(leadMap.containsKey(data.Number_x)){
                            lead.Id = leadMap.get(data.Number_x);
                        }
                        system.debug(data.FirstName);
                        system.debug(data.LastName);
                        lead.ProspectId__c = data.Number_x;
                        lead.FirstName = data?.FirstName != null ? data.FirstName : '(blank)';
                        lead.LastName = data?.LastName != null ? data.LastName : '(blank)';
                        lead.Status = data.Status;
                        lead.Date_of_Birth__c = data.DateOfBirth != null ? Date.ValueOf(data.DateOfBirth) : null;
                        lead.Trial_Start_Date__c = data.TrialStartDate != null ? Date.ValueOf(data.TrialStartDate) : null;
                        lead.Trial_End_Date__c = data.TrialEndDate != null ? Date.ValueOf(data.TrialEndDate) : null;
                        lead.Contact_Method__c = data.ContactMethod?.Name;
                        lead.Clubfit_Channel_bric__c = data.Source?.Name;
                        lead.Email = data.Contact?.Email;
                        lead.MobilePhone = data.Contact?.Mobile;
                        lead.Street = data.Contact?.Address;
                        lead.City = data.Contact?.Suburb;
                        lead.State = data.Contact?.State;
                        lead.PostalCode = data.Contact?.PostCode;
                        lead.Postcode__c = data.Contact?.PostCode;
                        lead.Clubfit_Status_Code_bric__c = response.getStatusCode();
                        lead.Clubfit_Submitted_DateTime_bric__c = System.now();
                        lead.Club__c = clubId;
                        
                        if(userMap.containsKey(data.SalesPerson.Email)){
                            lead.Salesperson__c = userMap.get(data.SalesPerson.Email);
                        }
                        
                        leadsToUpsert.add(lead);
                        
                        
                    }
                    
                    
                    
                }
                
                if(leadsToUpsert.size() > 0){
                    
                    system.debug(leadsToUpsert);
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
                    
                    //apiSettings.Last_Status_Sync_DateTime__c =  now;
                    update apiSettings;
                }
                
            }  
            
        }
        
        return response;
        
    }     
    
    
    public static Map<String, String> getUserMap(){
        
        Map<String, String> userMap = new Map<String, String>();
        for(User u : [SELECT Id, Email FROM User]){
            userMap.put(u.Email, u.Id);
        }
        
        return userMap;
        
    }
    
     public static Map<String, String> getProspectLeadMap(){
        
        Map<String, String> leadMap = new Map<String, String>();
        for(Lead lead : [SELECT Id, ProspectId__c FROM Lead]){
            leadMap.put(lead.ProspectId__c, lead.Id);
        }
        
        return leadMap;
        
    }
    

}