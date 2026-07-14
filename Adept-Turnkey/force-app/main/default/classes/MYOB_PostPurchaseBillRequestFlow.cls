/*
* Author:         	Bricoleur Technologies
* Created Date:    20-Apr-2023
* Description:     Apex Class for MYOB Outbound Post Purchase Order callout Invoked from Flow
* Test Class:      N/A
* History:         20-Apr-2023 - Creation
*/
public class MYOB_PostPurchaseBillRequestFlow { 
    
     
    
    @InvocableMethod(label = 'Sync/Convert Bill To MYOB' description = 'Sends Salesforce Order to MYOB to Sync with MYOB Purchase Order.')
    public static void SendGoodsReceivedNoticeToMYOBFromFlow(List<MYOB_FlowParam_PurchaseBillItem> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        
        MYOB_PostPurchaseBillRequestFlow.MYOB_PostPurchaseBillRequestFlowAsync postPurchaseBill = new MYOB_PostPurchaseBillRequestFlow.MYOB_PostPurchaseBillRequestFlowAsync();
        postPurchaseBill.setParamString(JSON.serialize(params[0], true));        
        System.enqueueJob(postPurchaseBill);
        
    }
    
    private class MYOB_PostPurchaseBillRequestFlowAsync implements Queueable, Database.AllowsCallouts
    {
        
        private String paramString;
        
        public void setParamString(String paramString)
        {
            this.paramString = paramString;
        }
        
        public void execute(QueueableContext context)
        {
            
            system.debug(this.paramString);
            MYOB_FlowParam_PurchaseBillItem params = (MYOB_FlowParam_PurchaseBillItem)JSON.deserialize(this.paramString, MYOB_FlowParam_PurchaseBillItem.class);
            MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                                 FROM MYOB_API_Setting__mdt
                                                 WHERE DeveloperName = 'Default'];
            String clientID = apiSettings?.Client_ID__c;
            String endpoint = apiSettings?.Endpoint__c;
            String companyFileID = apiSettings?.Company_File_ID__c;
            String purchaseBillRequestBodyString = '';
             
            
            
            nao__Invoice__c invToUpdate = new nao__Invoice__c();
            invToUpdate.Id = params.SFID;
            invToUpdate.MYOB_Last_Sync_DateTime__c = system.now();
            
            if(apiSettings == NULL || clientID == NULL || endpoint == NULL) return;
            
            Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
            
            //check if an Order has been synced already, if not, create MYOB Sales Order
            if(String.isBlank(params.UID )){
                //Not yet Synced
                
                HttpResponse postResponse; 
                 
                MYOB_RestRequestCollection.PurchaseBillItemBody purchaseBillRequestBody = SetPostPurchaseBillItemBody(params);
                purchaseBillRequestBodyString = JSON.serialize(purchaseBillRequestBody, true);
                
                system.debug('purchaseBillRequestBodyString: ' + purchaseBillRequestBodyString);
                Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                        purchaseBillRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(purchaseBillRequestBodyString , requestBodyReplacementList);
                
                system.debug('END POINT: ' + endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM);
                HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM, purchaseBillRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                system.debug('postOrderResponse: ' + postOrderResponse.getBody());
                invToUpdate.MYOB_Response__c = postOrderResponse?.getBody();
                String locationUri = postOrderResponse.getHeader('location');
                System.debug('locationUri: ' + locationUri);
                if(locationUri != null){
                    
                    String salesOrderId = locationUri.substringAfter('/Item/');                        
                    invToUpdate.External_Accounting_Id__c = salesOrderId;
                    
                    Order odr = [SELECT Id, MYOB_Status__c FROM Order WHERE OrderNumber= : params.OrderNumber];
                    odr.MYOB_Status__c = 'ConvertedToBill';
                    update odr;
                }
                
                
            }
            else{
                
                
                //Retrieve SalesOrder to get RowVersion
                HttpResponse getOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM + '/' + params.UID, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET); 
                system.debug('ROW VERSION ENDPOINT: ' + endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM + '/' + params.UID);
                system.debug('ROW VERSION getOrderResponse: ' + getOrderResponse);
                String getResponseBodyString = getOrderResponse?.getBody();   
                MYOB_RestResponseCollection.SalesOrder myobSalesOrder = (MYOB_RestResponseCollection.SalesOrder)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.SalesOrder.class);
                system.debug('ROW VERSION EXIST, GOOD TO UPDATE: ' + myobSalesOrder.RowVersion);
                
                //Add the UID property and Row Version - PUT Method
                MYOB_RestRequestCollection.PurchaseBillItemBody purchaseBillRequestBody = SetPostPurchaseBillItemBody(params);
                purchaseBillRequestBodyString = JSON.serialize(purchaseBillRequestBody, true);
              
                
                Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                        purchaseBillRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(purchaseBillRequestBodyString , requestBodyReplacementList);
                system.debug('endpoint : ' + endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM + '/' + params.UID);
                system.debug('purchaseBillRequestBodyString : ' + purchaseBillRequestBodyString);
                HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM + '/' + params.UID, purchaseBillRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                
                system.debug('postOrderResponse?.getBody() : ' + postOrderResponse?.getBody());
                //Update Order - Row version
                invToUpdate.Id = params.SFID;
                invToUpdate.MYOB_Row_Version__c = myobSalesOrder.RowVersion;
                invToUpdate.MYOB_Response__c = postOrderResponse?.getBody();
                
                
            }
            
            update invToUpdate;
        }
    }
    
    
    
    /*   
private static MYOB_RestRequestCollection.CustomerRequestBodyUpdate SetPutContactBody(MYOB_FlowParam_Customer params, String UID, String RowVersion)
{

MYOB_RestRequestCollection.CustomerRequestBodyUpdate requestBody = new MYOB_RestRequestCollection.CustomerRequestBodyUpdate();

//requestBody.FirstName = params.FirstName;
//requestBody.LastName = params.LastName;
requestBody.CompanyName = params.CompanyName;
requestBody.SellingDetails = params.SellingDetails;
requestBody.IsIndividual = params.IsIndividual;
requestBody.DisplayID = params.DisplayID;
requestBody.Addresses = params.Addresses; 
requestBody.Notes = params.Notes;
requestBody.UID = UID;
requestBody.RowVersion = RowVersion;
return requestBody;
}
*/
    
    private static MYOB_RestRequestCollection.CustomerRequestBody SetPostContactBody(MYOB_FlowParam_Customer params, String UID, String RowVersion)
    {
        
        MYOB_RestRequestCollection.CustomerRequestBody requestBody = new MYOB_RestRequestCollection.CustomerRequestBody();
        
        requestBody.FirstName = params.FirstName;
        requestBody.LastName = params.LastName;
        requestBody.CompanyName = params.CompanyName;
        requestBody.SellingDetails = params.SellingDetails;
        requestBody.IsIndividual = params.IsIndividual;
        requestBody.DisplayID = params.DisplayID;
        requestBody.Addresses = params.Addresses; 
        requestBody.Notes = params.Notes;
        
        return requestBody; 
    }
    
    private static MYOB_RestRequestCollection.PurchaseBillItemBody SetPostPurchaseBillItemBody(MYOB_FlowParam_PurchaseBillItem params)
    {
        
        MYOB_RestRequestCollection.PurchaseBillItemBody requestBody = new MYOB_RestRequestCollection.PurchaseBillItemBody();
        requestBody.BillDeliveryStatus = params.BillDeliveryStatus;
        requestBody.Date_x = params.Date_x;
        requestBody.FreightTaxCode = params.FreightTaxCode;
        requestBody.IsTaxInclusive = params.IsTaxInclusive;    
        requestBody.Order = params.Order;
        requestBody.RowVersion = params.RowVersion;
        requestBody.ShipToAddress = params.ShipToAddress;
        requestBody.Status = params.Status; 
        requestBody.Supplier = params.Supplier;
        requestBody.Number_x = params.OrderNumber;
        requestBody.Lines = params.Lines;
        requestBody.UID = params.UID != '' ? params.UID : null;
        return requestBody;
        
    }
     
     
    
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOBByUID( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '/' + params.UID, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();   
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        MYOB_RestResponseCollection.Contact myobContactItem = (MYOB_RestResponseCollection.Contact)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.Contact.class);
        
        return myobContactItem;
        
        
        
    }    
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOB( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        String customerParam = '';
        
        customerParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_COMPNAME + MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + params.CompanyName +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '?' + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + customerParam, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();   
        
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.ContactResponseBody myobContact = (MYOB_RestResponseCollection.ContactResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.ContactResponseBody.class);
        MYOB_RestResponseCollection.Contact myobContactItem = new MYOB_RestResponseCollection.Contact();
        system.debug('myobContact :: ' + myobContact);
        if(myobContact == NULL) return null;
        else if(myobContact.Items?.size() > 0 ){
            myobContactItem =  myobContact.Items[0];            
        }else{
            myobContactItem = null;
        }
        return myobContactItem; 
    }    
}