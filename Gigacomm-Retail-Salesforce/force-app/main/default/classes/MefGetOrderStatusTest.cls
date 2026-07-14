/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 10-Oct-25
@Desc:
@History: 
[1] CLAZARRA 10-Oct-25 Created
*/
@isTest
public class MefGetOrderStatusTest {
    
    @TestSetup
    static void setupTestData() {
        // Create custom setting for MEF API
        Mef_API_Settings__c apiSettings = new Mef_API_Settings__c(
            Name = 'Default',
            Active__c = true,
            Endpoint__c = 'https://test.endpoint.com/',
            NonNamedCredentialEndpoint__c = 'https://test.endpoint.com/', 
            Subscription_Key__c = '454544151'
        );
        insert apiSettings;
        
        // Create test products
        List<Product2> products = new List<Product2>();
        Product2 prod1 = new Product2(
            Name = 'Test Product 1',
            ProductCode = 'SKU001',
            IsActive = true
        );
        Product2 prod2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'SKU002',
            IsActive = true
        );
        products.add(prod1);
        products.add(prod2);
        insert products;
    }
    
    @isTest
    static void getOrderStatusTest() {
        
        Account acc = new Account();
        acc.Name=  'account';
        insert acc; 
        
        Opportunity opp = new Opportunity();
        opp.CloseDate = system.today();
        opp.Name = 'test';
        opp.Type = 'Residential';
		opp.accountId = acc.Id;
        opp.StageName = 'Qualification';
        opp.Mef_Order_Product_Id_bric__c = 'OD-7070'; 
        insert opp;
        
        test.StartTest();
        Test.setMock(HttpCalloutMock.class, new MefOrderStatusResponseGenerator());
        MefGetOrderStatus.getOrderStatus(opp);
        
        test.stopTest();
    }
    
    @isTest
    static void getOrderStatusFailTest() {
        
        Account acc = new Account();
        acc.Name=  'account';
        insert acc; 
        
        Opportunity opp = new Opportunity();
        opp.CloseDate = system.today();
        opp.Name = 'test';
        opp.Type = 'Residential';
        opp.accountId = acc.Id;
        opp.StageName = 'Qualification';
        opp.Mef_Order_Product_Id_bric__c = 'OD-7070'; 
        insert opp;
        
        test.StartTest();
        Test.setMock(HttpCalloutMock.class, new MefOrderStatusFailResponseGenerator());
        MefGetOrderStatus.getOrderStatus(opp);
        
        test.stopTest();
    }
    
}