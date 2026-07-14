/*
* Author:         	Bricoleur Technologies
* Created Date:    November 22, 2021
* Description:     Apex Class for MYOB Outbound Post Contact callout Invoked from Flow
* Test Class:      N/A
* History:         November 22, 2021 - Creation
*/
public class MYOB_PostProductRequestFlow   
{
    
    private class MYOB_PostProductRequestFlowAsync implements Queueable, Database.AllowsCallouts
    {
        
        private String paramString;
        
        public void setParamString(String paramString)
        {
            this.paramString = paramString;
        }
        
        public void execute(QueueableContext context)
        {
            
            MYOB_FlowParam_Product params = (MYOB_FlowParam_Product)JSON.deserialize(this.paramString, MYOB_FlowParam_Product.class);
            MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                                 FROM MYOB_API_Setting__mdt
                                                 WHERE DeveloperName = 'Default'];
            String clientID = apiSettings?.Client_ID__c;
            String endpoint = apiSettings?.Endpoint__c;
            String companyFileID = apiSettings?.Company_File_ID__c;
            
            if(apiSettings == NULL || clientID == NULL || endpoint == NULL) return;
            
            Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
            
            if(String.isBlank(params.UID)){
                
                MYOB_RestResponseCollection.InventoryItemBody myobProduct = SearchProductFromMYOB(requestHeader, endpoint, companyFileID, params);
                system.debug('myobProduct ' + myobProduct);
                
                if(myobProduct != null && myobProduct?.UID != null){
                    
                    Product2 prod = new Product2();
                    prod.Id = params.SFID;
                    prod.MYOB_Row_Version__c = myobProduct?.RowVersion;
                    
                    prod.MYOB_Last_Sync_DateTime__c = system.now();
                    prod.MYOB_Response__c = '';
                    
                    String requestBodyString = '';
                    
                    MYOB_RestRequestCollection.InventoryItemBody requestBody = SetPostProductBody(params);
                    requestBodyString = JSON.serialize(requestBody, true);
                    
                    Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                            requestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
                    
                    
                    system.debug('requestBodyString ' + requestBodyString);
                    
                    try{
                        
                        HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM+ '/' + params.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                        system.debug('postResponse?.getBody:'+postResponse?.getBody());
                        Database.update(prod);                         
                        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM);
                        
                    }catch(Exception err){
                        
                        Utilities.CreateExceptionLog(err,'MYOB_PostContactRequestFlow - Account Record Update');
                    }
                }
                else{
                    
                    String requestBodyString = '';
                    
                    MYOB_RestRequestCollection.InventoryItemBody requestBody = SetPostProductBody(params);
                    requestBodyString = JSON.serialize(requestBody, true);
                    
                    Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                            requestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
                    
                    system.debug('requestBodyString ' + requestBodyString);
                    
                    
                    HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
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
                                Product2 prod = new Product2();
                                prod.Id = params.SFID;
                                prod.MYOB_Number__c = myobProduct?.Number_x;
                                prod.MYOB_Row_Version__c = myobProduct?.RowVersion;
                                prod.MYOB_Last_Sync_DateTime__c = system.now();
                                prod.MYOB_Response__c = '';
                                prod.Accounting_External_Id__c = UID;
                                update prod;
                                
                            }
                        }
                    }
                    
                    Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, requestBodyString, postResponseBodyString, postResponseStatusCode, MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM);
                    
                }
            }else{
                
                String requestBodyString = '';
                HttpResponse postResponse;
                MYOB_RestResponseCollection.InventoryItemBody myobProduct = SearchProductFromMYOBByUID(requestHeader, endpoint, companyFileID, params);
                
               
                if(myobProduct?.RowVersion != null){
                    MYOB_RestRequestCollection.InventoryItemBody requestBody = SetPutProductBody(params, myobProduct.RowVersion);
                     requestBodyString = JSON.serialize(requestBody, true);
                    
                    Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                        requestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(requestBodyString , requestBodyReplacementList);
                    
                    system.debug('myobProduct SearchProductFromMYOBByUID ' +  JSON.serialize(requestBody, true));
                    
                   
                    postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM+ '/' + params.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                    string response = postResponse?.getBody();
                    system.debug('myobProduct response ' + response);
                    
                    Product2 prod = new Product2();
                    prod.Id = params.SFID;
                    prod.MYOB_Row_Version__c = myobProduct?.RowVersion;
                    prod.MYOB_Last_Sync_DateTime__c = system.now();
                    prod.MYOB_Response__c = response;
                    update prod;
                    
                    
                    Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM);
                }
            }
            
            
            
            
            
            
        }
        
        
        
    }
    
    @InvocableMethod(label = 'Sync Product To MYOB' description = 'Sends Salesforce Account to MYOB to Sync with MYOB Contact.')
    public static void SendProductToMYOBFromFlow(List<MYOB_FlowParam_Product> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        
        MYOB_PostProductRequestFlow.MYOB_PostProductRequestFlowAsync postProduct = new MYOB_PostProductRequestFlow.MYOB_PostProductRequestFlowAsync();
        postProduct.setParamString(JSON.serialize(params[0]));        
        System.enqueueJob(postProduct);
        
    }
    
    public static MYOB_RestRequestCollection.InventoryItemBody SetPostProductBody(MYOB_FlowParam_Product params)
    {
        
        MYOB_RestRequestCollection.InventoryItemBody requestBody = new MYOB_RestRequestCollection.InventoryItemBody();
   
        requestBody.Number_x = params.Number_x;
        requestBody.Name = params.Name; 
        requestBody.IsActive = params.IsActive;
        requestBody.Description = params.Description;
        requestBody.BaseSellingPrice = params.BaseSellingPrice;
        requestBody.IsBought = params.IsBought;
        requestBody.IsSold = params.IsSold;
    	requestBody.IsInventoried = params.IsInventoried;
        requestBody.RowVersion = params.RowVersion;
        requestBody.UID = params.UID != '' ? params.UID : null;
        
        return requestBody;
    }
    
    public static MYOB_RestRequestCollection.InventoryItemBody SetPutProductBody(MYOB_FlowParam_Product params, String rowVersion)
    {
        
        MYOB_RestRequestCollection.InventoryItemBody requestBody = new MYOB_RestRequestCollection.InventoryItemBody();
   
        requestBody.Number_x = params.Number_x;
        requestBody.Name = params.Name; 
        requestBody.IsActive = params.IsActive;
        requestBody.Description = params.Description;
        requestBody.BaseSellingPrice = params.BaseSellingPrice;
        requestBody.IsBought = params.IsBought;
        requestBody.IsSold = params.IsSold;
    	requestBody.IsInventoried = params.IsInventoried;
        requestBody.RowVersion = rowVersion;
        requestBody.UID = params.UID != '' ? params.UID : null;
        
        return requestBody;
    }
    
    public static MYOB_RestResponseCollection.InventoryItemBody SearchProductFromMYOBByUID( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Product params){
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM
                                                              + '/' + params.UID, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();   
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.InventoryItemBody myobProduct = (MYOB_RestResponseCollection.InventoryItemBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.InventoryItemBody.class);
        
        if(myobProduct == NULL) return null;
        return myobProduct;
        
    }    
    
    public static MYOB_RestResponseCollection.InventoryItemBody SearchProductFromMYOB( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Product params){
        String customerParam = '';
        
        customerParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_NUMBER + MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + params.Number_x +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        
        system.debug('customerParam :: ' + customerParam);
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVENTORY_ITEM
                                                              + '?' + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + customerParam, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();  
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.InventoryItemBody myobProduct = (MYOB_RestResponseCollection.InventoryItemBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.InventoryItemBody.class);
        
        
        if(myobProduct == NULL) return null;
        else{
            return myobProduct;         
        }
        
        
        
        
    }    
}