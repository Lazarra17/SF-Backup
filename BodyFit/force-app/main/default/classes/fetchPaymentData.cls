public class fetchPaymentData {
    public static List<Payment_History__c> getPaymentHistory(String APIKey, Integer limits, Integer Offset, string clubName, Map<String,Id> clubMap) {
        List<Payment_History__c> paymentListRecords = new List<Payment_History__c>();
        Set<String> setOfmemberId = new Set<String>();
        fetchAccessToken.AccessTokenResponse tokenData = fetchAccessToken.getAccessToken();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        // Set the endpoint URL https://api.clubfit.net.au/v1/members/attendance/visits?limit=500&offset=1000
        String endpoint = Label.Payment_Endpoint + '?limit=' + limits + '&offset=' + Offset;
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
            err.Source_Class__c = 'fetchPaymentData';
            insert err;
        }
        
        
        // Check the response status
        if (response.getStatusCode() == 200) {
            // Deserialize the JSON response into the memberResponseWrapper class
            String responseData = response.getBody();
            system.debug('responseData 34'+ responseData);
            String responseBody = responseData.replace('Number', 'Numbers');
            system.debug('responseBody 34'+ responseBody);
            paymentResponseWrapper payements = (paymentResponseWrapper) JSON.deserialize(responseBody, paymentResponseWrapper.class);
            system.debug('payements '+payements);
            
            if(payements.data != null){
                for (paymentResponseWrapper.payment wrapRecord : payements.data) {
                    Payment_History__c paymentRecord = new Payment_History__c();
                    paymentRecord.Member_Id__c = String.valueOf(wrapRecord.Numbers);
                    paymentRecord.Payment_Date__c = wrapRecord.PaymentDate;
                    paymentRecord.Club__c = clubMap.get(clubName);
                    paymentRecord.Amount__c = wrapRecord.Amount;
                    paymentRecord.Payment_Type__c = wrapRecord.PaymentType;
                    paymentRecord.Response__c = wrapRecord.Response;
                    paymentRecord.Payment_Description__c = wrapRecord.PaymentDescription;
                    paymentRecord.Payment_Reference_Id__c = wrapRecord.PaymentForReference.Id;
                    paymentRecord.Payment_Reference_Name__c = wrapRecord.PaymentForReference.Name;
                    paymentRecord.Access_Card_Fee__c = wrapRecord.FeeBreakdown.AccessCardFee;
                    paymentRecord.Add_On_Amount__c = wrapRecord.FeeBreakdown.AddOnAmount;
                    paymentRecord.Adjustment__c = wrapRecord.FeeBreakdown.Adjustment; 
                    paymentRecord.Arrears_Fee__c = wrapRecord.FeeBreakdown.ArrearsFee;
                    paymentRecord.Cancellation_Late_Fee__c = wrapRecord.FeeBreakdown.CancellationLateFee;
                    paymentRecord.Card_Surcharge_Fee__c = wrapRecord.FeeBreakdown.CardSurchargeFee;
                    paymentRecord.Class_No_Show_Fee__c = wrapRecord.FeeBreakdown.ClassNoShowFee;
                    paymentRecord.Creche_Class_No_Show_Fee__c = wrapRecord.FeeBreakdown.CrecheClassNoShowFee;
                    paymentRecord.Dishonour_Fee__c = wrapRecord.FeeBreakdown.DishonourFee;
                    paymentRecord.Joining_Fee__c = wrapRecord.FeeBreakdown.JoiningFee;
                    paymentRecord.Maintenance_Fee__c = wrapRecord.FeeBreakdown.MaintenanceFee;
                    paymentRecord.Pos_Transaction__c = wrapRecord.FeeBreakdown.PosTransaction;
                    paymentRecord.Prorata__c = wrapRecord.FeeBreakdown.Prorata;
                    paymentRecord.Transaction_Fee__c = wrapRecord.FeeBreakdown.TransactionFee;
                    paymentRecord.Suspension_Fee__c = wrapRecord.FeeBreakdown.SuspensionFee;
                    paymentRecord.Subscription_Fee__c = wrapRecord.FeeBreakdown.SubscriptionFee;
                    paymentRecord.Setup_Fee__c = wrapRecord.FeeBreakdown.SetupFee;
                    paymentRecord.Pt_No_Show_Fee__c = wrapRecord.FeeBreakdown.PtNoShowFee;
                    paymentRecord.IsRefund__c = wrapRecord.Refund.IsRefund;
                    paymentRecord.Refunded_Payment_Id__c = wrapRecord.Refund.RefundedPaymentId;
                    paymentListRecords.add(paymentRecord);
                }
            }
        } else {
            Error_Log__c errRecord = new Error_Log__c();
            errRecord.Error_Message__c = 'Response is null or Callout failed';
            errRecord.Source_Class__c = 'fetchPaymentData';
            insert errRecord;
        }
        return paymentListRecords;
    }
}