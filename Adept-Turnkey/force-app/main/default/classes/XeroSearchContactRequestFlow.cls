/*
 * Author:          Alfonso Maquilan
 * Created Date:    June 02, 2021
 * Description:     Apex Class for Xero Outbound Get Contact callout Invoked from Flow
 * Test Class:      N/A
 * History:         Jun. 02, 2021 - Creation
 * 			        Aug. 11, 2021 - Updated GenerateEndpointParameter method to encode everything after the WHERE parameter
*/
public class XeroSearchContactRequestFlow 
{
    @InvocableMethod(label = 'Get From Xero' description = 'Get corresponding Xero Contact')
    public static void SearchContactInXero(List<XeroReqGetFlowParamsContact> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        GetContact(params[0].AccountRecord , params[0].Parameter , params[0].ParameterValue);
    }
    
    private static void GetContact(Account acctRecord , String parameter , String parameterValue)
    {
        if(!Utilities_Bric.CheckStringIfNullOrBlank(parameterValue)) return;
        
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        if(tenantId == NULL) return;
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        String calloutEndpoint = endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_CONTACTS + GenerateEndpointParameter(parameter , parameterValue);

        HttpResponse response = RestHandler.ExecuteRequest(requestHeader , calloutEndpoint , NULL, CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET); 
        String responseBodyString = response?.getBody();

        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return;
        
        RestResponseCollectionXero.GetContactResponseBody responseBody = (RestResponseCollectionXero.GetContactResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.GetContactResponseBody.class);

        if(responseBody == NULL || responseBody.Contacts.isEmpty()) return;
        PostXeroRequest.UpdateAccountFromXero(acctRecord.Id , responseBody?.Contacts[0]); 
    }
    
    private static String GenerateEndpointParameter(String parameter , String parameterValue)
    {
        String encodedParameter = parameter + CONSTANTS_BRIC.GENERIC_EQUALS + '"' + parameterValue + '"';
        encodedParameter = EncodingUtil.urlEncode(encodedParameter, 'UTF-8');
        return CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_PARAMETER_WHERE + CONSTANTS_BRIC.GENERIC_EQUALS + encodedParameter;
    }
}