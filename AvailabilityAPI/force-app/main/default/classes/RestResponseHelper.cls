/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Service Class for RestResponse
@History: [1] Created - 3-Nov-2026
*/
public class RestResponseHelper {

    public static void sendResponse(Integer statusCode, Object payload) {
        
        RestContext.response.statusCode = statusCode;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(payload));
    }
}