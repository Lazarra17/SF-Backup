@IsTest
private class AvailabilityServiceBaseTest {

    /**
     * Test implementation of abstract class
     */
    private class TestAvailabilityService extends AvailabilityServiceBase {
        public override Object getAvailability(String uprn) {
            return getAccount(uprn);
        }

        public Account testGetAccount(String uprn) {
            return getAccount(uprn);
        }
    }

    @TestSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Account',
            UPRN__c = '101'
        );
        insert acc;
    }

    @IsTest
    static void testGetAccount_Success() {
        TestAvailabilityService service = new TestAvailabilityService();

        Test.startTest();
        Account result = service.testGetAccount('101');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('101', result.UPRN__c);
    }

    @IsTest
    static void testGetAccount_BlankUPRN() {
        TestAvailabilityService service = new TestAvailabilityService();

        try {
            service.testGetAccount('');
            System.assert(false, 'Expected AvailabilityException');
        } catch (AvailabilityException ex) {
            System.assertEquals(
                AvailabilityConstants.ERR_MSG_UPRN_PARAMETER_IS_REQUIRED,
                ex.getMessage()
            );
        }
    }

    @IsTest
    static void testGetAccount_NullUPRN() {
        TestAvailabilityService service = new TestAvailabilityService();

        try {
            service.testGetAccount(null);
            System.assert(false, 'Expected AvailabilityException');
        } catch (AvailabilityException ex) {
            System.assertEquals(
                AvailabilityConstants.ERR_MSG_UPRN_PARAMETER_IS_REQUIRED,
                ex.getMessage()
            );
        }
    }

    @IsTest
    static void testGetAccount_UPRNNotFound() {
        TestAvailabilityService service = new TestAvailabilityService();

        try {
            service.testGetAccount('999999');
            System.assert(false, 'Expected ResourceNotFoundException');
        } catch (ResourceNotFoundException ex) {
            System.assertEquals(
                AvailabilityConstants.ERR_MSG_CLIENT_ERROR_THE_GIVEN_UPRN_COULD_NOT_BE_FOUND,
                ex.getMessage()
            );
        }
    }

    @IsTest
    static void testGetAvailability_Success() {
        TestAvailabilityService service = new TestAvailabilityService();

        Test.startTest();
        Account result = (Account)service.getAvailability('101');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('101', result.UPRN__c);
    }
}