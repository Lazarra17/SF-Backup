public class fetchMembershipDataUsingFromDate {

    public static List<Account> getMembers(String APIKey, Integer limits, Integer Offset, Id personAccountId, String club, Map<String, Id> clubMap) {
        List<Account> accountsList = new List<Account>();
        Set<String> setOfmemberId = new Set<String>();
        fetchAccessToken.AccessTokenResponse tokenData = fetchAccessToken.getAccessToken();
        String fromDate;
        
        if(Label.Member_From_Date != 'Blank') {
            fromDate = Label.Member_From_Date;
        } else {
            fromDate = String.valueOf(Date.today().addDays(-1));
        }
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        // Set the endpoint URL https://api.clubfit.net.au/v1/members?limit=500&offset=1000
        String endpoint = Label.Membership_Endpoint + '?fromdate' + fromDate + 'limit=' + limits + '&offset=' + Offset;
        
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('x-api-key', APIKey);
        // Set the Authorization header with bearer token
        request.setHeader('Authorization', 'Bearer ' + tokenData.AccessToken);
        // Send the request and get the response
        HttpResponse response;
        
        try {
            response = http.send(request);
        } catch (Exception e) {
            Error_Log__c err = new Error_Log__c();
            err.Error_Message__c = e.getMessage();
            err.Source_Class__c = 'fetchMembershipData';
            insert err;
        }
        
        // Check the response status
        if (response != null && response.getStatusCode() == 200) {
            // Deserialize the JSON response into the memberResponseWrapper class
            String responseData = response.getBody();
            String responseBody = responseData.replace('Number', 'NumberData');
            memberResponseWrapper members = (memberResponseWrapper) JSON.deserialize(responseBody, memberResponseWrapper.class);
            
            if(members.data != null){
                for(memberResponseWrapper.Member wrapRecord : members.data){
                    Account accRecord = new Account();
                    accRecord.RecordTypeId = personAccountId;
                    accRecord.Clubfit_Member_Id__c = String.valueOf(wrapRecord.NumberData);
                    String fName = wrapRecord.FirstName;
                    if(fName.length() > 40){
                        accRecord.FirstName = fName.substring(0, 40);
                    }else{
                        accRecord.FirstName = wrapRecord.FirstName;
                    }
                    accRecord.LastName = wrapRecord.LastName;
                    accRecord.Gender__c = wrapRecord.Gender;
                    accRecord.Status__c = wrapRecord.Status;
                    accRecord.PersonEmail = wrapRecord.Contact.Email;
                    accRecord.PersonMobilePhone = wrapRecord.Contact.Mobile;
                    accRecord.BillingStreet = wrapRecord.Contact.Address;
                    accRecord.BillingCity = wrapRecord.Contact.Suburb;
                    accRecord.BillingState = wrapRecord.Contact.State;
                    accRecord.BillingPostalCode = wrapRecord.Contact.Postcode;
                    accRecord.Membership_ID__pc = String.valueOf(wrapRecord.Membership.Id);
                    accRecord.Start_Date__pc = Date.valueOf(wrapRecord.Membership.StartDate);
                    if(wrapRecord.Membership.ExpiryDate != null){
                        accRecord.Expiry_Date__c =  Date.valueOf(wrapRecord.Membership.ExpiryDate);
                    }
                    accRecord.Membership_Name__c = wrapRecord.Membership.Name;
                    accRecord.Membership_Type__c = wrapRecord.Membership.Type;
                    accRecord.Fitness_Passport_Number__c = String.valueOf(wrapRecord.FitnessPassportNumber);
                    accRecord.et4ae5__HasOptedOutOfMobile__pc = wrapRecord.Contact.OptOutSms;
                    accRecord.AssociatedClub__c = clubMap.get(club);
                    accRecord.Barcode__c = String.valueOf(wrapRecord.Barcode);
                    accRecord.PersonHasOptedOutOfEmail = wrapRecord.Contact.OptOutEmail;
                    accRecord.Membership_Type__c = wrapRecord.Membership.Type;
                    if(wrapRecord.LastUpdatedUtcDateTime != null){
                        accRecord.Member_Last_Updated__c = Date.valueOf(wrapRecord.LastUpdatedUtcDateTime);
                    }
                    if(wrapRecord.LastName == null || wrapRecord.LastName == ''){
                        accRecord.LastName = 'Blank';
                    }
                    if(!setOfmemberId.contains(String.valueOf(wrapRecord.NumberData))){
                        setOfmemberId.add(String.valueOf(wrapRecord.NumberData));
                        accountsList.add(accRecord);
                    }
                }
            }
        } else {
            Error_Log__c errRec = new Error_Log__c();
            errRec.Error_Message__c = 'Callout failed or Response is blank';
            errRec.Source_Class__c = 'fetchMembershipData';
            insert errRec;
        }
        return accountsList;
    }
}