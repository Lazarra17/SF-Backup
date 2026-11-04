/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Contains the Logic for Rest API
@History: [1] Created - 3-Nov-2026
*/
@RestResource(urlMapping='/availability/v2/*')
global with sharing class AvailabilityV2Rest {

    @HttpGet
    global static void getAvailability() {

        try {

            String uprn = RestContext.request.params.get(AvailabilityConstants.UPRN);

            AvailabilityV2Service service = new AvailabilityV2Service();

            RestResponseHelper.sendResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_200, service.getAvailability(uprn));

        } //codes below are exception to change the status message
        catch(ResourceNotFoundException ex) {
            
            Utility.CreateExceptionLog(ex, AvailabilityConstants.AVAILABILITY_API);
            RestResponseHelper.sendResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_404, new ErrorResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_404, AvailabilityConstants.ERR_MSG_CLIENT_ERROR_THE_GIVEN_UPRN_COULD_NOT_BE_FOUND));                              
        }
        /*
        catch(BadRequestException  ex) {
            
            Utility.CreateExceptionLog(ex, AvailabilityConstants.AVAILABILITY_API);
            RestResponseHelper.sendResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_400, new ErrorResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_400, AvailabilityConstants.ERR_MSG_CLIENT_ERROR_REVIEW_THE_MESSAGE_TO_DETERMINE_THE_ERROR));
        }
        catch(ForbiddenException ex) {
            
            Utility.CreateExceptionLog(ex, AvailabilityConstants.AVAILABILITY_API);
            RestResponseHelper.sendResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_403, new ErrorResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_403, AvailabilityConstants.ERR_MSG_FORBIDDEN));
        }
        catch(AuthenticationException ex) {
            
            Utility.CreateExceptionLog(ex, AvailabilityConstants.AVAILABILITY_API);
            RestResponseHelper.sendResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_501, new ErrorResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_501, AvailabilityConstants.ERR_MSG_AUTHENTICATION_ERROR));
        }
        catch(ServiceUnavailableException ex) {
            
            Utility.CreateExceptionLog(ex, AvailabilityConstants.AVAILABILITY_API);
            RestResponseHelper.sendResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_503, new ErrorResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_503, AvailabilityConstants.ERR_MSG_SERVER_ERROR));
        }*/
        catch(Exception ex) {
            Utility.CreateExceptionLog(ex, AvailabilityConstants.AVAILABILITY_API);
            RestResponseHelper.sendResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_500, new ErrorResponse(AvailabilityConstants.INTEGRATION_REST_RESPONSE_500, ex.getMessage()));
        }
        
    }
}