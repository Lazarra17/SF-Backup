@isTest
public class GigaCommOrderWizardControllerTest {
    
    @testSetup
    public static void setupData(){ 
        List<Product2> plan = GigaCommTestDataBuilder.createProducts(false, 1, 'Data');
        List<Product2> promoPlan = GigaCommTestDataBuilder.createProducts(false, 1, 'Data');
        List<Product2> installation = GigaCommTestDataBuilder.createProducts(true, 1, 'Installation');
        List<Product2> hardware = GigaCommTestDataBuilder.createProducts(false, 1, 'Hardware');
    
        
        hardware[0].ProductCode= Constants.GIGACOMM_ROUTER_SKU;
        insert hardware;
        
            
        plan[0].Installation_SKU_bric__c = installation[0].id;
        plan[0].Installation_Discount_SKU_bric__c = installation[0].id;
        plan[0].Agent_Discount_bric__c = hardware[0].id;
        
        insert plan;
        
        promoPlan[0].Installation_SKU_bric__c = installation[0].id;
        promoPlan[0].Installation_Discount_SKU_bric__c = installation[0].id;
        promoPlan[0].Agent_Discount_bric__c = hardware[0].id;
        
        insert promoPlan;
        
        List<Product2> prodList = new List<Product2>();
        prodList.add(plan[0]);
        prodList.add(installation[0]);
        prodList.add(hardware[0]);
        prodList.add(promoPlan[0]);
        
        List<Product_Inclusion_bric__c> PIs =  GigaCommTestDataBuilder.createProductInclusions(true, 1, plan[0]);
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);
        List<PricebookEntry> plans = new List<PricebookEntry>();
        List<Kiosk_Bric__c> kiosk = GigaCommTestDataBuilder.createKiosk(true, 1);
        List<Lead> leads = GigaCommTestDataBuilder.createLeads(true, 1);
        
        List<Lead_Product_Item__c> leadProdPlan = GigaCommTestDataBuilder.createdLeadProductItem(true, plan, leads[0].Id);
        List<Lead_Product_Item__c> leadProdRouter = GigaCommTestDataBuilder.createdLeadProductItem(true, hardware, leads[0].Id);
        List<Lead_Product_Item__c> leadProdInstallation = GigaCommTestDataBuilder.createdLeadProductItem(true, installation, leads[0].Id);
        List<Lead_Product_Item__c> leadPromoPlan = GigaCommTestDataBuilder.createdLeadProductItem(false, plan, leads[0].Id);
        leadPromoPlan[0].Voucher_Type_bric__c = 'Installation Discount';
        insert leadPromoPlan;
        
        List<Voucher__c> vouchers = GigaCommTestDataBuilder.createVouchers(true,  1);
        List<Voucher_Status__c> vouchersStatus = GigaCommTestDataBuilder.createVoucherStatuses(true, vouchers[0],  1);
        List<Voucher_Product__c> vouchersProducts = GigaCommTestDataBuilder.createVoucherProducts(true, vouchers[0], promoPlan[0], plan[0], 1);
        
        
        Mef_API_Settings__c mefApi = new Mef_API_Settings__c();
        mefApi.Active__c = true;
        insert mefApi;
    }
    
    /*
    private static testMethod void getPlansTest() {
    
        List<Product2> prodList = GigaCommTestDataBuilder.createProducts(true, 4);
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);
        List<PricebookEntry> plans = new List<PricebookEntry>();

        Test.startTest();
            GigaCommOrderWizardController.getPlans();
        Test.stopTest();

    } 

    private static testMethod void getLeadTest() {

        List<Lead> leadList = GigaCommTestDataBuilder.createLeads(true, 1);
        List<Product2> prodList = GigaCommTestDataBuilder.createProducts(false, 1);
        prodList[0].Family = 'Hardware';
        insert prodList;
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);
        List<Lead_Product_Item__c> lpiList = GigaCommTestDataBuilder.createdLeadProductItem(true, prodList, leadList[0].Id);
        List<Product_Inclusion_bric__c> pis = GigaCommTestDataBuilder.createProductInclusions(true, 1, prodList[0]);
        GigaCommOrderWizardController.SiteLead siteLead = new GigaCommOrderWizardController.SiteLead();

        Test.startTest();
            siteLead = GigaCommOrderWizardController.getLead(leadList[0].Id);
        Test.stopTest();

        Assert.isTrue(siteLead != null, 'SiteLead not null');
    }
*/
    
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
        GigaCommOrderWizardController.createLead(JSON.serialize(sl));
        
        GigaCommOrderWizardController.getPicklistValues('Opportunity', 'StageName', 'Qualification');
        Test.stopTest();
        
    }
    
    private static testMethod void UpdateLeadAddressCheckTest() {
        GigaCommOrderWizardController.getPlans();
        Lead l = [SELECT Id, Voucher_bric__c FROM Lead LIMIT 1];
        Voucher__c v = [SELECT Id FROM Voucher__c LIMIT 1];
        l.Voucher_bric__c = v.Id;
        update l;
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Address Check', kiosk.Id);
        system.debug(sl);
        
        sl.Id = l.Id;
        Test.startTest();
        GigaCommOrderWizardController.updateLead(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    private static testMethod void UpdateLeadPlanSelectedTest() {
        GigaCommOrderWizardController.getPlans();
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = '12 Months';
        Test.startTest();
        GigaCommOrderWizardController.updateLead(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    private static testMethod void UpdateLeadNoPlanExistTest() {
        GigaCommOrderWizardController.getPlans();
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = '12 Months';
        sl.IncludeRouter = false;
        delete lp;
        Test.startTest();
        GigaCommOrderWizardController.updateLead(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    private static testMethod void UpdateLeadPlanSelectedNotExistTest() {
        GigaCommOrderWizardController.getPlans();
        List<Lead_Product_Item__c> lps = [SELECT id FROM Lead_Product_Item__c];
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = '12 Months';
        
        delete lps;
        Test.startTest();
        GigaCommOrderWizardController.updateLead(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    
     private static testMethod void UpdateLeadRouterAddedTest() {
        GigaCommOrderWizardController.getPlans();
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Router Added', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.AgentPriceOverride = false;
        sl.Status = 'Router Added';
        sl.IncludeRouter = false;
        Test.startTest();
        GigaCommOrderWizardController.updateLead(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    private static testMethod void UpdateLeadFreeRouterTest() {
        GigaCommOrderWizardController.getPlans();
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Router Added', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.AgentPriceOverride = false;
        sl.Status = 'Router Added';
        sl.IncludeRouter = false;
        Test.startTest();
        GigaCommOrderWizardController.updateFreeRouter(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    private static testMethod void UpdateLeadFreeRouterAgentOverrideTest() {
        GigaCommOrderWizardController.getPlans();
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Lead_Product_Item__c lpRouter = [SELECT Id, Quantity_bric__c, Unit_Price_bric__c, TECH_PriceBookEntryId_bric__c, Product_bric__c FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Hardware' LIMIT 1];
        Lead_Product_Item__c planSelected = [SELECT Id, Quantity_bric__c, Unit_Price_bric__c, TECH_PriceBookEntryId_bric__c, Product_bric__c FROM Lead_Product_Item__c 
                                             WHERE Product_bric__r.Family = 'Data'  LIMIT 1];
 
        
        GigaCommOrderWizardController.SiteLead sl = new GigaCommOrderWizardController.SiteLead();
        sl.State = 'VIC';
        sl.IncludeRouter = false;
        sl.Street = 'Street';
        sl.Suburb = 'SOUTHBANK';
        sl.CountryCode = 'AU';
        sl.Id = l.Id;
        sl.AgentPriceOverride = true;
        sl.Status = 'Router Added';
        sl.Router = lpRouter;
        sl.PlanSelected = planSelected;
        Test.startTest();
        GigaCommOrderWizardController.updateFreeRouter(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    
    private static testMethod void UpdateLeadRouterQuantity2Test() {
        GigaCommOrderWizardController.getPlans();
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Lead_Product_Item__c plan = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        List<Lead_Product_Item__c> lps = [SELECT id, Quantity_bric__c, Unit_Price_bric__c FROM Lead_Product_Item__c];
        Lead_Product_Item__c lp = [SELECT Id, Quantity_bric__c, Unit_Price_bric__c FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Hardware' LIMIT 1];
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Router Added', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.AgentPriceOverride = true;
        sl.Router = lp;
        sl.Status = 'Router Added';
        sl.IncludeRouter = false;
        sl.PlanSelected = plan;
        delete lps;
        Test.startTest();
        GigaCommOrderWizardController.updateLead(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    private static testMethod void removeItemTest() {
        GigaCommOrderWizardController.getRouter();
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Hardware' LIMIT 1];
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Router Added', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.AgentPriceOverride = false;
        sl.Router = lp;
        sl.IncludeRouter = false;
        Test.startTest();
        GigaCommOrderWizardController.removeItem(JSON.serialize(sl));
        Test.stopTest();
        
    }
    
    
    private static testMethod void applyPromoTest() {
        
        GigaCommOrderWizardController.getPlans();
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        Voucher__c v = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c];
        system.debug(v);
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = 'Monthly';
        Test.startTest();
        GigaCommOrderWizardController.applyPromoCode(sl, 'PROMO0');
        Test.stopTest();
        
    }
    
    private static testMethod void applyPromoVoucherNotExistTest() {
        
        GigaCommOrderWizardController.getPlans();
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        Voucher__c v = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c];
        system.debug(v);
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = 'Monthly';
        Test.startTest();
        GigaCommOrderWizardController.applyPromoCode(sl, 'NOTEXIST');
        Test.stopTest();
        
    }
    
    private static testMethod void applyPromoVoucherExpiredTest() {
        
        GigaCommOrderWizardController.getPlans();
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        Voucher_Status__c vs = [SELECT Id, Status_bric__c FROM Voucher_Status__c LIMIT 1];
    	vs.Status_bric__c = 'Inactive';
        update vs;
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = 'Monthly';
        Test.startTest();
        GigaCommOrderWizardController.applyPromoCode(sl, 'PROMO0');
        Test.stopTest();
        
    }
    
    private static testMethod void applyPromoNoVoucherProdTest() {
        
        GigaCommOrderWizardController.getPlans();
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        Voucher_Product__c vs = [SELECT Id, Apply_bric__c FROM Voucher_Product__c LIMIT 1];
    	vs.Apply_bric__c = '';
        update vs;
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = 'Monthly';
        Test.startTest();
        GigaCommOrderWizardController.applyPromoCode(sl, 'PROMO0');
        Test.stopTest();
        
    }
    
    private static testMethod void applyPromoNoVoucherStatusTest() {
        
        GigaCommOrderWizardController.getPlans();
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Kiosk_Bric__c kiosk = [SELECT Id FROM Kiosk_Bric__c LIMIT 1];
        Voucher_Status__c vs = [SELECT Id, Status_bric__c FROM Voucher_Status__c LIMIT 1];
        delete vs;
        
        List<String> productCodes = new List<String>();
        for(Product2 prod : [SELECT Id, ProductCode FROM Product2]){
            productCodes.add(prod.ProductCode);
        }
        
        Test.setMock(HttpCalloutMock.class, new GigaCommPOQMockHttpResponseGenerator());
        
        GigaCommOrderWizardController.SiteLead sl = GigaCommTestDataBuilder.generateSiteLead('Plan Selected', kiosk.Id);
        system.debug(sl);
        sl.Id = l.Id;
        sl.PlanSelected = lp;
        sl.Term = 'Monthly';
        Test.startTest();
        GigaCommOrderWizardController.applyPromoCode(sl, 'PROMO0');
        Test.stopTest();
        
    }
    
    private static testMethod void removeVoucherTest() {
        
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        Voucher__c v = [SELECT Id FROM Voucher__c ];
        Test.startTest();
        GigaCommOrderWizardController.removeVouchers(l.Id, v.Id);
        Test.stopTest();
        
    }
    @IsTest
    static void testGetSlides() {

        // Create test data
        Header_Config__c active1 = new Header_Config__c(
            Type__c = 'Image',
            Image_URL__c = 'https://test1.com',
            Video_HTML__c = '<video></video>',
            Small_Tag__c = 'Tag1',
            Title_Line1__c = 'Line1 A',
            Title_Line2__c = 'Line2 A',
            Subtitle__c = 'Sub A',
            Button_Label__c = 'Click A',
            Sort_Order__c = 1,
            Active__c = true
        );

        Header_Config__c active2 = new Header_Config__c(
            Type__c = 'Video',
            Image_URL__c = 'https://test2.com',
            Video_HTML__c = '<video>2</video>',
            Small_Tag__c = 'Tag2',
            Title_Line1__c = 'Line1 B',
            Title_Line2__c = 'Line2 B',
            Subtitle__c = 'Sub B',
            Button_Label__c = 'Click B',
            Sort_Order__c = 2,
            Active__c = true
        );

        Header_Config__c inactive = new Header_Config__c(
            Type__c = 'Image',
            Image_URL__c = 'https://inactive.com',
            Active__c = false
        );

        insert new List<Header_Config__c> { active1, active2, inactive };

        Test.startTest();
        List<GigaCommOrderWizardController.SlideDTO> result = GigaCommOrderWizardController.getSlides();
        Test.stopTest();

        // EXPECT: Only 2 active records
        System.assertEquals(2, result.size(), 'Only active records should return');

        // EXPECT: Sorted by Sort_Order__c
        System.assertEquals(active1.Id, result[0].id);
        System.assertEquals(active2.Id, result[1].id);

        // EXPECT: DTO mapping correctness
        GigaCommOrderWizardController.SlideDTO dto = result[0];
        System.assertEquals('Image', dto.type);
        System.assertEquals('https://test1.com', dto.imageUrl);
        System.assertEquals('<video></video>', dto.videoHtml);
        System.assertEquals('Tag1', dto.smallTag);
        System.assertEquals('Line1 A', dto.titleLine1);
        System.assertEquals('Line2 A', dto.titleLine2);
        System.assertEquals('Sub A', dto.subtitle);
        System.assertEquals('Click A', dto.buttonLabel);
    }
    
    
    
}