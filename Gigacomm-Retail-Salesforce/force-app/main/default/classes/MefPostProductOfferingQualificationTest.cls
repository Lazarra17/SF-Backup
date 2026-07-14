@isTest
private class MefPostProductOfferingQualificationTest {
    
    @TestSetup
    static void setupTestData() {
        // Create custom setting for MEF API
        Mef_API_Settings__c apiSettings = new Mef_API_Settings__c(
            Name = 'Default',
            Active__c = true,
            Endpoint__c = 'https://test.endpoint.com/'
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
    static void testPostPOQ_Success() {
        // Create test site lead
        GigaCommOrderWizardController.SiteLead siteLead = new GigaCommOrderWizardController.SiteLead();
        siteLead.StreetType = 'Street';
        siteLead.StreetName = 'Test Street';
        siteLead.StreetNr = '123';
        siteLead.Suburb = 'Test Suburb';
        siteLead.State = 'NSW';
        siteLead.PostCode = '2000';
        siteLead.CountryCode = 'AU';
        
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MefPostPOQMock());
        
        Test.startTest(); 
        MefPostProductOfferingQualification.PostPOQ(siteLead);
        Test.stopTest();
        
     
    }
    
    @isTest
    static void testPostPOQ_InactiveAPI() {
        // Update API settings to inactive
        Mef_API_Settings__c apiSettings = Mef_API_Settings__c.getOrgDefaults();
        apiSettings.Active__c = false;
        update apiSettings;
        
        // Create test site lead
        GigaCommOrderWizardController.SiteLead siteLead = new GigaCommOrderWizardController.SiteLead();
        
        Test.startTest();
        MefPostProductOfferingQualification.PostPOQ(siteLead);
        Test.stopTest();
        
    }
    
    @isTest
    static void testPostPOQ_ErrorResponse() {
        // Create test site lead
        GigaCommOrderWizardController.SiteLead siteLead = new GigaCommOrderWizardController.SiteLead();
        
        // Mock the HTTP callout with error response
        Test.setMock(HttpCalloutMock.class, new MefPostPOQErrorMock());
        
        Test.startTest();
        MefPostProductOfferingQualification.PostPOQ(siteLead);
        Test.stopTest();
        
    }
    
    @isTest
    static void testPostPOQ_Utilites() {
        try{
            Product2 prod  = new Product2();
            update prod;
        }catch(exception e){
            Utilities.CreateExceptionLog(e);
            Utilities.CreateExceptionLog(e, 'test');
            Utilities.createException(e, 'test');
            Utilities.CreateExceptionLog('test', 'test');
            Utilities.CheckResponseBodyValidity(1, 'test');
        }
        
        
        
    }
    
    
    // Mock class for successful response
    private class MefPostPOQMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Create mock response body
            RestResponseCollectionMef.PostPOQResponseBody responseBody = new RestResponseCollectionMef.PostPOQResponseBody();
            responseBody.productOfferingQualificationItem = new List<RestResponseCollectionMef.ProductOfferingQualificationItem>();
            
            RestResponseCollectionMef.ProductOfferingQualificationItem item = new RestResponseCollectionMef.ProductOfferingQualificationItem();
            item.AlternateProductOfferingProposal = new List<RestResponseCollectionMef.AlternateProductOfferingProposal>();
            
            // Add two proposals with Green confidence
            RestResponseCollectionMef.AlternateProductOfferingProposal prop1 = new RestResponseCollectionMef.AlternateProductOfferingProposal();
            prop1.serviceabilityConfidence = 'Green';
            prop1.alternateProduct = new RestResponseCollectionMef.AlternateProduct();
            prop1.alternateProduct.productOffering = new RestResponseCollectionMef.ProductOffering();
            prop1.alternateProduct.productOffering.id = 'SKU001';
            
            RestResponseCollectionMef.AlternateProductOfferingProposal prop2 = new RestResponseCollectionMef.AlternateProductOfferingProposal();
            prop2.serviceabilityConfidence = 'Green';
            prop2.alternateProduct = new RestResponseCollectionMef.AlternateProduct();
            prop2.alternateProduct.productOffering = new RestResponseCollectionMef.ProductOffering();
            prop2.alternateProduct.productOffering.id = 'SKU002';
            
            item.AlternateProductOfferingProposal.add(prop1);
            item.AlternateProductOfferingProposal.add(prop2);
            responseBody.productOfferingQualificationItem.add(item);
            
            res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }
    
    // Mock class for error response
    private class MefPostPOQErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"error": "Bad Request"}');
            return res;
        }
    }
}