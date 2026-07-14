@IsTest
public class InvoicePdfControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Invoice record
        nao__Invoice__c testInvoice = new nao__Invoice__c(
            nao__Account_Bric__c = testAccount.Id
        );
        insert testInvoice;

        // You can add additional related records if necessary
    }

    @IsTest
    static void testConstructor() {
        // Simulate the parameters that would be passed to the controller
        String testObjectName = Constants.NAO_INVOICE;
        String testRecordId = [SELECT Id FROM nao__Invoice__c LIMIT 1].Id;
        String testChildObjName = Constants.NAO_INVOICE_LINES;
        String testLogoUrl = 'http://example.com/logo.png';

        // Simulate the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/'+Constants.NAO_TAXINVOICEPDF));
        ApexPages.currentPage().getParameters().put('sObjectType', testObjectName);
        ApexPages.currentPage().getParameters().put('Id', testRecordId);
        ApexPages.currentPage().getParameters().put('childSObjectType', testChildObjName);
        ApexPages.currentPage().getParameters().put('pdfLogo', testLogoUrl);

        // Instantiate the controller
        InvoicePdfController controller = new InvoicePdfController();

        // Validate that the constructor initialized the properties correctly
        System.assertEquals(testLogoUrl, controller.logoUrl, 'Expected logoUrl to be set.');
        System.assertNotEquals(null, controller.recordList, 'recordList should not be null.');
    }

    @IsTest
    static void testRecordListPopulation() {
        // Simulate the page parameters
        Test.setCurrentPageReference(new PageReference('/apex/'+Constants.NAO_TAXINVOICEPDF));
        ApexPages.currentPage().getParameters().put('sObjectType', Constants.NAO_INVOICE);
        ApexPages.currentPage().getParameters().put('Id', [SELECT Id FROM nao__Invoice__c LIMIT 1].Id);
        ApexPages.currentPage().getParameters().put('childSObjectType', Constants.NAO_INVOICE_LINES);

        // Instantiate the controller
        InvoicePdfController controller = new InvoicePdfController();

        // Validate that the recordList is populated as expected
        System.assertNotEquals(null, controller.recordList, 'recordList should be populated.');
        System.assert(controller.recordList.size() > 0, 'recordList should contain records.');
    }
}