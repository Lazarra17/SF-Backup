/*
* Author: Bricoleur Technologies 
* Created Date: Feb 26, 2025
* Description: Helper class for trigger MYOB Trigger Hanlder
*/

public class MYOB_InvoiceTriggerHandlerHelper {
    
    
    public static void upsertNaoInvoices(List<MYOB_Invoice__c> newInvoices, Set<String> myobInvoiceIdsSet){
        
        Map<String, MYOB_Invoice__c> myobInvoiceMap = new Map<String, MYOB_Invoice__c>();
        Map<String, nao__Invoice__c> naoInvoiceMap = new Map<String, nao__Invoice__c>();
        Map<String, Order> myobOrdersMap = new Map<String, Order>();
        Set<String> myobOrderUIdSet = new Set<String>();
        for(MYOB_Invoice__c inv : newInvoices){
            myobOrderUIdSet.add(inv.Sales_Order_Id_bric__c);
            
        }
        
        //Map Sales Order MYOB
        for(Order odr : [SELECT Id, Accounting_External_Id__c FROM Order WHERE Accounting_External_Id__c IN : myobOrderUIdSet]){
            myobOrdersMap.put(odr.Accounting_External_Id__c, odr);
        }
        
        //query MYOB invoice LINES to map and compare later for MYOB Invoice
        for(MYOB_Invoice__c inv : newInvoices){
            
            
            Id invRecType = Schema.SObjectType.nao__Invoice__c.getRecordTypeInfosByDeveloperName().get('Invoice').getRecordTypeId();
            nao__Invoice__c newInv = new nao__Invoice__c();
            
            newInv.RecordTypeId = invRecType;
            newInv.External_Accounting_Id__c = inv.MYOB_UID_bric__c;
            newInv.nao__Account_Bric__c = inv.Customer_bric__c;
            newInv.nao__Status_Bric__c = inv.Status_bric__c;
            newInv.nao__Type_Bric__c = 'Invoice';
            newInv.nao__Invoice_Date_bric__c = inv.Invoice_Date_bric__c;
            newInv.nao__PO_Number_bric__c = inv.CustomerPurchaseOrderNumber_bric__c;
            newInv.nao__Amount_Paid__c = inv.TotalAmount_bric__c - inv.Balance_Due_Amount_bric__c;
            newInv.nao__Invoice_Due_Date__c = inv.Promised_Date_bric__c;
            newInv.Balance_Due_Amount__c = inv.Balance_Due_Amount_bric__c;
            newInv.Last_Payment_Date__c = inv.Last_Payment_Date_bric__c;
            newInv.nao__Notes_Bric__c = inv.Journal_Memo_Bric__c;
            newInv.nao__Shipping_Street_Bric__c = inv.Ship_To_Address_bric__c;
            newInv.MYOB_Last_Sync_DateTime__c = system.now();
            //get the correct Order and relate it
            if(myobOrdersMap.containsKey(inv.Sales_Order_Id_bric__c)){
                newInv.nao__Order_Bric__c = myobOrdersMap.get(inv.Sales_Order_Id_bric__c).Id;
            }
            
            
            naoInvoiceMap.put(inv.MYOB_UID_bric__c, newInv);
            
            
            
        }
        
        
        
        
        if(naoInvoiceMap.size() > 0){
            upsert naoInvoiceMap.values() External_Accounting_Id__c;
            
            //Update line items
            updateNaoInvoiceLines(naoInvoiceMap, myobInvoiceIdsSet);
            
        }
        
        
       
        
    }
    
    
    
   
    public static void updateNaoInvoices(List<MYOB_Invoice__c> newInvoices, Set<String> myobInvoiceIdsSet){
        
        Map<String, MYOB_Invoice__c> myobInvoiceMap = new Map<String, MYOB_Invoice__c>();
        Map<String, nao__Invoice__c> naoInvoiceMap = new Map<String, nao__Invoice__c>();
        
        
        //query nao invoice LINES to map and compare later for MYOB Invoice
        for(nao__Invoice__c inv : [SELECT Id, External_Accounting_Id__c, nao__Amount_Paid__c, Last_Payment_Date__c
                                           FROM nao__Invoice__c WHERE External_Accounting_Id__c IN : myobInvoiceIdsSet]){
                                               
                                               naoInvoiceMap.put(inv.External_Accounting_Id__c, inv);
                                               
                                           }
        
        
        //query MYOB invoice LINES to map and compare later for MYOB Invoice
        for(MYOB_Invoice__c inv : newInvoices){
            
            if(inv.MYOB_UID_bric__c != ''){
                myobInvoiceMap.put(inv.MYOB_UID_bric__c, inv);
            }
            
            
        }
        
        for(String uid : naoInvoiceMap.keySet()){
            
            if(myobInvoiceMap.containsKey(uid)){
                naoInvoiceMap.get(uid).nao__Amount_Paid__c = myobInvoiceMap.get(uid).TotalAmount_bric__c - myobInvoiceMap.get(uid).Balance_Due_Amount_bric__c;
                naoInvoiceMap.get(uid).Balance_Due_Amount__c = myobInvoiceMap.get(uid).Balance_Due_Amount_bric__c;
                
                naoInvoiceMap.get(uid).Last_Payment_Date__c = myobInvoiceMap.get(uid).Last_Payment_Date_bric__c;
                
            }
            
            
        }
        
        
        if(naoInvoiceMap.size() > 0){
            update naoInvoiceMap.values();
            
            //Update line items
            updateNaoInvoiceLines(naoInvoiceMap, myobInvoiceIdsSet);
            
        }
        
        
       
        
    }
    
    public static void updateNaoInvoiceLines(Map<String, nao__Invoice__c> naoInvoiceMap, Set<String> myobInvoiceIdsSet){
        Map<String, MYOB_Invoice_Line_Item__c> myobInvoiceLinesMap = new Map<String, MYOB_Invoice_Line_Item__c>();
        Map<String, nao__Invoice_Lines__c> naoInvoiceLinesMap = new Map<String, nao__Invoice_Lines__c>();
        List<nao__Invoice_Lines__c> invoiceLinestoUpsert = new List<nao__Invoice_Lines__c>();
        
        
        //query MYOB invoice LINES to map and compare later for MYOB Invoice
        for(MYOB_Invoice_Line_Item__c line : [SELECT Id, Row_ID_bric__c, Cost_Of_Goods_Sold_bric__c, Description_Bric__c, Discount_Percent_bric__c, 
                                              Ship_Quantity_bric__c, Unit_Count_bric__c, Unit_Of_Measure_bric__c, MYOB_Invoice__r.MYOB_UID_bric__c,
                                              Unit_Price_bric__c, Total_Bric__c 
                                              FROM MYOB_Invoice_Line_Item__c WHERE MYOB_Invoice__r.MYOB_UID_bric__c IN : myobInvoiceIdsSet]){
                                                  
                                                  if(naoInvoiceMap.containsKey(line.MYOB_Invoice__r.MYOB_UID_bric__c)){
                                                      
                                                      nao__Invoice_Lines__c naoInvoiceLine = new nao__Invoice_Lines__c();
                                                      naoInvoiceLine.nao__Invoice_bric__c = naoInvoiceMap.get(line.MYOB_Invoice__r.MYOB_UID_bric__c).Id;
                                                      naoInvoiceLine.nao__Quantity_bric__c = line.Ship_Quantity_bric__c;
                                                      naoInvoiceLine.nao__Description_Bric__c = line.Description_Bric__c;
                                                      naoInvoiceLine.nao__Amount_Bric__c = line.Total_Bric__c;
                                                      naoInvoiceLine.nao__Unit_Cost__c = line.Unit_Price_bric__c;
                                                      naoInvoiceLine.MYOB_Row_Id__c = line.Row_ID_bric__c;
                                                      invoiceLinestoUpsert.add(naoInvoiceLine);
                                                  }
                                                  
                                                  
                                              }
        
        
        
        if(invoiceLinestoUpsert.size() > 0){
            upsert invoiceLinestoUpsert nao__Invoice_Lines__c.MYOB_Row_Id__c;
             
        }
        
    }
    
}