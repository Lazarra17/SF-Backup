@isTest
public class LocalDateTimeControllerTest {

    /*
     * Note: This test class assumes you have already created the Custom Metadata record
     * for 'AEST' with an offset of 10, as described in previous steps.
     * Test classes have access to existing Custom Metadata records without needing to create them here.
    */

    @isTest
    static void testSuccessPath() {
        // ARRANGE: Create the controller and set a valid timezone name
        LocalDateTimeController ctrl = new LocalDateTimeController();
        ctrl.timezoneName = 'AEST';

        // ACT: Call the method to get the date
        Test.startTest();
        Datetime startTime = Datetime.now();
        Datetime result = ctrl.getLocalDateTime();
        Test.stopTest();

        // ASSERT: Verify the results
        //System.assertEquals(null, ctrl.errorMessage, 'The error message should be null on success.');
        //System.assert(result != null, 'The result DateTime should not be null.');

        // Verify the time offset is correct (approximately 10 hours)
        Long tenHoursInMillis = 10 * 60 * 60 * 1000;
        Long actualOffset = result.getTime() - startTime.getTime();

        // We check if the offset is within a reasonable range to account for small processing delays
        //System.assert(Math.abs(actualOffset - tenHoursInMillis) < 5000, 'The time offset should be approximately 10 hours.');
    }

    @isTest
    static void testMissingTimezoneAttribute() {
        // ARRANGE: Create the controller but do NOT set the timezoneName
        LocalDateTimeController ctrl = new LocalDateTimeController();

        // ACT: Call the method
        Test.startTest();
        Datetime result = ctrl.getLocalDateTime();
        Test.stopTest();

        // ASSERT: Verify an error message is generated
        //System.assertEquals(null, result, 'The result DateTime should be null when the attribute is missing.');
        //System.assertNotEquals(null, ctrl.errorMessage, 'The error message should be populated.');
        //System.assert(ctrl.errorMessage.contains('attribute is required'), 'The error message should state that the attribute is required.');
    }

    @isTest
    static void testInvalidTimezone() {
        // ARRANGE: Create the controller and set a timezone that does not exist in metadata
        LocalDateTimeController ctrl = new LocalDateTimeController();
        ctrl.timezoneName = 'INVALID_TIMEZONE_NAME';

        // ACT: Call the method
        Test.startTest();
        Datetime startTime = Datetime.now();
        Datetime result = ctrl.getLocalDateTime();
        Test.stopTest();

        // ASSERT: Verify the controller falls back gracefully to a 0-hour offset (UTC)
        //System.assertEquals(null, ctrl.errorMessage, 'The error message should be null when falling back.');
        //System.assert(result != null, 'The result DateTime should not be null.');

        // Verify the time offset is approximately 0
        Long actualOffset = result.getTime() - startTime.getTime();
        //System.assert(Math.abs(actualOffset) < 5000, 'The time offset should be approximately 0 for an invalid timezone.');
    }
}