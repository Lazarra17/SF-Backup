/*
 * Author: 			Bricoleur Technologies
 * Created Date: 	July 22, 2021
 * Description: 	Batchable Class for Retrieving Xero Quotes
 * Test Class: 		N/A
 * History: 		July 22, 2021 - Creation
 */
public class XeroGetQuoteBatch implements Database.Batchable<RestResponseCollectionXero.Quote>,Database.AllowsCallouts, Database.Stateful
{
        
    public Iterable<RestResponseCollectionXero.Quote> start(Database.BatchableContext context)
    {   
        
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        String tenantId = apiSettings?.TenantID__c;
        String endpoint = apiSettings?.Endpoint__c;
        
        XeroQuoteBatchSettings__c xeroQuoteSettings = XeroQuoteBatchSettings__c.getOrgDefaults();
        String modifiedSince = getUTCDateTime(xeroQuoteSettings?.LastSycnedDateTime__c);

        if(apiSettings == NULL || tenantId == NULL || endpoint == NULL) return new List<RestResponseCollectionXero.Quote>();
        
        Map<String , String> requestHeader = XeroRequestUtilities.ConstructRequestHeaders(tenantId);
        requestHeader.put(CONSTANTS_BRIC.INTEGRATION_XERO_HEADER_KEY_IF_MODIFIED_SINCE,modifiedSince);

        HttpResponse response = RestHandler.ExecuteRequest(requestHeader,endpoint + CONSTANTS_BRIC.INTEGRATION_XERO_ENDPOINT_QUOTES,null,CONSTANTS_BRIC.INTEGRATION_REST_METHOD_GET);
        String responseBodyString = response?.getBody();

        if(!XeroRequestUtilities.CheckResponseBodyValidity(response?.getStatusCode() , responseBodyString)) return new List<RestResponseCollectionXero.Quote>();
        
        RestResponseCollectionXero.PostQuoteResponseBody responseBody = (RestResponseCollectionXero.PostQuoteResponseBody)JSON.deserialize(responseBodyString, RestResponseCollectionXero.PostQuoteResponseBody.class) ;
        
       
        if(responseBody == NULL) return new List<RestResponseCollectionXero.Quote>();
        system.debug('responseBody.Quotes ::: ' + responseBody.Quotes);
        return responseBody.Quotes;
        
    }
    
    public void execute(Database.BatchableContext context, List<RestResponseCollectionXero.Quote> xeroQuoteList) {
        if(xeroQuoteList != NULL && xeroQuoteList.size() > 0) UpdateQuoteAndLineItemsFromXeroQuote(xeroQuoteList);
    }
    
    public static Boolean UpdateQuoteAndLineItemsFromXeroQuote(List<RestResponseCollectionXero.Quote> quoteList)
    {
        
        Boolean isSuccess;
        Savepoint sp = Database.setSavepoint();
        
        //GET Product2ID
        Map<String,PriceBookEntry> productXeroItemCodeMap = new Map<String,PriceBookEntry>();
        Map<String,String> productToPricebookMap = new Map<String,String>();
        for(PriceBookEntry pbe :  [SELECT Id, Product2Id, Product2.Id, Product2.ProductCode,PriceBook2.Id,PriceBook2.IsStandard 
                                   FROM PriceBookEntry 
                                   WHERE Product2.ProductCode != NULL
                                   AND IsActive = TRUE])
        {
            if(pbe.Product2.ProductCode != NULL && pbe.Product2.ProductCode != ''){
                String key = pbe.PriceBook2.Id +'-'+pbe.Product2.ProductCode;
                productXeroItemCodeMap.put(key,pbe);
                
                if(!pbe.PriceBook2.IsStandard){
                    productToPricebookMap.put(pbe.Product2.ProductCode,pbe.PriceBook2.Id);                    
                }
            }
        }

        //GET Quote
        Map<String,Quote> xeroQuoteMap = new Map<String,Quote>();
        for(Quote quoteItem :  [SELECT Id, Xero_Quote_Id__c,Pricebook2Id
                                FROM Quote 
                                WHERE Xero_Quote_Id__c != NULL])
        {
            if(quoteItem.Xero_Quote_Id__c != NULL && quoteItem.Xero_Quote_Id__c != ''){
                xeroQuoteMap.put(quoteItem.Xero_Quote_Id__c,quoteItem);
            }
        }
        
        //GET Opportunity
        Map<String,Opportunity> xeroOppMap = new Map<String,Opportunity>();
        for(Opportunity oppItem :  [SELECT Id, Name,PriceBook2Id,Xero_Reference__c FROM Opportunity
                                   WHERE Xero_Reference__c != '' AND Xero_Reference__c != null])
        {
            xeroOppMap.put(oppItem.Xero_Reference__c,oppItem);
        }   
        
        List<Quote> quoteListToUpdate = new List<Quote>();
        List<QuoteLineItem> quoteLineItemToUpdateList = new List<QuoteLineItem>();
        Set<Id> quoteIds = new Set<Id>();
        
        for(RestResponseCollectionXero.Quote quote : quoteList){
            Quote quoteRecordToUpdate = new Quote();       
            quoteRecordToUpdate.Id = xeroQuoteMap.get(quote.QuoteID)?.Id;
            quoteRecordToUpdate.Xero_Quote_ID__c = quote.QuoteID;
            quoteRecordToUpdate.Xero_Quote_Number__c = quote.QuoteNumber;
            quoteRecordToUpdate.Name = quote.QuoteNumber;
            quoteRecordToUpdate.ExpirationDate = Date.valueOf(quote.DateString?.replace(CONSTANTS_BRIC.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS_BRIC.GENERIC_BLANK));
            quoteRecordToUpdate.Description = quote.Summary?.abbreviate(32000);
            if(!String.isBlank(quote.Title)) quoteRecordToUpdate.Title__c = quote.Title;
            quoteRecordToUpdate.Terms__c = quote.Terms;
            quoteRecordToUpdate.Tax = quote.TotalTax;            
            if(!String.isBlank(quote.DateString)) quoteRecordToUpdate.Issued_Date__c = Date.valueOf(quote.DateString?.replace(CONSTANTS_BRIC.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS_BRIC.GENERIC_BLANK));
            if(!String.isBlank(quote.ExpiryDateString)) quoteRecordToUpdate.ExpirationDate = Date.valueOf(quote.ExpiryDateString?.replace(CONSTANTS_BRIC.XERO_OBJECT_INVOICE_DUE_DATE_EXTENSION , CONSTANTS_BRIC.GENERIC_BLANK));
            quoteRecordToUpdate.Status = quote.Status;     
            
            if(quoteRecordToUpdate.Id == null){
                quoteRecordToUpdate.OpportunityId = xeroOppMap.get(quote.Reference)?.Id;
                quoteRecordToUpdate.PriceBook2Id = xeroOppMap.get(quote.Reference)?.PriceBook2Id;                
                quoteRecordToUpdate.Name = quote.QuoteNumber;
            }
            
            if(xeroOppMap.get(quote.Reference)?.Id != null){
                quoteListToUpdate.add(quoteRecordToUpdate);
            }
        }
        
        if(!quoteListToUpdate.isEmpty()) Database.Upsert(quoteListToUpdate,false);

        //GET Latest Quotes
        for(Quote quoteItem :  [SELECT Id, Xero_Quote_Id__c,Pricebook2Id
                                FROM Quote 
                                WHERE Xero_Quote_Id__c != NULL])
        {
            if(quoteItem.Xero_Quote_Id__c != NULL && quoteItem.Xero_Quote_Id__c != ''){
                xeroQuoteMap.put(quoteItem.Xero_Quote_Id__c,quoteItem);
            }
        }
        
        for(RestResponseCollectionXero.Quote quote : quoteList){
            for(RestResponseCollectionXero.LineItem quoteLineItem : quote.LineItems)
            {
                if(quoteLineItem.Description != 'Placeholder'  && quoteLineItem.ItemCode != null && quoteLineItem.ItemCode != ''){
                    QuoteLineItem quoteLineItemToUpdate = new QuoteLineItem();
                    quoteLineItemToUpdate.XeroId__c = quoteLineItem.LineItemID;                
                    quoteLineItemToUpdate.Quantity = quoteLineItem.Quantity != null && quoteLineItem.Quantity != 0 ? quoteLineItem.Quantity : 1;
                    quoteLineItemToUpdate.UnitPrice = quoteLineItem.UnitAmount != null ? quoteLineItem.UnitAmount : 0;
                    quoteLineItemToUpdate.Description = quoteLineItem.Description?.abbreviate(255);
                    quoteLineItemToUpdate.QuoteId = xeroQuoteMap.get(quote.QuoteID)?.Id;  
                    quoteLineItemToUpdate.Discount = quoteLineItem.DiscountRate;
                    
                    String key = xeroQuoteMap.get(quote.QuoteID)?.PriceBook2Id +'-'+ quoteLineItem.ItemCode;                   
                    quoteLineItemToUpdate.PricebookEntryId = productXeroItemCodeMap.get(key)?.Id;
                    quoteLineItemToUpdateList.add(quoteLineItemToUpdate);
                    
                    quoteIds.add(quoteLineItemToUpdate.QuoteId);
                }
            }
        }
        try
        {
            //GET QuoteLineItems
            List<QuoteLineItem> quoteLineCurrent = [SELECT Id, QuoteId 
                                                    FROM QuoteLineItem
                                                    WHERE QuoteId IN :quoteIds];
            
            if(!quoteLineCurrent.isEmpty()) Database.Delete(quoteLineCurrent,false);
            if(!quoteLineItemToUpdateList.isEmpty()) Database.Insert(quoteLineItemToUpdateList,false);
            isSuccess = true;
        }
        catch(Exception err)
        {
            Database.rollback(sp);
            Utilities_Bric.CreateExceptionLog(err);
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
    public void finish(Database.BatchableContext context) {
        XeroQuoteBatchSettings__c xeroQuoteSettings = XeroQuoteBatchSettings__c.getOrgDefaults();
        if(xeroQuoteSettings != NULL)
        {
            xeroQuoteSettings.LastSycnedDateTime__c = System.now();
            Database.Update(xeroQuoteSettings);
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