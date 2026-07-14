@IsTest
public class GigaCommAddressFinderFooterCtrlTest {
    
    @testSetup
    public static void setupData(){ 
        List<Product2> plan = GigaCommTestDataBuilder.createProducts(false, 1, 'Data');
        List<Product2> installation = GigaCommTestDataBuilder.createProducts(true, 1, 'Installation');
        List<Product2> hardware = GigaCommTestDataBuilder.createProducts(false, 1, 'Hardware');
        
        plan[0].Installation_SKU_bric__c = installation[0].id;
        plan[0].Installation_Discount_SKU_bric__c = installation[0].id;
        plan[0].Agent_Discount_bric__c = hardware[0].id;
        
        insert plan;
        
        hardware[0].ProductCode= Constants.GIGACOMM_ROUTER_SKU;
        insert hardware;
        List<Product2> prodList = new List<Product2>();
        prodList.add(plan[0]);
        prodList.add(installation[0]);
        prodList.add(hardware[0]);
        List<Product_Inclusion_bric__c> PIs =  GigaCommTestDataBuilder.createProductInclusions(true, 1, plan[0]);
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);
        List<PricebookEntry> plans = new List<PricebookEntry>();
        List<Kiosk_Bric__c> kiosk = GigaCommTestDataBuilder.createKiosk(true, 1);
        List<Lead> leads = GigaCommTestDataBuilder.createLeads(true, 1);
        
        List<Lead_Product_Item__c> leadProdPlan = GigaCommTestDataBuilder.createdLeadProductItem(true, plan, leads[0].Id);
        List<Lead_Product_Item__c> leadProdRouter = GigaCommTestDataBuilder.createdLeadProductItem(true, hardware, leads[0].Id);
        List<Lead_Product_Item__c> leadProdInstallation = GigaCommTestDataBuilder.createdLeadProductItem(true, installation, leads[0].Id);
        
        Mef_API_Settings__c mefApi = new Mef_API_Settings__c();
        mefApi.Active__c = true;
        insert mefApi;
    }
    
    
       
    private static testMethod void createLeadTest() {
        
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Address Check', kiosk.Id);
        system.debug(sl);
        
        
        Test.startTest();
        GigaCommAddressFinderFooterController.createLead(JSON.serialize(sl));
        
        Test.stopTest();
        
    }

}