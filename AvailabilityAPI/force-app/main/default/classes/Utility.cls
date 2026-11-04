/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Contains generic helper methods that can be reused anywhere.
@History: [1] Created - 3-Nov-2026
*/
public class Utility {
    
    public static void CreateExceptionLog(Exception error, String customString)
    {
     
        Exception_Log__c newException = new Exception_Log__c();
        newException.StackTrace__c = error?.getStackTraceString().abbreviate(AvailabilityConstants.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.ExceptionMessage__c = error?.getMessage().abbreviate(AvailabilityConstants.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        newException.CustomString__c = customString.abbreviate(AvailabilityConstants.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        Database.insert(newException);
    }
 
}