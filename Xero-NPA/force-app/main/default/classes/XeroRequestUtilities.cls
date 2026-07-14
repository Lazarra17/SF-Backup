/*
 * Author:          Alfonso Maquilan
 * Created Date:    May 14, 2021
 * Description:     Utility Class for Xero Request
 * Test Class:      N/A
 * History:         May 14, 2021 - Creation
*/
public class XeroRequestUtilities 
{
    public static void GetTenantId()
    {
        HttpResponse response = RestHandler.ExecuteRequest(null, CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_CONNECTION, null, CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET);

        if(response.getStatusCode() != CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200) return;
        
        String responseString = response.getBody();
        
        if(responseString == NULL) return;
        
        List<RestResponseCollectionXero.XeroTenantIdResponseBody> tenantIdResponse = (List<RestResponseCollectionXero.XeroTenantIdResponseBody>)JSON.deserialize(responseString, List<RestResponseCollectionXero.XeroTenantIdResponseBody>.class);
		
        XeroAPISettings__c xeroAPISettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        if(xeroAPISettings != NULL && tenantIdResponse != NULL)
        {
            xeroAPISettings.TenantId__c = tenantIdResponse[0].tenantId;
            Database.Update(xeroAPISettings);
        }
    }
    
    public static Map<String , String> ConstructRequestHeaders(String tenantId)
    {
        return new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_XERO_HEADER_KEY_TENANT_ID => tenantId, 
                                        CONSTANTS_BRIC.INTEGRATION_XERO_HEADER_KEY_ACCEPT => CONSTANTS_BRIC.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON, 
                                        CONSTANTS_BRIC.INTEGRATION_KEY_CONTENT_TYPE => CONSTANTS_BRIC.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON};
    }
    
    public static String FormatJSONBodyString(String responseBodyString , Map<String , String> responseBodyReplacementList)
    {
        for(String stringToReplace : responseBodyReplacementList.keySet())
        {
            responseBodyString = responseBodyString.replace(stringToReplace , responseBodyReplacementList.get(stringToReplace));
        }
        
        return responseBodyString;
    }
    
    public static Boolean CheckResponseBodyValidity(Integer responseStatusCode , String responseBodyString)
    {
        Boolean isValid;
        
        if(responseStatusCode == NULL || responseStatusCode != CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200)
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