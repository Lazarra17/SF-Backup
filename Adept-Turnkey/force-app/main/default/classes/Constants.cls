public class Constants 
{
	//Generic Constants
	/*public static final String GENERIC_BLANK = '';
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
    
    //Date and Time Constants
    public static final String DATE_AND_TIME_TIME_EXTENSION = '00:00:00';
    
    //SObject Field Constants
    public static final String SOBJECT_FIELD_ID = 'Id';
    
    //SObject Constants
    public static final String SOBJECT_ACCOUNT = 'Account';
    public static final String SOBJECT_OPPORTUNITY = 'Opportunity';
    public static final String SOBJECT_OPPORTUNITY_LINE_ITEM = 'OpportunityLineItem';
    public static final String SOBJECT_XERO_WEBHOOK_STORAGE = 'XeroWebhookStorage';
    public static final String SOBJECT_XERO_WEBHOOK_STORAGE_C = 'XeroWebhookStorage__c';
    public static final String SOBJECT_XERO_INBOUND_FIELD_MAPPING = 'XeroInboundFieldMapping';
    public static final String SOBJECT_XERO_INBOUND_FIELD_MAPPING_C = 'XeroInboundFieldMapping_c';
    
    //Opportunity Constants
    public static final String OPPORTUNITY_STAGE_PROSPECTING = 'Prospecting';
    
    //Xero Inbound Field Mapping Constants
    public static final String XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT = 'XeroObject__c';
    public static final String XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT = 'CONTACT';
    public static final String XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE = 'INVOICE';
    public static final String XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE_LINE_ITEM = 'INVOICE LINE ITEM';
    
    //Validation Constants
    public static final String VALIDATION_ACTIVE_XERO_CONTACT_MAPPING_EXIST = 'An active Xero Contact Mapping already exists, only one can be active at a time.';
    public static final String VALIDATION_ACTIVE_XERO_CONTACT_MAPPING_EXIST_PERSONACCOUNT = 'An active Xero Contact Mapping already exists for Person Account, only one can be active at a time.';
    public static final String VALIDATION_ACTIVE_XERO_INVOICE_MAPPING_EXIST = 'An active Xero Invoice Mapping already exists, only one can be active at a time.';
    public static final String VALIDATION_ACTIVE_XERO_INVOICE_LINE_ITEM_MAPPING_EXIST = 'An active Xero Invoice Line Item Mapping already exists, only one can be active at a time.';
    public static final String PERSONACCOUNT_NOT_ENABLED = 'Person Account is not enabled in your organization. You cannot check the "Is Person Account" box.';
    
    //Flow Constants
    //Sync to Xero
    public static final String FLOW_SYNC_TO_XERO_VARIABLE_RECORD_ID = 'RecordId';
    public static final String FLOW_SYNC_TO_XERO_VARIABLE_SOBJECT = 'SObject';
    
    //Get Contact From Xero
    public static final String FLOW_GET_CONTACT_FROM_XERO_VARIABLE_RECORD_ID = 'RecordId';*/
    
    //Exception Log Constants
    public static final Integer EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT = 255;
    public static final Integer EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT = 131072;
    
    //Regular Expressions
    /*public static final String REGEX_PERIOD = '\\.';
    
    //Integration Constants
    public static final String INTEGRATION_REST_METHOD_GET = 'GET';
    public static final String INTEGRATION_REST_METHOD_POST = 'POST';
    public static final String INTEGRATION_REST_METHOD_PUT = 'PUT';
    public static final Integer INTEGRATION_REST_RESPONSE_200 = 200;
    public static final Integer INTEGRATION_REST_RESPONSE_401 = 401;
    public static final Integer INTEGRATION_REST_RESPONSE_400 = 400;
    
    //URI=L Constants
    public static final String URL_ENCODE_DOUBLE_QUOTE = '%22';
        
    public static final String INTEGRATION_KEY_TYPE = 'Type';
    public static final String INTEGRATION_KEY_TYPE_X = 'Type_x';
    public static final String INTEGRATION_KEY_DATE = 'Date';
    public static final String INTEGRATION_KEY_DATE_X = 'Date_x';
    public static final String INTEGRATION_VALUE_CONTENT_TYPE_APPJSON = 'application/json';
    public static final String INTEGRATION_VALUE_CONTENT_TYPE_APPPDF = 'application/pdf';
    public static final String INTEGRATION_KEY_CONTENT_TYPE = 'Content-Type';
    
    //Rest Response Collection
    //Xero
   /* public static final String RESPONSE_COLLECTION_XERO_INVOICE_DUE_DATE_STRING = 'DueDateString';
    public static final String RESPONSE_COLLECTION_XERO_INVOICE_DATE_STRING = 'DateString';
    
    //XERO Integeration Constants
    public static final String INTEGRATION_XERO_ENDPOINT_CONNECTION = 'callout:Xero_App/connections';
    public static final String INTEGRATION_XERO_ENDPOINT_INVOICES = '/Invoices';
    public static final String INTEGRATION_XERO_ENDPOINT_PURCHASEORDERS = '/PurchaseOrders';
    public static final String INTEGRATION_XERO_ENDPOINT_CONTACTS = '/Contacts';
    public static final String INTEGRATION_XERO_ENDPOINT_QUOTES = '/Quotes';
    public static final String INTEGRATION_XERO_ENDPOINT_ITEMS = '/Items';
    public static final String INTEGRATION_XERO_ENDPOINT_PAYMENTS = '/Payments';
    public static final String INTEGRATION_XERO_ENDPOINT_PARAMETER_ID = '?IDs';
    public static final String INTEGRATION_XERO_ENDPOINT_PARAMETER_WHERE = '?Where';
    
    public static final String INTEGRATION_XERO_HEADER_KEY_TENANT_ID = 'xero-tenant-id';
    public static final String INTEGRATION_XERO_HEADER_KEY_ACCEPT = 'Accept';
    public static final String INTEGRATION_XERO_HEADER_KEY_XERO_SIGNATURE = 'x-xero-signature';
    public static final String INTEGRATION_XERO_HEADER_KEY_IF_MODIFIED_SINCE = 'If-Modified-Since';
    
    
    public static final String INTEGRATION_XERO_WEBHOOK_SETTINGS = 'Xero_Webhook_Listener';
    
    public static final String INTEGRATION_XERO_EVENT_CATEGORY_CONTACT = 'CONTACT';
    public static final String INTEGRATION_XERO_EVENT_CATEGORY_INVOICE = 'INVOICE';
    public static final String INTEGRATION_XERO_EVENT_TYPE_UPDATE = 'UPDATE';
    
    public static final String INTEGRATION_XERO_PHONE_PHONE_TYPE_DEFAULT = 'DEFAULT';
    public static final String INTEGRATION_XERO_PHONE_PHONE_TYPE_FAX = 'FAX';
    public static final String INTEGRATION_XERO_PHONE_PHONE_TYPE_MOBILE = 'MOBILE';
    
    
    public static final String INTEGRATION_XERO_ADDRESS_ADDRESS_TYPE_STREET = 'STREET';
    public static final String INTEGRATION_XERO_ADDRESS_ADDRESS_TYPE_POBOX = 'POBOX';
    
    //Xero Objects Constants
    public static final String XERO_OBJECT_CONTACT = 'Contact';
    public static final String XERO_OBJECT_INVOICE = 'Invoice';

    //Invoice
    public static final String XERO_OBJECT_INVOICE_TYPE_ACCREC = 'ACCREC';
    public static final String XERO_OBJECT_INVOICE_TYPE_STATUS = 'AUTHORISED';
    public static final String XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION = 'T00:00:00';
    
    //Invoice Line Item
    public static final String XERO_OBJECT_INVOICE_LINE_ITEM_ACCOUNT_CODE_200 = '200';
    
    //Crypto Constants
    public static final String CRYPTO_HASHING_ALGORITHM_HMAC256 = 'hmacSHA256';
    
    //Toast Message Constants
    public static final String TOAST_XERO_SYNC_SUCCESSFUL = 'Successfully synced with Xero.';
    public static final String TOAST_XERO_SYNC_UNSUCCESSFUL = 'Sync with Xero unsuccessful.';
    public static final String TOAST_XERO_SYNC_UNSUPPORTED = 'Sync with Xero is unsupported for this SObject.';
    public static final String TOAST_XERO_SETTING_NOT_FOUND = 'Xero API Settings not found.';
    public static final String TOAST_XERO_TENANT_ID_NOT_SET = 'Tenant Id is not set on Xero API Settings.';
    public static final String TOAST_XERO_ACCOUNT_NOT_SYNCED = 'Account has not yet been synced with Xero.';
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
    }*/
    
       
}