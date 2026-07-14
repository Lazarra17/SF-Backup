/**
 * @description Class to retrieve various Schema properties
 * @author Bricoleur Technologies
 * @date Aug-15-2024
 * [1] JP Sulit 10-28-2024 Added concat logic for getObjSubquery where the parent object is related to multiple but same objects
 */

public class SchemaHelper {

    /** 
     * @description get RecordTypeIdByDeveloperName
     * @param objectAPIName
     * @param recordType
     * @return Id
    */
    public static Id getRecordTypeIdByDeveloperName(String objectAPIName, String recordType)
    {
        return Schema.getGlobalDescribe().get(objectAPIName)?.getDescribe().getRecordTypeInfosByDeveloperName().get(recordType)?.getRecordTypeId();
    }
    
    /*public static Map<String, String> getPicklistValues(String objApiName, String fieldName) 
    {
        Map<String, String>  mapOfPickVals = new Map<String, String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objApiName);
        Sobject objectName = targetType.newSObject();
        Schema.sObjectType objectType = objectName.getSObjectType(); 
        Schema.DescribeSObjectResult sObjectDescribe = objectType.getDescribe(); 
        Map<String, Schema.SObjectField> fieldMap = sObjectDescribe.fields.getMap(); 
        List<Schema.PicklistEntry> pickVal = fieldMap.get(fieldName).getDescribe().getPickListValues(); 
        
        for (Schema.PicklistEntry pv : pickVal) 
        {
            mapOfPickVals.put(pv.getValue(), pv.getLabel());
        }
        return mapOfPickVals;
    }*/

    /** 
     * @description get ObjectQuery
     * @param strObj
     * @param relFields
     * @return string
    */
	public static String getObjectQuery(String strObj, String relFields) 
    {
		Map<String, Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();
		Schema.SObjectType objType = globalDescription.get(strObj);
		Schema.DescribeSObjectResult result = objType.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = result.fields.getMap();

		String strQry = 'SELECT ';

		for(Schema.SObjectField f : fieldMap.values()) 
        {
            if(f.getDescribe().isAccessible()) {
                String strFieldName = f.getDescribe().getName();
                //Schema.DescribeFieldResult fr = f.getDescribe();
                strQry += strFieldName + ',';
            }
		}
		strQry = String.isBlank(relFields)?strQry.subString(0, strQry.length() - 1):strQry+relFields;
		strQry += ' FROM ' + strObj;
		return strQry;
	}

    /** 
     * @description get ObjSubquery
     * @param parentObj
     * @param childObj
     * @return string
    */
    public static String getObjSubquery(String parentObj, String childObj) {

        String childQuery = '';

        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(parentObj);
        // Retrieve the fields and relationships for the object
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        //Map<String, Schema.SObjectField> fields = describeResult.fields.getMap();
        List<Schema.ChildRelationship> childRelationships = describeResult.getChildRelationships();

        /** [1] JP Sulit 10-28-2024 Added concat logic for getObjSubquery where the parent object is related to multiple but same objects */
        //START
        Map<String, Set<String>> sameMultiChildMap = new Map<String, Set<String>>();

        for(Schema.ChildRelationship childRel : childRelationships) {
            if(childRel.getRelationshipName() != null && String.valueOf(childRel.getChildSObject()) == childObj) {
                if(!sameMultiChildMap.containsKey(childObj)) {
                    sameMultiChildMap.put(childObj, new Set<String>{childRel.getRelationshipName()});
                }
                else {
                    sameMultiChildMap.get(childObj).add(childRel.getRelationshipName());
                }
            }
        }

        for(Schema.ChildRelationship childRel : childRelationships) {
            if(childRel.getRelationshipName() != null && String.valueOf(childRel.getChildSObject()) == childObj) {
                // Build subquery based on child relationships
                
                if(sameMultiChildMap != null && sameMultiChildMap.containsKey(childObj) && sameMultiChildMap.get(childObj).contains(childRel.getRelationshipName())) {
                    String tempChildQuery = getObjectQuery(String.valueOf(childRel.getChildSObject()), '');
                    if(String.isNotBlank(childQuery)) {
                        childQuery += ',('+tempChildQuery.substring(0, tempChildQuery.length() - String.valueOf(childRel.getChildSObject()).length()) + ' ' +  childRel.getRelationshipName()+')';
                    }
                    else {
                        childQuery = '('+tempChildQuery.substring(0, tempChildQuery.length() - String.valueOf(childRel.getChildSObject()).length()) + ' ' +  childRel.getRelationshipName()+')';
                    }
                }
                else {
                    childQuery = getObjectQuery(String.valueOf(childRel.getChildSObject()), '');
                    childQuery = '('+childQuery.substring(0, childQuery.length() - String.valueOf(childRel.getChildSObject()).length()) + ' ' +  childRel.getRelationshipName()+')';
                }
            }
        }

       // System.debug('childQuery bric '+childQuery);

        /*for(Schema.ChildRelationship childRel : childRelationships) {
            if(childRel.getRelationshipName() != null && String.valueOf(childRel.getChildSObject()) == childObj) {
                system.debug(childObj+' == '+String.valueOf(childRel.getChildSObject()));
                // Build subquery based on child relationships
                childQuery = getObjectQuery(String.valueOf(childRel.getChildSObject()), '');
                childQuery = '('+childQuery.substring(0, childQuery.length() - String.valueOf(childRel.getChildSObject()).length()) + ' ' +  childRel.getRelationshipName()+')';
            }
        }*/
        //END

        return childQuery;
    }

    /*public static Map<String, ChildRelationship> getChildRelationshipMap(String parentsObj)
    {
        Map<String, ChildRelationship> sObjChildRelationshipName = new Map<String, ChildRelationship>();
        //Create sobject Instance 
        sObject dynamicObj = (SObject)Type.forName(parentsObj).newInstance();
        //get the type token
        SObjectType sObjType = dynamicObj.getSObjectType();
        //get describe
        DescribeSobjectResult sObjDescribe = sObjType.getDescribe();
        //loop through children
        for(Schema.ChildRelationship rels :sObjDescribe.getChildRelationships())
        {
            //put the child in map
            sObjChildRelationshipName.put(String.ValueOf(rels.getChildSObject()), rels);
        }
        return sObjChildRelationshipName;
    }

    public static String getChildRelationshipName(String parentsObj, String childsObj) 
    {
        //Create sobject Instance 
        sObject dynamicObj = (SObject)Type.forName(parentsObj).newInstance();
        //get the type token
        SObjectType sObjType = dynamicObj.getSObjectType();
        //get describe
        DescribeSobjectResult sObjDescribe = sObjType.getDescribe();
        //loop through children
        for(Schema.ChildRelationship rels : sObjDescribe.getChildRelationships())
        {
            //find the child
            if(String.ValueOf(rels.getChildSObject()) == childsObj)
            {
                return rels.getRelationshipName();
            }
        }
        return null;
    }

    public static String getFieldLabelFromAPINames(String objectApi, String fieldApi)
    {
        System.debug('objectApi bric '+objectApi);
        System.debug('fieldApi bric '+fieldApi);
        if(String.IsNotBlank(objectApi) && String.IsNotBlank(fieldApi))
        {
            return (String) Schema.getGlobalDescribe().get(objectApi).getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel();
        }
        return '';
    }*/
}