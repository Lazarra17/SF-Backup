/*
 * Author:          Bricoleur Technologies - Kristine Arcangel
 * Created Date:    June 9, 2022
 * Description:     Test Class for XeroDummyAPICall
 * Test Class:      N/A
 * History:         June 9, 2022 - Creation
*/

@IsTest
public class XeroDummyAPICallTest {

    @isTest
    private static void GetTenantIdSuccessful()
    {
        String testTenantId = '1111111111111';
        List<RestResponseCollectionXero.XeroTenantIdResponseBody> responseBody = new List<RestResponseCollectionXero.XeroTenantIdResponseBody>{SetXeroTenantIdResponseBody(testTenantId)};
        MockResponse response = new MockResponse(CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200 , JSON.serialize(responseBody));
        
        test.startTest();
        
        test.setMock(HttpCalloutMock.class, response);
        XeroDummyAPICallSchedulable.GetTenantId();
        
        XeroDummyAPICallSchedulable sh1 = new XeroDummyAPICallSchedulable();        
        String sch = '0 0 23 * * ?';
        system.schedule('Test Xero Dummy API Call', sch, sh1); 
        
        test.stopTest();

    }
    
    private static RestResponseCollectionXero.XeroTenantIdResponseBody SetXeroTenantIdResponseBody(String testTenantId)
    {
        RestResponseCollectionXero.XeroTenantIdResponseBody responseBody = new RestResponseCollectionXero.XeroTenantIdResponseBody();
        responseBody.id = 'testId';
        responseBody.authEventId = 'testAuthEventId';
        responseBody.tenantId = testTenantId;
        responseBody.tenantType = 'testTenantType';
        responseBody.tenantName = 'testTenantName';
        responseBody.createdDateUtc = '2020-01-01';
        responseBody.updatedDateUtc = '2020-01-01';
        
        return responseBody;
    }
    
    
    
}