@isTest
public class GigaCommInstallerAccessRequiredCtrlTest {
    
    @isTest
    static void testGetHasInstallerAccess_true() {
        // Create required test data
        List<Product2> prodList = GigaCommTestDataBuilder.createProducts(false, 1, 'Data');
        prodList[0].Installer_Access_Required_Bric__c = true;
        insert prodList;
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbeList[0].Id
        );
        insert oli;

        Test.startTest();
        GigaCommInstallerAccessRequiredCtrl ctrl = new GigaCommInstallerAccessRequiredCtrl();
        ctrl.oppId = opp.Id;
        Boolean result = ctrl.getHasInstallerAccess();
        Test.stopTest();

        System.assertEquals(true, result, 'Expected access to be true');
    }

    @isTest
    static void testGetHasInstallerAccess_false() {
        // Create required test data with product that does NOT require installer access
        List<Product2> prodList = GigaCommTestDataBuilder.createProducts(false, 1, 'Data');
        prodList[0].Family = 'Hardware';
        insert prodList;
        List<PricebookEntry> pbeList = GigaCommTestDataBuilder.createPBEs(true, prodList);

        Opportunity opp = new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 200,
            PricebookEntryId = pbeList[0].Id
        );
        insert oli;

        Test.startTest();
        GigaCommInstallerAccessRequiredCtrl ctrl = new GigaCommInstallerAccessRequiredCtrl();
        ctrl.oppId = opp.Id;
        Boolean result = ctrl.getHasInstallerAccess();
        Test.stopTest();

        System.assertEquals(false, result, 'Expected access to be false');
    }

    @isTest
    static void testGetHasInstallerAccess_noOLI() {
        // No OpportunityLineItem case
        Opportunity opp = new Opportunity(
            Name = 'Test Opp 3',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        Test.startTest();
        GigaCommInstallerAccessRequiredCtrl ctrl = new GigaCommInstallerAccessRequiredCtrl();
        ctrl.oppId = opp.Id;
        Boolean result = ctrl.getHasInstallerAccess();
        Test.stopTest();

        System.assertEquals(false, result, 'Expected access to be false when no OLIs');
    }
}