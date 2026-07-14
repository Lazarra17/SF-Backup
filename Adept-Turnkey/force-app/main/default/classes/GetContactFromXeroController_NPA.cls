/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	July 15, 2021
 * Description: 	Apex Controller Class for getContactFromXero LWC for No Person Account
 * Test Class: 		N/A
 * History:    		July 15, 2021 - Creation
*/
public class GetContactFromXeroController_NPA 
{
	@AuraEnabled
    public static LWCObjects.ResponseToast GetFromXero(String recordId)
    {
        LWCObjects.ResponseToast response = new LWCObjects.ResponseToast();
        
        Map<String , Object> flowParams = new Map<String , Object>{CONSTANTS_BRIC.FLOW_GET_CONTACT_FROM_XERO_VARIABLE_RECORD_ID => recordId};
        Flow.Interview.GetOrPostContactToXero_NoPersonAccount getorPostContactFromXero = new Flow.Interview.GetOrPostContactToXero_NoPersonAccount(flowParams);
        
        try
        {
            getorPostContactFromXero.start();
            Utilities_Bric.SetResponseToast(response , TRUE , CONSTANTS_BRIC.TOAST_XERO_SYNC_SUCCESSFUL);
        }
        catch(Exception err)
        {
            Utilities_Bric.CreateExceptionLog(err);
            Utilities_Bric.SetResponseToast(response , FALSE , CONSTANTS_BRIC.TOAST_XERO_SYNC_UNSUCCESSFUL);
        }
        
        return response;
    }
}