/*
* Author: 			Alfonso Maquilan
* Created Date: 	May 06, 2021
* Description: 		Apex Handler Class for XeroAPI class
* Test Class: 		XeroAPITest
* History: 			May 06, 2021 - Creation
*					May 20, 2021 - Xero Webhook body String is inserted as a record.
*/
public class XeroAPIHandler 
{
	public static Boolean Authentication(String webhookKey)
    {
        Boolean requestIsValid;
        String xeroSignature = RestContext.request.headers.get(CONSTANTS_BRIC.INTEGRATION_XERO_HEADER_KEY_XERO_SIGNATURE);
        String xeroPayloadString = RestContext.request?.requestBody?.toString();
        
        if(!ValidateCryptoInputs(new List<String>{webhookKey , xeroSignature , xeroPayloadString}))
        {
            requestIsValid = FALSE;
            return requestIsValid;
        }
        
        Blob signedPayload = Crypto.generateMac(CONSTANTS_BRIC.CRYPTO_HASHING_ALGORITHM_HMAC256, Blob.valueOf(xeroPayloadString), Blob.valueOf(webhookKey));
        
        if(signedPayload == NULL)
        {
            requestIsValid = FALSE;
            return requestIsValid;
        }
       
        String encodedPayload = EncodingUtil.base64Encode(signedPayload);
        requestIsValid = encodedPayload == xeroSignature ? TRUE : FALSE;
        
        return requestIsValid;
    }
    
    private static Boolean ValidateCryptoInputs(List<String> cryptoInputList)
    {
        for(String cryptoInput : cryptoInputList)
        {
            if(cryptoInput == NULL || String.isBlank(cryptoInput)) return FALSE;
        }
        
        return TRUE;
    }
    
    public static Boolean ProcessPostRequest(String requestBodyString)
    {
        Boolean isSuccess;
        
        XeroAPIRequestCollection.PostRequestContact requestBody;
        if(Utilities_Bric.CheckStringIfNullOrBlank(requestBodyString)) requestBody = (XeroAPIRequestCollection.PostRequestContact)JSON.deserialize(requestBodyString, XeroAPIRequestCollection.PostRequestContact.class);
        
        if(requestBody == NULL)
        {
            isSuccess = FALSE;
            return isSuccess;
        }
        
        List<XeroWebhookStorage__c> webhookStorageToInsertList = new List<XeroWebhookStorage__c>();

        for(XeroAPIRequestCollection.Event event : requestBody.Events)  
        {
            XeroWebhookStorage__c webhookStorageRecord = new XeroWebhookStorage__c();
            webhookStorageRecord.XeroId__c = event.resourceId;
            webhookStorageRecord.Event__c = event.eventType;
            webhookStorageRecord.XeroObject__c = event.eventCategory;
            
            webhookStorageToInsertList.add(webhookStorageRecord);
        }
        
        try
        {
            Database.insert(webhookStorageToInsertList , FALSE);
            isSuccess = TRUE;
        }
        catch(Exception err)
        {
            Utilities_Bric.CreateExceptionLog(err);
            isSuccess = FALSE;
        }
        
        return isSuccess;
    }
}