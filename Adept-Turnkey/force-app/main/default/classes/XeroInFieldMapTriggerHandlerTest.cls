/*
 * Author:          Alfonso Maquilan
 * Created Date:    May  24, 2021
 * Description:     Apex Test Class for XeroInFieldMapTriggerHandler
 * Test Class:      N/A
 * History:         May  24, 2021 - Creation
 */
@isTest
public class XeroInFieldMapTriggerHandlerTest 
{
    @testSetup
    private static void Setup()
    {
        XeroInboundFieldMapping__c xeroContactFieldMapping = new XeroInboundFieldMapping__c();
        xeroContactFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT;
        xeroContactFieldMapping.SalesforceObject__c = 'Account';
        xeroContactFieldMapping.FieldMapping__c = 'Name=Name,Phone=Phone,Fax=Fax,ShippingStreet=AddressLine1,ShippingCity=City,ShippingState=Region,ShippingPostalCode=PostalCode,ShippingCountry=Country';
        xeroContactFieldMapping.Active__c = TRUE;
        
        XeroInboundFieldMapping__c xeroInvoiceFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE;
        xeroInvoiceFieldMapping.SalesforceObject__c = 'Xero_Loading_Object__c';
        xeroInvoiceFieldMapping.FieldMapping__c = 'Id=Reference,CloseDate=DueDateString';
        xeroInvoiceFieldMapping.Active__c = TRUE;
        
        XeroInboundFieldMapping__c xeroInvoiceLineItemFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceLineItemFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE_LINE_ITEM;
        xeroInvoiceLineItemFieldMapping.SalesforceObject__c = 'Xero_Line_Item_Load__c';
        xeroInvoiceLineItemFieldMapping.SalesforceLookupField__c = 'Xero_Loading_Object__c';
        xeroInvoiceLineItemFieldMapping.FieldMapping__c = 'Id=Description,Quantity=Quantity,UnitPrice=UnitAmount';
        xeroInvoiceLineItemFieldMapping.Active__c = TRUE;
        
        Insert new List<XeroInboundFieldMapping__c>{xeroContactFieldMapping , xeroInvoiceFieldMapping , xeroInvoiceLineItemFieldMapping};
    }
    
    @isTest
    private static void SuccessfulFieldMappingInsert()
    {
        Delete [SELECT Id FROM XeroInboundFieldMapping__c];
        
        XeroInboundFieldMapping__c xeroContactFieldMapping = new XeroInboundFieldMapping__c();
        xeroContactFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT;
        xeroContactFieldMapping.FieldMapping__c = 'Name=Name,Phone=Phone,Fax=Fax,ShippingStreet=AddressLine1,ShippingCity=City,ShippingState=Region,ShippingPostalCode=PostalCode,ShippingCountry=Country';
        xeroContactFieldMapping.Active__c = TRUE;
        
        test.startTest();
        
        Insert xeroContactFieldMapping;
            
        test.stopTest();
        
        List<XeroInboundFieldMapping__c> xeroContactFieldMappingInserted = [SELECT XeroObject__c, FieldMapping__c, Active__c FROM XeroInboundFieldMapping__c];
        System.assert(!xeroContactFieldMappingInserted.isEmpty());
        System.assertEquals(xeroContactFieldMapping.XeroObject__c, xeroContactFieldMappingInserted[0].XeroObject__c);
        System.assertEquals(xeroContactFieldMapping.FieldMapping__c, xeroContactFieldMappingInserted[0].FieldMapping__c);
        System.assertEquals(xeroContactFieldMapping.Active__c, xeroContactFieldMappingInserted[0].Active__c);
    }
    
    @isTest
    private static void FailedFieldMappingInsertExistingContactMapping()
    {
        XeroInboundFieldMapping__c xeroContactFieldMapping = new XeroInboundFieldMapping__c();
        xeroContactFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT;
        xeroContactFieldMapping.SalesforceObject__c = 'Account';
        xeroContactFieldMapping.FieldMapping__c = 'Name=Name,Phone=Phone,Fax=Fax,ShippingStreet=AddressLine1,ShippingCity=City,ShippingState=Region,ShippingPostalCode=PostalCode,ShippingCountry=Country';
        xeroContactFieldMapping.Active__c = TRUE;
        
        test.startTest();
        
        List<Database.SaveResult> insertResult = Database.Insert(new List<XeroInboundFieldMapping__c>{xeroContactFieldMapping} , false);
            
        test.stopTest();
        
        if(insertResult.size() > 0){
            String errorMessage = insertResult[0]?.getErrors()[0]?.getMessage();
            System.assertEquals(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_CONTACT_MAPPING_EXIST, errorMessage);
        }
    }
    
    @isTest
    private static void FailedFieldMappingInsertExistingInvoiceMapping()
    {
        XeroInboundFieldMapping__c xeroInvoiceFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE;
        xeroInvoiceFieldMapping.SalesforceObject__c = 'Xero_Loading_Object__c';
        xeroInvoiceFieldMapping.FieldMapping__c = 'Id=Reference,CloseDate=DueDateString';
        xeroInvoiceFieldMapping.Active__c = TRUE;
        
            test.startTest();
            
            List<Database.SaveResult> insertResult = Database.Insert(new List<XeroInboundFieldMapping__c>{xeroInvoiceFieldMapping} , false);
            
            test.stopTest();
            
            if(insertResult.size() > 0){
                String errorMessage = insertResult[0]?.getErrors()[0]?.getMessage();
                System.assertEquals(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_INVOICE_MAPPING_EXIST, errorMessage);
            }
    }
    
    @isTest
    private static void FailedFieldMappingInsertExistingInvoiceLineItemMapping()
    {
        XeroInboundFieldMapping__c xeroInvoiceLineItemFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceLineItemFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE_LINE_ITEM;
        xeroInvoiceLineItemFieldMapping.SalesforceObject__c = 'Xero_Line_Item_Load__c';
        xeroInvoiceLineItemFieldMapping.SalesforceLookupField__c = 'Xero_Loading_Object__c';
        xeroInvoiceLineItemFieldMapping.FieldMapping__c = 'Id=Description,Quantity=Quantity,UnitPrice=UnitAmount';
        xeroInvoiceLineItemFieldMapping.Active__c = TRUE;
        
        test.startTest();
        
        List<Database.SaveResult> insertResult = Database.Insert(new List<XeroInboundFieldMapping__c>{xeroInvoiceLineItemFieldMapping} , false);
        
        test.stopTest();
        
        if(insertResult.size() > 0){
            String errorMessage = insertResult[0]?.getErrors()[0]?.getMessage();
            System.assertEquals(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_INVOICE_LINE_ITEM_MAPPING_EXIST, errorMessage);
        }
    }
    
    @isTest
    private static void FailedFieldMappingUpdateExistingContactMapping()
    {
        XeroInboundFieldMapping__c xeroContactFieldMapping = new XeroInboundFieldMapping__c();
        xeroContactFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_CONTACT;
        xeroContactFieldMapping.SalesforceObject__c = 'Account';
        xeroContactFieldMapping.FieldMapping__c = 'Name=Name,Phone=Phone,Fax=Fax,ShippingStreet=AddressLine1,ShippingCity=City,ShippingState=Region,ShippingPostalCode=PostalCode,ShippingCountry=Country';
        xeroContactFieldMapping.Active__c = FALSE;
        Insert xeroContactFieldMapping;
        
        test.startTest();
        
        xeroContactFieldMapping.Active__c = TRUE;
        List<Database.SaveResult> insertResult = Database.Update(new List<XeroInboundFieldMapping__c>{xeroContactFieldMapping} , false);
            
        test.stopTest();
        if(insertResult.size() > 0){
            String errorMessage = insertResult[0]?.getErrors()[0]?.getMessage();
            System.assertEquals(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_CONTACT_MAPPING_EXIST, errorMessage);
        }
    }
    
    @isTest
    private static void FailedFieldMappingUpdateExistingInvoiceMapping()
    {
        XeroInboundFieldMapping__c xeroInvoiceFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE;
        xeroInvoiceFieldMapping.SalesforceObject__c = 'Xero_Loading_Object__c';
        xeroInvoiceFieldMapping.FieldMapping__c = 'Id=Reference,CloseDate=DueDateString';
        xeroInvoiceFieldMapping.Active__c = FALSE;
        Insert xeroInvoiceFieldMapping;
        
        test.startTest();
        
        xeroInvoiceFieldMapping.Active__c = TRUE;
        List<Database.SaveResult> insertResult = Database.Update(new List<XeroInboundFieldMapping__c>{xeroInvoiceFieldMapping} , false);
            
        test.stopTest();
        
        if(insertResult.size() > 0){
            String errorMessage = insertResult[0]?.getErrors()[0]?.getMessage();
            System.assertEquals(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_INVOICE_MAPPING_EXIST, errorMessage);
        }
    }
    
    @isTest
    private static void FailedFieldMappingUpdateExistingInvoiceLineItemMapping()
    {
        XeroInboundFieldMapping__c xeroInvoiceLineItemFieldMapping = new XeroInboundFieldMapping__c();
        xeroInvoiceLineItemFieldMapping.XeroObject__c = CONSTANTS_BRIC.XERO_INBOUND_FIELD_MAPPING_XERO_OBJECT_INVOICE_LINE_ITEM;
        xeroInvoiceLineItemFieldMapping.FieldMapping__c = 'Id=Description,Quantity=Quantity,UnitPrice=UnitAmount';
        xeroInvoiceLineItemFieldMapping.SalesforceObject__c = 'Xero_Line_Item_Load__c';
        xeroInvoiceLineItemFieldMapping.SalesforceLookupField__c = 'Xero_Loading_Object__c';
        xeroInvoiceLineItemFieldMapping.Active__c = FALSE;
        Insert xeroInvoiceLineItemFieldMapping;
        
        test.startTest();
        
        xeroInvoiceLineItemFieldMapping.Active__c = TRUE;
        List<Database.SaveResult> insertResult = Database.Update(new List<XeroInboundFieldMapping__c>{xeroInvoiceLineItemFieldMapping} , false);
        
        test.stopTest();
        
        if(insertResult.size() > 0){
            String errorMessage = insertResult[0]?.getErrors()[0]?.getMessage();
            System.assertEquals(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_INVOICE_LINE_ITEM_MAPPING_EXIST, errorMessage);
        }
    }
}