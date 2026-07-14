/*
 * Author:          Alfonso Maquilan
 * Created Date:    May 20, 2021
 * Description:     Trigger Handler for Account object
 * Test Class:      N/A
 * History:         May  20, 2021 - Creation 
*/
public class XeroWebhookStorageTriggerHandler extends TriggerHandler
{
    public override void GenericInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
    }
    
    public override void BeforeInsertInitialization(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {
    }
    
    public override void BeforeUpdateInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
    }
    
    public override void BeforeDeleteInitialization(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
    }
    
    public override void AfterInsertInitialization(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {

    }
    
    public override void AfterUpdateInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
        
    }
    
    public override void AfterDeleteInitialization(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
        
    }
    
    public override void BeforeInsertProcess(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {
        for(XeroWebhookStorage__c webhookRecord : (List<XeroWebhookStorage__c>)newSObjectList)
        {
            webhookRecord.Processed__c = TRUE;
        }
    }
    
    public override void BeforeUpdateProcess(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {

    }
    
    public override void BeforeDeleteProcess(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
        
    }
    
    public override void AfterInsertProcess(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {
        List<String> xeroContactIdList = new List<String>();
        List<String> xeroInvoiceIdList = new List<String>();
        
        for(XeroWebhookStorage__c webhookRecord : (List<XeroWebhookStorage__c>)newSObjectList)
        {
            //if(CheckWebhookRecord(webhookRecord.XeroObject__c , CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_CATEGORY_CONTACT) &&  webhookRecord.Event__c == CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_TYPE_UPDATE) xeroContactIdList.add(webhookRecord.XeroId__c);
            if(CheckWebhookRecord(webhookRecord.XeroObject__c , CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_CATEGORY_CONTACT)) xeroContactIdList.add(webhookRecord.XeroId__c);
            else if(CheckWebhookRecord(webhookRecord.XeroObject__c , CONSTANTS_BRIC.INTEGRATION_XERO_EVENT_CATEGORY_INVOICE)) xeroInvoiceIdList.add(webhookRecord.XeroId__c);
        }
        
        XeroAPISettings__c apiSettings = XeroAPISettings__c.getInstance(Label.Xero_Setting);
        if(!xeroContactIdList.isEmpty()) RunAsyncXeroCallout(apiSettings , xeroContactIdList , CONSTANTS_BRIC.XERO_OBJECT_CONTACT);
        if(!xeroInvoiceIdList.isEmpty()) RunAsyncXeroCallout(apiSettings , xeroInvoiceIdList , CONSTANTS_BRIC.XERO_OBJECT_INVOICE);
    }
    
    public override void AfterUpdateProcess(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
        
    }
    
    public override void AfterDeleteProcess(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
        
    }
    
    public override void AfterInsertDMLOperations()
    {

    }
    
    public override void AfterUpdateDMLOperations()
    {
        
    }
    
    public override void AfterDeleteDMLOperations()
    {
        
    }
    
    private static Boolean CheckWebhookRecord(String xeroObject , String xeroObjectChecker)
    {
        return xeroObject == xeroObjectChecker;
    }
    
    private static void RunAsyncXeroCallout(XeroAPISettings__c apiSettings , List<String> xeroIdList , String calloutToRun)
    {
        AsyncXeroCallouts asyncXeroCallout = new AsyncXeroCallouts();
        asyncXeroCallout.InstantiateProperties();
        asyncXeroCallout.SetCalloutToRun(calloutToRun);
        asyncXeroCallout.SetAPISettings(apiSettings);
        asyncXeroCallout.SetIdList(xeroIdList);
        
        System.enqueueJob(asyncXeroCallout);
    }
}