/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May 6, 2021
 * Description: 	Apex Controller Class for syncWithXeroLwc LWC
 * Test Class: 		XeroRequestTest
 * History:    		May 06, 2021 - Creation
 * 					May 24, 2021 - Changed Sync to Xero trigger, SendToXero method now calls the Sync_to_Xero flow.
*/
public class SyncWithXeroController 
{
	@AuraEnabled
    public static LWCObjects.ResponseToast SendToXero(String recordId , String sObjectName)
    {
        LWCObjects.ResponseToast response = new LWCObjects.ResponseToast();
        
        Map<String , Object> flowParams = new Map<String , Object>{CONSTANTS.FLOW_SYNC_TO_XERO_VARIABLE_RECORD_ID => recordId , CONSTANTS.FLOW_SYNC_TO_XERO_VARIABLE_SOBJECT => sObjectName};
        Flow.Interview.SyncToXero_NoPersonAccount syncToXeroFlow = new Flow.Interview.SyncToXero_NoPersonAccount(flowParams);
        
        try
        {
            syncToXeroFlow.start();
            Utilities_Bric.SetResponseToast(response , TRUE , CONSTANTS.TOAST_XERO_SYNC_SUCCESSFUL);
        }
        catch(Exception err)
        {
            Utilities_Bric.CreateExceptionLog(err);
            Utilities_Bric.SetResponseToast(response , FALSE , CONSTANTS.TOAST_XERO_SYNC_UNSUCCESSFUL);
        }
        
        return response;
    }
}