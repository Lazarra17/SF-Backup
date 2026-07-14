/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	June 02, 2021
 * Description: 	Apex Class for Xero Outbound Contact Get Request Body
 * Test Class: 		N/A
 * History:    		Jun. 02, 2021 - Creation
*/
public class XeroReqGetFlowParamsContact 
{
    @AuraEnabled @InvocableVariable public Account AccountRecord;
    @AuraEnabled @InvocableVariable public String Parameter;
    @AuraEnabled @InvocableVariable public String ParameterValue;
}