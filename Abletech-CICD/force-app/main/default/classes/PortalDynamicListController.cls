public with sharing class PortalDynamicListController {

    public class ListResult {
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public Map<String, String> labels;
    }

    @AuraEnabled
    public static ListResult getDynamicList(
        String objectApiName,
        String fieldNames,
        String filterClause,
        String sortExpression,
        Integer limitSize,
        Integer offset
    ) {
        try {
            SObjectType objType = validateObject(objectApiName);
            String objectName = objType.getDescribe().getName();

            String safeFields = String.escapeSingleQuotes(fieldNames);

            if (!safeFields.containsIgnoreCase('Id')) {
                safeFields += ', Id';
            }

            String query = 'SELECT ' + safeFields + ' FROM ' + objectName;

            if (String.isNotBlank(filterClause)) {
                query += ' WHERE ' + filterClause;
            }

            query += ' WITH SECURITY_ENFORCED';

            if (String.isNotBlank(sortExpression)) {
                query += ' ORDER BY ' + String.escapeSingleQuotes(sortExpression);
            }

            if (limitSize != null && limitSize > 0) {
                query += ' LIMIT :limitSize';
            } else {
                query += ' LIMIT 50';
                if (offset != null && offset > 0) {
                    query += ' OFFSET :offset';
                }
            }

            ListResult result = new ListResult();
            result.records = Database.query(query);
            result.labels = getFieldLabels(objectName, fieldNames);

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    private static SObjectType validateObject(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Object API Name is required.');
        }

        SObjectType objType = Schema.getGlobalDescribe().get(objectApiName.trim());
        if (objType == null) {
            throw new AuraHandledException('Invalid object: ' + objectApiName);
        }

        DescribeSObjectResult describe = objType.getDescribe();
        if (!describe.isAccessible()) {
            throw new AuraHandledException('Object not accessible: ' + objectApiName);
        }
        if (!describe.isQueryable()) {
            throw new AuraHandledException('Object not queryable: ' + objectApiName);
        }

        return objType;
    }

    private static Map<String, String> getFieldLabels(String rootObjectName, String fieldNamesStr) {
        Map<String, String> labelMap = new Map<String, String>();
        if (String.isBlank(fieldNamesStr)) {
            return labelMap;
        }

        SObjectType rootType = Schema.getGlobalDescribe().get(rootObjectName);
        if (rootType == null) {
            return labelMap;
        }

        List<String> fields = fieldNamesStr.replace(' ', '').split(',');

        for (String fieldPath : fields) {
            try {
                SObjectType currentType = rootType;
                String currentLabel = fieldPath;
                List<String> parts = fieldPath.split('\\.');

                for (Integer i = 0; i < parts.size(); i++) {
                    String part = parts[i];
                    Map<String, SObjectField> fieldMap = currentType.getDescribe().fields.getMap();

                    SObjectField sField = null;
                    if (fieldMap.containsKey(part)) {
                        sField = fieldMap.get(part);
                    } else if (part.endsWith('__r')) {
                        String lookupField = part.replace('__r', '__c');
                        if (fieldMap.containsKey(lookupField)) {
                            sField = fieldMap.get(lookupField);
                        }
                    } else if (fieldMap.containsKey(part + 'Id')) {
                        sField = fieldMap.get(part + 'Id');
                    }

                    if (sField != null) {
                        DescribeFieldResult dfr = sField.getDescribe();
                        if (i == parts.size() - 1) {
                            currentLabel = dfr.getLabel();
                        } else if (!dfr.getReferenceTo().isEmpty()) {
                            currentType = dfr.getReferenceTo()[0];
                        }
                    }
                }
                labelMap.put(fieldPath, currentLabel);
            } catch (Exception e) {
                labelMap.put(fieldPath, fieldPath);
            }
        }
        return labelMap;
    }
}