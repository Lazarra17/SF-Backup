/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 13-Sept-25
@History: 
[1] CLAZARRA - 13-Sept-25 - Created
*/
global class MetaMockHttpResponseGenerator implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest req) {
        
        String body = '{}';
        
        // Replace with your desired mock response
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200); // Replace with your desired status code
        res.setBody(body); // Replace with your mock response body
        return res;
    } 

}