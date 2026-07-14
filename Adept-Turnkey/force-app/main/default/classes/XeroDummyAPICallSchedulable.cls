/*
* Author:          Bricoleur Technologies - Kristine Arcangel
* Created Date:    June 9, 2022
* Description:     Schedulable API call to Xero to ensure refresh tokens don't expire
* Test Class:      N/A
* History:         June 9, 2022 - Creation
*/
public class XeroDummyAPICallSchedulable implements Schedulable {
    
    public void execute(SchedulableContext ctx){
        GetTenantId();
    }
    
    @future(callout=true)
    public static void GetTenantId()
    {
        HttpResponse response = RestHandler.ExecuteRequest(null, CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_CONNECTION, null, CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET);
        
    }
    
    
}