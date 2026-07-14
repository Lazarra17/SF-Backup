/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc:
@History:
[1] CLAZARRA 12-Sept-25 : Created
*/ 
public class MetaPostConversionLeads {
    
    public static HttpResponse PostConversionLead(Lead lead){
        Meta_API_Settings__c apiSettings = Meta_API_Settings__c.getOrgDefaults();
        HttpResponse response = new HttpResponse();
        
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == null || !isActive || lead.sfleadcaphfprod__External_Lead_ID__c == '') { 
            return response;
        }else{ 
            
            Map<String , String> requestHeader = Utilities.ConstructRequestHeaders();
            RestRequestCollectionMeta requestBody = SetPostRequestBody(lead);
            String requestBodyString = JSON.serialize(requestBody);
            system.debug('requestBodyString: '+requestBodyString);  
            system.debug('endpoint: '+endpoint);  
            system.debug('Opportunity: ' + lead.ConvertedOpportunityId);
            response = RestHandler.ExecuteRequest(requestHeader ,endpoint, requestBodyString, CONSTANTS.INTEGRATION_REST_METHOD_POST); 
         
            String responseBodyString = response?.getBody();
            system.debug(response);
            system.debug(responseBodyString);
           
            
            //Create Error Logs if invalid response
            if(!Utilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
                RestHandler.ExceptionLogWrapper contactExLog = new RestHandler.ExceptionLogWrapper();
                contactExLog.requestBody = requestBodyString;
                contactExLog.requestEndpoint =  endpoint;
                contactExLog.responseBody = responseBodyString;
                contactExLog.statusCode = String.valueOf(response?.getStatusCode());
                Utilities.CreateExceptionLog(JSON.serialize(contactExLog), CONSTANTS.META_CONVERSIONS_API);   
              
                return response;
            }
            
             
            RestResponseCollectionMeta responseBody = (RestResponseCollectionMeta)
                JSON.deserialize(responseBodyString, RestResponseCollectionMeta.class);
            
                     
                lead.Meta_Submitted_DateTime_bric__c = System.now();
                lead.Meta_Status_Code_bric__c = response.getStatusCode();
                lead.Meta_Fbtrace_Id_bric__c = responseBody.fbtrace_id;
                lead.Meta_Response_Payload_bric__c = responseBodyString;
                update lead;
                
        
            
                        
        }
        
        return response;
        
    }      
    
     
    private static RestRequestCollectionMeta SetPostRequestBody(Lead lead)
    {
        RestRequestCollectionMeta postRequestBody = new RestRequestCollectionMeta();
        List<RestRequestCollectionMeta.Data> dataList = new List<RestRequestCollectionMeta.Data>();
        
        RestRequestCollectionMeta.Data data = new RestRequestCollectionMeta.Data();
        
        //Construct Custom Data
        RestRequestCollectionMeta.custom_data customData = new RestRequestCollectionMeta.custom_data();
        customData.event_source = CONSTANTS.CRM;
        customData.lead_event_source = CONSTANTS.SALESFORCE;
        
        //Construct User Data
        RestRequestCollectionMeta.user_data userData = new RestRequestCollectionMeta.user_data();
        if(lead.sfleadcaphfprod__External_Lead_ID__c != '') userData.lead_id = Long.valueOf(lead.sfleadcaphfprod__External_Lead_ID__c.substring(3));
        
        if(lead.FirstName != '') userData.fn = Utilities.encryptSha256(lead.FirstName);  
        if(lead.LastName != '') userData.ln = Utilities.encryptSha256(lead.LastName) ;
        if(lead.Email != '') userData.em = Utilities.encryptSha256(lead.Email);
        if(lead.MobilePhone != '') userData.ph = Utilities.encryptSha256(lead.MobilePhone);
        if(lead.TECH_Date_of_Birth_bric__c != null) userData.db = Utilities.encryptSha256(lead.TECH_Date_of_Birth_bric__c.replaceAll('-',''));
        if(lead.City != '') userData.ct = Utilities.encryptSha256(lead.City);
        if(lead.State != '') userData.st = Utilities.encryptSha256(lead.State);
        if(lead.PostalCode != '') userData.zp = Utilities.encryptSha256(lead.PostalCode);
        if(lead.Country != '') userData.country = Utilities.encryptSha256(lead.Country);
        userData.external_id = Utilities.encryptSha256(lead.Id);
        
        Datetime now = Datetime.now();
        Long epochMilliseconds = now.getTime();
        Long unixTimestampSeconds  =  epochMilliseconds / 1000L;
        system.debug(unixTimestampSeconds);
        
        data.action_source = CONSTANTS.WEBSITE;
        data.event_name = CONSTANTS.META_LEAD_CONVERSION;
        data.event_time = unixTimestampSeconds; //requires unix timestamp
        data.custom_data = customData;
        data.user_data = userData;
        
        dataList.add(data);
        postRequestBody.data  = dataList;
         
        return postRequestBody;
        
        
    }
  
}