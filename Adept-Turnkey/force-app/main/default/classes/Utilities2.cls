/**
*@description Utility Class for reusable methods
*@date October 18, 2021 
*@author Bricoleur Technologies
* [1] JP Sulit Oct-16-2024 - Added Security.stripInaccessible for DMLs that has ApexCRUDViolation in code scan
* [2] JP Sulit Feb-25-2025 Bulkify exception logs
*/
@NamespaceAccessible
public with sharing class Utilities2
{
    /** 
     * @description [2] JP Sulit Feb-25-2025 Bulkify exception logs
     * @param errorList
    */
	//START
    public static void createExceptionLog(List<Exception> errorList)
    {
        List<nao__Exception_Log__c> errorLogs = new List<nao__Exception_Log__c>();

        for(Exception error : errorList) {
            nao__Exception_Log__c newException = new nao__Exception_Log__c();
            newException.nao__StackTrace__c = error.getStackTraceString().abbreviate(CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
            newException.nao__ExceptionMessage__c = error.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
            errorLogs.add(newException);
        }
        
        //Database.insert(errorLogs, false);
        SObjectAccessDecision decExcInsert = Security.stripInaccessible(AccessType.CREATABLE, errorLogs); 
        Database.insert(decExcInsert.getRecords());
    }
    //END    
    /** 
     * @description Creates nao__Exception_Log__c record
     * @param error
     * @param customString
    */
    public static void createExceptionLog(Exception error, String customString)
    {
        nao__Exception_Log__c newException = new nao__Exception_Log__c();
        newException.nao__StackTrace__c = error?.getStackTraceString().abbreviate(CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.nao__ExceptionMessage__c = error?.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        newException.nao__CustomString__c = customString.abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        //[1] JP Sulit Oct-16-2024 - Added Security.stripInaccessible for DMLs that has ApexCRUDViolation in code scan
        //START
        SObjectAccessDecision decExcInsert = Security.stripInaccessible(AccessType.CREATABLE, new List<nao__Exception_Log__c> {newException}); 
        Database.insert(decExcInsert.getRecords());
        //Database.insert(newException);
        //END
    }
    /** 
     * @description Creates nao__Exception_Log__c record
     * @param error
    */    
    public static void createExceptionLog(Exception error)
    {
        nao__Exception_Log__c newException = new nao__Exception_Log__c();
        newException.nao__StackTrace__c = error.getStackTraceString().abbreviate(CONSTANTS.EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT);
        newException.nao__ExceptionMessage__c = error.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        //[1] JP Sulit Oct-16-2024 - Added Security.stripInaccessible for DMLs that has ApexCRUDViolation in code scan
        //START
        SObjectAccessDecision decExcInsert = Security.stripInaccessible(AccessType.CREATABLE, new List<nao__Exception_Log__c> {newException}); 
        Database.insert(decExcInsert.getRecords());
        //Database.insert(newException);
        //END
    }
    /** 
     * @description Sets LWC Response Toast
     * @param response
     * @param isSuccess
     * @param message
    */
    /*public static void setResponseToast(LWCObjects.ResponseToast response, Boolean isSuccess , String message)
    {	
        response.Message = message;
        
        if(isSuccess)
        {
            response.Title = CONSTANTS.GENERIC_UPPERCASE_SUCCESS;
            response.Result = CONSTANTS.GENERIC_SUCCESS;

        }
        else
        {
            response.Title = CONSTANTS.GENERIC_UPPERCASE_ERROR;
            response.Result = CONSTANTS.GENERIC_ERROR;
        }
    }*/    
    /** 
     * @description Generates rest response
     * @param responseCode
     * @param responseBody
     * @return RestResponse
    */
    public static RestResponse generateRestResponse(Integer responseCode , String responseBody)
    {
        RestResponse response = new RestResponse();

        response.statusCode = responseCode;
        if(responseBody != NULL) {response.responseBody = blob.valueOf(responseBody);}
        
        return response;
    }
    /** 
     * @description Sets rest response
     * @param response
     * @param responseCode
     * @param responseBody
     * @return RestResponse
    */
    public static RestResponse setRestResponse(RestResponse response , Integer responseCode , String responseBody)
    {  
        if(test.isRunningTest()) {response = new RestResponse();}
        
        response.statusCode = responseCode;
        if(responseBody != NULL) {response.responseBody = blob.valueOf(responseBody);}
        
        return response;
    }
    
    /** 
     * @description Creates exception log for Messaging.SendEmailError
     * @param error
    */
    public static void createExceptionLog(Messaging.SendEmailError error)
    {
        nao__Exception_Log__c newException = new nao__Exception_Log__c();
        newException.nao__ExceptionMessage__c = error.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
        
        //[2] CLAZARRA 06-Mar-2025 - Added Security.stripInaccessible for DMLs that has ApexCRUDViolation in code scan
        SObjectAccessDecision decOiInsert = Security.stripInaccessible(AccessType.CREATABLE, new List<nao__Exception_Log__c>{newException}); 
        Database.insert(decOiInsert.getRecords());
        //[2]END
    }

    /** 
     * @description Creates bulkified exception logs for Messaging.SendEmailError
     * @param error
    */
    public static void createExceptionLog(List<Messaging.SendEmailError> error)
    {
        List<nao__Exception_Log__c> exLogs = new List<nao__Exception_Log__c>();
        for(Messaging.SendEmailError err : error) {
            nao__Exception_Log__c newException = new nao__Exception_Log__c();
            newException.nao__ExceptionMessage__c = err.getMessage().abbreviate(CONSTANTS.EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT);
            exLogs.add(newException);
        }     
        SObjectAccessDecision decOiInsert = Security.stripInaccessible(AccessType.CREATABLE, exLogs); 
        Database.insert(decOiInsert.getRecords());
    }
    
    /** 
     * @description Checks blank strings
     * @param stringToCheck
     * @return Boolean
    */
    public static Boolean checkStringIfNullOrBlank(String stringToCheck)
    {
        return stringToCheck != NULL && !String.IsBlank(stringToCheck);
    }
    /** 
     * @description Formats JSON string
     * @param responseBodyString
     * @param responseBodyReplacementList
     * @return String
    */
     public static String formatJSONBodyString(String responseBodyString , Map<String , String> responseBodyReplacementList)
    {
        for(String stringToReplace : responseBodyReplacementList.keySet())
        {
            responseBodyString = responseBodyString.replace(stringToReplace , responseBodyReplacementList.get(stringToReplace));
        }
        
        return responseBodyString;
    }
    /** 
     * @description Checks if Person Account is enabled
     * @return Boolean
    */
     public static Boolean checkIfPersonAccountEnabled()
    {
        return Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount');
    }
    /** 
     * @description Returns SOQL string
     * @return String
    */    
    public static String generateAccountSOQL()
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
    /** 
     * @description Checks response body validity
     * @param responseStatusCode
     * @param responseBodyString
     * @return Boolean
    */           
   public static Boolean checkResponseBodyValidity(Integer responseStatusCode , String responseBodyString)
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