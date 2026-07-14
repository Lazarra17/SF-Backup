public class ClubFitService {
    // Gets the bearer token from ClubFit API
    public static String getAccessToken() {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://api.clubfit.net.au/v1/token');
    req.setMethod('POST');
    
    // Basic Auth
    String credentials = 'bodyfit:Techila25$';
    Blob headerValue = Blob.valueOf(credentials);
    String authHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
    req.setHeader('Authorization', authHeader);
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    // If the token endpoint requires a POST body, set it here. For example:
    // req.setBody('grant_type=client_credentials');
    
    Http http = new Http();
    HTTPResponse res = http.send(req);
    if (res.getStatusCode() == 200) {
        // Parse the JSON response
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        // The correct key is "AccessToken", not "token"
        String accessToken = (String) result.get('AccessToken');
        return accessToken;
    } else {
        throw new CalloutException('Failed to get token: ' + res.getBody());
    }
}


    
    // Retrieves member data for a given club using its API key and date parameters.
    public static String getMembersJSON(String fromDate, String updateDate, String clubApiKey) {
        String token = getAccessToken();
        // Construct the URL. Adjust offset & limit if you have paging requirements.
        String url = 'https://api.clubfit.net.au/v1/members?fromdate=' + 
                     EncodingUtil.urlEncode(fromDate, 'UTF-8') + 
                     '&limit=500&offset=0&updatedate=' + 
                     EncodingUtil.urlEncode(updateDate, 'UTF-8');
                     
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('x-api-key', clubApiKey);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            // Handle error appropriately
            throw new CalloutException('Failed to get members: ' + res.getBody());
        }
    }
	    public static String getVisitsJSON(String fromDate, String clubApiKey, Integer offset) {
        String token = getAccessToken();

        // Example URL
        String url = 'https://api.clubfit.net.au/v1/members/attendance/visits'
            + '?fromdate=' + EncodingUtil.urlEncode(fromDate, 'UTF-8')
            + '&limit=500'
            + '&offset=' + offset
            + '&status=Active';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('x-api-key', clubApiKey);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new CalloutException('Failed to get visits: ' + res.getBody());
        }
    }
	    public static String getPaymentHistoryJSON(String fromDate, String clubApiKey, Integer offset) {
        String token = getAccessToken();
        String url = 'https://api.clubfit.net.au/v1/members/payment/history'
            + '?fromdate=' + EncodingUtil.urlEncode(fromDate, 'UTF-8')
            + '&limit=500'
            + '&offset=' + offset;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('x-api-key', clubApiKey);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new CalloutException('Failed to get payment history: ' + res.getBody());
        }
    }


}