global class MefOrderStatusFailResponseGenerator implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
        
        String body = '{' +
            ' "id": "OD-7070", ' +
            ' "href": "", ' +
            ' "orderDate": "2025-09-04T03:37:29.569674Z", ' +
            ' "completionDate": "2025-09-05T23:59:59+00:00", ' +
            ' "expectedCompletionDate": "2025-09-05T08:00:00+00:00", ' +
            ' "state": "completed", ' +
            ' "note": [ { ' +
            '   "author": "Author", ' +
            '   "date": "2025-07-02T08:00:00.000Z", ' +
            '   "id": "00kOa00000B7R5FIAV", ' +
            '   "source": "seller", ' +
            '  "text": "text" ' +
            ' }], ' +
            ' "productOrderItem": [ ' +
            '    { ' +     
            '        "product": { ' +
            '            "id": "00kOa00000B7R5FIAV" ' +
            '        } ' +
            '    } ' +
            '] ' +
            '}';
        
        
        // Replace with your desired mock response
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(400); // Replace with your desired status code
        res.setBody(body); // Replace with your mock response body
        return res;
    } 
    
}