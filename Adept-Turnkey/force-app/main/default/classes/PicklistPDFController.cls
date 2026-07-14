public class PicklistPDFController {
    
    public String recordId {get;set;}
    public List<String> recordIdList {get;set;}
    public List<Order> orderRec {get;set;}
    public Date dateGenerated {get;set;}
    public List<OrderItem> orderLineList {get;set;}
    public ApexPages.StandardSetController setOrderCtrl {get;set;}
    
    public PicklistPDFController(ApexPages.StandardSetController stdController) {
        
        this.setOrderCtrl = stdController;        
        List<Order> selectedIds = (List<Order>)setOrderCtrl.getSelected();    
        
        recordId =  ApexPages.currentPage().getParameters().get('id');
        system.debug('recordId::: ' + recordId);        
        
        String recordIds =  ApexPages.currentPage().getParameters().get('recordids');
        system.debug('recordIds::: ' + recordIds);        
        if(recordIds != null && recordIds != ''){
            recordIds = recordIds.replace('[','');
            recordIds = recordIds.replace(']','');
            recordIdList = recordIds.split(',');
            selectedIds.addAll([SELECT Id, Name, AccountId, Account.Name,Xero_Purchase_Order_Number__c,Inventory_Location__c,OrderNumber,BillToContactId,BillToContact.Name,
                                                                 //s_c__Contact_Email__c,s_c__Contact_Phone__c,
                                								 Inventory_Location__r.Name,
                                                                 BillingStreet,BillingState,BillingCity,BillingCountry,BillingPostalCode,
                                                                 ShippingStreet,ShippingState,ShippingCity,ShippingCountry,ShippingPostalCode,                
                                                                 (SELECT Id,Product2.Name, Product2Id, Product2.ProductCode,Quantity,Product2.QuantityUnitOfMeasure,Warehouse_Location__c FROM OrderItems
                                                                  ORDER BY Warehouse_Location__c)
                                                                 FROM Order
                                                                 WHERE Id IN :recordIdList]);
        }
            
        if(recordId != null && recordId != '' ) selectedIds.add([SELECT Id, Name, AccountId, Account.Name,Xero_Purchase_Order_Number__c,Inventory_Location__c,OrderNumber,BillToContactId,BillToContact.Name,
                                                                 //s_c__Contact_Email__c,s_c__Contact_Phone__c,
                                                                 Inventory_Location__r.Name,
                                                                 BillingStreet,BillingState,BillingCity,BillingCountry,BillingPostalCode,
                                                                 ShippingStreet,ShippingState,ShippingCity,ShippingCountry,ShippingPostalCode,                
                                                                 (SELECT Id,Product2.Name, Product2Id, Product2.ProductCode,Quantity,Product2.QuantityUnitOfMeasure,Warehouse_Location__c FROM OrderItems
                                                                  ORDER BY Warehouse_Location__c)
                                                                 FROM Order
                                                                 WHERE Id =:recordId]);
        
        system.debug('selectedIds::: ' + selectedIds);
        
        orderRec = [SELECT Id, Name, AccountId, Account.Name,Xero_Purchase_Order_Number__c,Inventory_Location__c,OrderNumber,BillToContactId,BillToContact.Name,
                    //s_c__Contact_Email__c,s_c__Contact_Phone__c,
                    Inventory_Location__r.Name,
                    BillingStreet,BillingState,BillingCity,BillingCountry,BillingPostalCode,
                    ShippingStreet,ShippingState,ShippingCity,ShippingCountry,ShippingPostalCode,                
                    (SELECT Id,Product2.Name, Product2Id, Product2.ProductCode,Quantity,Product2.QuantityUnitOfMeasure,
                     Warehouse_Location__c FROM OrderItems
                     ORDER BY Warehouse_Location__c)
                    FROM Order
                    WHERE Id IN: selectedIds];
        
    }
    
    @InvocableMethod(label='Generate and save Picklist File' description='Generate and save Picklist File' category='Order')
    public static void savePdfAsAttachment(List<List<String>> params){
        
        List<String> selectedIds = params[0];
        
        if(selectedIds != null)     
        {            
            
            List<Order> orderList = [SELECT Id, OrderNumber
                                     FROM Order
                                     WHERE Id IN: selectedIds
                                    ];
            
            List<ContentDocument> filelist = [SELECT Id, Title FROM ContentDocument WHERE Title != ''];
            Map<String,ContentDocument> fileMap = new Map<String,ContentDocument>();
            for(ContentDocument fileRecord : filelist){
                fileMap.put(fileRecord.Title, fileRecord);
            }
                
            
            for(Order ord : orderList){
                PageReference pdf =  Page.PicklistVFPage;
                pdf.getParameters().put('id',ord.Id);
                pdf.setRedirect(true);
                Blob body;
                try
                {
                    body = !Test.isRunningTest()?pdf.getContentAsPDF():Blob.valueOf('This is a test PDF content');
                    String fileRecName = ord.OrderNumber + '.pdf';
                    
                    ContentVersion cv = new ContentVersion();
                    cv.ContentLocation = 'S'; 
                    cv.PathOnClient = fileRecName;
                    cv.Title = fileRecName;
                    cv.VersionData = body;
                    if(fileMap.get(fileRecName)?.Id != NULL){
                        cv.ContentDocumentId = fileMap.get(fileRecName)?.Id;
                    }
                    insert cv;   
                    
                    if(cv.ContentDocumentId == null){
                        Id cdId = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Title = :fileRecName LIMIT 1]?.ContentDocumentId;                        
                        
                        ContentDocumentLink cd = New ContentDocumentLink();
                        cd.LinkedEntityId = ord.Id;
                        cd.ContentDocumentId = cdId;
                        cd.shareType = 'V';
                        insert cd; 
                        
                    }
                    
                }
                catch(DmlException e)
                {                    
                    throw new AuraHandledException(e.getMessage());   
                }   
            }
        }
        
    }
    
}