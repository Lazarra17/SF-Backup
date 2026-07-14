/*
@Author: Chad Lazarra (Bricoleur Technology)
@Date:
@History:
*/
global class GigaCommPOQMockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        
        String body = '{' +
  '"statusCode": null,'+
  '"stateChange": ['+
   ' {'+
   '   "state": "done",'+
   '   "changeDate": "2025-05-21T10:58:39.7470858Z"'+
   ' }'+
  '],'+
 ' "state": "done",'+
  '"relatedContactInformation": null,'+
 ' "productOfferingQualificationItem": ['+
 '   {'+
   '   "stateChange": ['+
    '    {'+
   '       "state": "done",'+
   '       "changeDate": "2025-05-21T10:58:39.7470858Z"'+
   '     }'+
   '   ],'+
    '  "state": "",'+
   '   "serviceabilityConfidence": "Green",'+
    '  "qualificationResult": "qualified",'+
   '   "installationInterval": {'+
    '    "units": "day",'+
   '     "amount": 5'+
    '  },'+
   '   "id": "1",'+
   '   "guaranteedUntilDate": "2025-05-21T10:58:39.7470858Z",'+
   '   "deliveryType": "onNetWithBuild",'+
   '   "alternateProductOfferingProposal": ['+
    '    {'+
    '      "serviceabilityConfidence": "Green",'+
     '     "installationInterval": {'+
    '        "units": "day",'+
    '        "amount": 5'+
     '     },'+ 
     '     "id": "42954e0c-4592-482c-bef9-b2e400b4e83c",'+
          '"guaranteedUntilDate": "2025-05-21T10:58:39.7481655Z",'+
          '"deliveryType": "onNetWithBuild",'+
          '"alternateProduct": {'+
            '"productOffering": {'+
              '"id": "SKU1001160"'+
            '}'+
          '}'+
        '}'+
      ']'+
    '}'+
  '],'+
  '"id": "8582a2ec-9b1a-4954-a2bc-b2e400b4e835",'+
  '"href": "",'+
  '"creationDate": "2025-05-21T10:58:39.7470858Z"'+
'}';
        
        
        // Replace with your desired mock response
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200); // Replace with your desired status code
        res.setBody(body); // Replace with your mock response body
        return res;
    } 
}