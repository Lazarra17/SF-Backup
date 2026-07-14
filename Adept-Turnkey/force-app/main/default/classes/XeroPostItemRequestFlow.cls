/*
 * Author:          Bricoleur Technologies - Kristine Arcangel
 * Created Date:    June 10, 2022
 * Description:     Apex Class for Xero Outbound Post Item callout Invoked from Flow
 * Test Class:      
 * History:         June 10, 2022 - Creation
*/
public class XeroPostItemRequestFlow {

    private class PostItemAsync implements Queueable, Database.AllowsCallouts
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
            
            RestResponseCollectionXero.GetItemResponseBody responseBody = (RestResponseCollectionXero.GetItemResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetItemResponseBody.class) ;
            
            if(responseBody == NULL) return;
            
            PostXeroRequest.UpdateProductFromXero(this.SalesforceRecordId , responseBody.Items[0]);
        }
    }
    
    @InvocableMethod(label = 'Sync Product to Xero' description = 'Sends Salesforce Product to Xero to Sync with Xero Item.')
    public static void SendItemToXeroFlow(List<XeroReqFlowParamsItem> params)
    {
        if(params == NULL || params.isEmpty()) return;
        PostItem(params[0]);
        
    }
    
    private static void PostItem(XeroReqFlowParamsItem params)
    {
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        
        RestRequestCollectionXero.Item requestBody = SetPostItemBody(params);
            
        String requestBodyString = JSON.serialize(requestBody);
 
        Map<String , String> requestBodyReplacementList = new Map<String , String>{CONSTANTS_BRIC.INTEGRATION_KEY_TYPE_X => CONSTANTS_BRIC.INTEGRATION_KEY_TYPE,
                                                                                   CONSTANTS_BRIC.INTEGRATION_KEY_DATE_X => CONSTANTS_BRIC.INTEGRATION_KEY_DATE};   
        requestBodyString = XeroRequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
        
        XeroPostItemRequestFlow.PostItemAsync postItem = new XeroPostItemRequestFlow.PostItemAsync();
        postItem.setEndpoint(endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_ITEMS);
        postItem.setRequestHeader(requestHeader);
        postItem.setRequestBody(requestBodyString);
        postItem.setRequestMethod(CONSTANTS_BRIC.INTEGRATION_REST_METHOD_POST);        
        postItem.setSalesforceRecordId(params.SalesforceID);
        
        System.enqueueJob(postItem);
    }
    
    private static RestRequestCollectionXero.Item SetPostItemBody(XeroReqFlowParamsItem params)
    {
        RestRequestCollectionXero.Item requestBody = new RestRequestCollectionXero.Item();
        if (params.ItemID != '' && params.ItemID != null) requestBody.ItemID = params.ItemID;        
        requestBody.Name = params.Name;
        requestBody.Code = params.Code;
        requestBody.Description = params.Description;
        requestBody.PurchaseDescription = params.PurchaseDescription;
        requestBody.IsTrackedAsInventory = params.IsTrackedAsInventory;
        requestBody.IsSold = params.IsSold;
        requestBody.IsPurchased = params.IsPurchased;
        requestBody.PurchaseDetails = new RestRequestCollectionXero.PurchaseSalesDetails();
        requestBody.PurchaseDetails.AccountCode = params.PurchaseDetails?.AccountCode;
        requestBody.PurchaseDetails.UnitPrice = params.PurchaseDetails?.UnitPrice;
        requestBody.PurchaseDetails.TaxType = params.PurchaseDetails?.TaxType;
        requestBody.SalesDetails = new RestRequestCollectionXero.PurchaseSalesDetails();
        requestBody.SalesDetails.AccountCode = params.SalesDetails?.AccountCode;
        requestBody.SalesDetails.UnitPrice = params.SalesDetails?.UnitPrice;
        requestBody.SalesDetails.TaxType = params.SalesDetails?.TaxType;
        return requestBody;
    }

    
}