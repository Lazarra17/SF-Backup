public class fetchVisitData {
    
    public static List<Visitation__c> getVisits(String APIKey, Integer limits, Integer Offset, string clubName, Map<String,Id> clubMap) {
        List<Visitation__c> visitationListRecords = new List<Visitation__c>();
        Set<String> setOfmemberId = new Set<String>();
        fetchAccessToken.AccessTokenResponse tokenData = fetchAccessToken.getAccessToken();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set the endpoint URL https://api.clubfit.net.au/v1/members/attendance/visits?limit=500&offset=1000
        String endpoint = Label.Visit_Endpoint + '?limit=' + limits + '&offset=' + Offset;
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('x-api-key', APIKey);
        // Set the Authorization header with bearer token
        request.setHeader('Authorization', 'Bearer ' + tokenData.AccessToken);
        // Send the request and get the response
        HttpResponse response;
        response = http.send(request);
        
        // Check the response status
        if (response != null && response.getStatusCode() == 200) {
            // Deserialize the JSON response into the memberResponseWrapper class
            String responseData = response.getBody();
            visitResponseWrapper visitors = (visitResponseWrapper) JSON.deserialize(responseData, visitResponseWrapper.class);
            for (visitResponseWrapper.Visit wrapRecord : visitors.data) {
                Visitation__c visitationRecord = new Visitation__c();
                visitationRecord.Member_ID__c = wrapRecord.MemberNumber;
                visitationRecord.Door__c = wrapRecord.Door;
                visitationRecord.Scan_Source__c = wrapRecord.ScanSource;
                visitationRecord.Date_Time__c = wrapRecord.VisitDateTime;
                visitationRecord.Club__c = clubMap.get(clubName);
                visitationListRecords.add(visitationRecord);
            }
        } else {
            Error_Log__c errRecord = new Error_Log__c();
            errRecord.Error_Message__c = 'Response is null or Callout failed';
            errRecord.Source_Class__c = 'fetchVisitData';
            insert errRecord;
        }
        return visitationListRecords;
    }
}