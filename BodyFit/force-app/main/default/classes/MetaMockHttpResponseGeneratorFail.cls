global class MetaMockHttpResponseGeneratorFail implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest req) {
        
        String body = '{' +
            '""data": []"'+
            '}';
        
        // Replace with your desired mock response
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(400); // Replace with your desired status code
        res.setBody(body); // Replace with your mock response body
        return res;
    } 
}