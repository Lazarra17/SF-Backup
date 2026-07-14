/*
* @Author: Bricoleur Technology
* @Date: March 5, 2026
* @Desc:
*
*/
public class MYOB_GetOrdersBatch implements Database.Batchable<MYOB_RestResponseCollection.SalesOrder>,Database.AllowsCallouts, Database.Stateful
{
    
    public String paramString;
    
    public MYOB_GetOrdersBatch(String params){
        
        paramString = params;
        
    }
    
    public Iterable<MYOB_RestResponseCollection.SalesOrder> start(Database.BatchableContext context)
    {   
        
        MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                             FROM MYOB_API_Setting__mdt
                                             WHERE DeveloperName = 'Default'];
        String clientID = apiSettings?.Client_ID__c;
        String endpoint = apiSettings?.Endpoint__c;
        String companyFileID = apiSettings?.Company_File_ID__c;
        
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        String modifiedSince = getUTCDateTime(MYOBProcessingSettings?.Sales_Order_Sync_Date_Time__c.addMinutes(-30));
        
        if(apiSettings == NULL || endpoint == NULL || modifiedSince == NULL) return new List<MYOB_RestResponseCollection.SalesOrder>();
        
        Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
        
        String lastModifiedParam = '';        
        lastModifiedParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_LASTMODIFIED + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_DATETIME +
                                                   MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + modifiedSince +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        if(paramString == '') paramString = MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + lastModifiedParam;
        
        system.debug('paramString: ' + paramString);
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM + '/'
                                                              + '?' + paramString, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();  
        
        //system.debug('getResponseBodyString: '+ getResponseBodyString);
        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET, null, getResponse?.getBody(), getResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM
                                           + '?' +paramString);
        
        Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X,
            MYOB_CONSTANTS.INTEGRATION_KEY_TYPE => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X,
            MYOB_CONSTANTS.INTEGRATION_KEY_DATE => MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X};   
                getResponseBodyString = MYOB_RequestUtilities.FormatJSONBodyString(getResponseBodyString , requestBodyReplacementList);
        
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)){ 
            paramString = '';
            return new List<MYOB_RestResponseCollection.SalesOrder>();
        }
        
        
        MYOB_RestResponseCollection.SalesOrderResponseBody myobOrdersResponse = (MYOB_RestResponseCollection.SalesOrderResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.SalesOrderResponseBody.class);
        List<MYOB_RestResponseCollection.SalesOrder> myobOrderItems = new List<MYOB_RestResponseCollection.SalesOrder>();
        
        if(myobOrdersResponse == NULL) {
            paramString = '';
            return new List<MYOB_RestResponseCollection.SalesOrder>();
        }
        else if(myobOrdersResponse.Items?.size() > 0 ){
            paramString = myobOrdersResponse.NextPageLink;
            paramString = paramString?.substringAfter('?');
            
            myobOrderItems =  myobOrdersResponse.Items;        
        }else{
            paramString = '';
            return new List<MYOB_RestResponseCollection.SalesOrder>();
        }
        return myobOrderItems;    
    }
    
    
    public void execute(Database.BatchableContext context, List<MYOB_RestResponseCollection.SalesOrder> myobSalesOrderList)
    {
        
        system.debug('Size: ' + myobSalesOrderList.size());
        
        List<Order> ordersForUpsert = new List<Order>();
        
        Map<String,Order> orderMap = new Map<String,Order>();
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        Map<String,MYOB_OrderPrice> myobProdAmountMap = new Map<String,MYOB_OrderPrice>();
        
        Set<String> ordersUIDs = new Set<String>();
        Set<String> customerUIDs = new Set<String>();
        Set<String> prodUIDS = new Set<String>();
        
       
        
        if(myobSalesOrderList != NULL && myobSalesOrderList.size() > 0){
            
            for(MYOB_RestResponseCollection.SalesOrder myobOdrItem : myobSalesOrderList) {
                ordersUIDs.add(myobOdrItem.UID);
                customerUIDs.add(myobOdrItem.Customer?.UID);
                
                for(MYOB_RestResponseCollection.OrderLines line : myobOdrItem.Lines){
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
            Map<String,Account> accountMYOBUIDMap = upsertAccounts(myobSalesOrderList, customerUIDs, standardPB.Id);
            
            //Map the Existing Orders and compare the MYOB Row Version to check if it's been updated
            for(Order odr : [SELECT Id, MYOB_Row_Version__c, Accounting_External_Id__c, Status, Pricebook2Id FROM Order WHERE Accounting_External_Id__c IN : ordersUIDs]){
                orderMap.put(odr.Accounting_External_Id__c, odr);
            }
            
            //Upsert Locations
            Map<String, Schema.Location> myobLocationMap  = upsertLocations(myobSalesOrderList);
            Schema.Location loc = new Schema.Location();
            if(myobLocationMap.size() > 0){
                loc = myobLocationMap.values().get(0);  //get the first value of the Map for Order Warehouse
            }
            
            //Upsert Products
            Map<String,Product2> myobProdMap = upsertProducts(myobSalesOrderList, standardPB);
            
            //Create Pricebook Entries if no Pricebook Entries
            Map<String, PriceBookEntry> prodPBEntryMap = upsertPriceBookEntries(myobSalesOrderList, standardPB, myobProdMap, myobProdAmountMap);
            
            //Logic upserting the Order
            Id salesOrdRecTypeId = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Sales_Order').getRecordTypeId();
            for(MYOB_RestResponseCollection.SalesOrder myobOdrItem : myobSalesOrderList) {
                
                //Account should exist due to upsert a above
                if(accountMYOBUIDMap.containsKey(myobOdrItem.Customer?.UID)){
                    
                    Order orderRecord = new Order();
                    orderRecord.AccountId = accountMYOBUIDMap.get(myobOdrItem.Customer?.UID).Id;
                    
                    //New Order status should be Draft
                    if(!orderMap.containsKey(myobOdrItem.UID)){
                        system.debug('## DOES NOT EXIST');
                        orderRecord.Status = 'Draft';
                     }
                    orderRecord.recordTypeID = salesOrdRecTypeId;
                    
                    orderRecord.PoNumber = myobOdrItem.CustomerPurchaseOrderNumber;
                    orderRecord.MYOB_Number__c = myobOdrItem.Number_x;
                    orderRecord.EffectiveDate = Date.valueOf(myobOdrItem.Date_x);
                    orderRecord.MYOB_Last_Sync_DateTime__c = system.now();
                    orderRecord.MYOB_Row_Version__c = myobOdrItem.RowVersion;
                    orderRecord.MYOB_Status__c = myobOdrItem.Status;
                    orderRecord.Accounting_External_Id__c = myobOdrItem.UID;
                    orderRecord.MYOB_UID__c = myobOdrItem.UID;
                    orderRecord.Pricebook2Id = standardPB.Id;
                    orderRecord.CurrencyIsoCode = myobOdrItem.ForeignCurrency != null ? myobOdrItem.ForeignCurrency.Code : 'AUD';
                    orderRecord.MYOB_Response__c = '';
                    
                    
                    for(MYOB_RestResponseCollection.OrderLines line : myobOdrItem.Lines){
                        
                        if(myobLocationMap.containsKey(line?.Location?.UID)){
                            orderRecord.nao__Inventory_Location__c = myobLocationMap.get(line?.Location?.UID).Id;
                            
                        }                
                        
                    }
                    
                    if(myobOdrItem.Status == 'ConvertedToInvoice'){
                        orderRecord.MYOB_Order_Invoiced__c = true;
                    }
                    orderMap.put(myobOdrItem.UID, orderRecord);
                }
                
            }
            
            if(orderMap.size() > 0){
                try{
                    system.debug('orderMap:'+orderMap);
                    //Upsert Order via External Id
                    upsert orderMap.values() Order.Accounting_External_Id__c;
                    
                  	processLineItems(myobSalesOrderList, orderMap, accountMYOBUIDMap, myobProdMap, prodPBEntryMap);
                    
                    
                }catch(Exception err){
                    Utilities.CreateExceptionLog(err,'MYOB_GetOrdersBatch');
                }
            }
            
            
            
            
        }
    }
    
    
    
    
    
    public void finish(Database.BatchableContext context) {
        MYOBProcessingSettings__c MYOBProcessingSettings = MYOBProcessingSettings__c.getOrgDefaults();
        if(MYOBProcessingSettings != NULL)
        {
            MYOBProcessingSettings.Sales_Order_Sync_Date_Time__c = System.now();
           // Database.Update(MYOBProcessingSettings);
        } 
        
        system.debug('finish paramString : ' + paramString);        
        if(paramString != '' && paramString != null){
            Database.executeBatch(new MYOB_GetOrdersBatch(paramString)); 
            
        }else{
            //Reschedule then delete the previous job for cleaner 
            List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger 
                                               WHERE CronJobDetail.Name LIKE '%MYOB_GetOrdersBatch%'];
            for (CronTrigger job : scheduledJobs) {
                try {
                    System.abortJob(job.Id);
                } catch (Exception e) {
                    System.debug('Job already processed or removed: ' + e.getMessage());
                }
            }
            Datetime nextRun = System.now().addMinutes(15);
            String cronStr = nextRun.format('s m H d M ? yyyy');
            //System.schedule('MYOB_GetOrdersBatch', cronStr, new MYOB_OrderBatchSchedulable());
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
    
    public Map<String, Schema.Location> upsertLocations(List<MYOB_RestResponseCollection.SalesOrder> myobSalesOrderList){
        
        Map<String,Schema.Location> myobLocationMap = new Map<String,Schema.Location>();
        //Set the Location for upsert
        for(MYOB_RestResponseCollection.SalesOrder myobOdrItem : myobSalesOrderList) {
            
            for(MYOB_RestResponseCollection.OrderLines line : myobOdrItem.Lines){
                
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
    
    public Map<String,Product2> upsertProducts(List<MYOB_RestResponseCollection.SalesOrder> myobSalesOrderList, PriceBook2 standardPB){
        
        Map<String,Product2> myobProdMap = new Map<String,Product2>();
        
      
        
        //Create Products
        for(MYOB_RestResponseCollection.SalesOrder myobOdrItem : myobSalesOrderList) {
            
            //Checks the currency code
            String currencyCode = '';
            if(myobOdrItem.ForeignCurrency != null){
                currencyCode = myobOdrItem.ForeignCurrency.Code;
            }else{
                currencyCode = 'AUD';
            }
            
            
            for(MYOB_RestResponseCollection.OrderLines line : myobOdrItem.Lines){
                
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
        
        system.debug('myobProdMap: ' + myobProdMap.values());
        //Upsert Products from MYOB Products
        upsert myobProdMap.values() Product2.Accounting_External_Id__c;
        
        
        

        
        return myobProdMap;
        
    }
    
    
    public Map<String,PriceBookEntry> upsertPriceBookEntries(List<MYOB_RestResponseCollection.SalesOrder> myobSalesOrderList, PriceBook2 standardPB, Map<String,Product2> myobProdMap, Map<String,MYOB_OrderPrice> myobProdAmountMap){
     
        
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
        
        
        for(MYOB_RestResponseCollection.SalesOrder SalesOrder : myobSalesOrderList){
            String currencyCode = '';
            if(SalesOrder.ForeignCurrency != null){
                currencyCode = SalesOrder.ForeignCurrency.Code;
            }else{
                currencyCode = 'AUD';
            }
            for(MYOB_RestResponseCollection.OrderLines line : SalesOrder.Lines){
                
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
    
    public Map<String,Account> upsertAccounts(List<MYOB_RestResponseCollection.SalesOrder> myobSalesOrderList, Set<String> customerUIDs, String priceBookId){
        Map<String,Account> accountMYOBUIDMap = new Map<String, Account>();
        
                List<Account> accountList = [SELECT Id, Name, MYOB_GUID__c, External_Accounting_Id__c, nao__Supplier_Pricebook__c, nao__Account_Price_Book__c FROM Account WHERE External_Accounting_Id__c IN : customerUIDs];
        
        for(Account acc : accountList){
            if(acc.nao__Supplier_Pricebook__c == null)acc.nao__Supplier_Pricebook__c = priceBookId;
            if(acc.nao__Account_Price_Book__c == null)acc.nao__Account_Price_Book__c = priceBookId;
            accountMYOBUIDMap.put(acc.External_Accounting_Id__c, acc);
            
            
        }
        
        
        //Upsert an account which is needed for Order Creation
        for(MYOB_RestResponseCollection.SalesOrder myobOdrItem : myobSalesOrderList) {
            
            if(!accountMYOBUIDMap.containsKey(myobOdrItem.Customer?.UID)){
                
                Account acc = new Account();
                acc.MYOB_GUID__c = myobOdrItem.Customer?.UID;
                acc.External_Accounting_Id__c = myobOdrItem.Customer?.UID;
                acc.Name = myobOdrItem.Customer?.Name;
                accountMYOBUIDMap.put(myobOdrItem.Customer?.UID, acc);
                
            } 
            
        }
        
        
        //insert the Accounts from map so that the Ids get auto populated
        upsert accountMYOBUIDMap.values();
        system.debug('accountMYOBUIDMap: ' + accountMYOBUIDMap);
        
        
        return accountMYOBUIDMap;
        
        
    }
    
    
    public void processLineItems(List<MYOB_RestResponseCollection.SalesOrder> myobOdrList, Map<String, Order> orderMap, Map<String, Account> myobAccountMap, Map<String, Product2> myobProdMap,  Map<String, PriceBookEntry> prodPBEntryMap){
        
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
        
        
        for(MYOB_RestResponseCollection.SalesOrder salesOrder : myobOdrList){
            system.debug('salesOrder.Lines: ' + salesOrder.Lines);
            
            String currencyCode = '';
            if(salesOrder.ForeignCurrency != null){
                currencyCode = salesOrder.ForeignCurrency.Code;
            }else{
                currencyCode = 'AUD';
            }
            
            for(MYOB_RestResponseCollection.OrderLines line : salesOrder.Lines){
                
                if(orderMap.containsKey(salesOrder.UID)){
                    OrderItem item = new OrderItem();
                    item.OrderId = orderMap.get(salesOrder.UID).Id;
                    item.UnitPrice = line.UnitPrice;
                    item.MYOB_Row_Id__c = salesOrder.UID + '_' + String.valueOf(line.RowID);
                    item.MYOB_Row_Version__c = String.valueOf(line.RowVersion);
                    item.Quantity = line.ShipQuantity; 
                    
                    /*
                    item.Product2Id = myobProdMap.get(line.Item.UID).Id;
                    item.PricebookEntryId = priceBookEntryMap.get(myobProdMap.get(line.Item.UID).Id).Id;
                    */
                    item.Product2Id = prodPBEntryMap.get(line.Item.UID + '_' + currencyCode).Product2Id;
                    item.PricebookEntryId = prodPBEntryMap.get(line.Item.UID + '_' + currencyCode).Id;
                    
                    
                    lineItemsToUpsert.add(item);
                }
                
                
            }
            
        }
        
        
        if(lineItemsToUpsert.size() > 0){ 
         
                //upsert line item with external Id    
                upsert lineItemsToUpsert OrderItem.MYOB_Row_Id__c;
                system.debug('Lines to Upsert: ' + lineItemsToUpsert);
            
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