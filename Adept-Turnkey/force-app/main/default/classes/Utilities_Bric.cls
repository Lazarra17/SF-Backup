/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	October 18, 2021 
 * Description: 	Utility Class for reusable methods
 * Test Class: 		N/A
*/
public class Utilities_Bric 
{    
    public static void CreateExceptionLog(Exception error, String customString)
    {
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = error?.getStackTraceString().abbreviate(CONSTANTS_BRIC.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error?.getMessage().abbreviate(CONSTANTS_BRIC.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        newException.CustomString__c = customString.abbreviate(CONSTANTS_BRIC.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        Database.insert(newException);
    }
    
    public static void CreateExceptionLog(Exception error)
    {
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = error.getStackTraceString().abbreviate(CONSTANTS_BRIC.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error.getMessage().abbreviate(CONSTANTS_BRIC.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        
        Database.insert(newException);
    }

    public static void SetResponseToast(LWCObjects.ResponseToast response, Boolean isSuccess , String message)
    {	
        response.Message = message;
        
        if(isSuccess)
        {
            response.Title = CONSTANTS_BRIC.GENERIC_UPPERCASE_SUCCESS;
            response.Result = CONSTANTS_BRIC.GENERIC_SUCCESS;

        }
        else
        {
            response.Title = CONSTANTS_BRIC.GENERIC_UPPERCASE_ERROR;
            response.Result = CONSTANTS_BRIC.GENERIC_ERROR;
        }
    }    
       
    public static RestResponse GenerateRestResponse(Integer responseCode , String responseBody)
    {
        RestResponse response = new RestResponse();

        response.statusCode = responseCode;
        if(responseBody != NULL) response.responseBody = blob.valueOf(responseBody);
        
        return response;
    }
    
    public static RestResponse SetRestResponse(RestResponse response , Integer responseCode , String responseBody)
    {  
        if(test.isRunningTest()) response = new RestResponse();
        
        response.statusCode = responseCode;
        if(responseBody != NULL) response.responseBody = blob.valueOf(responseBody);
        
        return response;
    }
    
    public static Boolean CheckStringIfNullOrBlank(String stringToCheck)
    {
        return stringToCheck != NULL && !String.IsBlank(stringToCheck);
    }
    
     public static String FormatJSONBodyString(String responseBodyString , Map<String , String> responseBodyReplacementList)
    {
        for(String stringToReplace : responseBodyReplacementList.keySet())
        {
            responseBodyString = responseBodyString.replace(stringToReplace , responseBodyReplacementList.get(stringToReplace));
        }
        
        return responseBodyString;
    }
     public static Boolean CheckIfPersonAccountEnabled()
    {
        return Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount');
    }
    
    public static String GenerateAccountSOQL()
    {
        Schema.DescribeSObjectResult r = Account.sObjectType.getDescribe();
		List<String> apiNames =  new list<String>
        {
            'Id', 
            'Name', 
            'FirstName', 
            'LastName', 
            'XeroId__c', 
            'Phone',
            'Fax', 
            'ShippingCity', 
            'ShippingState', 
            'ShippingPostalCode',
            'ShippingCountry', 
            'ShippingStreet', 
            'isPersonAccount'
        };
        String query = 'SELECT ';
        
        for(String apiName : apiNames){

            if(r.fields.getMap().keySet().contains(apiName.toLowerCase())){
                query += apiName + ',';
            }
        
        }
        
        query = query.removeEnd(',');
                       
        query += ' FROM Account'; 
        
        return query;
    
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