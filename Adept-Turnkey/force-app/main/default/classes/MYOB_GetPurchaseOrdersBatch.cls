/*
* @Author: Bricoleur Technology
* @Date: March 5, 2026
* @Desc:
*
*/
public class MYOB_GetPurchaseOrdersBatch implements Database.Batchable<MYOB_RestResponseCollection.PurchaseOrder>,Database.AllowsCallouts, Database.Stateful
{
    
    public String paramString;
    
    public MYOB_GetPurchaseOrdersBatch(String params){
        
        paramString = params;
        
    }
    
    public Iterable<MYOB_RestResponseCollection.PurchaseOrder> start(Database.BatchableContext context)
    {   
        
        MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                             FROM MYOB_API_Setting__mdt
                                             WHERE DeveloperName = 'Default'];
        String clientID = apiSettings?.Client_ID__c;
        String endpoint = apiSettings?.Endpoint__c;
        String companyFileID = apiSettings?.Company_File_ID__c;
        
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        //String modifiedSince = getUTCDateTime(MYOBProcessingSettings?.Purchase_Order_Sync_Date_Time__c);
        
        //if(apiSettings == NULL || endpoint == NULL || modifiedSince == NULL) return new List<MYOB_RestResponseCollection.PurchaseOrder>();
        
        Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
        
        String lastModifiedParam = '';        
        lastModifiedParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_STATUS_EQ +
                                                   MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_OPEN +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        if(paramString == '') paramString = MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + lastModifiedParam;
        
        system.debug('paramString: ' + paramString);
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_PURCHASE_ORDERS_ITEM + '/'
                                                              + '?' + paramString, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();  
        
       // system.debug('getResponseBodyString: '+ getResponseBodyString); 
        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET, null, getResponse?.getBody(), getResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM
                                           + '?' +paramString);
        
        Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X,
            MYOB_CONSTANTS.INTEGRATION_KEY_TYPE => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X,
            MYOB_CONSTANTS.INTEGRATION_KEY_DATE => MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X};   
                getResponseBodyString = MYOB_RequestUtilities.FormatJSONBodyString(getResponseBodyString , requestBodyReplacementList);
        
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)){ 
            paramString = '';
            return new List<MYOB_RestResponseCollection.PurchaseOrder>();
        }
        
        
        MYOB_RestResponseCollection.PurchaseOrderResponseBody myobOrdersResponse = (MYOB_RestResponseCollection.PurchaseOrderResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.PurchaseOrderResponseBody.class);
        List<MYOB_RestResponseCollection.PurchaseOrder> myobOrderItems = new List<MYOB_RestResponseCollection.PurchaseOrder>();
        
        if(myobOrdersResponse == NULL) {
            paramString = '';
            return new List<MYOB_RestResponseCollection.PurchaseOrder>();
        }
        else if(myobOrdersResponse.Items?.size() > 0 ){
            paramString = myobOrdersResponse.NextPageLink;
            paramString = paramString?.substringAfter('?');
            
            myobOrderItems =  myobOrdersResponse.Items;        
        }else{
            paramString = '';
            return new List<MYOB_RestResponseCollection.PurchaseOrder>();
        }
        return myobOrderItems;    
    }
    
    
    public void execute(Database.BatchableContext context, List<MYOB_RestResponseCollection.PurchaseOrder> myobPurchaseOrderList)
    {
        
        system.debug('Size: ' + myobPurchaseOrderList.size());
        
        List<Order> ordersForUpsert = new List<Order>();
        
        Map<String,Order> orderMap = new Map<String,Order>();
        Map<String,Order> orderMaptoUpdate = new Map<String,Order>();
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        Map<String,MYOB_OrderPrice> myobProdAmountMap = new Map<String,MYOB_OrderPrice>();
        
        Set<String> ordersUIDs = new Set<String>();
        Set<String> supplierUIDs = new Set<String>();
        Set<String> prodUIDS = new Set<String>();
        
        if(myobPurchaseOrderList != NULL && myobPurchaseOrderList.size() > 0){
            
            for(MYOB_RestResponseCollection.PurchaseOrder myobOdrItem : myobPurchaseOrderList) {
                ordersUIDs.add(myobOdrItem.UID);
                supplierUIDs.add(myobOdrItem.Supplier?.UID);
                
                for(MYOB_FlowParam_PurchaseOrderItemLine line : myobOdrItem.Lines){
                    //map the prices
                    MYOB_OrderPrice odrPrice = new MYOB_OrderPrice();
                    
                    if(myobOdrItem.ForeignCurrency != null){
                        odrPrice.UnitPrice = line.UnitPriceForeign;
                        odrPrice.CurrencyIsoCode = myobOdrItem.ForeignCurrency?.Code;
                    }else{
                        odrPrice.UnitPrice = line.UnitPrice;
                        odrPrice.CurrencyIsoCode = 'AUD';
                    }
                    
                    
                    myobProdAmountMap.put(line.Item.UID, odrPrice);
                    
                    
                }
                
                
            }
            
            //Upsert Accounts
            Map<String,Account> accountMYOBUIDMap = upsertAccounts(myobPurchaseOrderList, supplierUIDs, standardPB.Id);
            
            
            //Map the Existing Orders and compare the MYOB Row Version to check if it's been updated
            for(Order odr : [SELECT Id, MYOB_Row_Version__c, Accounting_External_Id__c, Status, Pricebook2Id FROM Order WHERE Accounting_External_Id__c IN : ordersUIDs]){
                orderMap.put(odr.Accounting_External_Id__c, odr);
            }
            
            //Upsert Locations
            Map<String, Schema.Location> myobLocationMap  = upsertLocations(myobPurchaseOrderList);
            Schema.Location loc = new Schema.Location();
            if(myobLocationMap.size() > 0){
                loc = myobLocationMap.values().get(0);  //get the first value of the Map for Order Warehouse
            }
            
            //Upsert Products
            Map<String,Product2> myobProdMap = upsertProducts(myobPurchaseOrderList, standardPB);
            
            //Create Pricebook Entries if no Pricebook Entries
            Map<String, PriceBookEntry> prodPBEntryMap = upsertPriceBookEntries(myobPurchaseOrderList, standardPB, myobProdMap, myobProdAmountMap);
            
            //Logic upserting the Order
            Id purchaseOrdRecTypeId = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
            
            for(MYOB_RestResponseCollection.PurchaseOrder myobOdrItem : myobPurchaseOrderList) {
                
                if(orderMap.containsKey(myobOdrItem.UID)){
                    //system.debug('UID to UPDATE: ' + myobOdrItem.UID);
                    if(orderMap.get(myobOdrItem.UID).MYOB_Row_Version__c != myobOdrItem.RowVersion){
                         
                        //Account should exist due to upsert a above
                        if(accountMYOBUIDMap.containsKey(myobOdrItem.Supplier?.UID)){
                            system.debug('UPDATE ORDER');
                            Order orderRecord = new Order();
                            orderRecord.AccountId = accountMYOBUIDMap.get(myobOdrItem.Supplier?.UID).Id;
                            orderRecord.recordTypeID = purchaseOrdRecTypeId;
                            orderRecord.MYOB_Number__c = myobOdrItem.Number_x;
                            orderRecord.EffectiveDate = Date.ValueOf(myobOdrItem.Date_x);
                            orderRecord.MYOB_Last_Sync_DateTime__c = system.now();
                            orderRecord.MYOB_Row_Version__c = myobOdrItem.RowVersion;
                            orderRecord.MYOB_Status__c = myobOdrItem.Status;
                            orderRecord.Accounting_External_Id__c = myobOdrItem.UID;
                            orderRecord.MYOB_UID__c = myobOdrItem.UID;
                            orderRecord.CurrencyIsoCode = myobOdrItem.ForeignCurrency != null ? myobOdrItem.ForeignCurrency.Code : 'AUD';
                            //orderRecord.Pricebook2Id = standardPB.Id;
                            //orderRecord.Status = 'Draft';
                            orderRecord.MYOB_Response__c = '';
                             
                            
                            for(MYOB_FlowParam_PurchaseOrderItemLine line : myobOdrItem.Lines){
                                
                                if(myobLocationMap.containsKey(line?.Location?.UID)){
                                    orderRecord.nao__Inventory_Location__c = myobLocationMap.get(line?.Location?.UID).Id;
                                    
                                }                
                                
                            }
                            
                        
                            orderMaptoUpdate.put(myobOdrItem.UID, orderRecord);
                        }
                        
                    }
                    
                }else{
                    //New Orders From MYOB 
                    //Account should exist due to upsert a above
                    if(accountMYOBUIDMap.containsKey(myobOdrItem.Supplier?.UID)){
                        system.debug('CREATE ORDER');
                        Order orderRecord = new Order();
                        orderRecord.AccountId = accountMYOBUIDMap.get(myobOdrItem.Supplier?.UID).Id;
                        orderRecord.recordTypeID = purchaseOrdRecTypeId;
                        orderRecord.MYOB_Number__c = myobOdrItem.Number_x;
                        orderRecord.EffectiveDate = Date.ValueOf(myobOdrItem.Date_x);
                        orderRecord.MYOB_Last_Sync_DateTime__c = system.now();
                        orderRecord.MYOB_Row_Version__c = myobOdrItem.RowVersion;
                        orderRecord.MYOB_Status__c = myobOdrItem.Status;
                        orderRecord.Accounting_External_Id__c = myobOdrItem.UID;
                        orderRecord.MYOB_UID__c = myobOdrItem.UID;
                        //orderRecord.Pricebook2Id = accountMYOBUIDMap.get(myobOdrItem.Supplier?.UID).nao__Supplier_Pricebook__c != null ? accountMYOBUIDMap.get(myobOdrItem.Supplier?.UID).nao__Supplier_Pricebook__c : standardPB.Id;
                        orderRecord.Pricebook2Id = standardPB.Id;
                        orderRecord.CurrencyIsoCode = myobOdrItem.ForeignCurrency != null ? myobOdrItem.ForeignCurrency.Code : 'AUD';
                        orderRecord.Status = 'Draft';
                        orderRecord.MYOB_Response__c = '';
                        
                        
                        for(MYOB_FlowParam_PurchaseOrderItemLine line : myobOdrItem.Lines){
                            
                            if(myobLocationMap.containsKey(line?.Location?.UID)){
                                orderRecord.nao__Inventory_Location__c = myobLocationMap.get(line?.Location?.UID).Id;
                                
                            }                
                            
                        }
                        
                        
                        orderMaptoUpdate.put(myobOdrItem.UID, orderRecord);
                    }
                }
                
         
                
            }
            system.debug('orderMaptoUpdate:' + JSON.serializePretty(orderMaptoUpdate));
            if(orderMaptoUpdate.size() > 0){
            try{
                    
                    //Upsert Order via External Id
                    upsert orderMaptoUpdate.values() Order.Accounting_External_Id__c;
                    
               		processLineItems(myobPurchaseOrderList, orderMaptoUpdate, accountMYOBUIDMap, myobProdMap, prodPBEntryMap);
                    
                
                }catch(Exception err){
                    Utilities.CreateExceptionLog(err,'MYOB_GetPurchaseOrdersBatch');
                }
             
            }
            
            
            
            
        }
    }
    
     
    
    
    
    public void finish(Database.BatchableContext context) {
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        if(MYOBProcessingSettings != NULL)
        {
            MYOBProcessingSettings.Purchase_Order_Sync_Date_Time__c = System.now();
            Database.Update(MYOBProcessingSettings);
        } 
        
        system.debug('finish paramString : ' + paramString);        
        if(paramString != '' && paramString != null){
            Database.executeBatch(new MYOB_GetPurchaseOrdersBatch(paramString)); 
            
        }else{
            //Reschedule then delete the previous job for cleaner 
            List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger 
                                               WHERE CronJobDetail.Name LIKE '%MYOB_GetPurchaseOrdersBatch%'];
            for (CronTrigger job : scheduledJobs) {
                try {
                    System.abortJob(job.Id);
                } catch (Exception e) {
                    System.debug('Job already processed or removed: ' + e.getMessage());
                }
            }
            Datetime nextRun = System.now().addMinutes(15);
            String cronStr = nextRun.format('s m H d M ? yyyy');
            //System.schedule('MYOB_GetPurchaseOrdersBatch', cronStr, new MYOB_PurchaseOrderBatchSchedulable());
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
    
    public Map<String, Schema.Location> upsertLocations(List<MYOB_RestResponseCollection.PurchaseOrder> myobPurchaseOrderList){
        
        Map<String,Schema.Location> myobLocationMap = new Map<String,Schema.Location>();
        //Set the Location for upsert
        for(MYOB_RestResponseCollection.PurchaseOrder myobOdrItem : myobPurchaseOrderList) {
            
            for(MYOB_FlowParam_PurchaseOrderItemLine line : myobOdrItem.Lines){
                
                Schema.Location loc = new Schema.Location();
                if(line?.Location != null){
                    if(!myobLocationMap.containsKey(line?.Location?.UID)){
                        
                        loc.External_Accounting_Id__c = line?.Location?.UID;
                        loc.Name = line?.Location?.Name;
                        loc.MYOB_Location_Id__c = line?.Location?.Identifier;
                        myobLocationMap.put(line?.Location?.UID, loc);
                        
                    }                
                }
                 
            }
            
        }
        
        system.debug('##########myobLocationMap: ' + myobLocationMap);
        //Upsert Location
        if(myobLocationMap.size() > 0){
            upsert myobLocationMap.values() Schema.Location.External_Accounting_Id__c;
        }
        
        
        return myobLocationMap;
    }
    
    public Map<String,Product2> upsertProducts(List<MYOB_RestResponseCollection.PurchaseOrder> myobPurchaseOrderList, PriceBook2 standardPB){
        
        Map<String,Product2> myobProdMap = new Map<String,Product2>();
        
      
        
        //Create Products
        for(MYOB_RestResponseCollection.PurchaseOrder myobOdrItem : myobPurchaseOrderList) {
            
            String currencyCode = '';
            if(myobOdrItem.ForeignCurrency != null){
                currencyCode = myobOdrItem.ForeignCurrency.Code;
            }else{
                currencyCode = 'AUD';
            }
            
            for(MYOB_FlowParam_PurchaseOrderItemLine line : myobOdrItem.Lines){
                
                if(myobProdMap.values() != null){
                    if(JSON.serialize(myobProdMap.values()).containsIgnoreCase(line.Item.UID)){
                        continue;
                    }
                }
                
                Product2 prod = new Product2();
                prod.Name = line.Item.Name; 
                prod.MYOB_Number__c = line.Item.Number_x;
                //prod.MYOB_UID__c = line.Item.UID;
                prod.Accounting_External_Id__c = line.Item.UID;
                prod.Currency__c = 'AUD';
                prod.Currency_Rate__c = 0.60;
                prod.Supplier_Discount__c = .25;
                prod.List_Price_Margin__c = .40;  
                prod.Description = line.Description;
                prod.MYOB_Last_Sync_DateTime__c = system.now();
                prod.ProductCode = line.Item.Name;
                
                myobProdMap.put(line.Item.UID + '_'  + currencyCode, prod);
                
                
                
            }
            
        }
        
        //system.debug('myobProdMap: ' + myobProdMap.values());
        //Upsert Products from MYOB Products
        upsert myobProdMap.values() Product2.Accounting_External_Id__c;
        
        
        

        
        return myobProdMap;
        
    }
    
    
    public Map<String,PriceBookEntry> upsertPriceBookEntries(List<MYOB_RestResponseCollection.PurchaseOrder> myobPurchaseOrderList, PriceBook2 standardPB, Map<String,Product2> myobProdMap, Map<String,MYOB_OrderPrice> myobProdAmountMap){
      
        //Create Pricebook Entries if no Pricebook Entries
        
        Map<String, PriceBookEntry> prodPBEntryMap = new Map<String, PriceBookEntry>();
        List<PriceBookEntry> PBEntriesToInsert = new List<PriceBookEntry>();
        List<PriceBookEntry> PBEntriesToUpdate = new List<PriceBookEntry>();
        List<PriceBookEntry> PBEntriesToUpsert = new List<PriceBookEntry>();
        
        
        Map<String, String> prodCurrencyMap = new Map<String, String>();
        for(PriceBookEntry pb : [SELECT Id, UnitPrice, Product2Id, CurrencyIsoCode, Product2.Accounting_External_Id__c FROM PriceBookEntry WHERE Product2Id IN : myobProdMap.values() AND PriceBook2.Name = 'Standard Price Book']){
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Id = pb.Id;
            pbe.UnitPrice = pb.UnitPrice;
            prodPBEntryMap.put(pb.Product2.Accounting_External_Id__c + '_' + pb.CurrencyIsoCode, pbe);
            
            
        }
        
        
        
        
        List<PriceBookEntry> pbEntries = new List<PriceBookEntry>();
        
        
        for(MYOB_RestResponseCollection.PurchaseOrder PurchaseOrder : myobPurchaseOrderList){
            String currencyCode = '';
            if(PurchaseOrder.ForeignCurrency != null){
                currencyCode = PurchaseOrder.ForeignCurrency.Code;
            }else{
                currencyCode = 'AUD';
            }
            for(MYOB_FlowParam_PurchaseOrderItemLine line : PurchaseOrder.Lines){
                
                //Create PriceBook Entry
                PriceBookEntry pbEntry = new PriceBookEntry();
                
                if(prodPBEntryMap.containsKey(line.Item.UID + '_' + currencyCode)){
                    //Update Existing PriceBook Entry
                    if(PBEntriesToUpsert.size() > 0){
                        if(JSON.serialize(PBEntriesToUpsert).contains(prodPBEntryMap.get(line.Item.UID + '_' + currencyCode).Id)){
                            continue;
                        }
                    }
                   
                    pbEntry.id = prodPBEntryMap.get(line.Item.UID + '_' + currencyCode).Id;
                    pbEntry.UnitPrice = myobProdAmountMap.get(line.Item.UID).UnitPrice;
                    
                    
                }else{
                    
                    pbEntry.Product2Id = myobProdMap.get(line.Item.UID + '_' + currencyCode).Id;
                    pbEntry.Pricebook2Id = standardPB.Id;
                    pbEntry.IsActive = true; 
                    pbEntry.UnitPrice = myobProdAmountMap.get(line.Item.UID).UnitPrice; 
                    pbEntry.CurrencyIsoCode = myobProdAmountMap.get(line.Item.UID).CurrencyIsoCode;
                    
                    
                    system.debug('myobProdMap Name: ' + myobProdMap.get(line.Item.UID + '_' + currencyCode).Name);
                    system.debug('pbEntry: ' + pbEntry);
                }
                
                
                PBEntriesToUpsert.add(pbEntry);
                //prodPBEntryMap.put(line.Item.UID + '_' + currencyCode, pbEntry);
                
                
                
            }
            
        }
        
        system.debug('PBEntriesToUpsert: ' + PBEntriesToUpsert);
        if(PBEntriesToUpsert.size() > 0){
            upsert PBEntriesToUpsert;
        }
         
        
        for(PriceBookEntry pb : [SELECT Id, CurrencyIsoCode, Product2.Accounting_External_Id__c FROM PriceBookEntry WHERE Id IN : PBEntriesToUpsert]){
            prodPBEntryMap.put(pb.Product2.Accounting_External_Id__c + '_' + pb.CurrencyIsoCode, pb);
            
            
        }
        
        system.debug('prodPBEntryMap: ' + JSON.serializePretty(prodPBEntryMap.values()));
     
        
        return prodPBEntryMap;
        
    }
    
    public Map<String,Account> upsertAccounts(List<MYOB_RestResponseCollection.PurchaseOrder> myobPurchaseOrderList, Set<String> supplierUIDs, String priceBookId){
        Map<String,Account> accountMYOBUIDMap = new Map<String, Account>();
        
        List<Account> accountList = [SELECT Id, Name, MYOB_Supplier_Id__c, nao__Supplier_Pricebook__c, nao__Account_Price_Book__c FROM Account WHERE MYOB_Supplier_Id__c IN : supplierUIDs];
        
        for(Account acc : accountList){
            
            if(acc.nao__Supplier_Pricebook__c == null)acc.nao__Supplier_Pricebook__c = priceBookId;
            if(acc.nao__Account_Price_Book__c == null)acc.nao__Account_Price_Book__c = priceBookId;
                
            accountMYOBUIDMap.put(acc.MYOB_Supplier_Id__c, acc);
            
        }
        
        
        //Upsert an account which is needed for Order Creation
        for(MYOB_RestResponseCollection.PurchaseOrder myobOdrItem : myobPurchaseOrderList) {
            
            if(!accountMYOBUIDMap.containsKey(myobOdrItem.Supplier?.UID)){
                
                Account acc = new Account();
                acc.MYOB_Supplier_Id__c = myobOdrItem.Supplier?.UID;
                acc.Name = myobOdrItem.Supplier?.Name;
                acc.nao__Account_Price_Book__c = priceBookId;
                acc.nao__Supplier_Pricebook__c = priceBookId;
                accountMYOBUIDMap.put(myobOdrItem.Supplier?.UID, acc);
                
            }else{
                
            } 
            
        }
        
        
        //insert the Accounts from map so that the Ids get auto populated
        upsert accountMYOBUIDMap.values();
        system.debug('accountMYOBUIDMap: ' + accountMYOBUIDMap);
        
        
        return accountMYOBUIDMap;
        
        
    }
    
    
    public void processLineItems(List<MYOB_RestResponseCollection.PurchaseOrder> myobOdrList, Map<String, Order> orderMap, Map<String, Account> myobAccountMap, Map<String, Product2> myobProdMap,  Map<String, PriceBookEntry> prodPBEntryMap ){
        
        Set<String> orderUIDs = new Set<String>(); 
        List<OrderItem> lineItemsToUpsert = new List<OrderItem>();
        
        //Remove OrderItme with no MYOB Row because they are not in MYOB
        /*
        List<OrderItem> odrITemToDelete = [SELECT Id FROM OrderItem WHERE OrderId IN : orderMap.values()];
        system.debug('##odrITemToDelete: ' + odrITemToDelete);
        if(odrITemToDelete.size() > 0){
            delete odrITemToDelete;
        }
        */
        
        
        List<Order> orderList = [SELECT Id, Accounting_External_Id__c FROM Order WHERE Accounting_External_Id__c IN: orderMap.KeySet()]; 
        
        for(MYOB_RestResponseCollection.PurchaseOrder PurchaseOrder : myobOdrList){
            
            String currencyCode = '';
            if(PurchaseOrder.ForeignCurrency != null){
                currencyCode = PurchaseOrder.ForeignCurrency.Code;
            }else{
                currencyCode = 'AUD';
            }
            
            
            for(MYOB_FlowParam_PurchaseOrderItemLine line : PurchaseOrder.Lines){
                
                if(orderMap.containsKey(PurchaseOrder.UID)){
                    
                    system.debug('PurchaseOrder.line: ' + line);
                    
                    OrderItem item = new OrderItem();
                    item.OrderId = orderMap.get(PurchaseOrder.UID).Id;
                    item.UnitPrice = line.UnitPrice;
                    item.MYOB_Row_Version__c = String.valueOf(line.RowVersion);
                    item.Quantity = line.BillQuantity; 
                    item.nao__Amount_Received__c = line.ReceivedQuantity;
                    item.MYOB_Row_Id__c = PurchaseOrder.UID + '_' + String.valueOf(line.RowID);
                    
                    //item.Product2Id = myobProdMap.get(line.Item.UID).Id;
                    item.Product2Id = prodPBEntryMap.get(line.Item.UID + '_' + currencyCode).Product2Id;
                    item.PricebookEntryId = prodPBEntryMap.get(line.Item.UID + '_' + currencyCode).Id;
                    
                    lineItemsToUpsert.add(item);
                }
                
                
            }
            
        }
        
        
        if(lineItemsToUpsert.size() > 0){ 
            
            //upsert line item with external Id   
            system.debug('Lines to Upsert: ' + lineItemsToUpsert); 
            upsert lineItemsToUpsert OrderItem.MYOB_Row_Id__c;
            
            
            
            
        }
        
        
    }
    
    public Date getDateValue(string dt){
        if(dt == '' || dt == NULL) return NULL;
        return Date.valueOf(dt);
    }
    
    public class MYOB_OrderPrice{
        public Decimal UnitPrice;
        public String CurrencyIsoCode;
    }
    
    
}