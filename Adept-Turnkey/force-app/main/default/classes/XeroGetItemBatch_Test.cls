/*
* Author:          Bricoleur Technologies
* Created Date:    April 22, 2022
* Description:     Apex Test Class for XeroGetItemBatch
* Test Class:      N/A
* History:         April 22, 2022 - Creation
*/
@isTest

public class XeroGetItemBatch_Test {
    
    
    @testSetup
    private static void Setup()
    {
        XeroAPISettings__c xeroAPISettings = new XeroAPISettings__c();
        xeroAPISettings.Name = Label.Xero_Setting;
        xeroAPISettings.TenantId__c = 'tenantId';   
        xeroAPISettings.Endpoint__c = 'endpoint';
        insert xeroAPISettings;
                        
        XeroProductSyncSetting__c xeroProductSettings = new XeroProductSyncSetting__c();
		xeroProductSettings.Name = 'Default';
		xeroProductSettings.Modified_After__c = System.now();
        insert xeroProductSettings;
    }
    
    @isTest
    private static void GetXeroItemBatch_Test()
    {
        RestResponseCollectionXero.Item xeroItem = new RestResponseCollectionXero.Item();
        xeroItem.Code = 'ABC';
        xeroItem.Description = 'Product Description';
        xeroItem.ItemID = 'XeroItemID';
        xeroItem.Name = 'Product Name';
        xeroItem.SalesDetails = new RestResponseCollectionXero.PurchaseSalesDetails();
        xeroItem.SalesDetails.UnitPrice = 100;        
        
        RestResponseCollectionXero.GetItemResponseBody getItemResponseBody = new RestResponseCollectionXero.GetItemResponseBody();
        getItemResponseBody.Items = new List<RestResponseCollectionXero.Item>{xeroItem};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(getItemResponseBody));
        
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        XeroGetItemBatch batch= new XeroGetItemBatch();
        Id jobid= Database.executeBatch(batch,1);
        test.stopTest();
        
    }
    
    @isTest
    private static void GetXeroItemBatch400_Test()
    {
        RestResponseCollectionXero.Item xeroItem = new RestResponseCollectionXero.Item();
        xeroItem.Code = 'ABC';
        xeroItem.Description = 'Product Description';
        xeroItem.ItemID = 'XeroItemID';
        xeroItem.Name = 'Product Name';
        xeroItem.SalesDetails = new RestResponseCollectionXero.PurchaseSalesDetails();
        xeroItem.SalesDetails.UnitPrice = 100;        
        
        RestResponseCollectionXero.GetItemResponseBody getItemResponseBody = new RestResponseCollectionXero.GetItemResponseBody();
        getItemResponseBody.Items = new List<RestResponseCollectionXero.Item>{xeroItem};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , JSON.serialize(getItemResponseBody));
        
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        XeroGetItemBatch batch= new XeroGetItemBatch();
        Id jobid= Database.executeBatch(batch,1);
        test.stopTest();
        
    }
    
    @isTest
    private static void GetXeroItemBatchNoModifiedAfter_Test()
    {
        
        XeroProductSyncSetting__c xeroProductSettings = XeroProductSyncSetting__c.getInstance('Default');
        xeroProductSettings.Modified_After__c = null;
        update xeroProductSettings;
        
        RestResponseCollectionXero.Item xeroItem = new RestResponseCollectionXero.Item();
        xeroItem.Code = 'ABC';
        xeroItem.Description = 'Product Description';
        xeroItem.ItemID = 'XeroItemID';
        xeroItem.Name = 'Product Name';
        xeroItem.SalesDetails = new RestResponseCollectionXero.PurchaseSalesDetails();
        xeroItem.SalesDetails.UnitPrice = 100;        
        
        RestResponseCollectionXero.GetItemResponseBody getItemResponseBody = new RestResponseCollectionXero.GetItemResponseBody();
        getItemResponseBody.Items = new List<RestResponseCollectionXero.Item>{xeroItem};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400 , JSON.serialize(getItemResponseBody));
        
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        XeroGetItemBatch batch= new XeroGetItemBatch();
        Id jobid= Database.executeBatch(batch,1);
        test.stopTest();
        
    }
        
    @isTest
    private static void GetXeroItemBatchSchedulable_Test()
    {
        RestResponseCollectionXero.Item xeroItem = new RestResponseCollectionXero.Item();
        xeroItem.Code = 'ABC';
        xeroItem.Description = 'Product Description';
        xeroItem.ItemID = 'XeroItemID';
        xeroItem.Name = 'Product Name';
        xeroItem.SalesDetails = new RestResponseCollectionXero.PurchaseSalesDetails();
        xeroItem.SalesDetails.UnitPrice = 100;        
        
        RestResponseCollectionXero.GetItemResponseBody getItemResponseBody = new RestResponseCollectionXero.GetItemResponseBody();
        getItemResponseBody.Items = new List<RestResponseCollectionXero.Item>{xeroItem};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(getItemResponseBody));
        
        test.startTest();        
        test.setMock(HttpCalloutMock.class, response);
        XeroGetItemBatchSchedulable batch= new XeroGetItemBatchSchedulable();
        String cronExp = '0 0 23 * * ?';
        system.schedule('Xero Item Batch', cronExp, batch);
        test.stopTest();
        
    }
}