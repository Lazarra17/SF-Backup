/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date: 13-Sept-25
@History: 
[1] CLAZARRA - 13-Nov-25 - Created
*/
global class ClubfitTokenMockResponseGenerator implements HttpCalloutMock{

  
    global HTTPResponse respond(HTTPRequest req) {
        
        String body = '{"AccessToken" : "tokenTest", '+
            '"data": [{ ' +
            '"Number": "10175", ' +
            '"FirstName": "Micheal", ' +
            '"LastName": null, ' +
            '"Status": "NotInterested", ' +
            '"Barcode": null, ' +
            '"DateOfBirth": null, ' +
            '"Gender": "M", ' +
            '"TrialStartDate": null, ' +
            '"TrialEndDate": null, ' +
            '"CreatedDateUtc": "2023-03-16T06:34:41.69", ' +
            '"SalesPerson": { ' +
            '    "Email": "philippa@bodyfit.com.au" ' +
            '}, ' +
            '"Contact": {  ' +
            '    "Email": null, ' +
            '    "Mobile": "0412143278" ' +
            '}' +
        '}  ' +
    ']   ' +
            ' }';
        
        // Replace with your desired mock response
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200); // Replace with your desired status code
        res.setBody(body); // Replace with your mock response body
        return res;
    } 

}