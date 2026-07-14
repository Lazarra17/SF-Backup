/*
 * Author: 			Bricoleur Technologies - Kristine Arcangel
 * Created Date: 	February 3, 2023
 * Description: 	Apex Class for Xero Outbound Account Request Body Payment Terms Fields
 * Test Class: 		N/A
 * History:    		February 3, 2023 - Creation
*/
public class XeroReqFlowParamsBillSalesPaymentTerms {
    
    @AuraEnabled @InvocableVariable public Integer Day;
    @AuraEnabled @InvocableVariable public String Type_x;
}