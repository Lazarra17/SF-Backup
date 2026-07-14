/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 13-Sept-25
@History: 
[1] CLAZARRA - 13-Nov-25 - Created
*/
global class ClubfitTokenFailMockResponseGenerator implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest req) {
        
        String body = null;
        
        // Replace with your desired mock response
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200); // Replace with your desired status code
        res.setBody(body); // Replace with your mock response body
        return res;
    } 
}