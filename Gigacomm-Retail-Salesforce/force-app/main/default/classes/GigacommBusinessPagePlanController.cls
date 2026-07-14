public without sharing class GigacommBusinessPagePlanController {
    
    
    @auraEnabled
    public static List<Map<String, String>> getPicklistValues(String objObject, String fld,String selected_string){
        // Get the object type of the SObject.
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(objObject);
        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        // Get a map of fields for the SObject
        Map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values = fieldMap.get(fld).getDescribe().getPickListValues();
        
        String myValue = '';
        if (selected_string != null){
            
            myValue = selected_string;
            
        }
        
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        options.add(new Map<String, String>());
        
        options.get(0).put('label','Select State');
        
        options.get(0).put('value','');
        
        
        Integer I = 1;
        
        for (Schema.PicklistEntry a: values) {
            
            if(a.getValue() == 'NC'){
                continue;
            }
            options.add(new Map<String, String>());
            
            options.get(I).put('label',a.getLabel());
            
            options.get(I).put('value',a.getValue());
            
            if (myValue != '') {
                
                if (selected_string == a.getValue()) {
                    
                    options.get(I).put('selected','true');
                    
                }//end of if No2
                
            }//end of if No1
            
            I = I + 1;
            
        }
        
        return options;
        
    }

}