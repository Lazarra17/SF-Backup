({
    doInit : function(component, event, helper) {
        
    },
    
    validateInput : function(component, event, helper){
        var validity = component.find("agentCode").get("v.validity");
        if (validity.valid) {
            helper.navigateTo(component, event);
        } else {
            return  component.find('agentCode').showHelpMessageIfInvalid();
            
        }
    },
    
     
})