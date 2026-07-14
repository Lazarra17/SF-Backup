/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	October 18, 2021 
 * Description: 	Utility Class for reusable methods
 * Test Class: 		N/A
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
    
    /*
    public static void CreateExceptionLog(String statusCode, String error)
    {
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = statusCode;
        newException.ExceptionMessage__c = error;
        
        Database.insert(newException);
    }
   
    */
   
    
    
    /*
     public static Boolean CheckIfPersonAccountEnabled()
    {
        return Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount');
    }
    */
     
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