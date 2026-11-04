/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Constant Variables
@History: [1] Created - 3-Nov-2026
*/
public class AvailabilityConstants {
    
     //Exception Log Constants
    public static final Integer EXCEPTION_LOG_STACK_TRACE_FIELD_LIMIT = 255;
    public static final Integer EXCEPTION_LOG_EXCEPTION_LOG_FIELD_LIMIT = 131072;
    
    public static final String UPRN = 'UPRN';
    public static final String AVAILABILITY_API = 'AVAILABILITY API';
    
    
   	//Integration Constants
    public static final String INTEGRATION_REST_METHOD_GET = 'GET';
    public static final Integer INTEGRATION_REST_RESPONSE_200 = 200;
    public static final Integer INTEGRATION_REST_RESPONSE_400 = 400;
    public static final Integer INTEGRATION_REST_RESPONSE_403 = 403;
    public static final Integer INTEGRATION_REST_RESPONSE_404 = 404;
    public static final Integer INTEGRATION_REST_RESPONSE_501 = 501;
    public static final Integer INTEGRATION_REST_RESPONSE_503 = 403;
    public static final Integer INTEGRATION_REST_RESPONSE_500 = 500;
    
    public static final String ERR_MSG_UPRN_PARAMETER_IS_REQUIRED  = 'UPRN parameter is required';
    public static final String ERR_MSG_CLIENT_ERROR_THE_GIVEN_UPRN_COULD_NOT_BE_FOUND = 'Client error, the given UPRN could not be found';
	public static final String ERR_MSG_CLIENT_ERROR_REVIEW_THE_MESSAGE_TO_DETERMINE_THE_ERROR = 'Client error, review the message to determine the error. This is most likely to be a poorly formatted request';
   	public static final String ERR_MSG_FORBIDDEN = 'Forbidden';
    public static final String ERR_MSG_AUTHENTICATION_ERROR = 'Authentication Error. Check that you are using a valid authorised token and that the token hasn’t expired';
    public static final String ERR_MSG_SERVER_ERROR = 'Server error, indicates the server is busy, overloaded, or down for maintenance. The request will have to be retried at a later time';
   
        
    
}