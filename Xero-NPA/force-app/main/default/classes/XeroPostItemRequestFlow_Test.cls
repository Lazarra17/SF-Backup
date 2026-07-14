/*
* Author:          Bricoleur Technologies - Kristine Arcangel
* Created Date:    June 28, 2022
* Description:     Apex Test Class for XeroPostItemRequestFlow
* Test Class:      N/A
* History:         June 28, 2022 - Creation
*/
@isTest

public class XeroPostItemRequestFlow_Test {
    
    @testSetup
    private static void Setup()
    {
        List<Account> testAcctList = TestDataFactory.CreateAccounts(3 , TRUE);
        
        Contact testCon = TestDataFactory.CreateContacts(1 , testAcctList[0].Id, TRUE)[0];
        Opportunity testOpp = TestDataFactory.CreateOpportunities(1 , testAcctList[0].Id , testCon.Id , TRUE)[0];
        List<Product2> testProductList = TestDataFactory.CreateProducts(3 , TRUE);
        Id pricebookId = Test.getStandardPricebookId();
        
        TestDataFactory.PricebookEntryParameters pbEParams1 = SetPricebookEntryParams(pricebookId , testProductList[0].Id , 100);
        TestDataFactory.PricebookEntryParameters pbEParams2 = SetPricebookEntryParams(pricebookId , testProductList[1].Id , 200);
        TestDataFactory.PricebookEntryParameters pbEParams3 = SetPricebookEntryParams(pricebookId , testProductList[2].Id , 300);
        
        List<PricebookEntry> testPbEList = new List<PricebookEntry>{TestDataFactory.CreatePricebookEntries(1 , pbEParams1, FALSE)[0],
            TestDataFactory.CreatePricebookEntries(1 , pbEParams2, FALSE)[0],
            TestDataFactory.CreatePricebookEntries(1 , pbEParams3, FALSE)[0]};
                
                Insert testPbEList;
        
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams1 = SetOppLineItemsParams(testOpp.Id , testPbEList[0].Id , 2 , 100);
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams2 = SetOppLineItemsParams(testOpp.Id , testPbEList[1].Id , 3 , 200);
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams3 = SetOppLineItemsParams(testOpp.Id , testPbEList[2].Id , 1 , 300);
        
        List<OpportunityLineItem> oppLineItemTestList = TestDataFactory.CreateOpportunityLineItems(2 , oppLineItemParams2, FALSE);
        oppLineItemTestList.add(TestDataFactory.CreateOpportunityLineItems(1 , oppLineItemParams1, FALSE)[0]);
        oppLineItemTestList.add(TestDataFactory.CreateOpportunityLineItems(1 , oppLineItemParams3, FALSE)[0]);
        
        Insert oppLineItemTestList;
        
        XeroAPISettings__c xeroAPISettings = new XeroAPISettings__c();
        xeroAPISettings.Name = Label.Xero_Setting;
        xeroAPISettings.Endpoint__c = 'callout:Xero_App/api.xro/2.0';
        
        Insert xeroAPISettings;
    }
    
    private static TestDataFactory.PricebookEntryParameters SetPricebookEntryParams(String pricebookId , String productId , Integer unitPrice)
    {
        TestDataFactory.PricebookEntryParameters pbEParams = new TestDataFactory.PricebookEntryParameters();
        pbEParams.PricebookId = pricebookId;
        pbEParams.ProductId = productId;
        pbEParams.UnitPrice = unitPrice;
        
        return pbEParams;
    }
    
    private static TestDataFactory.OpportunityLineItemParameters SetOppLineItemsParams(String oppId , String pbeId , Decimal qty , Decimal pbeUnitPrice)
    {
        TestDataFactory.OpportunityLineItemParameters oppLineItemParams = new TestDataFactory.OpportunityLineItemParameters();
        oppLineItemParams.OppId = oppId;
        oppLineItemParams.PbeId = pbeId;
        oppLineItemParams.Quantity = qty;
        oppLineItemParams.PbeUnitPrice = pbeUnitPrice;
        
        return oppLineItemParams;
    }
    
    private static RestResponseCollectionXero.XeroTenantIdResponseBody SetXeroTenantIdResponseBody(String testTenantId)
    {
        RestResponseCollectionXero.XeroTenantIdResponseBody responseBody = new RestResponseCollectionXero.XeroTenantIdResponseBody();
        responseBody.id = 'testId';
        responseBody.authEventId = 'testAuthEventId';
        responseBody.tenantId = testTenantId;
        responseBody.tenantType = 'testTenantType';
        responseBody.tenantName = 'testTenantName';
        responseBody.createdDateUtc = '2020-01-01';
        responseBody.updatedDateUtc = '2020-01-01';
        
        return responseBody;
    }
    
    private static void SetTenantId(String tenantId)
    {
        XeroAPISettings__c xeroAPISettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        if(xeroAPISettings != NULL)
        {
            xeroAPISettings.TenantId__c = tenantId;
            Database.Update(xeroAPISettings);
        }
    }
    
    
    @isTest
    private static void PostItemSuccess()
    {
        String tenantId = 'testTenantId';
        SetTenantId(tenantId);
        
        Id prodId = [SELECT Id FROM Product2 LIMIT 1].Id;
        XeroReqFlowParamsItem paramsItem = new XeroReqFlowParamsItem();
        paramsItem.SalesforceID = prodId;
        
        String xeroId = '11111';
        RestResponseCollectionXero.Item responseItem = new RestResponseCollectionXero.Item();
        responseItem.ItemID = xeroId;
        
        
        RestResponseCollectionXero.GetItemResponseBody postItemResponseBody = new RestResponseCollectionXero.GetItemResponseBody();
        postItemResponseBody.Items = new List<RestResponseCollectionXero.Item>{responseItem};
            
            MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(postItemResponseBody));
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroPostItemRequestFlow.SendItemToXeroFlow(new List<XeroReqFlowParamsItem>{paramsItem});
        
        test.stopTest();
        
        Product2 productRecord = [SELECT XeroId__c FROM Product2 WHERE Id = :prodId];        
        System.assertEquals(xeroId, productRecord.XeroId__c);
    }
    
}