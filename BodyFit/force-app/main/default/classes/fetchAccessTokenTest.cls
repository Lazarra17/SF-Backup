@isTest
public class fetchAccessTokenTest {
    
      // Mock class to simulate the HTTP response for a successful request
    private class AccessTokenMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Create a fake HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"AccessToken": "mockAccessToken123", "ExpiresIn": 3600, "TokenType": "Bearer"}');
            return res;
        }
    }

    // Mock class to simulate an error response
    private class AccessTokenErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error": "invalid_request"}');
            return res;
        }
    }

    // Mock class to simulate an exception during the HTTP request
    private class ExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Throw a custom exception to simulate an error
            throw new CalloutException('Simulated callout exception');
        }
    }

    @isTest
    static void testGetAccessTokenSuccess() {
        // Set up the mock callout for a successful response
        Test.setMock(HttpCalloutMock.class, new AccessTokenMock());

        // Call the method to test
        test.startTest();
        fetchAccessToken.AccessTokenResponse result = fetchAccessToken.getAccessToken();
        test.stopTest();

    }

    @isTest
    static void testGetAccessTokenError() {
        // Set up the mock callout with an error response
        Test.setMock(HttpCalloutMock.class, new AccessTokenErrorMock());

        // Call the method to test
        test.startTest();
        fetchAccessToken.AccessTokenResponse result = fetchAccessToken.getAccessToken();
        test.stopTest();

    }

    @isTest
    static void testGetAccessTokenException() {
        // Set up the mock callout to throw an exception
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        // Call the method to test
        test.startTest();
        fetchAccessToken.AccessTokenResponse result = fetchAccessToken.getAccessToken();
        test.stopTest();

    }

}