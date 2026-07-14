/*
* Author:         	Bricoleur Technologies
* Created Date:    August 8, 2023
* Description:     Apex Class for MYOB Outbound Post Sales Order callout Invoked from Flow
* Test Class:      N/A
* History:         August 8, 2023 - Creation
*/
public class MYOB_PostInvoiceRequestFlow {
    
     private class MYOB_PostInvoiceRequestFlowAsync implements Queueable, Database.AllowsCallouts
    {

        private String paramString;
        
		public void setParamString(String paramString)
        {
            this.paramString = paramString;
        }
        
        public void execute(QueueableContext context)
        {
            MYOB_FlowParam_Invoice params = (MYOB_FlowParam_Invoice)JSON.deserialize(this.paramString, MYOB_FlowParam_Invoice.class);
            MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                                 FROM MYOB_API_Setting__mdt
                                                 WHERE DeveloperName = 'Default'];
            String clientID = apiSettings?.Client_ID__c;
            String endpoint = apiSettings?.Endpoint__c;
            String companyFileID = apiSettings?.Company_File_ID__c;
            String invoiceRequestBodyString = '';
            
            
            if(apiSettings == NULL || clientID == NULL || endpoint == NULL) return;
            
            Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
            
            nao__Invoice__c invoice = new nao__Invoice__c();
            invoice.Id = params.SFInvoiceId;
            invoice.MYOB_Last_Sync_DateTime__c = system.now();
            
            
            //Get InvoiceLinesMap
            Map<String, nao__Invoice_Lines__c> prodMYOBLinesMap = new Map<String,nao__Invoice_Lines__c>();
            for(nao__Invoice_Lines__c invLine : [SELECT Id, MYOB_Row_Id__c, nao__Product_bric__c, nao__Product_bric__r.MYOB_UID__c FROM nao__Invoice_Lines__c WHERE nao__Invoice_bric__c =: params.SFInvoiceId AND nao__Product_bric__c != null]){
                prodMYOBLinesMap.put(invLine.nao__Product_bric__r.MYOB_UID__c, invLine);
            }
            system.debug('prodMYOBLinesMap: ' + prodMYOBLinesMap);
            
            
            //Set Request Body
            MYOB_RestRequestCollection.InvoiceRequestBody invoiceRequestBody = SetPostInvoiceBody(params);
            if(invoiceRequestBody.UID == ''){
                invoiceRequestBody.UID = null;
            }
            
            
            invoiceRequestBodyString = JSON.serialize(invoiceRequestBody, true);  //remove null values
            Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                    invoiceRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(invoiceRequestBodyString , requestBodyReplacementList);
            
            //check if an Invoice has been synced already, if not, create MYOB Invoice
            if(String.isBlank(params.UID )){
                
                
                system.debug('INVOICE:  ' + invoiceRequestBodyString);
                HttpResponse postInvoiceResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM, 
                                                                            invoiceRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                system.debug('postInvoiceResponse:  ' + postInvoiceResponse.getBody());
                try{
                    
                    invoice.MYOB_Response__c = postInvoiceResponse?.getBody();
                    String locationUri = postInvoiceResponse?.getHeader('location');
                    if(locationUri != null){
                        String invoiceId = locationUri.substringAfter('/Item/');
                        invoice.External_Accounting_Id__c = invoiceId;
                         
                        
                        //Retrieve MYOB Invoice to update the invoice lines to get the Row Id
                        MYOB_RestResponseCollection.Invoice MYOBInvoice = SearchInvoiceFromMYOBByUID(requestHeader , endpoint, companyFileID, invoiceId);
                        
                        for(MYOB_RestResponseCollection.InvoiceLineItem line : MYOBInvoice.Lines){
                            
                            if(prodMYOBLinesMap.containsKey(line.Item.UID)){
                                prodMYOBLinesMap.get(line.Item.UID).MYOB_Row_Id__c = String.valueOF(line.RowID);
                                
                            }
                            
                        }
                        system.debug('invoice lines: ' + prodMYOBLinesMap);
                        if(prodMYOBLinesMap.size() > 0){
                            update prodMYOBLinesMap.values(); 
                            
                            
                        }
                        
                        
                        if(params.Order?.UID != ''){
                            //Update the converted SalesOrder 
                            Order odr = new Order();
                            odr.Accounting_External_Id__c = params.Order.UID;
                            odr.MYOB_Status__c = 'ConvertedToInvoice';
                            odr.MYOB_Order_Invoiced__c = true;
                            upsert odr Order.Accounting_External_Id__c;
                        }
                        
                        
                        
                    }
                
                    
                    Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, invoiceRequestBodyString, postInvoiceResponse?.getBody(), postInvoiceResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM);
                    
                    
                }catch(Exception err){
                    
                    Utilities.CreateExceptionLog(err,'MYOB_PostOrderRequestFlow - Account Record Update');
                }
                
                    
             
            }
            
            else{  //MYOB Invoice UID Exist in CRM
                //PUT METHOD
                
                MYOB_RestResponseCollection.Invoice MYOBInvoice = SearchInvoiceFromMYOBByUID(requestHeader , endpoint, companyFileID, params.UID);
                if(MYOBInvoice != null){
                    
                    //Check if the MYOB Invoice status is still open
                    if(MYOBInvoice.Status != 'Closed'){
                        
                        
                        //update invoice row version for PUT
                        invoice.MYOB_Row_Version__c = MYOBInvoice.RowVersion;
                        
                        invoiceRequestBody.RowVersion = MYOBInvoice.RowVersion;
                        invoiceRequestBody.Terms = MYOBInvoice.Terms;
                        
                        invoiceRequestBodyString = JSON.serialize(invoiceRequestBody, true);  //remove null values
                        requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                            MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                            MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                                invoiceRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(invoiceRequestBodyString , requestBodyReplacementList);
                        
                        system.debug('invoiceRequestBodyString:  ' + invoiceRequestBodyString);
                        HttpResponse postInvoiceResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM + '/' + params.UID, 
                                                                                      invoiceRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                        system.debug('postInvoiceResponse:  ' + postInvoiceResponse.getBody());
                        try{
                            
                            Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, invoiceRequestBodyString, postInvoiceResponse?.getBody(), postInvoiceResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM);
                            
                            invoice.MYOB_Response__c = postInvoiceResponse?.getBody();
                        
                            for(MYOB_RestResponseCollection.InvoiceLineItem line : MYOBInvoice.Lines){
                                
                                if(prodMYOBLinesMap.containsKey(line.Item.UID)){
                                    prodMYOBLinesMap.get(line.Item.UID).MYOB_Row_Id__c = String.valueOF(line.RowID);
                                    
                                }
                                
                            }
                            system.debug('invoice lines: ' + prodMYOBLinesMap);
                            if(prodMYOBLinesMap.size() > 0){
                                update prodMYOBLinesMap.values(); 
                            }
                            
                            
                          
                            
                        }catch(Exception err){
                            
                            Utilities.CreateExceptionLog(err,'MYOB_PostOrderRequestFlow - Account Record Update');
                        }   
                    }else{
                        invoice.MYOB_Response__c = 'Invoice status is closed.';
                    }
                }
                
                
            }
            
            
            update invoice;
            
        } 
        
    } 
    
    
    @InvocableMethod(label = 'Sync Invoice To MYOB' description = 'Sends Salesforce Invoice to MYOB to Sync with MYOB Sales Order.')
    public static void SendInvoiceToMYOBFromFlow(List<MYOB_FlowParam_Invoice> params) 
    {
        if(params == NULL || params.isEmpty()) return; 
        
        MYOB_PostInvoiceRequestFlow.MYOB_PostInvoiceRequestFlowAsync postInvoice = new MYOB_PostInvoiceRequestFlow.MYOB_PostInvoiceRequestFlowAsync();
        postInvoice.setParamString(JSON.serialize(params[0]));        
        System.enqueueJob(postInvoice);
        
    } 
    

    
    private static MYOB_RestRequestCollection.InvoiceRequestBody SetPostInvoiceBody(MYOB_FlowParam_Invoice params)
    {
        
        MYOB_RestRequestCollection.InvoiceRequestBody requestBody = new MYOB_RestRequestCollection.InvoiceRequestBody();
        requestBody.UID = params.UID;
        requestBody.Number_x = params.Number_x;
        requestBody.Date_x = system.Today();
        requestBody.IsTaxInclusive = params.IsTaxInclusive;     
        requestBody.Order = params.Order;
        requestBody.Customer = params.Customer;
        requestBody.Lines = params.Lines;
        requestBody.CustomerPurchaseOrderNumber = params.CustomerPurchaseOrderNumber;
        
        
        return requestBody;
    }
    
    public static MYOB_RestResponseCollection.Invoice SearchInvoiceFromMYOBByUID( Map<String , String> requestHeader, String endpoint, String companyFileId, String invoiceUid){
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM
                                                              + '/' + invoiceUid, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();   
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        MYOB_RestResponseCollection.Invoice myobInvoice = (MYOB_RestResponseCollection.Invoice)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.Invoice.class);
        
        if(myobInvoice == NULL) return null;
        return myobInvoice;
        
    }  
    
    
}