/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Test Class for AvailabilityV2Rest
@History: [1] Created - 3-Nov-2026
*/
@IsTest
private class AvailabilityV2RestTest {

    private static void setupRestRequest(String uprn) {
        
        List<Account> accList = TestDataFactory.createAccount(1, true);
        

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/availability/v2';
        req.httpMethod = 'GET';

        if(uprn != null) {
            req.addParameter('UPRN', uprn);
        }

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void testGetAvailability_Success() {

        setupRestRequest('101');

        Test.startTest();
        AvailabilityV2Rest.getAvailability();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest
    static void testGetAvailability_BadRequestException() {

        setupRestRequest(null);

        Test.startTest();
        AvailabilityV2Rest.getAvailability();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @IsTest
    static void testGetAvailability_ResourceNotFoundException() {

        setupRestRequest('110001');

        Test.startTest();
        AvailabilityV2Rest.getAvailability();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

  /*
    @IsTest
    static void testGetAvailability_ForbiddenException() {
        
        //setupRestRequest('101');
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/availability/2121/412121/2121';
        req.httpMethod = 'GET';
        
        
        req.addParameter('UPRN', '101');
        

        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        User restrictedUser = TestDataFactory.createStandardUser(true);
        
        
        System.runAs(restrictedUser) {
            AvailabilityV1Rest.getAvailability();
            
        }
        System.assertEquals(403, RestContext.response.statusCode);
    }
  	
    @IsTest
    static void testGetAvailability_AuthenticationException() {

        setupRestRequest('AUTH_ERROR');

        Test.startTest();
        AvailabilityV1Rest.getAvailability();
        Test.stopTest();

        System.assertEquals(501, RestContext.response.statusCode);
    }	

    @IsTest
    static void testGetAvailability_ServiceUnavailableException() {

        setupRestRequest('SERVICE_DOWN');

        Test.startTest();
        AvailabilityV1Rest.getAvailability();
        Test.stopTest();

        System.assertEquals(503, RestContext.response.statusCode);
    }

    @IsTest
    static void testGetAvailability_GenericException() {

        setupRestRequest('THROW_EXCEPTION');

        Test.startTest();
        AvailabilityV1Rest.getAvailability();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }
    */
   
}