public class MYOB_MockResponse implements HttpCalloutMock{
    
    private Integer ResponseCode;	
    private String ResponseBody;	
    
    public MYOB_MockResponse(Integer responseCode , String responseBody){
        this.ResponseCode = responseCode;	
        this.ResponseBody = responseBody;	
    }
    
    public HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();	
        if(this.ResponseBody != NULL) response.setBody(this.ResponseBody);	
        if(this.ResponseCode != NULL) response.setStatusCode(this.ResponseCode);
        
        if(request.getEndpoint().contains(MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER) && request.getMethod() == 'POST'){
            response.setStatusCode(MYOB_CONSTANTS.INTEGRATION_REST_RESPONSE_201);
            response.setHeader(MYOB_CONSTANTS.INTEGRATION_HEADER_MYOB_LOCATION, '/ContactUID');
        }
        return response;	
    }	
}