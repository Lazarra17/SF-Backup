public class MefRequestUtilities {
    
    public static Map<String , String> ConstructRequestHeaders(Mef_API_Settings__c apiSettings)
    {
        return new Map<String , String>{
                CONSTANTS.INTEGRATION_KEY_ACCEPT => CONSTANTS.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON,
                CONSTANTS.INTEGRATION_KEY_SUBSCRIPTION => apiSettings?.Subscription_Key__c
                };
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
}