/*
* Author:           Alfonso Maquilan
* Created Date:     May 07, 2021
* Description:      Apex Class for Async Callouts to Xero
* Test Class:       N/A
* History:          May 07, 2021 - Creation
*/
public class AsyncXeroCallouts implements Queueable,Database.AllowsCallouts
{
    private XeroAPISettings__c APISettings;
    private String CalloutToRun;
    private List<String> IdList;
    
    public void InstantiateProperties()
    {
        this.APISettings = new XeroAPISettings__c();
        this.CalloutToRun = CONSTANTS_BRIC.GENERIC_BLANK;
        this.IdList = new List<String>();
    }
    
    public void SetAPISettings(XeroAPISettings__c apiSettings)
    {
        this.APISettings = apiSettings;
    }
    
    public void SetCalloutToRun(String calloutToRun)
    {
        this.CalloutToRun = calloutToRun;
    }
    
    public void SetIdList(List<String> IdList)
    {
        this.IdList.addAll(IdList);
    }
    
    public void Execute(QueueableContext context)
    {
        if(this.CalloutToRun != NULL && !String.IsBlank(this.CalloutToRun)) RunCallout();
    }
    
    private void RunCallout()
    {
        Switch on this.CalloutToRun
        {
            When 'Contact'
            {
                if(CheckAPISettings()) XeroRequest.GetContacts(this.APISettings , this.IdList , TRUE);
            }
            When 'Invoice'
            {
                if(CheckAPISettings()) XeroRequest.GetInvoices(this.APISettings , this.IdList , TRUE);
            }
        }
    }
    
    private Boolean CheckAPISettings()
    {
        return this.APISettings != NULL;
    }
}