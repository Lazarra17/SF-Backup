/**
* @description Controller class for OppPdf 
* @date Feb 12 2025
* @author Bricoleur Technologies
* @history:
* [1] CLAZARRA - 07-Mar-2025 -  Replace by Constant value
* [2] JPS 11 Apr 2025 - Updated public access modifiers to global
*/
global with sharing class InvoicePdfController {
    String objectName;
    String childObjName;
    String recordId;
    /** 
* @description getter setter
*/
    global List<nao__Invoice__c> recordList {get; set;} //[2] JPS 11 Apr 2025 - Updated public access modifiers to global
    global List<nao__Invoice_Lines__c> invoiceLines {get; set;}
    /** 
* @description getter setter
*/
    global String logoUrl {get; set;} //[2] JPS 11 Apr 2025 - Updated public access modifiers to global
    
    /** 
* @description Constructor
*/
    global InvoicePdfController() { //[2] JPS 11 Apr 2025 - Updated public access modifiers to global
        objectName = ApexPages.currentPage().getParameters().get('sObjectType');
        recordId = ApexPages.currentPage().getParameters().get('Id');
        childObjName = ApexPages.currentPage().getParameters().get('childSObjectType');
        logoUrl = ApexPages.currentPage().getParameters().get('pdfLogo');
        // sObj = ApexPages.currentPage().getParameters().get('sObject');
        //[1] CLAZARRA - 07-Mar-2025 -  Replace by Constant value
        String relFields = Constants.NAO_ACCOUNT_BRIC_R_NAME + ',nao__Sales_Rep_bric__r.Name,nao__Account_Bric__r.nao__ABN__c,nao__Order_Bric__r.BillToContact.Name,nao__Order_Bric__r.ShipToContact.Name,nao__Order_Bric__r.OrderNumber,nao__Order_Bric__r.TotalAmount';
        // system.debug('sObj: ' + sObj);
        
        // if(sObj == '' || sObj == null){
        recordList = (List<nao__Invoice__c>) DocTemplateGenUtil.getRecords(objectName, childObjName, relFields, recordId);
        invoiceLines = [SELECT Id, nao__Quantity_bric__c, Is_Additional_Line_Item_Bric__c, nao__Product_Code__c, nao__Product_Name__c, nao__Amount_Bric__c, nao__Total_Inc_Tax__c, nao__Description_Bric__c FROM nao__Invoice_Lines__c WHERE nao__Invoice_bric__c =: recordId ORDER BY Sort_Order_Bric__c ASC];
        System.debug('invoiceLines '+invoiceLines);
        // system.debug('invoiceLines:]
        //system.debug('recordList: ' + recordList);
        //system.debug('recordList: ' + recordList.size());
        // }else{
        //     recordList = (List<nao__Invoice__c>)JSON.deserialize(sObj, List<nao__Invoice__c>.class);
        //}
        
    }
}