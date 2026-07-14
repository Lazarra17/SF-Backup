public class fetchAccessToken {
    public class AccessTokenResponse {
        public String AccessToken;
        public Integer ExpiresIn;
        public String TokenType;
    }
    
    public static AccessTokenResponse getAccessToken() {
        String endpoint = Label.Access_Token_Endpoint;
        String username = Label.UserName;
        String password = Label.Password;
        
        // Create the HTTP request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        
        // Set Basic Authentication
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
        request.setHeader('Authorization', authorizationHeader);
        request.setHeader('Content-Type', 'application/json');
        
        try {
            // Send the request
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                // Parse the response
                AccessTokenResponse tokenResponse = (AccessTokenResponse) JSON.deserialize(response.getBody(), AccessTokenResponse.class);
                System.debug('tokenResponse: ' + tokenResponse);
                return tokenResponse;
            } else {
                System.debug('Error: ' + response.getStatus());
                System.debug('Response Body: ' + response.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return null;
        }
    }
}