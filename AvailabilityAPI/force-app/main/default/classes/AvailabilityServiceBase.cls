/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Abstract Class - Contains Common Logic for Rest Webservice
@History: [1] Created - 3-Nov-2026
*/
public abstract class AvailabilityServiceBase {

    protected Account getAccount(String uprn) {

        if(String.isBlank(uprn)) {
            throw new AvailabilityException(AvailabilityConstants.ERR_MSG_UPRN_PARAMETER_IS_REQUIRED);
        }

        Account acc = AvailabilitySOQLBank.getByUPRN(uprn);

        if(acc == null) {
            throw new ResourceNotFoundException(AvailabilityConstants.ERR_MSG_CLIENT_ERROR_THE_GIVEN_UPRN_COULD_NOT_BE_FOUND);
        }

        return acc;
    }

    public abstract Object getAvailability(String uprn);
}