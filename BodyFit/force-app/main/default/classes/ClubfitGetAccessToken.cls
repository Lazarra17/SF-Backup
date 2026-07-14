/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 
@Desc:
@History:
[1] CLAZARRA 12-Oct-27 : Created
*/
public class ClubfitGetAccessToken {
    
    public static HttpResponse getAccessToken(){
        
        Clubfit_API_Settings__c apiSettings = Clubfit_API_Settings__c.getOrgDefaults();
        HttpResponse response = new HttpResponse();
        
        Boolean isActive = apiSettings?.Active__c;
        String endpoint = apiSettings?.Endpoint__c;
        endpoint = endpoint + Constants.INTEGRATION_CLUBFIT_VERSION + Constants.INTEGRATION_CLUBFIT_TOKEN;
        
        
        if(apiSettings == null || !isActive ) { 
            return response;
        }else{ 
            
            Map<String , String> requestHeader = Utilities.ConstructClubfitAccessTokenRequestHeaders(apiSettings);
            response = RestHandler.ExecuteRequest(requestHeader ,endpoint, null, CONSTANTS.INTEGRATION_REST_METHOD_POST); 
            system.debug('response: ' + response);
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
            

            
        }
        
        return response;
        
    }

}