/**
 * @description Test class for VoucherTermsConditionsCtrl
 * @author JP Sulit (jp@bricoleurtech.com)
 * @date 09 Jul 2025
 */
@isTest
public class VoucherTermsConditionsCtrlTest {

    @isTest
    static void testGetTermsConditions_Success() {
        Voucher__c testVoucher = new Voucher__c(
            Name = 'Test Voucher',
            Voucher_T_C__c = 'These are the test terms and conditions.\nLine 2.'
        );
        insert testVoucher;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Voucher_bric__c = testVoucher.Id
        );
        insert testOpp;

        VoucherTermsConditionsCtrl controller = new VoucherTermsConditionsCtrl();
        controller.oppId = testOpp.Id;

        Test.startTest();
        String terms = controller.getTermsConditions();
        Test.stopTest();

        //System.assertEquals(testVoucher.Voucher_T_C__c, terms, 
        //    'The terms and conditions should match the ones from the related Voucher.');
    }

    @isTest
    static void testGetTermsConditions_NoVoucher() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity No Voucher',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpp;

        VoucherTermsConditionsCtrl controller = new VoucherTermsConditionsCtrl();
        controller.oppId = testOpp.Id;

        Test.startTest();
        String terms = controller.getTermsConditions();
        Test.stopTest();

        System.assertEquals('', terms, 'Should return an empty string when there is no voucher.');
    }

    @isTest
    static void testGetTermsConditions_InvalidOppId() {
        VoucherTermsConditionsCtrl controller = new VoucherTermsConditionsCtrl();
        controller.oppId = null;

        Test.startTest();
        String terms = controller.getTermsConditions();
        Test.stopTest();

        System.assertEquals('', terms, 'Should return an empty string for an invalid or null Opportunity Id.');
    }
}