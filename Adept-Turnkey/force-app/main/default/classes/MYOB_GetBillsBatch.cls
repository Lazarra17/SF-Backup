/*
* @Author: Bricoleur Technology
* @Date: March 5, 2026
* @Desc:
*
*/
public class MYOB_GetBillsBatch implements Database.Batchable<MYOB_RestResponseCollection.Bill>,Database.AllowsCallouts, Database.Stateful
{
       
    public String paramString;
    
    
    public MYOB_GetBillsBatch(String params){
        
        paramString = params;
         
    }
    
    public Iterable<MYOB_RestResponseCollection.Bill> start(Database.BatchableContext context)
    {   
        
        MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                             FROM MYOB_API_Setting__mdt
                                             WHERE DeveloperName = 'Default'];
        String clientID = apiSettings?.Client_ID__c;
        String endpoint = apiSettings?.Endpoint__c;
        String companyFileID = apiSettings?.Company_File_ID__c;
         
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        String modifiedSince = getUTCDateTime(MYOBProcessingSettings?.Bill_Sync_Date_Time__c);
        
        if(apiSettings == NULL || endpoint == NULL || modifiedSince == NULL) return new List<MYOB_RestResponseCollection.Bill>();
        
        Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
        
        String lastModifiedParam = '';        
        lastModifiedParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_STATUS_NE +
                                                   MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_CLOSED +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        
        if(paramString == '') paramString = MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + lastModifiedParam;
        
        system.debug('paramString: ' + EncodingUtil.urlDecode(paramString, 'UTF-8'));
        
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + 
                                                              MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM + '/' + '?' + paramString, 
                                                              null, 
                                                              MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);   
        system.debug('getResponse: '+getResponse); 
        String getResponseBodyString = getResponse?.getBody();  
        system.debug('getResponse:'+getResponse.getBody());
        
        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET, null, getResponse?.getBody(), getResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_BILL_ITEM
                                           + '?' +paramString);
        
        getResponseBodyString = getResponseBodyString.replaceAll('_x', '');
        
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)){ 
             paramString = '';
            return new List<MYOB_RestResponseCollection.Bill>();
        }
        
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        
        MYOB_RestResponseCollection.BillResponseBody myobBillResponse = (MYOB_RestResponseCollection.BillResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.BillResponseBody.class);
        List<MYOB_RestResponseCollection.Bill> myobBillItems = new List<MYOB_RestResponseCollection.Bill>();
        
        if(myobBillResponse == NULL) {
            paramString = '';
            return new List<MYOB_RestResponseCollection.Bill>();
        }
        else if(myobBillResponse.Items?.size() > 0 ){
            paramString = myobBillResponse.NextPageLink;
            paramString = paramString?.substringAfter('?');
            
            myobBillItems =  myobBillResponse.Items;        
        }else{
            paramString = '';
            return new List<MYOB_RestResponseCollection.Bill>();
        }
        return myobBillItems;    
    }
    
    
    public void execute(Database.BatchableContext context, List<MYOB_RestResponseCollection.Bill> myobBillList)
    {
      
        List<nao__Invoice__c> invoicesForUpsert = new List<nao__Invoice__c>();
        List<Account> accsForUpsert = new List<Account>();
        Map<String,Account> accsMapForUpsert = new Map<String,Account>();
        Map<String,Account> accountMYOBUIDMap = new Map<String,Account>();
        Map<String,String> myobBillMap = new Map<String,String>();
        Map<String,nao__Invoice__c> billsToUpdateMap = new Map<String,nao__Invoice__c>();
        Map<String,nao__Invoice__c> existingBillsMap = new Map<String,nao__Invoice__c>();
        Set<String> billUIDs = new Set<String>();
        Set<String> supplierUIDs = new Set<String>();
        
        if(myobBillList != NULL && myobBillList.size() > 0){
            for(MYOB_RestResponseCollection.Bill myobBillItem : myobBillList) {
                billUIDs.add(myobBillItem.UID);
                supplierUIDs.add(myobBillItem.Supplier?.UID); 
                myobBillMap.put(myobBillItem.UId, myobBillItem.RowVersion);
            }
        }
        List<Account> accountList = [SELECT Id, Name, MYOB_Supplier_Id__c FROM Account WHERE MYOB_Supplier_Id__c != ''];
        
        
        for(Account acc : accountList){
            
            accountMYOBUIDMap.put(acc.MYOB_Supplier_Id__c, acc);
            
        }
        
        
       
        List<nao__Invoice__c> billsList = [SELECT Id, External_Accounting_Id__c, MYOB_Row_Version__c FROM nao__Invoice__c WHERE External_Accounting_Id__c IN : billUIDs]; 
        for(nao__Invoice__c bill : billsList){
            
            //Checks if MYOB Bill has been updated and compare the Row Version in SF Nao Invoice
            if(myobBillMap.containsKey(bill.External_Accounting_Id__c)){
                if(myobBillMap.get(bill.External_Accounting_Id__c) != bill.MYOB_Row_Version__c){
                    billsToUpdateMap.put(bill.External_Accounting_Id__c, bill);
                }else{
                    existingBillsMap.put(bill.External_Accounting_Id__c, bill);
                }
            }
            
        }
        
        
      
        if(myobBillList != NULL && myobBillList.size() > 0){
            
            
            //Upsert Account from via external Id
            for(MYOB_RestResponseCollection.Bill myobBillItem : myobBillList) {
                nao__Invoice__c invoiceRecord = new nao__Invoice__c();
            
                
                
                //Upsert Account from via external Id
                Account acc = new Account();
                acc.MYOB_Supplier_Id__c = myobBillItem.Supplier?.UID;
                acc.Name = myobBillItem.Supplier?.Name;
                
                accsMapForUpsert.put(myobBillItem.Supplier?.UID, acc);
                
                            
            }
            
            //Upsert Account from via external Id
            if(accsMapForUpsert.size() > 0){
                upsert accsMapForUpsert.values() MYOB_Supplier_Id__c;                  
            }
            
            
            
            
            
            //Upsert NAO Invoice from via external Id
            for(MYOB_RestResponseCollection.Bill myobBillItem : myobBillList) {
               
                if(billsToUpdateMap.containsKey(myobBillItem.UID) || !existingBillsMap.containsKey(myobBillItem.UID)){
                    //UPDATE existing invoice AND //CREATE new invoices
                     nao__Invoice__c invoiceRecord = new nao__Invoice__c();
                    invoiceRecord.RecordTypeId = Schema.SObjectType.nao__Invoice__c.getRecordTypeInfosByDeveloperName().get('Bill').getRecordTypeId();
                    invoiceRecord.nao__Account_Bric__r = new Account(MYOB_Supplier_Id__c = myobBillItem.Supplier?.UID);
                    invoiceRecord.nao__Order_Bric__r = new Order(Accounting_External_Id__c = myobBillItem.Order?.UID);
                    invoiceRecord.nao__Invoice_Date_bric__c = myobBillItem.Date_x;
                    invoiceRecord.nao__Status_Bric__c = myobBillItem.Status;
                    invoiceRecord.nao__Notes_Bric__c = myobBillItem.JournalMemo;
                    invoiceRecord.CurrencyIsoCode = myobBillItem?.ForeignCurrency?.Code != null ? myobBillItem?.ForeignCurrency?.Code : 'AUD';
                    invoiceRecord.External_Accounting_Id__c = myobBillItem.UID;
                    
                    system.debug('External_Accounting_Id__c: ' + myobBillItem.UID + ' : ' + myobBillItem.Supplier?.UID + ' : ' + myobBillItem.Order?.Number_x);
                    
                    invoiceRecord.MYOB_Row_Version__c = myobBillItem.RowVersion;
                    invoiceRecord.MYOB_Last_Sync_DateTime__c = System.now();
                    invoiceRecord.MYOB_Status__c = myobBillItem.Status;
                     invoicesForUpsert.add(invoiceRecord);
                }
                
              
                
               
            }
           
            
            
            if(invoicesForUpsert.size() > 0){
                try{
                    system.debug('invoicesForUpsert1:'+ invoicesForUpsert);
                    Database.UpsertResult[] saveResultList = Database.upsert(invoicesForUpsert, nao__Invoice__c.External_Accounting_Id__c, false);
                    
                    
                    for (Database.UpsertResult sr : saveResultList) {
                        if (sr.isSuccess()) {
                            
                            //Process Lines
                            processLineItems(myobBillList, invoicesForUpsert);
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
                    Utilities.CreateExceptionLog(err,'MYOB_GetBillsBatch');
                }
            }
        }
    }
   
    public void processLineItems(List<MYOB_RestResponseCollection.Bill> myobBillList, List<nao__Invoice__c> invoicesForUpsert){
        
        Set<String> invoiceUIDs = new Set<String>();
        List<nao__Invoice_Lines__c> lineItemsToInsert = new List<nao__Invoice_Lines__c>();
        Map<String,nao__Invoice__c> invoiceMap = new Map<String,nao__Invoice__c>();
        
        
        for(nao__Invoice__c inv : invoicesForUpsert){
            
            invoiceMap.put(inv.External_Accounting_Id__c, inv);
        }
         
        
        List<nao__Invoice_Lines__c> lineItemsToDelete = [SELECT Id FROM nao__Invoice_Lines__c WHERE nao__Invoice_bric__c IN: invoicesForUpsert]; 
     
        
         for(MYOB_RestResponseCollection.Bill myobBillItem : myobBillList) {
            if(myobBillItem.Lines.size() > 0 ){
                
                
                for(MYOB_RestResponseCollection.BillLines myobBillLineItem: myobBillItem.Lines){
                    //TODO: 
                   
				                  
                    if(invoiceMap.containsKey(myobBillItem.UID)){
                      

                        nao__Invoice_Lines__c invItem = new nao__Invoice_Lines__c();
                        invItem.nao__Invoice_bric__c = invoiceMap.get(myobBillItem.UID).Id;
                        invItem.nao__Product_bric__r = new Product2(Accounting_External_Id__c = myobBillLineItem?.Item?.UID);      
                        invItem.nao__Quantity_bric__c = myobBillLineItem.ReceivedQuantity;
                        invItem.nao__Unit_Cost__c =  myobBillLineItem.UnitPriceForeign != null ? myobBillLineItem.UnitPriceForeign : myobBillLineItem.UnitPrice;
                        invItem.nao__Amount_bric__c = myobBillLineItem.Total;
                        invItem.nao__Description_Bric__c = myobBillLineItem.Description;
                        invItem.CurrencyIsoCode = myobBillItem?.ForeignCurrency?.Code != null ? myobBillItem?.ForeignCurrency?.Code : 'AUD';
                        
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
        
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        if(MYOBProcessingSettings != NULL)
        {
            MYOBProcessingSettings.Bill_Sync_Date_Time__c = System.now();
            //Database.Update(MYOBProcessingSettings);
        } 
        
        system.debug('finish paramString : ' + paramString);    
        
        if(paramString != '' && paramString != null) {
            Database.executeBatch(new MYOB_GetBillsBatch(paramString));
            
        }else{
            //Reschedule then delete the previous job for cleaner 
            /*
            List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger 
                                               WHERE CronJobDetail.Name LIKE '%MYOB_BillBatchSchedulable%'];
            for (CronTrigger job : scheduledJobs) {
                try {
                    System.abortJob(job.Id);
                } catch (Exception e) {
                    System.debug('Job already processed or removed: ' + e.getMessage());
                }
            }
            Datetime nextRun = System.now().addMinutes(15);
            String cronStr = nextRun.format('s m H d M ? yyyy');
            System.schedule('MYOB_BillBatchSchedulable', cronStr, new MYOB_BillBatchSchedulable());
*/
        }
    }
    
    public String getUTCDateTime(DateTime dt){
        dt = dt.addDays(-30);
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