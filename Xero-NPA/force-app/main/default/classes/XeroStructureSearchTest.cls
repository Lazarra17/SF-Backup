/*
 * Author:          Bricoleur
 * Created Date:    July 6, 2021
 * Description:     Apex Test Class for XeroStructureSearch
 * Test Class:      N/A
 * History:         July 6, 2021 - Creation
 */
@isTest
public class XeroStructureSearchTest {
    
    @isTest
    private static void SearchXeroPhoneTest()
    {
        RestResponseCollectionXero.Phone xeroPhone = new RestResponseCollectionXero.Phone();
        xeroPhone.PhoneType='Phone';
        List<RestResponseCollectionXero.Phone> xeroPhoneList = new List<RestResponseCollectionXero.Phone>{xeroPhone};
        
        String typeOfPhoneToSearch = 'Phone';
        test.startTest();
       	XeroStructureSearch.SearchXeroPhone(xeroPhoneList, typeOfPhoneToSearch);
        test.stopTest();
    }
    
    @isTest
    private static void GetXeroContactFromInvoiceTest()
    {
        RestResponseCollectionXero.XeroContact xeroContact = new RestResponseCollectionXero.XeroContact();
     
        test.startTest();
       	XeroStructureSearch.GetXeroContactFromInvoice(xeroContact);
        test.stopTest();
    }
    
    @isTest
    private static void SearchXeroAddressTest()
    {
        RestResponseCollectionXero.Address xeroAddress = new RestResponseCollectionXero.Address();
        xeroAddress.AddressType='BillingAddress';
        List<RestResponseCollectionXero.Address> xeroAddressList = new List<RestResponseCollectionXero.Address>{xeroAddress};
        
        String typeOfAddressToSearch = 'BillingAddress';
        test.startTest();
       	XeroStructureSearch.SearchXeroAddress(xeroAddressList, typeOfAddressToSearch);
        test.stopTest();
    }

}