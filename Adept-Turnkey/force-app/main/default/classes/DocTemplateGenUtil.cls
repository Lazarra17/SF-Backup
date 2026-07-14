/**
 * @description Utility class for NAO VF Doc Templates
 * @author Bricoleur Technologies
 * @date Aug-16-2024
 * [1] JP Sulit - Nov-6-2024 - Added function to strip inaccessible fields in an sObjectList
 */

 public with sharing class DocTemplateGenUtil {

    /**
     * @description Retrieves sObject records dynamically
     * @param objName
     * @param childObjName
     * @param relFields
     * @param recordId
     * @return List<sObject>
     */
    public static List<sObject> getRecords(String objName, String childObjName, String relFields, String recordId) {
        String childQry = SchemaHelper.getObjSubquery(objName, childObjName);
        if(String.isNotBlank(relFields)) {
            childQry += ','+relFields+' ';
        }
        String qry = SchemaHelper.getObjectQuery(objName, childQry)+' WHERE Id = \''+recordId+'\'';
        System.debug('qry '+qry);
        return getSecuredAccessRecords(Database.query(qry));
    }

    /**
     * @description Gets object api name by record id
     * @param recordId
     * @return String
     */
    public static String getObjectNameById(Id recordId) {
        SObjectType sObjectType = recordId.getSObjectType();
        return sObjectType.getDescribe().getName();
    }

    /**
     * @description Strips query inaccessible fields
     * @param sObjectList
     * @return List<sObject
     */
    //[1] JP Sulit - Nov-6-2024 - Added function to strip inaccessible fields in an sObjectList
    public static List<sObject> getSecuredAccessRecords(List<sObject> sObjectList) {
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, sObjectList);
        return (List<sObject>) securityDecision.getRecords();
    }

     public static Map<Id, Contact> getContactMapToSendInvoice(Set<Id> contactIds){
         Map<Id, Contact> contactMap = new Map<Id,Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN: contactIds AND Account.Automatically_Send_Invoices_bric__c = TRUE]);
         return contactMap;
     }
}