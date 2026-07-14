/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	January 14, 2021
 * Description: 	Utility Class for reusable methods
 * Test Class: 		N/A
*/
public class Utilities 
{    
    public static void CreateExceptionLogError(Database.Error error, String notes)
    {
       
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = String.valueof(error.getFields());
        newException.ExceptionMessage__c = error?.getMessage().abbreviate(MYOB_CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        newException.Notes__c = notes;
        Database.insert(newException);
    }
    public static void CreateExceptionLog(Exception error, String notes)
    {
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = error?.getStackTraceString().abbreviate(MYOB_CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error?.getMessage().abbreviate(MYOB_CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        newException.Notes__c = notes;
        Database.insert(newException);
    }
     public static void CreateExceptionLog(Exception error)
    {
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = error.getStackTraceString().abbreviate(CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        
        Database.insert(newException);
    }
    
    public static void CreateRequestResponseLog(String method, String requestBody, String responseBody, Integer statusCode, String integName)
    {
        Integration_Request_and_Response__c responseRequestLog = new Integration_Request_and_Response__c();
        responseRequestLog.Name = integName.abbreviate(80);
        responseRequestLog.Method__c = method;
        responseRequestLog.Request_String__c = requestBody?.abbreviate(MYOB_CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        responseRequestLog.Response_String__c = responseBody?.abbreviate(MYOB_CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        responseRequestLog.Status_Code__c = statusCode;
        Database.insert(responseRequestLog);
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
    
    public static Boolean CheckIfPersonAccountEnabled()
    {
        return Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount');
    }
    
   /* public static void SetResponseToast(LWCObjects.ResponseToast response, Boolean isSuccess , String message)
    {	
        response.Message = message;
        
        if(isSuccess)
        {
            response.Title = 'SUCCESS';
            response.Result = 'success';

        }
        else
        {
            response.Title = 'ERROR';
            response.Result = 'error';
        }
    }    */
       
    
}