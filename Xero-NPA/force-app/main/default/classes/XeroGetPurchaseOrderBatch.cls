/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	September 28, 2022
 * Description: 	Batchable Class for Retrieving Xero PO
 * Test Class: 		N/A
 * History: 		September 28, 2022 - Creation
 */
public class XeroGetPurchaseOrderBatch implements Database.Batchable<RestResponseCollectionXero.PurchaseOrder>,Database.AllowsCallouts, Database.Stateful
{
    public DateTime batchStartTime;
    public Boolean isSuccess;
    
     public Iterable<RestResponseCollectionXero.PurchaseOrder> start(Database.BatchableContext context)
    {   
        isSuccess = true;
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        XeroPurchaseOrderSyncSetting__c xeroPOSettings = XeroPurchaseOrderSyncSetting__c.getOrgDefaults();
        String modifiedSince = getUTCDateTime(xeroPOSettings?.Modified_After__c);
        batchStartTime = System.now();
            
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return new List<RestResponseCollectionXero.PurchaseOrder>();
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        if(modifiedSince != null && modifiedSince != '') requestHeader.put(CONSTANTS_BRIC.INTEGRATION_XERO_HEADER_KEY_IF_MODIFIED_SINCE,modifiedSince);

        HttpResponse response = RestHandler.ExecuteRequest(requestHeader,endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_PURCHASEORDERS,null,CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET);
        String responseBodyString = response?.getBody();
        
        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
            Utilities_Bric.CreateExceptionLog(null, response?.getStatusCode() + ' --- ' + responseBodyString);
            isSuccess = false;
            return new List<RestResponseCollectionXero.PurchaseOrder>();
        }
        
        RestResponseCollectionXero.GetPurchaseOrderResponseBody responseBody = (RestResponseCollectionXero.GetPurchaseOrderResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetPurchaseOrderResponseBody.class) ;
               
        if(responseBody == NULL) return new List<RestResponseCollectionXero.PurchaseOrder>();
        system.debug('responseBody.PurchaseOrders ::: ' + responseBody.PurchaseOrders);
        return responseBody.PurchaseOrders;
    }
    
    public void execute(Database.BatchableContext context, List<RestResponseCollectionXero.PurchaseOrder> xeroPurchaseOrderList) {

        List<Order> orderList = new List<Order>();
        
        //GET Current Order Records
        Map<String,Order> xeroOrderMap = new Map<String,Order>();
        for(Order orderRec :  [SELECT Id, Xero_PurchaseOrderID__c
                                FROM Order 
                                WHERE Xero_PurchaseOrderID__c != NULL])
        {
            if(orderRec.Xero_PurchaseOrderID__c != NULL && orderRec.Xero_PurchaseOrderID__c != ''){
                xeroOrderMap.put(orderRec.Xero_PurchaseOrderID__c,orderRec);
            }
        }
        
        if(xeroPurchaseOrderList.size() > 0){
            for(RestResponseCollectionXero.PurchaseOrder xeroPO: xeroPurchaseOrderList){
                Order orderRecord = new Order();
                orderRecord.Id = xeroOrderMap.get(xeroPO.PurchaseOrderID)?.Id;
                orderRecord.Xero_Purchase_Order_Status__c = xeroPO.Status;     
                if(orderRecord.Id != null) orderList.add(orderRecord);
            }
        }
        
        if(orderList.size() > 0){
            Database.update(orderList,false);
        }
        
    }
    
    public void finish(Database.BatchableContext context) {
        XeroPurchaseOrderSyncSetting__c xeroPOSettings = XeroPurchaseOrderSyncSetting__c.getOrgDefaults();        
        if(xeroPOSettings != NULL && isSuccess)
        {
            xeroPOSettings.Modified_After__c = batchStartTime;
            Database.Update(xeroPOSettings);
        } 
    }
    
    public String getUTCDateTime(DateTime dt){
        if(dt != null){
            Datetime GMTDate = Datetime.newInstance(
                dt.year(),
                dt.month(),
                dt.day(),
                dt.hour(),
                dt.minute(),
                dt.second());
            String formatted = GMTDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
            return formatted;
        }else{            
            return null;
        }
    }
}