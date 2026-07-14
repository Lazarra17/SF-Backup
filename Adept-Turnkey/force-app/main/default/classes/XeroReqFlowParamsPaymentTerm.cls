/*
 * Author: 			Bricoleur Technologies - Kristine Arcangel
 * Created Date: 	February 3, 2023
 * Description: 	Apex Class for Xero Outbound Account Request Body
 * Test Class: 		N/A
 * History:    		February 3, 2023 - Creation
*/
public class XeroReqFlowParamsPaymentTerm {
    
    @AuraEnabled @InvocableVariable public XeroReqFlowParamsBillSalesPaymentTerms Bills;
    @AuraEnabled @InvocableVariable public XeroReqFlowParamsBillSalesPaymentTerms Sales;
    

}