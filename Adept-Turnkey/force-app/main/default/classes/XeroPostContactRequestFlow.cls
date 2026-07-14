/*
 * Author:          Alfonso Maquilan
 * Created Date:    May 11, 2021
 * Description:     Apex Class for Xero Outbound Post Contact callout Invoked from Flow
 * Test Class:      N/A
 * History:         May 11, 2021 - Creation
 * History:         Aug 26, 2021 - Add POBox Mapping
*/
public class XeroPostContactRequestFlow   
{
    @InvocableMethod(label = 'Sync Contact To Xero' description = 'Sends Salesforce Account to Xero to Sync with Xero Contact.')
    public static void SendContactToXeroFromFlow(List<XeroReqFlowParamsContact> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        PostContact(params[0]);
    }
    
    private static void PostContact(XeroReqFlowParamsContact params)
    {
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        RestRequestCollectionXero.PostXeroContact requestBody = SetPostContactBody(params);
        String requestBodyString = JSON.serialize(requestBody);
        
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_KEY_TYPE_X => CONSTANTS_BRIC.INTEGRATION_KEY_TYPE};   
        requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
                
        HttpResponse response = RestHandler.ExecuteRequest(requestHeader , endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_CONTACTS , requestBodyString, CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST); 
        String responseBodyString = response?.getBody();

        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){ 
            RestHandler.ExceptionLogWrapper contactExLog = new RestHandler.ExceptionLogWrapper();
            contactExLog.requestBody = requestBodyString;
            contactExLog.requestEndpoint =  endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_CONTACTS;
            contactExLog.responseBody = responseBodyString;
            contactExLog.statusCode = String.valueOf(response?.getStatusCode());
            Utilities_Bric.CreateExceptionLog(null, JSON.serialize(contactExLog));   
            return;
        }
    
        RestResponseCollectionXero.PostContactResponseBody responseBody = (RestResponseCollectionXero.PostContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.PostContactResponseBody.class);
    
        if(responseBody == NULL) return;
        PostXeroRequest.UpdateAccountFromXero(params.RecordId , responseBody?.Contacts[0]);
    }
    
    private static RestRequestCollectionXero.PostXeroContact SetPostContactBody(XeroReqFlowParamsContact params)
    {
        RestRequestCollectionXero.PostXeroContact requestBody = new RestRequestCollectionXero.PostXeroContact();
        if(params.ContactID != NULL && !String.IsBlank(params.ContactID)) requestBody.ContactID = params.ContactID; 
        requestBody.Name = params.Name;
        requestBody.ContactNumber = params.ContactNumber;
        requestBody.AccountNumber = params.AccountNumber;
        requestBody.ContactStatus = params.ContactStatus;
        requestBody.FirstName = params.FirstName;
        requestBody.LastName = params.LastName;
        requestBody.EmailAddress = params.EmailAddress;
        requestBody.SkypeUserName = params.SkypeUserName;
        requestBody.BankAccountDetails = params.BankAccountDetails;
        requestBody.TaxNumber = params.TaxNumber;
        requestBody.AccountsReceivableTaxType = params.AccountsReceivableTaxType;
        requestBody.AccountsPayableTaxType = params.AccountsPayableTaxType;
        requestBody.IsSupplier = params.IsSupplier;
        requestBody.IsCustomer = params.IsCustomer;
        requestBody.DefaultCurrency = params.DefaultCurrency;
        requestBody.XeroNetworkKey = params.XeroNetworkKey;
        requestBody.SalesDefaultAccountCode = params.SalesDefaultAccountCode;
        requestBody.PurchasesDefaultAccountCode = params.PurchasesDefaultAccountCode;
        requestBody.SalesTrackingCategories = params.SalesTrackingCategories;
        requestBody.PurchasesTrackingCategories = params.PurchasesTrackingCategories;
        requestBody.TrackingCategoryName = params.TrackingCategoryName;
       
        requestBody.PaymentTerms = new RestRequestCollectionXero.PaymentTerm();
        requestBody.PaymentTerms.Sales = new RestRequestCollectionXero.BillSalesPaymentTerm();
        requestBody.PaymentTerms.Sales.Type_x = params.PaymentTerms?.Sales?.Type_x;
        requestBody.PaymentTerms.Sales.Day = params.PaymentTerms?.Sales?.Day;
            
        requestBody.Phones = GenerateXeroPhoneList(params.Phone,params.Fax,params.Mobile);
        requestBody.Addresses = GenerateXeroAddressList(params);

        return requestBody;
    }
    
    private static List<RestRequestCollectionXero.Address> GenerateXeroAddressList(XeroReqFlowParamsContact params)
    {
        RestRequestCollectionXero.Address xeroStreetAddress = new RestRequestCollectionXero.Address();
        xeroStreetAddress.AddressType = CONSTANTS_BRIC.INTEGRATION_XERO_ADDRESS_ADDRESS_TYPE_STREET;
        xeroStreetAddress.AddressLine1 = params.BillingStreet;
        xeroStreetAddress.City = params.BillingCity;
        xeroStreetAddress.Region = params.BillingState;
        xeroStreetAddress.PostalCode = params.BillingPostalCode;
        xeroStreetAddress.Country = params.BillingCountry;

        RestRequestCollectionXero.Address xeroPOBOXAddress = new RestRequestCollectionXero.Address();
        xeroPOBOXAddress.AddressType = CONSTANTS_BRIC.INTEGRATION_XERO_ADDRESS_ADDRESS_TYPE_POBOX;
        xeroPOBOXAddress.AddressLine1 = params.ShippingStreet;
        xeroPOBOXAddress.City = params.ShippingCity;
        xeroPOBOXAddress.Region = params.ShippingState;
        xeroPOBOXAddress.PostalCode = params.ShippingPostalCode;
        xeroPOBOXAddress.Country = params.ShippingCountry;
        
        return new List<RestRequestCollectionXero.Address>{xeroStreetAddress,xeroPOBOXAddress};
    }
    
    private static List<RestRequestCollectionXero.Phone> GenerateXeroPhoneList(String phoneNumber , String faxNumber, String mobileNumber)
    {
        RestRequestCollectionXero.Phone xeroContactPhone = CreateXeroPhone(CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_DEFAULT , phoneNumber);
        RestRequestCollectionXero.Phone xeroContactFax = CreateXeroPhone(CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_FAX , faxNumber);
        RestRequestCollectionXero.Phone xeroContactMobile = CreateXeroPhone(CONSTANTS_BRIC.INTEGRATION_XERO_PHONE_PHONE_TYPE_MOBILE , mobileNumber);
        
        return new List<RestRequestCollectionXero.Phone>{xeroContactPhone , xeroContactFax,xeroContactMobile};
    }
    
    private static RestRequestCollectionXero.Phone CreateXeroPhone(String phoneType , String phoneNumber)
    {
        RestRequestCollectionXero.Phone xeroPhone = new RestRequestCollectionXero.Phone();
        xeroPhone.PhoneType = phoneType;
        xeroPhone.PhoneNumber = phoneNumber;
        
        return xeroPhone;
    }
}