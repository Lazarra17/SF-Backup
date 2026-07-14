/*
 * Author:          Alfonso Maquilan
 * Created Date:    May 10, 2021
 * Description:     Apex Class to search for Information in Xero Data Structures
 * Test Class:      N/A
 * History:         May 10, 2021 - Creation
*/
public class XeroStructureSearch 
{
    public static RestResponseCollectionXero.Phone SearchXeroPhone(List<RestResponseCollectionXero.Phone> xeroPhoneList , String typeOfPhoneToSearch)
    {
        for(RestResponseCollectionXero.Phone xeroPhone : xeroPhoneList)
        {
            if(xeroPhone.PhoneType_x == typeOfPhoneToSearch) return xeroPhone;
        }
        
        return NULL;
    }
    
    public static RestResponseCollectionXero.Address SearchXeroAddress(List<RestResponseCollectionXero.Address> xeroAddressList , String typeOfAddressToSearch)
    {
        for(RestResponseCollectionXero.Address xeroAddress : xeroAddressList)
        {
            if(xeroAddress.AddressType_x == typeOfAddressToSearch) return xeroAddress;
        }
        
        return NULL;
    }
    
    public static RestResponseCollectionXero.XeroContact GetXeroContactFromInvoice(RestResponseCollectionXero.XeroContact xeroContact)
    {
        RestResponseCollectionXero.XeroContact xeroCon = new RestResponseCollectionXero.XeroContact();
        xeroCon.ContactID = xeroContact.ContactID;
        xeroCon.ContactStatus = xeroContact.ContactStatus;        
        
        return xeroCon;
    }
}