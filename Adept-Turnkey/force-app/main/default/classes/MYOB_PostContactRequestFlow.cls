/*
* Author:         	Bricoleur Technologies
* Created Date:    November 22, 2021
* Description:     Apex Class for MYOB Outbound Post Contact callout Invoked from Flow
* Test Class:      N/A
* History:         November 22, 2021 - Creation
					[1] 18-May-26 CLAZARRA - AT-80 - Added ABN to check existing account
*/
public class MYOB_PostContactRequestFlow   
{
    
     private class MYOB_PostContactRequestFlowAsync implements Queueable, Database.AllowsCallouts
    {

        private String paramString;
        
		public void setParamString(String paramString)
        {
            this.paramString = paramString;
        }
        
        public void execute(QueueableContext context)
        {
            
            MYOB_FlowParam_Customer params = (MYOB_FlowParam_Customer)JSON.deserialize(this.paramString, MYOB_FlowParam_Customer.class);
            MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                                 FROM MYOB_API_Setting__mdt
                                                 WHERE DeveloperName = 'Default'];
            String clientID = apiSettings?.Client_ID__c;
            String endpoint = apiSettings?.Endpoint__c;
            String companyFileID = apiSettings?.Company_File_ID__c;
            
            if(apiSettings == NULL || clientID == NULL || endpoint == NULL) return;
            
            Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
            
            
            //Sync contact
            if(params.AccountType != 'Supplier'){
             
                if(String.isBlank(params.UID)){
                    
                    MYOB_RestResponseCollection.Contact myobContact = SearchContactFromMYOBbyABN(requestHeader, endpoint, companyFileID, params);
                    if(myobContact == null){
                         myobContact = SearchContactFromMYOB(requestHeader, endpoint, companyFileID, params);
                    }
                    system.debug('myobContact ' + myobContact);
                    
                    if(myobContact != null && myobContact?.UID != null){
                        Account accountRecord = new Account();
                        accountRecord.Id = params.AccountSFID; 
                        accountRecord.MYOB_GUID__c = myobContact?.UID;
                        accountRecord.External_Accounting_Id__c = myobContact?.UID;
                        
                        accountRecord.MYOB_RowVersion__c = myobContact?.RowVersion;
                        accountRecord.MYOB_Last_Sync_DateTime__c = system.now();
                        //accountRecord.MYOB_Contact_Name__c = params.FirstName + ' ' + params.LastName;
                        //accountRecord.MYOB_Contact__c = params.ContactId;
                        String requestBodyString = '';
                        
                        MYOB_RestRequestCollection.CustomerRequestBody requestBody = SetPutContactBody(params, myobContact?.UID, myobContact?.RowVersion);
                        requestBodyString = JSON.serialize(requestBody, true);
                        system.debug('requestBodyString ' + requestBodyString);
                        
                        try{
                            
                            HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER+ '/' + params.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                            system.debug('postResponse?.getBody:'+postResponse?.getBody());
                            Database.update(accountRecord);                         
                            Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                            
                        }catch(Exception err){
                            
                            Utilities.CreateExceptionLog(err,'MYOB_PostContactRequestFlow - Account Record Update');
                        }
                    }else{
                        
                        String requestBodyString = '';
                        
                        MYOB_RestRequestCollection.CustomerRequestBody requestBody = SetPostContactBody(params);
                        requestBodyString = JSON.serialize(requestBody, true);
                        system.debug('requestBodyString ' + requestBodyString);
                        
                        
                        HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                        String postResponseBodyString = postResponse?.getBody();        
                        Integer postResponseStatusCode = postResponse?.getStatusCode();
                        
                        system.debug('postResponseBodyString: ' + postResponseBodyString);
                        
                        system.debug('postResponseStatusCode: ' + postResponseStatusCode);
                        if(postResponseStatusCode == MYOB_Constants.INTEGRATION_REST_RESPONSE_201){           
                            String myobLocation = postResponse?.getHeader(MYOB_CONSTANTS.INTEGRATION_HEADER_MYOB_LOCATION);
                            system.debug('myobLocation: ' + myobLocation);
                            if(myobLocation != null && myobLocation != ''){
                                String UID = myobLocation?.substringAfterLast('/');
                                if(UID != null && UID != ''){                            
                                    Account accountRecord = new Account();
                                    accountRecord.Id = params.AccountSFID;
                                    accountRecord.MYOB_GUID__c = UID;
                                    accountRecord.External_Accounting_Id__c = UID;
                                    accountRecord.MYOB_Response__c = postResponseBodyString;
                                    accountRecord.MYOB_Last_Sync_DateTime__c = system.now();
                                    //accountRecord.MYOB_Contact_Name__c = params.FirstName + ' ' + params.LastName;
                                    //accountRecord.MYOB_Contact__c = params.ContactId;
                                    update accountRecord;
                                }
                            }
                        }
                        
                        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, requestBodyString, postResponseBodyString, postResponseStatusCode, MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                        
                    }
                }else{
                    
                    String requestBodyString = '';
                    HttpResponse postResponse;
                    MYOB_RestResponseCollection.Contact myobContact = SearchContactFromMYOBByUID(requestHeader, endpoint, companyFileID, params);
                    
                    system.debug('myobContact SearchContactFromMYOBByUID ' + myobContact);
                    if(myobContact?.RowVersion != null){
                        MYOB_RestRequestCollection.CustomerRequestBody requestBody = SetPutContactBody(params,params.UID,myobContact?.RowVersion);
                        requestBodyString = JSON.serialize(requestBody, true);
                        system.debug('requestBodyString:  ' + requestBodyString);
                        postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER+ '/' + params.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                        string response = postResponse?.getBody();
                        Account accountRecord = new Account();
                        accountRecord.Id = params.AccountSFID;
                        accountRecord.MYOB_RowVersion__c = myobContact?.RowVersion;
                        accountRecord.MYOB_Last_Sync_DateTime__c = system.now();
                        accountRecord.MYOB_Response__c = response;
                        //accountRecord.MYOB_Contact_Name__c = params.FirstName + ' ' + params.LastName;
                        //accountRecord.MYOB_Contact__c = params.ContactId;
                        update accountRecord;
                        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                    }
                }
              
            }
            
            //Sync Supplier
            if(params.AccountType?.contains('Supplier')){
                //Run the Job to populate the Supplier Id
                MYOB_PostContactSupplierRequestFlow.MYOB_PostContactSupplierRequestFlowAsync postSupplier = new MYOB_PostContactSupplierRequestFlow.MYOB_PostContactSupplierRequestFlowAsync();
                postSupplier.setParamString(JSON.serialize(params));        
                System.enqueueJob(postSupplier);
            }
            
            
        }
        
        
        
    }

    @InvocableMethod(label = 'Sync Contact To MYOB' description = 'Sends Salesforce Account to MYOB to Sync with MYOB Contact.')
    public static void SendContactToMYOBFromFlow(List<MYOB_FlowParam_Customer> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        
        MYOB_PostContactRequestFlow.MYOB_PostContactRequestFlowAsync postContact = new MYOB_PostContactRequestFlow.MYOB_PostContactRequestFlowAsync();
        postContact.setParamString(JSON.serialize(params[0]));        
        System.enqueueJob(postContact);
        
    }
    
            
    private static MYOB_RestRequestCollection.CustomerRequestBody SetPutContactBody(MYOB_FlowParam_Customer params, String UID, String RowVersion)
    {
        
        MYOB_RestRequestCollection.CustomerRequestBody requestBody = new MYOB_RestRequestCollection.CustomerRequestBody();
         
        requestBody.FirstName = params.FirstName;
        requestBody.LastName = params.LastName;
        requestBody.CompanyName = params.CompanyName;
        requestBody.SellingDetails = params.SellingDetails;
        requestBody.IsIndividual = params.IsIndividual;
        requestBody.DisplayID = params.DisplayID;
        requestBody.Addresses = params.Addresses;
        requestBody.Notes = params.Notes;
        requestBody.UID = UID;
        requestBody.RowVersion = RowVersion;
        
        return requestBody;
    }
     
        
    public static MYOB_RestRequestCollection.CustomerRequestBody SetPostContactBody(MYOB_FlowParam_Customer params)
    {
        
        MYOB_RestRequestCollection.CustomerRequestBody requestBody = new MYOB_RestRequestCollection.CustomerRequestBody();
        //No need for FirstName and LastName since no person account enabled
        //requestBody.FirstName = params.FirstName;
        //requestBody.LastName = params.LastName;
        requestBody.CompanyName = params.CompanyName;
        requestBody.SellingDetails = params.SellingDetails; 
        requestBody.IsIndividual = params.IsIndividual;
        requestBody.DisplayID = params.DisplayID;
        requestBody.Addresses = params.Addresses;

        requestBody.Notes = params.Notes;
        
        return requestBody;
    }
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOBByUID( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '/' + params.UID, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();   
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.Contact myobContactItem = (MYOB_RestResponseCollection.Contact)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.Contact.class);
        
        if(myobContactItem == NULL) return null;
        return myobContactItem;
        
    }    
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOB( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        String customerParam = '';
        
        customerParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_COMPNAME + MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + params.CompanyName +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        
        system.debug('customerParam :: ' + customerParam);
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '?' + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + customerParam, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();  
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.ContactResponseBody myobContact = (MYOB_RestResponseCollection.ContactResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.ContactResponseBody.class);
        MYOB_RestResponseCollection.Contact myobContactItem = new MYOB_RestResponseCollection.Contact();
        
        if(myobContact == NULL) return null;
        else if(myobContact.Items?.size() > 0 ){
            myobContactItem =  myobContact.Items[0];            
        }else{
            myobContactItem = null;
        }
        return myobContactItem;
        
    } 
    
    //[1] 18-May-26 CLAZARRA - AT-80 - Added ABN to check existing account
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOBbyABN( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        String customerParam = '';
        
        customerParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_ABN + MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + params.ABN +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        
        system.debug('customerParam :: ' + customerParam);
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '?' + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + customerParam, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();  
        system.debug('#ABN getResponseBodyString :: ' + getResponseBodyString);
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.ContactResponseBody myobContact = (MYOB_RestResponseCollection.ContactResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.ContactResponseBody.class);
        MYOB_RestResponseCollection.Contact myobContactItem = new MYOB_RestResponseCollection.Contact();
        
        if(myobContact == NULL) return null;
        else if(myobContact.Items?.size() > 0 ){
            myobContactItem =  myobContact.Items[0];            
        }else{
            myobContactItem = null;
        }
        return myobContactItem;
        
    }
}