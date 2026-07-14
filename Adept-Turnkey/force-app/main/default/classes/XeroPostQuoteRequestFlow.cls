/*
 * Author:          Bricoleur Technologies
 * Created Date:    July 22, 2021
 * Description:     Apex Class for Xero Outbound Post Quote callout Invoked from Flow
 * Test Class:      
 * History:         July 22, 2021 - Creation
*/
public class XeroPostQuoteRequestFlow 
{
    private class PostQuoteAsync implements Queueable, Database.AllowsCallouts
    {
        private String Endpoint;
        private Map<String , String> RequestHeader;
        private String RequestBody;
        private String RequestMethod;
        private String SalesforceRecordId;
        
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
        
        public void execute(QueueableContext context)
        {
            HttpResponse response = RestHandler.ExecuteRequest(this.RequestHeader , this.Endpoint , this.RequestBody , this.RequestMethod);
            String responseBodyString = response?.getBody();

            if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return;
            
            RestResponseCollectionXero.PostQuoteResponseBody responseBody = (RestResponseCollectionXero.PostQuoteResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.PostQuoteResponseBody.class) ;
            
            if(responseBody == NULL) return;
            Schema.SObjectType OpportunityObject = Schema.getGlobalDescribe().containsKey('Opportunity') ? Schema.Opportunity.getSObjectType() : null;
            Schema.SObjectType QuoteObject = Schema.getGlobalDescribe().containsKey('Quote') ? Schema.Order.getSObjectType() : null;
            Id recordId = this.SalesforceRecordId;
            Schema.SObjectType record = recordId.getSObjectType();
            if(record == QuoteObject && QuoteObject != null){
                PostXeroRequest.UpdateQuoteAndLineItemsFromXeroQuote(this.SalesforceRecordId , responseBody.Quotes);
            }
        }
    }
    
    @InvocableMethod(label = 'Sync Opportunity to Xero Quote' description = 'Sends Salesforce Opportunity to Xero to Sync with Xero Quote.')
    public static void SendOpportunityToXeroQuoteFlow(List<XeroReqFlowParamsQuote> params)
    {
        if(params == NULL || params.isEmpty()) return;
        if(params[0].QuoteID != NULL && !String.isBlank(params[0].QuoteID)) GetQuote(params[0]);
        else PostQuote(params[0]);
    }

    private static void GetQuote(XeroReqFlowParamsQuote params)
    {
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        
        XeroPostQuoteRequestFlow.PostQuoteAsync postQuote = new XeroPostQuoteRequestFlow.PostQuoteAsync();
        postQuote.setEndpoint(endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_QUOTES + '/' + params.QuoteID);
        postQuote.setRequestHeader(requestHeader);
        postQuote.setRequestMethod(CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET);        
        postQuote.setSalesforceRecordId(params.SalesforceRecordId);
        
        System.enqueueJob(postQuote);
    }
    
    private static void PostQuote(XeroReqFlowParamsQuote params)
    {
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        
        RestRequestCollectionXero.PostQuoteBody requestBody = new RestRequestCollectionXero.PostQuoteBody();
        requestBody.Quote = SetPostQuoteBody(params);

        String requestBodyString = JSON.serialize(SetPostQuoteBody(params));
 
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_KEY_TYPE_X => CONSTANTS_BRIC.INTEGRATION_KEY_TYPE,
                                                                                   CONSTANTS_BRIC.INTEGRATION_KEY_DATE_X => CONSTANTS_BRIC.INTEGRATION_KEY_DATE};   
        requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
        system.debug('postquote requestBodyString::: ' + requestBodyString);
        XeroPostQuoteRequestFlow.PostQuoteAsync postQuote = new XeroPostQuoteRequestFlow.PostQuoteAsync();
        postQuote.setEndpoint(endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_QUOTES);
        postQuote.setRequestHeader(requestHeader);
        postQuote.setRequestBody(requestBodyString);
        postQuote.setRequestMethod(CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST);        
        postQuote.setSalesforceRecordId(params.SalesforceRecordId);
        
        System.enqueueJob(postQuote);
    }
    
    private static RestRequestCollectionXero.Quote SetPostQuoteBody(XeroReqFlowParamsQuote params)
    {
        RestRequestCollectionXero.Quote requestBody = new RestRequestCollectionXero.Quote();
        requestBody.QuoteNumber = params.QuoteNumber;
        requestBody.Reference = params.Reference;
        requestBody.Terms = params.Terms;
        requestBody.Contact = SetXeroContact(params.QuoteContactID);
        requestBody.Date_x = params.Date_x;
        requestBody.ExpiryDate = params.ExpiryDate;
        requestBody.Status = params.Status;
        requestBody.LineItems = SetXeroLineItems(params.lineItems);
        if(params.QuoteID != NULL && !String.IsBlank(params.QuoteID)) requestBody.QuoteID = params.QuoteID;
        requestBody.CurrencyCode = params.CurrencyCode;
        requestBody.SubTotal = params.SubTotal;
        requestBody.TotalTax = params.TotalTax;
        requestBody.Total = params.Total;
        requestBody.Title = params.Title;
        requestBody.Summary = params.Summary;
        requestBody.LineAmountTypes = params.LineAmountTypes;
        
        return requestBody;
    }
    
    private static RestRequestCollectionXero.XeroContact SetXeroContact(String contactId)
    {
        RestRequestCollectionXero.XeroContact xeroContact = new RestRequestCollectionXero.XeroContact();
        xeroContact.ContactID = contactId;
        
        return xeroContact;
    }
    
    private static List<RestRequestCollectionXero.XeroLineItem> SetXeroLineItems(List<XeroReqFlowLineItemParams> lineItems)
    {
        List<RestRequestCollectionXero.XeroLineItem> xeroLineItemList = new List<RestRequestCollectionXero.XeroLineItem>();
        
        for(XeroReqFlowLineItemParams lineItem : lineItems)
        {
            RestRequestCollectionXero.XeroLineItem xeroLine = new RestRequestCollectionXero.XeroLineItem();
            
            if(lineItem.LineItemId != NULL && !String.IsBlank(lineItem.LineItemId)) xeroLine.LineItemID = lineItem.LineItemId;            
            xeroLine.Description = lineItem.Description;
            if(lineItem.Quantity != NULL && !String.IsBlank(lineItem.Quantity)) xeroLine.Quantity = String.valueOf(lineItem.Quantity); else xeroLine.Quantity = '0';
            if(lineItem.UnitAmount != NULL && !String.IsBlank(lineItem.UnitAmount)) xeroLine.UnitAmount = String.valueOf(lineItem.UnitAmount); else xeroLine.UnitAmount = '0';
            xeroLine.AccountCode = lineItem.AccountCode;
            xeroLine.TaxType = lineItem.TaxType;
            xeroLine.TaxAmount = String.valueOf(lineItem.TaxAmount);
            xeroLine.LineAmount = String.valueOf(lineItem.LineAmount);
            xeroLine.DiscountRate = String.valueOf(lineItem.DiscountRate);
            xeroLine.ItemCode = lineItem.ItemCode;
            
            xeroLineItemList.add(xeroLine);
        }
        
        return xeroLineItemList;
    }
}