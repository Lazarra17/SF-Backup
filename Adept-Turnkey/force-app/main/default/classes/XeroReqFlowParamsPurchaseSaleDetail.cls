/*
 * Author: 			Bricoleur Technologies - Kristine Arcangel
 * Created Date: 	June 20, 2022
 * Description: 	Apex Class for Xero Outbound Item Purchase and/or Sale Detail Request Body
 * Test Class: 		N/A
* History:    		June 20, 2022 - Creation
*/

public class XeroReqFlowParamsPurchaseSaleDetail {
    
    
    @AuraEnabled @InvocableVariable public Decimal UnitPrice;
    @AuraEnabled @InvocableVariable public String AccountCode;
    @AuraEnabled @InvocableVariable public String TaxType;

}