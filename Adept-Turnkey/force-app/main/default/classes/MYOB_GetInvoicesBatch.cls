/*
* @Author: Bricoleur Technology
* @Date: March 5, 2026
* @Desc:
*
*/
public class MYOB_GetInvoicesBatch implements Database.Batchable<MYOB_RestResponseCollection.Invoice>,Database.AllowsCallouts, Database.Stateful
{
       
    public String paramString;
    
    
    public MYOB_GetInvoicesBatch(String params){
        
        paramString = params;
         
    }
    
    public Iterable<MYOB_RestResponseCollection.Invoice> start(Database.BatchableContext context)
    {   
        
        MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                             FROM MYOB_API_Setting__mdt
                                             WHERE DeveloperName = 'Default'];
        String clientID = apiSettings?.Client_ID__c;
        String endpoint = apiSettings?.Endpoint__c;
        String companyFileID = apiSettings?.Company_File_ID__c;
         
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        
        //Sync records 30minutes ago
        String modifiedSince = getUTCDateTime(MYOBProcessingSettings?.Invoice_Sync_Date_Time__c);
        
        if(apiSettings == NULL || endpoint == NULL || modifiedSince == NULL) return new List<MYOB_RestResponseCollection.Invoice>();
        
        Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
        
        String lastModifiedParam = '';        
        lastModifiedParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_LASTMODIFIED + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_DATETIME +
                                                   MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + modifiedSince +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        if(paramString == '') paramString = MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + lastModifiedParam;
        
        system.debug('paramString: ' + EncodingUtil.urlDecode(paramString, 'UTF-8'));
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM + '/'
                                                              + '?' + paramString, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();  
        system.debug('getResponse:'+getResponse.getBody());
        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET, null, getResponse?.getBody(), getResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_INVOICES_ITEM
                                           + '?' +paramString);
        /*
        Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X,
            MYOB_CONSTANTS.INTEGRATION_KEY_TYPE => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X,
            MYOB_CONSTANTS.INTEGRATION_KEY_DATE => MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X};   
                getResponseBodyString = MYOB_RequestUtilities.FormatJSONBodyString(getResponseBodyString , requestBodyReplacementList);
        */
        getResponseBodyString = getResponseBodyString.replaceAll('_x', '');
        
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)){ 
             paramString = '';
            return new List<MYOB_RestResponseCollection.Invoice>();
        }
        
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        
        MYOB_RestResponseCollection.InvoiceResponseBody myobInvoiceResponse = (MYOB_RestResponseCollection.InvoiceResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.InvoiceResponseBody.class);
        List<MYOB_RestResponseCollection.Invoice> myobInvoiceItems = new List<MYOB_RestResponseCollection.Invoice>();
        
        if(myobInvoiceResponse == NULL) {
            paramString = '';
            return new List<MYOB_RestResponseCollection.Invoice>();
        }
        else if(myobInvoiceResponse.Items?.size() > 0 ){
            paramString = myobInvoiceResponse.NextPageLink;
            paramString = paramString?.substringAfter('?');
            
            myobInvoiceItems =  myobInvoiceResponse.Items;        
        }else{
            paramString = '';
            return new List<MYOB_RestResponseCollection.Invoice>();
        }
        return myobInvoiceItems;    
    }
    
    
    public void execute(Database.BatchableContext context, List<MYOB_RestResponseCollection.Invoice> myobInvList)
    {
        List<MYOB_Invoice__c> invoicesForUpsert = new List<MYOB_Invoice__c>();
        List<Account> accsForUpsert = new List<Account>();
        Set<Account> accsForUpsertSet = new Set<Account>();
        Map<String,Account> accountIDMap = new Map<String,Account>();
        Map<String,Account> accountMYOBUIDMap = new Map<String,Account>();
        Map<String,Account> accountMYOBNameMap = new Map<String,Account>();
        Map<String,MYOB_Invoice__c> invoiceMap = new Map<String,MYOB_Invoice__c>();
        Set<String> invoiceUIDs = new Set<String>();
        Set<String> customerUIDs = new Set<String>();
        Set<String> customerPONumber = new Set<String>();
        
        if(myobInvList != NULL && myobInvList.size() > 0){
            for(MYOB_RestResponseCollection.Invoice myobInvItem : myobInvList) {
                invoiceUIDs.add(myobInvItem.UID);
                customerUIDs.add(myobInvItem.Customer?.UID);
				customerPONumber.add(myobInvItem.CustomerPurchaseOrderNumber);                
            }
        }
        List<Account> accountList = [SELECT Id, Name, MYOB_GUID__c FROM Account];

        
        for(Account acc : accountList){
            if(acc.MYOB_GUID__c != NULL && acc.MYOB_GUID__c != ''){
                accountMYOBUIDMap.put(acc.MYOB_GUID__c, acc);
            } 
            
            accountMYOBNameMap.put(acc.Name.deleteWhitespace(), acc);
        }
        
        
        List<MYOB_Invoice__c> invoiceList = [SELECT Id, MYOB_UID_bric__c FROM MYOB_Invoice__c WHERE MYOB_UID_bric__c IN: invoiceUIDs AND MYOB_UID_bric__c != NULL]; 
         for(MYOB_Invoice__c inv : invoiceList){
            if(inv.MYOB_UID_bric__c != NULL && inv.MYOB_UID_bric__c != '') invoiceMap.put(inv.MYOB_UID_bric__c, inv);
        }
        
        
        if(myobInvList != NULL && myobInvList.size() > 0){
            for(MYOB_RestResponseCollection.Invoice myobInvItem : myobInvList) {
                MYOB_Invoice__c invoiceRecord = new MYOB_Invoice__c();
                system.debug('##: ' + JSON.serialize(myobInvItem));
                system.debug('!!'+accountMYOBUIDMap);
                system.debug('!!'+myobInvItem.Customer?.UID);
                System.debug('!!'+accountMYOBNameMap);
                System.debug('!!'+myobInvItem.Customer?.Name);
                
                
                if(invoiceMap.get(myobInvItem.UID) != NULL) invoiceRecord.Id = invoiceMap.get(myobInvItem.UID)?.Id;
                
                
                if(accountMYOBUIDMap.get(myobInvItem.Customer?.UID) != NULL) invoiceRecord.Customer_bric__c = accountMYOBUIDMap.get(myobInvItem.Customer?.UID)?.Id;
                
                
                if(invoiceRecord.Customer_bric__c == NULL){
                    invoiceRecord.Customer_bric__c = accountMYOBNameMap.get(myobInvItem.Customer?.Name.deleteWhitespace())?.Id;
                    if(invoiceRecord.Customer_bric__c != NULL){
                        Account acc = new Account();
                        acc.Id = invoiceRecord.Customer_bric__c;
                        acc.MYOB_GUID__c = myobInvItem.Customer?.UID;
                        accsForUpsert.add(acc);
                        if(!accountIDMap.containsKey(acc.Id)){
                         accountIDMap.put(acc.Id,acc);   
                        }
                        
                    }
                }   
                    
                invoiceRecord.Balance_Due_Amount_bric__c = myobInvItem.BalanceDueAmount;
                invoiceRecord.Comments_Bric__c = myobInvItem.Comment;
                invoiceRecord.Invoice_Date_bric__c =getDateValue(myobInvItem.Date_x);
                invoiceRecord.Balance_Due_Amount_bric__c = myobInvItem.BalanceDueAmount;
                invoiceRecord.CustomerPurchaseOrderNumber_bric__c = myobInvItem.CustomerPurchaseOrderNumber;
                invoiceRecord.Invoice_Number_bric__c = myobInvItem.Number_x;
                invoiceRecord.InvoiceType_bric__c = 'Item';
                invoiceRecord.Is_Tax_Inclusive_bric__c = myobInvItem.IsTaxInclusive;
                invoiceRecord.Journal_Memo_Bric__c = myobInvItem.JournalMemo;
                invoiceRecord.Last_Payment_Date_bric__c = getDateValue(myobInvItem.LastPaymentDate);
                invoiceRecord.MYOB_UID_bric__c = myobInvItem.UID;
                invoiceRecord.Promised_Date_bric__c = getDateValue(myobInvItem.PromisedDate);
                invoiceRecord.Ship_To_Address_bric__c = myobInvItem.ShipToAddress;
                invoiceRecord.Status_Bric__c = myobInvItem.Status;
                invoiceRecord.SubTotal_bric__c = myobInvItem.Subtotal;
                invoiceRecord.TotalAmount_bric__c = myobInvItem.TotalAmount;
                invoiceRecord.TotalTax_bric__c = myobInvItem.TotalTax;
                invoiceRecord.Customer_Name_bric__c = myobInvItem.Customer?.Name;
                invoiceRecord.Customer_UID_bric__c = myobInvItem.Customer?.UID;                
                invoiceRecord.Salesperson_Name_bric__c = myobInvItem.Salesperson?.Name;
                invoiceRecord.Sales_Order_Id_bric__c = myobInvItem.Order?.UID; 
                invoicesForUpsert.add(invoiceRecord);
                
            }
            
            if(invoicesForUpsert.size() > 0){
                try{
                    system.debug('invoicesForUpsert1:'+invoicesForUpsert);
                    system.debug('accsForUpsert1:'+accsForUpsert.size());
                    system.debug('accsForUpsert2:'+accsForUpsert);
                    system.debug('accsForUpsert3:'+accountIDMap.values().size());
                    system.debug('accsForUpsert4:'+accountIDMap.values());
                    Database.UpsertResult[] saveResultList = Database.upsert(invoicesForUpsert, false);
                    
                    
                    for (Database.UpsertResult sr : saveResultList) {
                        if (sr.isSuccess()) {
                            system.debug('invoicesForUpsert2:'+invoicesForUpsert[0].id);
                            if(accsForUpsert.size() >0){
                                
                                accsForUpsertSet.addAll(accsForUpsert);
                                accsForUpsert.addAll(accsForUpsertSet);
                                // Database.upsert(accsForUpsert,false);   
                                Database.upsert(accountIDMap.values(),false);                       
                            }
                            
                            //Process Lines
                            processLineItems(myobInvList, invoicesForUpsert);
                            System.debug('Successfully inserted account. Account ID: ' + sr.getId());
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('The following error has occurred.');                    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Account fields that affected this error: ' + err.getFields());
                            }
                        }
}
                    
                    
                }catch(Exception err){
                    Utilities.CreateExceptionLog(err,'MYOB_GetInvoicesBatch');
                }
            }
        }
    }
    
    public void processLineItems(List<MYOB_RestResponseCollection.Invoice> myobInvList, List<MYOB_Invoice__c> invoicesForUpsert){
        
        Set<String> invoiceUIDs = new Set<String>();
        List<MYOB_Invoice_Line_Item__c> lineItemsToDelete = new List<MYOB_Invoice_Line_Item__c>();
        List<MYOB_Invoice_Line_Item__c> lineItemsToInsert = new List<MYOB_Invoice_Line_Item__c>();
        Map<String,MYOB_Invoice__c> invoiceMap = new Map<String,MYOB_Invoice__c>();
        
        if(myobInvList != NULL && myobInvList.size() > 0){
            for(MYOB_RestResponseCollection.Invoice myobInvItem : myobInvList) {
                invoiceUIDs.add(myobInvItem.UID);              
            }
        }
        system.debug('invoiceUIDs:'+invoiceUIDs);
        List<MYOB_Invoice__c> invoiceList = [SELECT Id, MYOB_UID_bric__c,(SELECT Id,Row_ID_bric__c FROM MYOB_Invoice_Line_Items__r) FROM MYOB_Invoice__c WHERE MYOB_UID_bric__c IN: invoiceUIDs AND MYOB_UID_bric__c != NULL]; 
        for(MYOB_Invoice__c inv : invoiceList){
            if(inv.MYOB_UID_bric__c != NULL && inv.MYOB_UID_bric__c != '') invoiceMap.put(inv.MYOB_UID_bric__c, inv);
            if(inv.MYOB_Invoice_Line_Items__r.size() > 0){
                lineItemsToDelete.addAll(inv.MYOB_Invoice_Line_Items__r);
            }
        }
        
        for(MYOB_RestResponseCollection.Invoice myobInvItem : myobInvList) {
            if(myobInvItem.Lines.size() > 0 ){
                for(MYOB_RestResponseCollection.InvoiceLineItem myobInvLineItem: myobInvItem.Lines){
                    //TODO: 
                    system.debug('!!myobInvItem.UID'+myobInvItem.UID);
                    system.debug('!!invoiceMap'+invoiceMap);
				                  
                    if(invoiceMap.get(myobInvItem.UID) != NULL){
                        MYOB_Invoice_Line_Item__c invItem = new MYOB_Invoice_Line_Item__c();
                        invItem.Row_ID_bric__c = String.valueOf(myobInvLineItem.RowID);
                        invItem.MYOB_Invoice__c = invoiceMap.get(myobInvItem.UID)?.Id;
                        invItem.Cost_Of_Goods_Sold_bric__c = myobInvLineItem.CostOfGoodsSold;
                        invItem.Description_Bric__c = myobInvLineItem.Description;
                        invItem.Discount_Percent_bric__c = myobInvLineItem.DiscountPercent;
                        invItem.Account_DisplayID_bric__c = myobInvLineItem.Account?.DisplayID;
                        invItem.Account_Name_Bric__c = myobInvLineItem.Account?.Name;
                        invItem.Item_Name_bric__c = myobInvLineItem.Item?.Name;
                        invItem.Item_Number_bric__c = myobInvLineItem.Item?.Number_x;
                        invItem.Ship_Quantity_bric__c = myobInvLineItem.shipQuantity;
                        invItem.Total_Bric__c = myobInvLineItem.Total;
                        invItem.Unit_Count_bric__c = myobInvLineItem.UnitCount;
                        invItem.Unit_Of_Measure_bric__c = myobInvLineItem.UnitOfMeasure;
                        invItem.Unit_Price_bric__c = myobInvLineItem.UnitPrice;                        
                        lineItemsToInsert.add(invItem);    
                        
                    }
                    
                }
            }
        }
        
        
        if(lineItemsToInsert.size() > 0){
            try{
                if(lineItemsToDelete.size() > 0){                    
                    Database.delete(lineItemsToDelete,false);
                }
                Database.insert(lineItemsToInsert,false);
                
                //Update the invoice so that the after update trigger will be invoked
                for(MYOB_Invoice__c inv : invoicesForUpsert){
                    inv.Last_Sync_DateTime__c = system.now();
                }
                
                update invoicesForUpsert;
                
            }catch(Exception err){
                Utilities.CreateExceptionLog(err,'MYOB_GetInvoicesBatch');
            }
            
        }
       
        
    }
     
    public Date getDateValue(string dt){
        if(dt == '' || dt == NULL) return NULL;
        return Date.valueOf(dt);
    }
    
    public void finish(Database.BatchableContext context) {
        
        
        system.debug('finish paramString : ' + paramString);    
        
        if(paramString != '' && paramString != null) {
            Database.executeBatch(new MYOB_GetInvoicesBatch(paramString));
            
        }else{
            
            MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
            if(MYOBProcessingSettings != NULL)
            {
                MYOBProcessingSettings.Invoice_Sync_Date_Time__c = System.now();
                Database.Update(MYOBProcessingSettings);
            } 
            
            
            //Reschedule then delete the previous job for cleaner 
            List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger 
                                               WHERE CronJobDetail.Name LIKE '%MYOB_InvoiceBatchSchedulable%'];
            for (CronTrigger job : scheduledJobs) {
                try {
                    System.abortJob(job.Id);
                } catch (Exception e) {
                    System.debug('Job already processed or removed: ' + e.getMessage());
                }
            }
            Datetime nextRun = System.now().addMinutes(15);
            String cronStr = nextRun.format('s m H d M ? yyyy');
            System.schedule('MYOB_InvoiceBatchSchedulable', cronStr, new MYOB_InvoiceBatchSchedulable());
        }
    }
    
    public String getUTCDateTime(DateTime dt){
        Datetime GMTDate = Datetime.newInstance(
            dt.year(),
            dt.month(),
            dt.day(),
            dt.hour(),
            dt.minute(),
            dt.second());
        String formatted = GMTDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss');
        return formatted;
    }

    
}