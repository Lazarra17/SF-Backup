/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May 10, 2021
 * Description: 	Apex Class to generate REST API Mock Responses
 * Test Class: 		N/A
 * History:    		May 10, 2021 - Creation
*/
public class MockResponse implements HttpCalloutMock
{
	private Integer ResponseCode;
    private String ResponseBody;
    
    public MockResponse(Integer responseCode , String responseBody)
    {
        this.ResponseCode = responseCode;
        this.responseBody = responseBody;
    }
    
    public HttpResponse respond(HttpRequest request)
    {
        HttpResponse response = new HttpResponse();
        if(this.ResponseBody != NULL) response.setBody(this.ResponseBody);
        if(this.ResponseCode != NULL) response.setStatusCode(this.ResponseCode);
        
        return response;
    }
}