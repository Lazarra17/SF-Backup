/*
* Author: Bricoleur Technologies
* Created Date: June 23, 2023
* Description: Apex class for all requests to MYOB 
*/

public class MYOB_Constants {
    
    //Generic Constants
    public static final String GENERIC_BLANK = '';
    public static final String GENERIC_SPACE = ' ';
    public static final String GENERIC_SUCCESS = 'success';
    public static final String GENERIC_UPPERCASE_SUCCESS = 'Success';
    public static final String GENERIC_ERROR = 'error';
    public static final String GENERIC_UPPERCASE_ERROR = 'Error';
    public static final String GENERIC_COMMA = ',';
    public static final String GENERIC_NEXT_LINE = '\n';
    public static final String GENERIC_PERIOD = '.';
    public static final String GENERIC_EQUALS = '=';
    public static final String GENERIC_QUESTION_MARK = '?';
    public static final String GENERIC_SINGLE_QUOTE = '\'';
    public static final String GENERIC_DASH = '-';
    
    //Date and Time Constants
    public static final String DATE_AND_TIME_TIME_EXTENSION = '00:00:00';
        
    //Exception Log Constants
    public static final Integer EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT = 255;
    public static final Integer EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT = 131072;
    
    
    //SOBJECT Constants
    public static final String ACCOUNT_TYPE_CUSTOMER = 'Customer';
    public static final String ACCOUNT_TYPE_SUPPLIER = 'Supplier';
    
    
    //Regular Expressions
    public static final String REGEX_PERIOD = '\\.';
    
    //Integration Constants
    public static final String INTEGRATION_REST_METHOD_GET = 'GET';
    public static final String INTEGRATION_REST_METHOD_POST = 'POST';
    public static final String INTEGRATION_REST_METHOD_PUT = 'PUT';
    public static final Integer INTEGRATION_REST_RESPONSE_200 = 200;
    public static final Integer INTEGRATION_REST_RESPONSE_401 = 401;
    public static final Integer INTEGRATION_REST_RESPONSE_400 = 400;
    public static final Integer INTEGRATION_REST_RESPONSE_201 = 201;
    
    //MYOB Constants
    public static final String INTEGRATION_HEADER_MYOB_KEY = 'x-myobapi-key';
    public static final String INTEGRATION_HEADER_MYOB_LOCATION = 'location';    
    public static final String INTEGRATION_HEADER_MYOB_VERSION = 'x-myobapi-version';
    public static final String INTEGRATION_HEADER_VALUE_MYOB_VERSION = 'v2';
    public static final String INTEGRATION_MYOB_HEADER_KEY_ACCEPT = 'Accept';
    public static final String INTEGRATION_VALUE_CONTENT_TYPE_APPJSON = 'application/json';
    public static final String INTEGRATION_KEY_CONTENT_TYPE = 'Content-Type';
    public static final String INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM = '/Inventory/Item';
    public static final String INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER = '/Contact/Customer';
    public static final String INTEGRATION_MYOB_ENDPOINT_CONTACT_SUPPLIER = '/Contact/Supplier';
    public static final String INTEGRATION_MYOB_ENDPOINT_INVOICES = '/Sale/Invoice/';
    public static final String INTEGRATION_MYOB_ENDPOINT_ORDERS = '/Sale/Order/';
    public static final String INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM = '/Sale/Order/Item';    
    public static final String INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM = '/Sale/Invoice/Item'; 
    public static final String INTEGRATION_MYOB_ENDPOINT_SALE_INVOICES = '/Sale/Invoice/Service'; 
    public static final String INTEGRATION_MYOB_ENDPOINT_PURCHASE_ORDERS_ITEM = '/Purchase/Order/Item';  
    public static final String INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM = '/Purchase/Bill/Item';  
    public static final String INTEGRATION_MYOB_ENDPOINT_JOB = '/GeneralLedger/Job';
    public static final String INTEGRATION_MYOB_ENDPOINT_CUSTOMER_PAYMENT = '/Sale/CustomerPayment';
    public static final String INTEGRATION_MYOB_ORDERBY = '$orderby=';
    public static final String INTEGRATION_MYOB_ORDERBY_ROW_VERSION = 'RowVersion asc';
    public static final String INTEGRATION_MYOB_ORDERBY_TOP_1000 = '&$top=1000';
    
    public static final String INTEGRATION_MYOB_FILTER = '$filter=';
    public static final String INTEGRATION_MYOB_FILTER_FIRSTNAME = 'FirstName eq ';
    public static final String INTEGRATION_MYOB_FILTER_LASTNAME = 'LastName eq ';
    public static final String INTEGRATION_MYOB_FILTER_COMPNAME = 'CompanyName eq ';
    public static final String INTEGRATION_MYOB_FILTER_DISPLAYID = 'DisplayID eq ';
    public static final String INTEGRATION_MYOB_FILTER_ABN = 'SellingDetails/ABN eq ';
    public static final String INTEGRATION_MYOB_FILTER_SUPPLIER_ABN = 'BuyingDetails/ABN eq ';
    public static final String INTEGRATION_MYOB_FILTER_NUMBER = 'Number eq ';
    public static final String INTEGRATION_MYOB_FILTER_LASTMODIFIED = 'LastModified ge ';
    public static final String INTEGRATION_MYOB_FILTER_CREATEDDATE = 'Date ge ';
    public static final String INTEGRATION_MYOB_FILTER_DATETIME = 'datetime';
    public static final String INTEGRATION_MYOB_FILTER_STATUS_NE = 'Status ne ';
    public static final String INTEGRATION_MYOB_FILTER_STATUS_EQ = 'Status eq ';
    public static final String INTEGRATION_MYOB_FILTER_CLOSED = 'Closed';    
	public static final String INTEGRATION_MYOB_FILTER_OPEN = 'Open';       
    //Flow Constants
    //Sync to MYOB
    public static final String FLOW_SYNC_TO_MYOB_VARIABLE_RECORD_ID = 'RecordId';
    public static final String FLOW_SYNC_TO_MYOB_VARIABLE_SOBJECT = 'SObject';
    
    //URI=L Constants
    public static final String URL_ENCODE_DOUBLE_QUOTE = '%22';
    
    public static final String INTEGRATION_KEY_TYPE = 'Type';
    public static final String INTEGRATION_KEY_TYPE_X = 'Type_x';
    public static final String INTEGRATION_KEY_NUMBER = 'Number';
    public static final String INTEGRATION_KEY_NUMBER_X = 'Number_x';
    public static final String INTEGRATION_KEY_DATE = 'Date';
    public static final String INTEGRATION_KEY_DATE_X = 'Date_x';
    
    //Crypto Constants
    public static final String CRYPTO_HASHING_ALGORITHM_HMAC256 = 'hmacSHA256';
        
    
    //Toast Message Constants
    public static final String TOAST_MYOB_SYNC_SUCCESSFUL = 'Successfully synced with MYOB.';
    public static final String TOAST_MYOB_SYNC_UNSUCCESSFUL = 'Sync with MYOB unsuccessful.';
    public static final String TOAST_MYOB_SYNC_UNSUPPORTED = 'Sync with MYOB is unsupported for this SObject.';
    public static final String TOAST_MYOB_SETTING_NOT_FOUND = 'MYOB API Settings not found.';
    public static final String TOAST_MYOB_TENANT_ID_NOT_SET = 'Tenant Id is not set on MYOB API Settings.';
    public static final String TOAST_MYOB_ACCOUNT_NOT_SYNCED = 'Account has not yet been synced with MYOB.';
    public static final String TOAST_RECORD_NOT_FOUND = 'Record was not found.';
    public static final String TOAST_ACCOUNT_NOT_FOUND = 'Account was not found.';
    public static final String TOAST_LINE_ITEMS_NOT_FOUND = 'Line items were not found.';
        
    //Error Messages
    public static final String ERROR_REQUEST_NOT_SET = 'Request has not been set.';
    
    public static String ERROR_MESSAGE_TRIGGER_HANDLER_METADATA_DOES_NOT_EXIST(String SObjectName)
    {
        return 'Object Trigger Handler for the \'' + SObjectName + '\' was not found, check the Trigger Handler Custom Metadata for \'' + SObjectName + '\'.';
    }
     
    public static String ERROR_MESSAGE_TRIGGER_HANDLER_DOES_NOT_EXIST(String SObjectName)
    {
        return 'Trigger Handler setting does not exist for the SObject \'' + SObjectName + '\'.';
    }

}