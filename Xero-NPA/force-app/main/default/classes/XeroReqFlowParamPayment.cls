/*
* Author: 			Bricoleur Technologies
* Created Date: 	July 18, 2023
* Description: 		Flow Parameter for Payment
* Test Class: 		
* History:    		July 18, 2023- Creation
*/
public class XeroReqFlowParamPayment {
    
    @AuraEnabled @InvocableVariable public XeroReqFlowParamsInvoice Invoice;
    @AuraEnabled @InvocableVariable public String Date_x;
    @AuraEnabled @InvocableVariable public Decimal Amount;
    @AuraEnabled @InvocableVariable public XeroReqFlowParamAccount Account;
}