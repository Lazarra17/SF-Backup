@isTest
public class ServiceNowApiMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint().contains('/oauth_token.do')){
            res.setBody('{"access_token": "67893873894823323982983983239829"}');
        }else{
            res.setBody('{"result": {"number": "INC12345","task_effective_number":"INC12345", "sys_id": "1234567890"}}');
        }
        res.setStatusCode(200);
        return res;    
    }
}