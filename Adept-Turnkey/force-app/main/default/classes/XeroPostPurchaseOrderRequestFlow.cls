/*
 * Author:          Kristine Arcangel
 * Created Date:    September 28, 2022
 * Description:     Apex Class for Xero Outbound Post Purchase Order callout Invoked from Flow
 * Test Class:      XeroRequestTest
 * History:         September 28, 2022 - Creation
 *                  July 18, 2024 - Added feature to pass PurchaseOrderNumber to Xero Purchase Order (jp@bricoleurtech.com)
*/
public class XeroPostPurchaseOrderRequestFlow 
{
    @testVisible
    private class PostPurchaseOrderAsync implements Queueable, Database.AllowsCallouts
    {
        @testVisible private String Endpoint;
        @testVisible private Map<String , String> RequestHeader;
        @testVisible private String RequestBody;
        @testVisible private String RequestMethod;
        @testVisible private String SalesforceRecordId;
        @testVisible private String ContactID;

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
        
         public String getContactID()
        {
            return this.ContactID;
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
        
          public void setContactID(string contactID)
        {
            this.ContactID = contactID;
        }
        
        
        public void execute(QueueableContext context)
        {
            List<Exception_Log__c> exceptionLogList = new List<Exception_Log__c>();
            HttpResponse response = RestHandler.ExecuteRequest(this.RequestHeader , this.Endpoint , this.RequestBody , this.RequestMethod);
            String responseBodyString = response?.getBody();
                       
            if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){                
                RestHandler.ExceptionLogWrapper invoiceExLog = new RestHandler.ExceptionLogWrapper();
                invoiceExLog.requestBody = this.RequestBody;
                invoiceExLog.requestEndpoint =  this.Endpoint;
                invoiceExLog.responseBody = responseBodyString;
                invoiceExLog.statusCode = String.valueOf(response?.getStatusCode());
               // updateAccountXeroId(this.SalesforceRecordId, this.ContactID);
                Utilities_Bric.CreateExceptionLog(null, JSON.serialize(invoiceExLog));
                
                return;
            }
            system.debug('responseBodyString:: ' + responseBodyString);
            RestResponseCollectionXero.GetPurchaseOrderResponseBody responseBody = (RestResponseCollectionXero.GetPurchaseOrderResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetPurchaseOrderResponseBody.class) ;
            
            if(responseBody == NULL){
                updateAccountXeroId(this.SalesforceRecordId, this.ContactID);
                return;
            }
            PostXeroRequest.UpdateOrderFromXeroPurchaseOrder(this.SalesforceRecordId , responseBody.PurchaseOrders[0]?.PurchaseOrderID , responseBody.PurchaseOrders[0]);  
            
        }
    }
    
    @InvocableMethod(label = 'Sync Order to Xero as Purchase Order' description = 'Sends Salesforce Record to Sync with Xero Purchase Order.')
    public static void SendOrderToXeroFlow(List<XeroReqFlowParamsPurchaseOrder> params)
    {
        if(params == NULL || params.isEmpty()) return;
        PostPurchaseOrder(params[0]);
    }
    
    private static void PostPurchaseOrder(XeroReqFlowParamsPurchaseOrder params)
    {
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        
        RestRequestCollectionXero.PostPurchaseOrderBody requestBody = new RestRequestCollectionXero.PostPurchaseOrderBody();
        requestBody.PurchaseOrders = new List<RestRequestCollectionXero.PurchaseOrder>{SetPostPurchaseOrderBody(params)};
            
        String requestBodyString = JSON.serialize(requestBody);
 
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_KEY_TYPE_X => CONSTANTS_BRIC.INTEGRATION_KEY_TYPE,
                                                                                   CONSTANTS_BRIC.INTEGRATION_KEY_DATE_X => CONSTANTS_BRIC.INTEGRATION_KEY_DATE};   
        requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
        
        XeroPostPurchaseOrderRequestFlow.PostPurchaseOrderAsync postPurchaseOrder = new XeroPostPurchaseOrderRequestFlow.PostPurchaseOrderAsync();
        postPurchaseOrder.setEndpoint(endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_PURCHASEORDERS);
        postPurchaseOrder.setRequestHeader(requestHeader);
        postPurchaseOrder.setRequestBody(requestBodyString);
        postPurchaseOrder.setRequestMethod(CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST);        
        postPurchaseOrder.setSalesforceRecordId(params.SalesforceID);
        
        System.enqueueJob(postPurchaseOrder);
    }
    
    private static RestRequestCollectionXero.PurchaseOrder SetPostPurchaseOrderBody(XeroReqFlowParamsPurchaseOrder params)
    {
        RestRequestCollectionXero.PurchaseOrder requestBody = new RestRequestCollectionXero.PurchaseOrder();
        requestBody.Reference = params.Reference;
        requestBody.Contact = SetXeroContact(params.ContactId);
        requestBody.Date_x = params.Date_x;
        requestBody.DeliveryDate = params.DeliveryDate;
        requestBody.LineItems = SetXeroLineItems(params.lineItems);
        requestBody.Status = params.Status;
        requestBody.PurchaseOrderNumber = params.PurchaseOrderNumber;
        if(params.PurchaseOrderID != NULL && !String.IsBlank(params.PurchaseOrderID)) requestBody.PurchaseOrderID = params.PurchaseOrderID;
        requestBody.LineAmountTypes = params.LineAmountTypes;
        
        return requestBody;
    }
    
    private static RestRequestCollectionXero.PurchaseOrderXeroContact SetXeroContact(String contactId)
    {
        RestRequestCollectionXero.PurchaseOrderXeroContact xeroContact = new RestRequestCollectionXero.PurchaseOrderXeroContact();
        xeroContact.ContactID = contactId;
        
        return xeroContact;
    }
    
    private static List<RestRequestCollectionXero.XeroLineItem> SetXeroLineItems(List<XeroReqFlowLineItemParams> lineItems)
    {
        List<RestRequestCollectionXero.XeroLineItem> xeroLineItemList = new List<RestRequestCollectionXero.XeroLineItem>();
        
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
            
            xeroLineItemList.add(xeroLine);
        }
        
        return xeroLineItemList;
    }

    @testVisible
    private static void updateAccountXeroId(String orderID, String xeroContactID){
        Order orderRec = [SELECT Id,AccountId FROM Order WHERE Id=:orderID];                
        if(xeroContactID != '' && xeroContactID != NULL){
            Account accRecord = new Account();
            accRecord.Id = orderRec.AccountId;
            accRecord.XeroId__c = xeroContactID;
            update accRecord;
        }
    }
    
}