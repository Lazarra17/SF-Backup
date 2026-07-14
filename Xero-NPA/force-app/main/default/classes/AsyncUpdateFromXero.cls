/*
* Author: 			Alfonso Maquilan
* Created Date: 	May 07, 2021
* Description: 		Apex Class for Async Updates from Xero
* Test Class: 		XeroRequestTest
* History: 			May 07, 2021 - Creation
*/
public class AsyncUpdateFromXero implements Queueable
{
    private String UpdateToRun;
    private List<Object> XeroObjectList;
    private List<String> XeroIdList;
    
    public void InstantiateProperties()
    {
        this.UpdateToRun = CONSTANTS_BRIC.GENERIC_BLANK;
        this.XeroObjectList = new List<Object>();
        this.XeroIdList = new List<String>();
    }
    
    public void SetUpdateToRun(String updateToRun)
    {
        this.UpdateToRun = updateToRun;
    }
    
    public void SetXeroObjectList(List<Object> xeroObjectList)
    {
        this.XeroObjectList = xeroObjectList;
    }
    
    public void SetXeroIdList(List<String> xeroIdList)
    {
        this.XeroIdList = xeroIdList;
    }
    
    public void execute(QueueableContext context)
    {
        if(this.UpdateToRun != NULL && !String.IsBlank(this.UpdateToRun)) RunUpdate();
    }
    
    private void RunUpdate()
    {
        Switch on this.UpdateToRun
        {
            When 'Account'
            {
                PostXeroRequest.UpdateAccountFromXeroBatch((List<RestResponseCollectionXero.XeroContact>)this.XeroObjectList , this.XeroIdList);
            }
            When 'Opportunity' 
            {
                PostXeroRequest.UpdateInvoiceAndInvoiceLineItemsFromXeroBatch((List<RestResponseCollectionXero.Invoice>)this.XeroObjectList , this.XeroIdList);
            }
        }
    }
}