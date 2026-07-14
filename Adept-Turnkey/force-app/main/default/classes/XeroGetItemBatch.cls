/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	April 22, 2022
 * Description: 	Batchable Class for Retrieving Xero Items
 * Test Class: 		N/A
 * History: 		April 22, 2022 - Creation
 */
public class XeroGetItemBatch implements Database.Batchable<RestResponseCollectionXero.Item>,Database.AllowsCallouts, Database.Stateful
{
    public DateTime batchStartTime;
    public Boolean isSuccess;
    
     public Iterable<RestResponseCollectionXero.Item> start(Database.BatchableContext context)
    {   
        isSuccess = true;
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        XeroProductSyncSetting__c xeroProductSettings = XeroProductSyncSetting__c.getInstance('Default');
        String modifiedSince = getUTCDateTime(xeroProductSettings?.Modified_After__c);
        batchStartTime = System.now();
            
        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return new List<RestResponseCollectionXero.Item>();
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        if(modifiedSince != null && modifiedSince != '') requestHeader.put(CONSTANTS_BRIC.INTEGRATION_XERO_HEADER_KEY_IF_MODIFIED_SINCE,modifiedSince);

        HttpResponse response = RestHandler.ExecuteRequest(requestHeader,endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_ITEMS,null,CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET);
        String responseBodyString = response?.getBody();
        
        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)){
            Utilities_Bric.CreateExceptionLog(null, response?.getStatusCode() + ' --- ' + responseBodyString);
            isSuccess = false;
            return new List<RestResponseCollectionXero.Item>();
        }
        
        RestResponseCollectionXero.GetItemResponseBody responseBody = (RestResponseCollectionXero.GetItemResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetItemResponseBody.class) ;
        
       
        if(responseBody == NULL) return new List<RestResponseCollectionXero.Item>();
        system.debug('responseBody.Items ::: ' + responseBody.Items);
        return responseBody.Items;
    }
    
    public void execute(Database.BatchableContext context, List<RestResponseCollectionXero.Item> xeroItemList) {

        List<Xero_Product_Loading_Object__c> xeroProductList = new List<Xero_Product_Loading_Object__c>();
        
        if(xeroItemList.size() > 0){
            for(RestResponseCollectionXero.Item xeroItem : xeroItemList){
                Xero_Product_Loading_Object__c productItem = new Xero_Product_Loading_Object__c();
                productItem.Code__c  = xeroItem.Code;
                productItem.Description__c = xeroItem.Description;
                productItem.IsPurchased__c = xeroItem.IsPurchased;
                productItem.IsSold__c = xeroItem.IsSold;
                productItem.IsTrackedAsInventory__c = xeroItem.IsTrackedAsInventory;
                productItem.ItemID__c = xeroItem.ItemID;
                productItem.Name__c = xeroItem.Name;
                productItem.PurchaseDescription__c = xeroItem.PurchaseDescription;
                productItem.PurchaseDetails_AccountCode__c = xeroItem.PurchaseDetails?.AccountCode;
                productItem.PurchaseDetails_TaxType__c = xeroItem.PurchaseDetails?.TaxType;
                productItem.PurchaseDetails_UnitPrice__c = xeroItem.PurchaseDetails?.UnitPrice != null ? xeroItem.PurchaseDetails?.UnitPrice : 0;
                productItem.SalesDetails_AccountCode__c = xeroItem.SalesDetails?.AccountCode;
                productItem.SalesDetails_TaxType__c = xeroItem.SalesDetails?.TaxType;
                productItem.SalesDetails_UnitPrice__c = xeroItem.SalesDetails?.UnitPrice != null ? xeroItem.SalesDetails?.UnitPrice : 0;
                productItem.UpdatedDateUTC__c = xeroItem.UpdatedDateUTC;
                
                xeroProductList.add(productItem);
            }
        }
        
        if(xeroProductList.size() > 0){
            Database.insert(xeroProductList,false);
        }
        
    }
    
    public void finish(Database.BatchableContext context) {
        XeroProductSyncSetting__c xeroProductSettings = XeroProductSyncSetting__c.getInstance('Default');
        if(xeroProductSettings != NULL && isSuccess)
        {
            xeroProductSettings.Modified_After__c = batchStartTime;
            Database.Update(xeroProductSettings);
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