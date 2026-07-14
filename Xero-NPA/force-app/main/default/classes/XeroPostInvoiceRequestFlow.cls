/*
* Author:          Alfonso Maquilan
* Created Date:    May 14, 2021
* Description:     Apex Class for Xero Outbound Post Invoice callout Invoked from Flow
* Test Class:      XeroRequestTest
* History:         May 14, 2021 - Creation
*/
public class XeroPostInvoiceRequestFlow 
{
    private class PostInvoiceAsync implements Queueable, Database.AllowsCallouts
    {
        private String Endpoint;
        private Map<String , String> RequestHeader;
        private String RequestBody;
        private String RequestMethod;
        private String SalesforceRecordId;
        private Boolean EmailToXero;
        private XeroReqFlowParamsInvoice InvoiceParams;
        private String InvoiceContactID;
        
        
        public void initializeProperties()
        {
            this.Endpoint = CONSTANTS_BRIC.GENERIC_BLANK;
            this.RequestHeader = new Map<String , String>();
            this.RequestBody = CONSTANTS_BRIC.GENERIC_BLANK;
            this.RequestMethod = CONSTANTS_BRIC.GENERIC_BLANK;
        }
        
        public String getEndpoint()
        {
            return this.Endpoint;
        }
        
        public Map<String , String> getRequestHeader()
        {
            return this.RequestHeader;
        }
        
        public String getRequestBody()
        {
            return this.RequestBody;
        }
        
        public String getRequestMethod()
        {
            return this.RequestMethod;
        }
        
        public String getSalesforceRecordId()
        {
            return this.SalesforceRecordId;
        }
        
        public Boolean getEmailToXero()
        {
            return this.EmailToXero;
        }
        
        public XeroReqFlowParamsInvoice getInvoiceParams()
        {
            return this.InvoiceParams;
        }
        
        public String getInvoiceContactID()
        {
            return this.InvoiceContactID;
        }
        
        public void setEndpoint(String endpoint)
        {
            this.Endpoint = endpoint;
        }
        
        public void setRequestHeader(Map<String , String> requestHeader)
        {
            this.RequestHeader = requestHeader;
        }
        
        public void setRequestBody(String requestBody)
        {
            this.RequestBody = requestBody;
        }
        
        public void setRequestMethod(String requestMethod)
        {
            this.RequestMethod = requestMethod;
        }
        
        public void setSalesforceRecordId(String salesforceRecordId)
        {
            this.SalesforceRecordId = salesforceRecordId;
        }
        
        public void setEmailToXero(Boolean emailToXero)
        {
            this.EmailToXero = EmailToXero;
        }
        
        public void setInvoiceParams(XeroReqFlowParamsInvoice invoiceParams)
        {
            this.InvoiceParams = InvoiceParams;
        }
        
        public void setInvoiceContactID(string invoiceContactID)
        {
            this.InvoiceContactID = invoiceContactID;
        }
        
        public void execute(QueueableContext context)
        {
            List<Exception_Log__c> exceptionLogList = new List<Exception_Log__c>();
            
            Schema.SObjectType OpportunityObject = Schema.getGlobalDescribe().containsKey('Opportunity') ? Schema.Opportunity.getSObjectType() : null;
            Schema.SObjectType OrderObject = Schema.getGlobalDescribe().containsKey('Order') ? Schema.Order.getSObjectType() : null;
            Schema.SObjectType WorkOrderObject = Schema.getGlobalDescribe().containsKey('WorkOrder') ? Schema.WorkOrder.getSObjectType() : null;
            Schema.SObjectType InvoiceObject = Schema.getGlobalDescribe().containsKey('Xero_Invoice__c') ? Schema.Xero_Invoice__c.getSObjectType() : null;
            
            Id recordId = this.SalesforceRecordId;
            Schema.SObjectType record = recordId.getSObjectType();
            System.debug('this.RequestBody:'+this.RequestBody);
            HttpResponse response = RestHandler.ExecuteRequest(this.RequestHeader , this.Endpoint , this.RequestBody , this.RequestMethod);
            String responseBodyString = response?.getBody();
            
            if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){ 
                
                RestHandler.ExceptionLogWrapper invoiceExLog = new RestHandler.ExceptionLogWrapper();
                invoiceExLog.requestBody = this.RequestBody;
                invoiceExLog.requestEndpoint =  this.Endpoint;
                invoiceExLog.responseBody = responseBodyString;
                invoiceExLog.statusCode = String.valueOf(response?.getStatusCode());
                if(record == OrderObject && OrderObject != null){
                    Order orderFail = [SELECT Id,AccountId FROM Order WHERE Id=:recordId];
                    orderFail.Id = recordId;	
                    orderFail.Xero_Status__c = 'Failed to Send to Xero';	
                    update orderFail;
                    
                    if(this.InvoiceParams.CreateContactInXero && this.InvoiceContactID != '' && this.InvoiceContactID != NULL){
                        Account accRecord = new Account();
                        accRecord.Id = orderFail.AccountId;
                        accRecord.XeroId__c = this.InvoiceContactID;
                        update accRecord;
                    }
                    
                }else if(record == InvoiceObject && InvoiceObject != null){
                    Xero_Invoice__c invoiceFail = [SELECT Id,Account__c FROM Xero_Invoice__c WHERE Id=:recordId];
                    invoiceFail.Id = recordId;	
                    invoiceFail.Status__c = 'Failed to Send to Xero';	
                    update invoiceFail;
                    
                    if(this.InvoiceParams.CreateContactInXero && this.InvoiceContactID != '' && this.InvoiceContactID != NULL){
                        Account accRecord = new Account();
                        accRecord.Id = invoiceFail.Account__c;
                        accRecord.XeroId__c = this.InvoiceContactID;
                        update accRecord;
                    }
                }
                else if(record == WorkOrderObject && WorkOrderObject != null){
                    WorkOrder workOrderFail = [SELECT Id,AccountId FROM WorkOrder WHERE Id=:recordId];
                    workOrderFail.Id = recordId;	
                    workOrderFail.Xero_Status__c = 'Failed to Send to Xero';	
                    update workOrderFail;
                    
                    if(this.InvoiceParams.CreateContactInXero && this.InvoiceContactID != '' && this.InvoiceContactID != NULL){
                        Account accRecord = new Account();
                        accRecord.Id = workOrderFail.AccountId;
                        accRecord.XeroId__c = this.InvoiceContactID;
                        update accRecord;
                    }
                }
                else if(record == OpportunityObject && OpportunityObject != null){
                    Opportunity opp = [SELECT Id,AccountId FROM Opportunity WHERE Id=:recordId];                    
                    if(this.InvoiceParams.CreateContactInXero && this.InvoiceContactID != '' && this.InvoiceContactID != NULL){
                        Account accRecord = new Account();
                        accRecord.Id = opp.AccountId;
                        accRecord.XeroId__c = this.InvoiceContactID;
                        update accRecord;
                    }
                }
                Utilities_Bric.CreateExceptionLog(null, JSON.serialize(invoiceExLog));                
                return;
            }
            
            RestResponseCollectionXero.PostInvoiceResponseBody responseBody = (RestResponseCollectionXero.PostInvoiceResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.PostInvoiceResponseBody.class) ;
            
            if(responseBody == NULL) return;
            
            //PUT PAYMENT
            if(this.InvoiceParams?.Payments?.size() > 0){
                HttpResponse paymentResponseBody = PutXeroPayments(this.RequestHeader, this.InvoiceParams , responseBody.Invoices[0]?.InvoiceID);
                String paymentResponseBodyString = paymentResponseBody?.getBody();
                
                if(XeroRequestUtilities.CheckResponseBodyValidity(paymentResponseBody?.getStatusCode() , paymentResponseBodyString)){
                    RestRequestCollectionXero.PutPaymentBody paymentResponse = (RestRequestCollectionXero.PutPaymentBody)JSON.deserialize(paymentResponseBodyString, RestRequestCollectionXero.PutPaymentBody.class);
                }else{
                    Exception_Log__c paymentException = new Exception_Log__c();
                    RestHandler.ExceptionLogWrapper paymentExLog = new RestHandler.ExceptionLogWrapper();
                    paymentExLog.requestBody = JSON.serialize(this.InvoiceParams);
                    paymentExLog.requestEndpoint = endpoint;
                    paymentExLog.responseBody = paymentResponseBodyString;
                    paymentExLog.statusCode = String.valueOf(paymentResponseBody?.getStatusCode());
                    paymentException.CustomString__c = JSON.serialize(paymentExLog);
                    exceptionLogList.add(paymentException);
                }
            }
            
            //EMAIL INVOICE
            if(this.EmailToXero != NULL && this.EmailToXero) RestHandler.ExecuteRequest(this.RequestHeader , this.Endpoint + '/'+responseBody.Invoices[0]?.InvoiceID +'/Email'  , null , this.RequestMethod);
            
            //GET INVOICE AS PDF
            Boolean getAsPDF = this.InvoiceParams?.GetInvoiceAsPDF; 
            ContentVersion invoicePDF = new ContentVersion();
            if(getAsPDF){
                invoicePDF = GetXeroInvoiceAsPDF(this.RequestHeader, this.Endpoint, this.SalesforceRecordId, responseBody.Invoices[0]?.InvoiceNumber, responseBody.Invoices[0]?.InvoiceID);
            }else{
                invoicePDF = null;
            }
            
            //DML Processing
            
            if(record == OpportunityObject && OpportunityObject != null){
                PostXeroRequest.UpdateOpportunityAndLineItemsFromXero(this.SalesforceRecordId , responseBody.Invoices[0]?.InvoiceID, this.InvoiceContactID, responseBody.Invoices[0]?.LineItems);
            }
            if(record == InvoiceObject && InvoiceObject != null){
                PostXeroRequest.UpdateInvoiceAndLineItemsFromXero(this.SalesforceRecordId , responseBody.Invoices[0]?.InvoiceID, this.InvoiceContactID, responseBody.Invoices[0]?.LineItems);
            }
            if(record == OrderObject && OrderObject != null){
                PostXeroRequest.UpdateOrderAndLineItemsFromXero(this.SalesforceRecordId , responseBody.Invoices[0]?.InvoiceID, this.InvoiceContactID, responseBody.Invoices[0]?.LineItems);
            }
            if(record == WorkOrderObject && WorkOrderObject != null){
                PostXeroRequest.UpdateWorkOrderAndLineItemsFromXero(this.SalesforceRecordId , responseBody.Invoices[0]?.InvoiceID, this.InvoiceContactID, responseBody.Invoices[0]?.LineItems);
            } 
            if(exceptionLogList.size() > 0) Database.insert(exceptionLogList);
            if(invoicePDF != null) Database.insert(invoicePDF);
        }
    }
    
    @InvocableMethod(label = 'Sync Invoice to Xero' description = 'Sends Salesforce Record to Sync with Xero Invoice.')
    public static void SendOpportunityToXeroFlow(List<XeroReqFlowParamsInvoice> params)
    {
        if(params == NULL || params.isEmpty()) return;
        PostInvoice(params[0]);
    }
    
    private static void PostInvoice(XeroReqFlowParamsInvoice params)
    {
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        
        RestRequestCollectionXero.PostInvoiceBody requestBody = new RestRequestCollectionXero.PostInvoiceBody();
        requestBody.Invoices = new List<RestRequestCollectionXero.Invoice>{SetPostInvoiceBody(params)};
            
            String requestBodyString = JSON.serialize(requestBody);
        
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_KEY_TYPE_X => CONSTANTS_BRIC.INTEGRATION_KEY_TYPE,
            CONSTANTS_BRIC.INTEGRATION_KEY_DATE_X => CONSTANTS_BRIC.INTEGRATION_KEY_DATE};   
                requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
        
        XeroPostInvoiceRequestFlow.PostInvoiceAsync postInvoice = new XeroPostInvoiceRequestFlow.PostInvoiceAsync();
        postInvoice.setEndpoint(endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_INVOICES);
        postInvoice.setRequestHeader(requestHeader);
        postInvoice.setRequestBody(requestBodyString);
        postInvoice.setRequestMethod(CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST);        
        postInvoice.setSalesforceRecordId(params.SalesforceID);       
        postInvoice.setEmailToXero(params.EmailToXero);       
        postInvoice.setInvoiceParams(params);
        
        System.enqueueJob(postInvoice);
    }
    
    private static RestRequestCollectionXero.Invoice SetPostInvoiceBody(XeroReqFlowParamsInvoice params)
    {
        RestRequestCollectionXero.Invoice requestBody = new RestRequestCollectionXero.Invoice();
        requestBody.Reference = params.Reference;
        requestBody.Type_x = params.InvoiceType != NULL && !String.IsBlank(params.InvoiceType) ? params.InvoiceType : CONSTANTS_BRIC.XERO_OBJECT_INVOICE_TYPE_ACCREC;
        requestBody.Contact = SetXeroContact(params.InvoiceContactId,params);
        requestBody.Date_x = params.Date_x;
        requestBody.DueDate = params.DueDate;
        requestBody.LineItems = SetXeroLineItems(params.lineItems);
        requestBody.Status = params.Status;
        if(params.InvoiceID != NULL && !String.IsBlank(params.InvoiceID)) requestBody.InvoiceID = params.InvoiceId;
        requestBody.Url = params.URL;
        requestBody.CurrencyCode = params.CurrencyCode;
        requestBody.CurrencyRate = params.CurrencyRate;
        requestBody.SentToContact = params.SentToContact;
        requestBody.ExpectedPaymentDate = params.ExpectedPaymentDate;
        requestBody.PlannedPaymentDate = params.PlannedPaymentDate;
        requestBody.LineAmountTypes = params.LineAmountTypes;
        requestBody.InvoiceNumber = params.InvoiceNumber;	
        
        return requestBody;
    }
    
    private static RestRequestCollectionXero.XeroContact SetXeroContact(String contactId,XeroReqFlowParamsInvoice invoiceParams)
    {
        if(contactID == NULL || contactID ==''){
            XeroReqFlowParamsContact params = new XeroReqFlowParamsContact();
            params = invoiceParams.Contact;
            if(invoiceParams.CreateContactInXero){
                contactId = GetContact(params.SearchParameter, params.SearchParameterValue)?.ContactID;
                if(contactId == NULL || contactId == '') contactId = PostContact(params)?.ContactID;     
                XeroPostInvoiceRequestFlow.PostInvoiceAsync postInvoice = new XeroPostInvoiceRequestFlow.PostInvoiceAsync();
                postInvoice.setInvoiceContactID(contactId);
            }
        }
        
        RestRequestCollectionXero.XeroContact xeroContact = new RestRequestCollectionXero.XeroContact();
        xeroContact.ContactID = contactId;
        
        return xeroContact;
    }
    
    private static List<RestRequestCollectionXero.XeroLineItem> SetXeroLineItems(List<XeroReqFlowLineItemParams> lineItems)
    {
        List<RestRequestCollectionXero.XeroLineItem> xeroLineItemList = new List<RestRequestCollectionXero.XeroLineItem>();
        System.debug('##lineItems'+lineItems);
        for(XeroReqFlowLineItemParams lineItem : lineItems)
        {
            RestRequestCollectionXero.XeroLineItem xeroLine = new RestRequestCollectionXero.XeroLineItem();
            xeroLine.LineItemID = lineItem.LineItemId;
            xeroLine.Description = lineItem.Description;
            xeroLine.Quantity = lineItem.Quantity;
            xeroLine.UnitAmount = lineItem.UnitAmount;
            xeroLine.AccountCode = lineItem.AccountCode != NULL && !String.IsBlank(lineItem.AccountCode) ? lineItem.AccountCode : CONSTANTS_BRIC.XERO_OBJECT_INVOICE_LINE_ITEM_ACCOUNT_CODE_200;
            xeroLine.TaxType = lineItem.TaxType;
            xeroLine.TaxAmount = lineItem.TaxAmount;
            xeroLine.LineAmount = lineItem.LineAmount;
            xeroLine.DiscountRate = lineItem.DiscountRate;
            xeroLine.ItemCode = lineItem.ItemCode;
            system.debug('lineItem.ItemCode:'+lineItem.ItemCode);
            xeroLineItemList.add(xeroLine);
        }
        
        return xeroLineItemList;
    }
    
    private static RestRequestCollectionXero.PostXeroContact SetPostContactBody(XeroReqFlowParamsContact params)
    {
        RestRequestCollectionXero.PostXeroContact requestBody = new RestRequestCollectionXero.PostXeroContact();
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
    
    private static RestResponseCollectionXero.XeroContact PostContact(XeroReqFlowParamsContact params)
    {
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return null;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        RestRequestCollectionXero.PostXeroContact requestBody = SetPostContactBody(params);
        String requestBodyString = JSON.serialize(requestBody);
        
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_KEY_TYPE_X => CONSTANTS_BRIC.INTEGRATION_KEY_TYPE};   
            requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
        
        HttpResponse response = RestHandler.ExecuteRequest(requestHeader , endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_CONTACTS , requestBodyString, CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST); 
        String responseBodyString = response?.getBody();
        
        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return null;
        
        RestResponseCollectionXero.PostContactResponseBody responseBody = (RestResponseCollectionXero.PostContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.PostContactResponseBody.class);
        
        if(responseBody == NULL) return null;
        if(responseBody?.Contacts == NULL) return null;
        return responseBody?.Contacts[0];
    }
    
    private static List<RestRequestCollectionXero.Payment> SetPutPaymentBody(List<XeroReqFlowParamPayment> paymentParams,String InvoiceID)
    {
        List<RestRequestCollectionXero.Payment> paymentList = new List<RestRequestCollectionXero.Payment>();
        
        for(XeroReqFlowParamPayment paymentParam : paymentParams){
            
            RestRequestCollectionXero.Payment paymentItem = new RestRequestCollectionXero.Payment();
            paymentItem.Account = paymentParam.Account;
            paymentItem.Amount = paymentParam.Amount;
            paymentItem.Date_x = paymentParam.Date_x;
            paymentItem.Invoice = new RestRequestCollectionXero.Invoice();
            paymentItem.Invoice.InvoiceID = InvoiceID;
            paymentList.add(paymentItem);
        }
        
        return paymentList;
    }
    
    private static ContentVersion GetXeroInvoiceAsPDF(Map<String,String> requestHeader, String endpoint, String salesforceID,String invoiceNumber, String invoiceID){
        
        HttpResponse invoiceResponse = new HttpResponse();
        Map<String,String> invoicePDFRequestHeader = requestHeader;
        invoicePDFRequestHeader.put(CONSTANTS_BRIC.INTEGRATION_XERO_HEADER_KEY_ACCEPT,CONSTANTS_BRIC.INTEGRATION_VALUE_CONTENT_TYPE_APPPDF);
        invoiceResponse = RestHandler.ExecuteRequest(invoicePDFRequestHeader , endpoint + '/'+ invoiceID , null , CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET);
        if(invoiceResponse != NULL){
            Blob invoicePDF = invoiceResponse?.getBodyAsBlob();
            if(invoicePDF != NULL){
                //SAVE PDF AS ATTACHMENT
                List<ContentVersion> cv = [SELECT ID,ContentDocumentId,FirstPublishLocationId,Title 
                                           FROM ContentVersion 
                                           WHERE FirstPublishLocationId =: salesforceID
                                           AND Title =: invoiceNumber];
                
                ContentVersion contentVerItem = new ContentVersion();
                if(cv.size() > 0){
                    contentVerItem.ContentDocumentId = cv[0]?.ContentDocumentId;
                    contentVerItem.versionData = invoicePDF;
                    contentVerItem.pathOnClient = +'/'+invoiceNumber+'.pdf';
                }else{
                    contentVerItem.versionData = invoicePDF;
                    contentVerItem.title = invoiceNumber;
                    contentVerItem.pathOnClient = +'/'+invoiceNumber+'.pdf';
                    contentVerItem.FirstPublishLocationId = salesforceID;
                }
                
                return contentVerItem;
            }
        }
        return null;
    }
    
    private static HttpResponse PutXeroPayments(Map<String,String> requestHeader,XeroReqFlowParamsInvoice invoiceParams, String invoiceID){
        
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String endpoint = apiSettings?.Endpoint__c;
        
        RestRequestCollectionXero.PutPaymentBody putPaymentReqBody = new RestRequestCollectionXero.PutPaymentBody();
        putPaymentReqBody.Payments = SetPutPaymentBody(invoiceParams?.Payments,invoiceID);              
        String paymentReqBodyString = JSON.serialize(putPaymentReqBody);                
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_KEY_DATE_X => CONSTANTS_BRIC.INTEGRATION_KEY_DATE};   
            paymentReqBodyString = XeroRequestUtilities.FormatJSONBodyString(paymentReqBodyString , requestBodyReplacementList);
        HttpResponse paymentResponseBody = RestHandler.ExecuteRequest(requestHeader , endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_PAYMENTS, paymentReqBodyString , CONSTANTS_BRIC.INTEGRATION_REST_METHOD_PUT);
        return paymentResponseBody;
        
    }
    
    private static RestResponseCollectionXero.XeroContact GetContact(String parameter , String parameterValue)
    {
        if(!Utilities_Bric.CheckStringIfNullOrBlank(parameterValue)) return null;
        
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(tenantId == NULL) return null;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        String calloutEndpoint = endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_CONTACTS + GenerateEndpointParameter(parameter , parameterValue);
        
        HttpResponse response = RestHandler.ExecuteRequest(requestHeader , calloutEndpoint , NULL, CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET); 
        String responseBodyString = response?.getBody();
        
        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return null;
        
        RestResponseCollectionXero.GetContactResponseBody responseBody = (RestResponseCollectionXero.GetContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetContactResponseBody.class);
        
        if(responseBody == NULL || responseBody.Contacts.isEmpty()) return null;
        return responseBody?.Contacts[0];
    }
    
    private static String GenerateEndpointParameter(String parameter , String parameterValue)
    {
        String encodedParameter = parameter + CONSTANTS_BRIC.GENERIC_EQUALS + '"' + parameterValue + '"';
        encodedParameter = EncodingUtil.urlEncode(encodedParameter, 'UTF-8');
        return CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_PARAMETER_WHERE + CONSTANTS_BRIC.GENERIC_EQUALS + encodedParameter;
    }
}