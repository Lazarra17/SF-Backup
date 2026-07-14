/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	12-Sept-25 
 * Description: 	Utility Class for reusable methods
 * Test Class: 		N/A
 * History:
 * [1]CLAZARRA 12-Sept-25 : Created 
*/
 
public class Utilities 
{    
    public static void CreateExceptionLog(Exception error, String customString)
    {
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = error?.getStackTraceString().abbreviate(CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error?.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        newException.CustomString__c = customString.abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        Database.insert(newException);
    } 
    
    public static void CreateExceptionLog(Database.Error error, String customString)
    {
        Exception_Log__c newException = new Exception_Log__c();
        //newException.StackTrace__c = error?.getStackTraceString().abbreviate(CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error?.getMessage();
        newException.CustomString__c = customString;
        Database.insert(newException);
    } 
    
    public static void CreateExceptionLog(Exception error)
    {
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = error.getStackTraceString().abbreviate(CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        
        Database.insert(newException);
    }
    
    public static void createException(Exception e, String Category){
        
        Exception_Log__c el = new Exception_Log__c();
        el.ExceptionMessage__c = e.getMessage();
        el.StackTrace__c = e.getStackTraceString();
        el.Notes__c = Category;
        insert el;
        
    }
    
    public static void CreateExceptionLog(String ErrorPayload, String Category){
        
        Exception_Log__c el = new Exception_Log__c();
        el.ExceptionMessage__c = ErrorPayload;
        el.Notes__c = Category;
        insert el;
        
    }
    
     
   public static Boolean CheckResponseBodyValidity(Integer responseStatusCode , String responseBodyString)
    {
        Boolean isValid;
        
        if(responseStatusCode == NULL || responseStatusCode != CONSTANTS.INTEGRATION_REST_RESPONSE_200)
        {
            isValid = FALSE;
            return isValid;
        }
        
        if(responseBodyString == NULL || String.IsBlank(responseBodyString))
        {
            isValid = FALSE;
            return isValid;
        }
        
        isValid = TRUE;
        return isValid;
    }
    
    public static Map<String, String> getApiKeyMap(){
        
        Map<String, String> apiKeyMap = new Map<String, String>();
        for(APIKeys__c key : [SELECT Id, Club__c, Key__c FROM APIKeys__c]){
            apiKeyMap.put(key.Club__c, key.Key__c);
        }
        
        return apiKeyMap;
        
    }  
    
    public static Map<String, String> getClubMap(){
        
        Map<String, String> clubMap = new Map<String, String>();
        for(Club__c club : [SELECT Id, Name FROM Club__c]){
            clubMap.put(club.Name, club.Id);
        }
        
        return clubMap;
        
    }
    
    public static Id resolveClubId(String clubNameFromApi) {
        if (String.isBlank(clubNameFromApi)) {
            return null;
        }
        
        Map<String, String> clubMap = getClubMap();
        if (clubMap.containsKey(clubNameFromApi)) {
            return clubMap.get(clubNameFromApi);
        }
        
        String normalizedApiName = clubNameFromApi.trim().toLowerCase();
        for (String clubName : clubMap.keySet()) {
            String normalizedClubName = clubName.trim().toLowerCase();
            if (normalizedClubName == normalizedApiName
                || normalizedClubName.endsWith(normalizedApiName)
                || normalizedClubName.endsWith(' ' + normalizedApiName)) {
                return clubMap.get(clubName);
            }
        }
        
        return null;
    }
    

    public static Map<String, String> getUserMap(){
        
        Map<String, String> userMap = new Map<String, String>();
        for(User u : [SELECT Id, Email FROM User]){
            userMap.put(u.Email, u.Id);
        }
        
        return userMap;
        
    }
    
    public static Map<String, String> getProspectLeadMap(Set<String> clubfitProspectIds){
        
        Map<String, String> leadMap = new Map<String, String>();
        for(Lead lead : [SELECT Id, ProspectId__c FROM Lead WHERE ProspectId__c IN : clubfitProspectIds]){
            leadMap.put(lead.ProspectId__c, lead.Id);
        }
        
        return leadMap;
        
    }
    
    public static String encryptSha256(String val){
        if(val == null){
            return '';
        }else{
            Blob targetBlob = Blob.valueOf(val);
            Blob hash = Crypto.generateDigest('SHA-256', targetBlob);
            return EncodingUtil.convertToHex(hash);
        }
    }
    
    public static Map<String , String> ConstructRequestHeaders()
    {
        return new Map<String , String>{CONSTANTS.INTEGRATION_KEY_CONTENT_TYPE => CONSTANTS.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON};
            }
    
    public static Map<String , String> ConstructClubfitProspectsRequestHeaders(String apiKey, String accessToken)
    {
        return new Map<String , String>{
            CONSTANTS.INTEGRATION_KEY_CONTENT_TYPE => CONSTANTS.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON,
                CONSTANTS.INTEGRATION_X_API_KEY => apiKey,   
                CONSTANTS.INTEGRATION_AUTHORIZATION => accessToken
                };
                    }
    
    public static Map<String , String> ConstructClubfitAccessTokenRequestHeaders(Clubfit_API_Settings__c apiSettings)
    {
        
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(apiSettings.Username__c + ':' + apiSettings.Password__c));
        
        return new Map<String , String>{
            CONSTANTS.INTEGRATION_KEY_CONTENT_TYPE => CONSTANTS.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON,
                CONSTANTS.INTEGRATION_AUTHORIZATION => authorizationHeader    
                };
                    }
    
    
    
}