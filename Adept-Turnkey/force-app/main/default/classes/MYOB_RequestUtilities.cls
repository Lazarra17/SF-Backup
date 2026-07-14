/*
 * Author:          Bricoleur Technologies
 * Created Date:    November 18, 2021
 * Description:     Utility Class for MYOB Request
 * Test Class:      N/A
 * History:         November 18, 2021 - Creation
*/

public class MYOB_RequestUtilities {

    
    public static Map<String , String> ConstructRequestHeaders(String clientId)
    {
        return new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_HEADER_MYOB_KEY => clientId, 
            MYOB_CONSTANTS.INTEGRATION_MYOB_HEADER_KEY_ACCEPT => MYOB_CONSTANTS.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON, 
            MYOB_CONSTANTS.INTEGRATION_KEY_CONTENT_TYPE => MYOB_CONSTANTS.INTEGRATION_VALUE_CONTENT_TYPE_APPJSON,
            MYOB_CONSTANTS.INTEGRATION_HEADER_MYOB_VERSION => MYOB_CONSTANTS.INTEGRATION_HEADER_VALUE_MYOB_VERSION};
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
        
        if(responseStatusCode == NULL || responseStatusCode != MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_200)
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