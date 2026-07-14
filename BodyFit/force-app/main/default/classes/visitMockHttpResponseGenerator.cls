public class visitMockHttpResponseGenerator implements HttpCalloutMock  {
 public HttpResponse respond(HttpRequest req) {
        // Create a mock HttpResponse with a sample JSON response
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        
        // Example mock response data matching the structure expected by visitResponseWrapper
        String jsonResponse = '{' +
            '"data": [' +
                '{' +
                    '"MemberNumber": "12345",' +
                    '"Door": "Main Entrance",' +
                    '"ScanSource": "Mobile App",' +
                    '"VisitDateTime": "2024-01-01T10:00:00Z"' +
                '},' +
                '{' +
                    '"MemberNumber": "",' +
                    '"Door": "Side Entrance",' +
                    '"ScanSource": "Card Swipe",' +
                    '"VisitDateTime": "2024-01-02T12:30:00Z"' +
                '}' +
            ']' +
        '}';
        
        res.setBody(jsonResponse);
        return res;
    }
}