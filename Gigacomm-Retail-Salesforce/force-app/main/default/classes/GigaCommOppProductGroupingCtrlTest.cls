@isTest
public class GigaCommOppProductGroupingCtrlTest {

    @TestSetup
    static void makeData(){
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Voucher__c voucher = new Voucher__c(Name = 'Test Voucher');
        insert voucher;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Voucher_bric__c = voucher.Id
        );
        insert opp;

        List<Product2> productsToInsert = new List<Product2>{
            new Product2(
                Name = 'Monthly Offer Plan', IsActive = true,
                Order_Confirmation_Line_Description_Bric__c = 'Monthly Offer Plan Desc',
                Frequency_bric__c = 'Monthly'
            ),
            new Product2(
                Name = 'Monthly Standard Plan', IsActive = true,
                Order_Confirmation_Line_Description_Bric__c = 'Monthly Standard Plan Desc',
                Frequency_bric__c = 'Monthly'
            ),
            new Product2(
                Name = 'Monthly Free Addon', IsActive = true,
                Order_Confirmation_Line_Description_Bric__c = 'Free Addon Desc',
                Frequency_bric__c = 'Monthly'
            ),
            new Product2(
                Name = 'One-time Fee', IsActive = true,
                Order_Confirmation_Line_Description_Bric__c = 'Installation Fee Desc',
                Frequency_bric__c = 'One-time'
            )
        };
        insert productsToInsert;

        Voucher_Product__c voucherProduct = new Voucher_Product__c(
            Voucher_bric__c = voucher.Id,
            Product_to_Apply_bric__c = productsToInsert[0].Id,
            Apply_if_Product_Present_bric__c = productsToInsert[0].Id,
            Duration_months_bric__c = 24
        );
        insert voucherProduct;

        List<PricebookEntry> pbesToInsert = new List<PricebookEntry>();
        Id standardPbId = Test.getStandardPricebookId();
        pbesToInsert.add(new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = productsToInsert[0].Id, UnitPrice = 100.00, IsActive = true));
        pbesToInsert.add(new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = productsToInsert[1].Id, UnitPrice = 50.00, IsActive = true));
        pbesToInsert.add(new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = productsToInsert[2].Id, UnitPrice = 0.00, IsActive = true));
        pbesToInsert.add(new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = productsToInsert[3].Id, UnitPrice = 150.00, IsActive = true));
        insert pbesToInsert;

        List<OpportunityLineItem> olisToInsert = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = opp.Id, PricebookEntryId = pbesToInsert[0].Id,
                Quantity = 1, UnitPrice = 100.00,
                Voucher_bric__c = voucher.Id, Voucher_Term_bric__c = 12
            ),
            new OpportunityLineItem(
                OpportunityId = opp.Id, PricebookEntryId = pbesToInsert[1].Id,
                Quantity = 1, UnitPrice = 50.00,
                Voucher_Term_bric__c = 12
            ),
            new OpportunityLineItem(
                OpportunityId = opp.Id, PricebookEntryId = pbesToInsert[2].Id,
                Quantity = 1, UnitPrice = 0.00
            ),
            new OpportunityLineItem(
                OpportunityId = opp.Id, PricebookEntryId = pbesToInsert[3].Id,
                Quantity = 1, UnitPrice = 150.00
            )
        };
        insert olisToInsert;
    }

    @isTest
    static void testMonthlyProductsAndTotals() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        Test.startTest();
        GigaCommOppProductGroupingCtrl ctrl = new GigaCommOppProductGroupingCtrl();
        ctrl.oppId = opp.Id;
        ctrl.frequency = 'Monthly';

        List<OpportunityLineItem> results = ctrl.getProductsByFrequency();
        Decimal totalAll = ctrl.getProductTotals();
        Decimal totalNotZero = ctrl.getProductTotalsNotZero();
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should return 3 monthly products.');
        System.assertEquals(150.00, totalAll, 'Total of all monthly products should be 150.');
        System.assertEquals(150.00, totalNotZero, 'Total of monthly products with price > 0 should be 150.');
    }

    @isTest
    static void testGetMonthlyPlansWithVoucher() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        Test.startTest();
        GigaCommOppProductGroupingCtrl ctrl = new GigaCommOppProductGroupingCtrl();
        ctrl.oppId = opp.Id;
        ctrl.frequency = 'Monthly';

        List<GigaCommOppProductGroupingCtrl.PlansWrapper> plans = ctrl.getPlans();
        Test.stopTest();
        
        System.assertEquals(3, plans.size(), 'Should return 3 plan wrappers for monthly products.');

        Boolean offerTermCorrect = false;
        Boolean standardTermCorrect = false;

        for (GigaCommOppProductGroupingCtrl.PlansWrapper plan : plans) {
            String productName = plan.oppProduct.PriceBookEntry.Product2.Name;
            if (productName == 'Monthly Offer Plan') {
                System.assertEquals(24, plan.voucherTerm, 'Offer plan voucher term should be 24.');
                offerTermCorrect = true;
            } else if (productName == 'Monthly Standard Plan') {
                System.assertEquals(12, plan.voucherTerm, 'Standard plan voucher term should be 12.');
                standardTermCorrect = true;
            }
        }
        
        System.assert(offerTermCorrect, 'The offer plan with the correct overridden voucher term was not found.');
        System.assert(standardTermCorrect, 'The standard plan with the correct voucher term was not found.');
    }

    @isTest
    static void testGetPlansForOtherFrequency() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        Test.startTest();
        GigaCommOppProductGroupingCtrl ctrl = new GigaCommOppProductGroupingCtrl();
        ctrl.oppId = opp.Id;
        ctrl.frequency = 'One-time';

        List<GigaCommOppProductGroupingCtrl.PlansWrapper> plans = ctrl.getPlans();
        Test.stopTest();

        System.assertEquals(1, plans.size(), 'Should return 1 plan wrapper for the One-time product.');
        System.assertEquals(null, plans[0].voucherTerm, 'Voucher term should be null for non-monthly frequencies.');
        System.assertEquals('One-time Fee', plans[0].oppProduct.PriceBookEntry.Product2.Name);
    }

    @isTest
    static void testNoProductsFound() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        Test.startTest();
        GigaCommOppProductGroupingCtrl ctrl = new GigaCommOppProductGroupingCtrl();
        ctrl.oppId = opp.Id;
        ctrl.frequency = 'Yearly';

        List<OpportunityLineItem> results = ctrl.getProductsByFrequency();
        Decimal total = ctrl.getProductTotals();
        List<GigaCommOppProductGroupingCtrl.PlansWrapper> plans = ctrl.getPlans();
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return 0 products for a frequency that does not exist.');
        System.assertEquals(0, total, 'Total should be 0 when no products are found.');
        System.assertEquals(0, plans.size(), 'Plans list should be empty when no products are found.');
    }
}