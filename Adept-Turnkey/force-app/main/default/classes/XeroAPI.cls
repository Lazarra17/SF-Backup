/*
* Author:           Alfonso Maquilan
* Created Date:     May 06, 2021
* Description:      Apex API Class to handle callouts from Xero webhook
* Test Class:       N/A
* History:          May 06, 2021 - Creation
*/
@RestResource(urlMapping = '/SalesforceXero')
global class XeroAPI 
{
    @HttpPost
    global static void DoPost()
    {
        RestResponse response = RestContext.response;
        String webhookKey = SalesforceForXeroAPISettings__c.getInstance(CONSTANTS_BRIC.INTEGRATION_XERO_WEBHOOK_SETTINGS)?.WebhookKey__c;

       if(!test.isRunningTest() && !XeroAPIHandler.Authentication(webhookKey))
        {
            Utilities_Bric.SetRestResponse(response , CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_401, null);
            return;
        }

        String requestBodyString = RestContext.request?.requestBody?.toString();
        
        if(requestBodyString == NULL || String.IsBlank(requestBodyString))
        {
            Utilities_Bric.SetRestResponse(response , CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_400, null);
            return;
        }
        
        XeroAPIHandler.ProcessPostRequest(requestBodyString);
        Utilities_Bric.SetRestResponse(response , CONSTANTS_BRIC.INTEGRATION_REST_RESPONSE_200, null);
    }
}