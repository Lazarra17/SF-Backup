/*
* Author:         	Bricoleur Technologies
* Created Date:    August 8, 2023
* Description:     Apex Class for MYOB Outbound Post Sales Order callout Invoked from Flow
* Test Class:      N/A
* History:         August 8, 2023 - Creation
				   [1] 18-May-26 CLAZARRA - AT-80 - Added ABN to check existing account
*/
public class MYOB_PostOrderRequestFlow {
    
     private class MYOB_PostOrderRequestFlowAsync implements Queueable, Database.AllowsCallouts
    {

        private String paramString;
        
		public void setParamString(String paramString)
        {
            this.paramString = paramString;
        }
        
        public void execute(QueueableContext context)
        {
            MYOB_FlowParam_SalesOrder params = (MYOB_FlowParam_SalesOrder)JSON.deserialize(this.paramString, MYOB_FlowParam_SalesOrder.class);
            MYOB_FlowParam_Customer customerParams = params.Customer;
            MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                                 FROM MYOB_API_Setting__mdt
                                                 WHERE DeveloperName = 'Default'];
            String clientID = apiSettings?.Client_ID__c;
            String endpoint = apiSettings?.Endpoint__c;
            String companyFileID = apiSettings?.Company_File_ID__c;
            String salesOrderRequestBodyString = '';
            Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            
            Account accountRecord = [SELECT Id, MYOB_Supplier_Id__c, nao__Account_Price_Book__c, nao__Supplier_Pricebook__c,
                                     MYOB_Last_Sync_DateTime__c, MYOB_RowVersion__c FROM Account WHERE Id =: customerParams.AccountSFID];
             
            //add the supplier price book
            if(accountRecord.nao__Supplier_Pricebook__c == null) accountRecord.nao__Supplier_Pricebook__c = standardPB.Id;
            if(accountRecord.nao__Account_Price_Book__c == null) accountRecord.nao__Account_Price_Book__c = standardPB.Id;
            
            Order odrToUpdate = new Order();
            odrToUpdate.Id = params.SFID;
            odrToUpdate.MYOB_Last_Sync_DateTime__c = system.now();
            
            if(apiSettings == NULL || clientID == NULL || endpoint == NULL) return;
            
            Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
            
            //check if an Order has been synced already, if not, create MYOB Sales Order
            if(String.isBlank(params.UID )){
                if(String.isBlank(customerParams.UID)){
                    
                    //[1] 18-May-26 CLAZARRA - AT-80 - Added ABN to check existing account
                    MYOB_RestResponseCollection.Contact myobContact = MYOB_PostContactRequestFlow.SearchContactFromMYOBbyABN(requestHeader, endpoint, companyFileID, customerParams);
                    if(myobContact == null){
                       myobContact = SearchContactFromMYOB(requestHeader, endpoint, companyFileID, customerParams);
                    }
                    
                    system.debug('is MYOB Contact Found? ' + myobContact);
                    if(myobContact != null && myobContact?.UID != null){
                     
                        accountRecord.MYOB_GUID__c = myobContact?.UID;
                        accountRecord.External_Accounting_Id__c = myobContact?.UID;
                        accountRecord.MYOB_Last_Sync_DateTime__c = system.now();
                        accountRecord.MYOB_RowVersion__c = myobContact?.RowVersion;
                        
                        
                        /*
                        String requestBodyString = '';                    
                        MYOB_RestRequestCollection.CustomerRequestBody requestBody = SetPostContactBody(customerParams, myobContact?.UID, myobContact?.RowVersion);
                        requestBodyString = JSON.serialize(requestBody, true);
                        system.debug('requestBodyString ' + requestBodyString);
                        */
                        
                        params.Customer.UID = myobContact?.UID;
                        
                       
                        MYOB_RestRequestCollection.SalesOrderRequestBody salesOrderRequestBody = SetPostSalesOrderBody(params);
                        salesOrderRequestBodyString = JSON.serialize(salesOrderRequestBody, true);
                        
                        system.debug('SALES ORDER:  ' + salesOrderRequestBodyString);
                        Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                            MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                            MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                                salesOrderRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(salesOrderRequestBodyString , requestBodyReplacementList);
                        
                        
                        HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM, 
                                                                                    salesOrderRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                        system.debug('postOrderResponse:  ' + postOrderResponse);
                        try{
                            odrToUpdate.MYOB_Response__c = postOrderResponse?.getBody();
                            Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, salesOrderRequestBodyString, postOrderResponse?.getBody(), postOrderResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM);
                            
                            
                            String locationUri = postOrderResponse?.getHeader('location');
                            System.debug('locationUri: ' + locationUri);
                            if(locationUri != null){
                                String salesOrderId = locationUri.substringAfter('/Item/');
                                
                                odrToUpdate.Accounting_External_Id__c = salesOrderId;
                                odrToUpdate.MYOB_Status__c = 'Open';
                                odrToUpdate.MYOB_Number__c = params.CustomerPurchaseOrderNumber;
                                odrToUpdate.MYOB_Response__c = postOrderResponse?.getBody();
                            }
                            
                        }catch(Exception err){
                            
                            Utilities.CreateExceptionLog(err,'MYOB_PostOrderRequestFlow - Account Record Update');
                        }
                        
                        
                    }
                    else{
                        
                        String requestBodyString = '';
                        
                        MYOB_RestRequestCollection.CustomerRequestBody requestBody = SetPostContactBody(customerParams, null, null);
                        
                        
                        requestBodyString = JSON.serialize(requestBody, true);
                        system.debug('requestBodyString ' + requestBodyString);
                      
                        HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER, 
                                                                               requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                        
                        
                        String postResponseBodyString = postResponse?.getBody();        
                        Integer postResponseStatusCode = postResponse?.getStatusCode();
                        system.debug('##postResponse: ' + postResponse);
                        system.debug('##PASSED: ' + postResponseBodyString);
                        
                        if(postResponseStatusCode == MYOB_Constants.INTEGRATION_REST_RESPONSE_201){           
                            String myobLocation = postResponse?.getHeader(MYOB_CONSTANTS.INTEGRATION_HEADER_MYOB_LOCATION);
                            system.debug('##PASSED myobLocation: ' + myobLocation);
                            if(myobLocation != null && myobLocation != ''){
                                String UID = myobLocation?.substringAfterLast('/');
                                if(UID != null && UID != ''){             
                                    
                                    params.Customer.UID = UID;
                                    MYOB_RestRequestCollection.SalesOrderRequestBody salesOrderRequestBody = SetPostSalesOrderBody(params);
                                    salesOrderRequestBodyString = JSON.serialize(salesOrderRequestBody, true);
                                     
                                    system.debug('SALES ORDER REQUEST: ' + salesOrderRequestBodyString);
                                    
                                    Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                                        MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                                        MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                                            salesOrderRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(salesOrderRequestBodyString , requestBodyReplacementList);
                                    HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM, salesOrderRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                                    Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, salesOrderRequestBodyString, postOrderResponse?.getBody(), postOrderResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM);
                                    
                                    odrToUpdate.MYOB_Response__c = postOrderResponse?.getBody();
                                    accountRecord.MYOB_GUID__c = UID;
                                    accountRecord.External_Accounting_Id__c = UID;
                                    accountRecord.MYOB_Last_Sync_DateTime__c = system.now();
                                    odrToUpdate.MYOB_Number__c = params.CustomerPurchaseOrderNumber;

                                    
                                    //Save the Sales Order UID
                                    String locationUri = postOrderResponse.getHeader('location');
                                    System.debug('locationUri: ' + locationUri);
                                    if(locationUri != null){
                                        
                                        String salesOrderId = locationUri.substringAfter('/Item/');                        
                                        odrToUpdate.Accounting_External_Id__c = salesOrderId;
                                        
                                    }
                                    
                                }
                            }
                        }else{
                            //It failed on Customer API
                            odrToUpdate.MYOB_Response__c = postResponseBodyString;
                        }
                        
                        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, requestBodyString, postResponseBodyString, postResponseStatusCode, MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                        
                    }
                }
                else{  //MYOB Customer UID Exist in CRM
                    
                    HttpResponse postResponse;
              
                    MYOB_RestRequestCollection.SalesOrderRequestBody salesOrderRequestBody = SetPostSalesOrderBody(params);
                    salesOrderRequestBodyString = JSON.serialize(salesOrderRequestBody, true);
                    
                    system.debug('salesOrderRequestBodyString: ' + salesOrderRequestBodyString);
                    Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                            salesOrderRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(salesOrderRequestBodyString , requestBodyReplacementList);
                    HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM, salesOrderRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                    system.debug('postOrderResponse: ' + postOrderResponse.getBody());
                    odrToUpdate.MYOB_Response__c = postOrderResponse?.getBody();
                    String locationUri = postOrderResponse.getHeader('location');
                    System.debug('locationUri: ' + locationUri);
                    if(locationUri != null){
                        
                        String salesOrderId = locationUri.substringAfter('/Item/');                        
                        odrToUpdate.Accounting_External_Id__c = salesOrderId;
                        odrToUpdate.MYOB_Status__c = 'Open';
                        odrToUpdate.MYOB_Number__c = params.CustomerPurchaseOrderNumber;

                    }
                    
                }
            }
            else{
                
                
                //Retrieve SalesOrder to get RowVersion
                HttpResponse getOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM + '/' + params.UID, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET); 
                system.debug('ROW VERSION ENDPOINT: ' + endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM + '/' + params.UID);
                system.debug('ROW VERSION getOrderResponse: ' + getOrderResponse);
                String getResponseBodyString = getOrderResponse?.getBody();   
                MYOB_RestResponseCollection.SalesOrder myobSalesOrder = (MYOB_RestResponseCollection.SalesOrder)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.SalesOrder.class);
                system.debug('ROW VERSION EXIST, GOOD TO UPDATE: ' + myobSalesOrder.RowVersion);
                
                //Add the UID property and Row Version - PUT Method
                MYOB_RestRequestCollection.SalesOrderRequestBody salesOrderRequestBody = SetPostSalesOrderBody(params);
                salesOrderRequestBodyString = JSON.serialize(salesOrderRequestBody, true);
                Map<String, Object> dynamicBody = (Map<String, Object>)JSON.deserializeUntyped(salesOrderRequestBodyString);
                // 2. Add your new properties
                dynamicBody.put('UID', params.UID);
                dynamicBody.put('RowVersion', myobSalesOrder.RowVersion);
                
                
                salesOrderRequestBodyString = JSON.serialize(dynamicBody, true);
                
                
                Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                        salesOrderRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(salesOrderRequestBodyString , requestBodyReplacementList);
                system.debug('endpoint : ' + endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM + '/' + params.UID);
                system.debug('salesOrderRequestBodyString : ' + salesOrderRequestBodyString);
                HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM + '/' + params.UID, salesOrderRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
               
                system.debug('postOrderResponse?.getBody() : ' + postOrderResponse?.getBody());
                //Update Order - Row version
                odrToUpdate.Id = params.SFID;
                odrToUpdate.MYOB_Row_Version__c = myobSalesOrder.RowVersion;
                odrToUpdate.MYOB_Response__c = postOrderResponse?.getBody();
                
                
            }
            
            update odrToUpdate;
            Database.update(accountRecord);
        }
    }

    @InvocableMethod(label = 'Sync Order To MYOB' description = 'Sends Salesforce Order to MYOB to Sync with MYOB Sales Order.')
    public static void SendOrderToMYOBFromFlow(List<MYOB_FlowParam_SalesOrder> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        
        MYOB_PostOrderRequestFlow.MYOB_PostOrderRequestFlowAsync postSalesOrder = new MYOB_PostOrderRequestFlow.MYOB_PostOrderRequestFlowAsync();
        postSalesOrder.setParamString(JSON.serialize(params[0]));        
        System.enqueueJob(postSalesOrder);
        
    }
    
         /*   
    private static MYOB_RestRequestCollection.CustomerRequestBodyUpdate SetPutContactBody(MYOB_FlowParam_Customer params, String UID, String RowVersion)
    {
        
        MYOB_RestRequestCollection.CustomerRequestBodyUpdate requestBody = new MYOB_RestRequestCollection.CustomerRequestBodyUpdate();
        
        //requestBody.FirstName = params.FirstName;
        //requestBody.LastName = params.LastName;
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
    */
        
    private static MYOB_RestRequestCollection.CustomerRequestBody SetPostContactBody(MYOB_FlowParam_Customer params, String UID, String RowVersion)
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
        
        return requestBody;
    }
    
    private static MYOB_RestRequestCollection.SalesOrderRequestBody SetPostSalesOrderBody(MYOB_FlowParam_SalesOrder params)
    {
        
        MYOB_RestRequestCollection.SalesOrderRequestBody requestBody = new MYOB_RestRequestCollection.SalesOrderRequestBody();
        requestBody.Number_x = params.CustomerPurchaseOrderNumber;
        requestBody.Date_x = params.Date_x;
        requestBody.CustomerPurchaseOrderNumber = params.CustomerPurchaseOrderNumber;
        requestBody.Customer = params.Customer;
        requestBody.Lines = params.Lines;
        requestBody.IsTaxInclusive = params.IsTaxInclusive;     
        requestBody.ForeignCurrency = params.ForeignCurrency;
        return requestBody;
    }
    

    
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOBByUID( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '/' + params.UID, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();   
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        MYOB_RestResponseCollection.Contact myobContactItem = (MYOB_RestResponseCollection.Contact)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.Contact.class);
        
        return myobContactItem;
        
        
        
    }    
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOB( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        String customerParam = '';
        
        customerParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_COMPNAME + MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + params.CompanyName +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '?' + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + customerParam, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();   
         
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.ContactResponseBody myobContact = (MYOB_RestResponseCollection.ContactResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.ContactResponseBody.class);
        MYOB_RestResponseCollection.Contact myobContactItem = new MYOB_RestResponseCollection.Contact();
        system.debug('myobContact :: ' + myobContact);
        if(myobContact == NULL) return null;
        else if(myobContact.Items?.size() > 0 ){
            myobContactItem =  myobContact.Items[0];            
        }else{
            myobContactItem = null;
        }
        return myobContactItem; 
    }    
}