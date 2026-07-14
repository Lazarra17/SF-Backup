public class paymentMockHttpResponseGenerator implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        // Create a mock HttpResponse with a sample JSON response
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        // Example mock response data matching the structure expected by paymentResponseWrapper
        String jsonResponse = '{' +
            '"href": "https://api.example.com/payments",' +
            '"next": "https://api.example.com/payments?page=2",' +
            '"data": [' +
                '{' +
                    '"Id": "P123",' +
                    '"Numbers": "1234567890",' +
                    '"Amount": 150.00,' +
                    '"PaymentDate": "2024-01-01T10:00:00Z",' +
                    '"PaymentType": "Credit Card",' +
                    '"Response": "Success",' +
                    '"PaymentDescription": "Membership Fee",' +
                    '"PaymentForReference": {' +
                        '"Id": "M001",' +
                        '"Name": "Membership 001"' +
                    '},' +
                    '"FeeBreakdown": {' +
                        '"AccessCardFee": 10.00,' +
                        '"AddOnAmount": 5.00,' +
                        '"Adjustment": 0.00,' +
                        '"ArrearsFee": 0.00,' +
                        '"CancellationLateFee": 0.00,' +
                        '"CardSurchargeFee": 2.50,' +
                        '"ClassNoShowFee": 0.00,' +
                        '"CrecheClassNoShowFee": 0.00,' +
                        '"DishonourFee": 0.00,' +
                        '"JoiningFee": 20.00,' +
                        '"MaintenanceFee": 10.00,' +
                        '"PosTransaction": 0.00,' +
                        '"Prorata": 0.00,' +
                        '"PtNoShowFee": 0.00,' +
                        '"SetupFee": 15.00,' +
                        '"SubscriptionFee": 100.00,' +
                        '"SuspensionFee": 0.00,' +
                        '"TransactionFee": 5.00' +
                    '},' +
                    '"Refund": {' +
                        '"IsRefund": false,' +
                        '"RefundedPaymentId": null' +
                    '}' +
                '}' +
            ']' +
        '}';

        res.setBody(jsonResponse);
        return res;
    }
}