@isTest
public class GigaCommOrderPersonalDetailsCtrlTest {
    
    @testSetup
    public static void setupData(){ 
        
        List<Lead> leadList = GigaCommTestDataBuilder.createLeads(true, 1);
        List<Product2> prodList = GigaCommTestDataBuilder.createProducts(false, 4, 'Data');
        prodList[0].Category_bric__c = 'Hardware';
        prodList[1].Category_bric__c = 'Installation';
        prodList[2].Category_bric__c = 'Data'; 
        prodList[3].Category_bric__c = 'Data'; 
        insert prodList;
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);
        List<Lead_Product_Item__c> lpiList = GigaCommTestDataBuilder.createdLeadProductItem(true, prodList, leadList[0].Id);
        
        
        List<Voucher__c> vouchers = GigaCommTestDataBuilder.createVouchers(true,  1);
        List<Voucher_Status__c> vouchersStatus = GigaCommTestDataBuilder.createVoucherStatuses(true, vouchers[0],  1);
        List<Voucher_Product__c> vouchersProducts = GigaCommTestDataBuilder.createVoucherProducts(true, vouchers[0], prodList[2], prodList[3], 1);
        
    }

    private static testMethod void getLeadTest() {

     
        List<Lead> leadList = [SELECT Id FROM Lead];
        GigaCommOrderPersonalDetailsController.SiteLead siteLead = new GigaCommOrderPersonalDetailsController.SiteLead();

        Test.startTest();
            siteLead = GigaCommOrderPersonalDetailsController.getLead(leadList[0].Id);
        Test.stopTest();

        Assert.isTrue(siteLead != null, 'SiteLead not null');
    }

    private static testMethod void updateLeadTest() {

        GigaCommOrderPersonalDetailsController.SiteLead slToUpdate = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(GigaCommTestDataBuilder.getStaticSiteLead(), GigaCommOrderPersonalDetailsController.SiteLead.class);
        List<Product2> prodList = GigaCommTestDataBuilder.createProducts(true, 4, 'Data');
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);
        List<Lead> leadList = GigaCommTestDataBuilder.createLeads(true, 1);
        slToUpdate.Lead = leadList[0];
        slToUpdate.Lead.TECH_LastName_bric__c = 'Test Lname';
        
        //Create Lead Products on Lead
        Lead_Product_Item__c lp = new Lead_Product_Item__c();
        lp.Product_bric__c = prodList[0].Id;
        lp.Lead_bric__c = leadList[0].Id;
        lp.Quantity_bric__c = 1;
        lp.Unit_Price_bric__c = 100;
        lp.TECH_PriceBookEntryId_bric__c = pbeList[0].Id;
        insert lp; 
        
        GigaCommOrderPersonalDetailsController.SiteLead sl = slToUpdate;
        
        String jsonString = JSON.serialize(sl);
        
        Test.startTest();
        
        GigaCommOrderPersonalDetailsController.updateLead(jsonString, true);
        Test.stopTest();

        Assert.isTrue(sl.Lead.Id != null, 'Lead ID is not null');
    }
    
    
    private static testMethod void applyPromoTest() {
        
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id, Term_bric__c, FirstName, TECH_LastName_bric__c, Email, MobilePhone, Unit_Number_Bric__c FROM Lead LIMIT 1];
        Voucher__c v = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c];
  
   
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(GigaCommTestDataBuilder.getStaticSiteLead(), GigaCommOrderPersonalDetailsController.SiteLead.class);
  
        Test.startTest();
        sl.Lead = l;
        GigaCommOrderPersonalDetailsController.applyPromoCode(JSON.Serialize(sl), 'PROMO0');
        Test.stopTest();
        
    }

    private static testMethod void applyPromoVoucherNotExistTest() {
        
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id, Term_bric__c, FirstName, TECH_LastName_bric__c, Email, MobilePhone, Unit_Number_Bric__c FROM Lead LIMIT 1];
        Voucher__c v = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c];
  
   
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(GigaCommTestDataBuilder.getStaticSiteLead(), GigaCommOrderPersonalDetailsController.SiteLead.class);
  
        Test.startTest();
        sl.Lead = l;
        GigaCommOrderPersonalDetailsController.applyPromoCode(JSON.Serialize(sl), 'NOEXIST');
        Test.stopTest();
        
    }
    
    private static testMethod void applyPromoVoucherExpiredTest() {
        
        Voucher_Status__c vs = [SELECT Id, Status_bric__c FROM Voucher_Status__c LIMIT 1];
    	vs.Status_bric__c = 'Inactive';
        update vs;
        
        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id, Term_bric__c, FirstName, TECH_LastName_bric__c, Email, MobilePhone, Unit_Number_Bric__c FROM Lead LIMIT 1];
        Voucher__c v = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c];
  
   
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(GigaCommTestDataBuilder.getStaticSiteLead(), GigaCommOrderPersonalDetailsController.SiteLead.class);
  
        Test.startTest();
        sl.Lead = l;
        GigaCommOrderPersonalDetailsController.applyPromoCode(JSON.Serialize(sl), 'PROMO0');
        Test.stopTest();
        
    }
    
    private static testMethod void applyPromoNoVoucherProdTest() {
        
        Voucher_Product__c vs = [SELECT Id, Apply_bric__c FROM Voucher_Product__c LIMIT 1];
    	vs.Apply_bric__c = '';
        update vs;
        

        Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id, Term_bric__c, FirstName, TECH_LastName_bric__c, Email, MobilePhone, Unit_Number_Bric__c FROM Lead LIMIT 1];
        Voucher__c v = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c];
  
   
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(GigaCommTestDataBuilder.getStaticSiteLead(), GigaCommOrderPersonalDetailsController.SiteLead.class);
  
        Test.startTest();
        sl.Lead = l;
        GigaCommOrderPersonalDetailsController.applyPromoCode(JSON.Serialize(sl), 'PROMO0');
        Test.stopTest();
        
    }
    
    private static testMethod void applyPromoNoVoucherStatusTest() {
        
        Voucher_Status__c vs = [SELECT Id, Status_bric__c FROM Voucher_Status__c LIMIT 1];
        delete vs;
        
         Lead_Product_Item__c lp = [SELECT Id FROM Lead_Product_Item__c WHERE Product_bric__r.Family = 'Data' LIMIT 1];
        Lead l = [SELECT Id, Term_bric__c, FirstName, TECH_LastName_bric__c, Email, MobilePhone, Unit_Number_Bric__c FROM Lead LIMIT 1];
        Voucher__c v = [SELECT Id, Voucher_Code_bric__c FROM Voucher__c];
  
   
        GigaCommOrderPersonalDetailsController.SiteLead sl = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(GigaCommTestDataBuilder.getStaticSiteLead(), GigaCommOrderPersonalDetailsController.SiteLead.class);
  
        Test.startTest();
        sl.Lead = l;
        GigaCommOrderPersonalDetailsController.applyPromoCode(JSON.Serialize(sl), 'PROMO0');
        Test.stopTest();
        
    }
    

    
    private static testMethod void removeVoucherTest() {
        
        GigaCommOrderPersonalDetailsController.SiteLead slToUpdate = (GigaCommOrderPersonalDetailsController.SiteLead)JSON.deserialize(GigaCommTestDataBuilder.getStaticSiteLead(), GigaCommOrderPersonalDetailsController.SiteLead.class);
        Lead l = [SELECT Id FROM Lead LIMIT 1];
        slToUpdate.Lead = l;
        Voucher__c v = [SELECT Id FROM Voucher__c ];
        Test.startTest();
        GigaCommOrderPersonalDetailsController.deleteVouchers(JSON.Serialize(slToUpdate), 'PROMO0');
        Test.stopTest();
        
    }

}