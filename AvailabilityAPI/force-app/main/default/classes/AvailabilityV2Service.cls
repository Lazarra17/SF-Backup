/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Contains Logic for the availability API v2
@History: [1] Created - 3-Nov-2026
*/
public with sharing class AvailabilityV2Service extends AvailabilityServiceBase {
    
    public override Object getAvailability(String uprn) {
        
        AvailabilityV2Response response = new AvailabilityV2Response();
        
        Account acc = getAccount(uprn);
        
        if(acc != null) {
            
            response.UPRNExists = true;
            response.ReadyForSale = acc.Ready_For_Sale__c;
            response.ClientJourney = Integer.valueOf(acc.Client_Journey__c);
            response.AvailableForPreOrder = acc.Available_For_Pre_Order__c;
        }
        
        return response;
    }
}