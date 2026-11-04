/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Service Class
@History: [1] Created - 3-Nov-2026
*/
public with sharing class AvailabilityV1Service extends AvailabilityServiceBase {

    public override Object getAvailability(String uprn) {

        AvailabilityV1Response response = new AvailabilityV1Response();

        Account acc = getAccount(uprn);

        if(acc != null) {

            response.UPRNExists = true;
            response.ReadyForSale = acc.Ready_For_Sale__c;
        }

        return response;
    }
}