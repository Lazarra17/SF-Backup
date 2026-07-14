public class MemberMockHttpResponseGenerator  implements HttpCalloutMock  {
 public HttpResponse respond(HttpRequest req) {
        // Create a mock HttpResponse with a sample JSON response
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        
        // Example mock response data (use your actual API response structure)
        String jsonResponse = '{' +
            '"data": [' +
            '{' +
                '"NumberData": "12345",' +
                '"FirstName": "A very long first name that exceeds forty characters",' +
                '"LastName": "",' +
                '"Gender": "M",' +
                '"Status": "Active",' +
                '"LastUpdatedUtcDateTime": "2025-01-01",' +
                '"Contact": {' +
                    '"Email": "john.doe@example.com",' +
                    '"Mobile": "555123456",' +
                    '"Suburb": "Sydney",' +
                    '"State": "NSW",' +
                    '"Postcode": "2000",' +
                    '"OptOutSms": false,' +
                    '"OptOutEmail": false' +
                '},' +
                '"Membership": {' +
                    '"Id": "67890",' +
                    '"StartDate": "2024-01-01",' +
            		'"SaleDate": "2023-02-03T18:08:04.42",' +
                    '"ExpiryDate": "2025-01-01",' +
                    '"Name": "Premium Membership",' +
                    '"Type": "Gold"' +
                '},' +
                '"FitnessPassportNumber": "987654321",' +
                '"Barcode": "111222333"' +
            '}]' +
        '}';

        res.setBody(jsonResponse);
        return res;
    }
}