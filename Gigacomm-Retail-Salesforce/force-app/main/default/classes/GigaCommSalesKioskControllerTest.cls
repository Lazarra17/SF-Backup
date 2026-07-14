@isTest
public class GigaCommSalesKioskControllerTest {
    private static testMethod void createLeadTest() {
        List<Kiosk_Bric__c> kioskList = GigaCommTestDataBuilder.createKiosk(true, 1);

        Lead l = new Lead();

        Test.startTest();
            l = GigaCommSalesKioskController.createLead(kioskList[0].Id, '12345');
        Test.stopTest();

        Assert.isTrue([SELECT Id FROM Lead WHERE Id =: l.Id] != null, 'Lead is created');
    }
}