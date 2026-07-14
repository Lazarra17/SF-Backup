@isTest
public class TourBookingControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            Username = 'testuser@example.com.testingtechilabodyfit',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;

        // Setup Test Data
        Club__c testClub = new Club__c(Name = 'Test Club');
        insert testClub;

        // Create Lead with all required fields and the test user as the Owner
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted', // Required field for Lead
            OwnerId = testUser.Id // Use the test user ID
        );
        insert testLead;
    }

    @isTest
    static void testTourBookingController() {
        Club__c testClub = [SELECT Id FROM Club__c LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Test.setCurrentPageReference(new PageReference('/apex/BookaTour'));
        ApexPages.currentPage().getParameters().put('clubId', testClub.Id);
        ApexPages.currentPage().getParameters().put('leadId', testLead.Id);

        TourBookingController controller = new TourBookingController();

        System.assertEquals(testClub.Id, controller.clubId, 'Club ID should match the parameter');
        System.assertEquals(testLead.Id, controller.leadId, 'Lead ID should match the parameter');
    }

    @isTest
    static void testLoadAvailableSlots() {
        Club__c testClub = [SELECT Id FROM Club__c LIMIT 1];
        Date testDate = Date.newInstance(2025, 3, 21);

        Club_Tour__c existingTour = new Club_Tour__c(
            Club__c = testClub.Id,
            Start_Time__c = Datetime.newInstance(testDate, Time.newInstance(9, 0, 0, 0))
        );
        insert existingTour;

        Test.setCurrentPageReference(new PageReference('/apex/BookaTour'));
        ApexPages.currentPage().getParameters().put('clubId', testClub.Id);

        TourBookingController controller = new TourBookingController();
        controller.selectedDate = testDate;
        controller.loadAvailableSlots();

        List<String> availableSlotLabels = new List<String>();
        for (SelectOption option : controller.availableSlots) {
            availableSlotLabels.add(option.getLabel());
        }

        System.assert(!availableSlotLabels.contains('9:00'), '9:00 slot should be unavailable');
        System.assert(availableSlotLabels.contains('10:00'), '10:00 slot should be available');
    }

    @isTest
    static void testBookTour() {
        Club__c testClub = [SELECT Id FROM Club__c LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Date testDate = Date.newInstance(2025, 3, 21);

        Test.setCurrentPageReference(new PageReference('/apex/BookaTour'));
        ApexPages.currentPage().getParameters().put('clubId', testClub.Id);
        ApexPages.currentPage().getParameters().put('leadId', testLead.Id);

        TourBookingController controller = new TourBookingController();
        controller.selectedDate = testDate;
        controller.selectedSlot = '9:30';

        PageReference result = controller.bookTour();

        System.assertNotEquals(null, result, 'PageReference should not be null');
        System.assertEquals('https://bodyfit.com.au/thank-you/', result.getUrl(), 'Redirect URL should match');
    }

    @isTest
    static void testConflictBooking() {
        Club__c testClub = [SELECT Id FROM Club__c LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Date testDate = Date.newInstance(2025, 3, 21);

        Club_Tour__c existingTour = new Club_Tour__c(
            Club__c = testClub.Id,
            Lead__c = testLead.Id,
            Start_Time__c = Datetime.newInstance(testDate, Time.newInstance(9, 30, 0, 0))
        );
        insert existingTour;

        Test.setCurrentPageReference(new PageReference('/apex/BookaTour'));
        ApexPages.currentPage().getParameters().put('clubId', testClub.Id);
        ApexPages.currentPage().getParameters().put('leadId', testLead.Id);

        TourBookingController controller = new TourBookingController();
        controller.selectedDate = testDate;
        controller.selectedSlot = '9:30';

        controller.bookTour();

        List<Club_Tour__c> tours = [SELECT Id FROM Club_Tour__c WHERE Club__c = :testClub.Id];
        System.assertEquals(1, tours.size(), 'Only one tour should exist after conflict resolution');
    }
}