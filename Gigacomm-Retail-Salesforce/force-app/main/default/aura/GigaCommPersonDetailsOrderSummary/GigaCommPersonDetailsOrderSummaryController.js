({
    myAction : function(component, event, helper) {
        
    },
    selectAllTerms: function (component, event, helper) {
        helper.toggleCheckboxes(component, event);
    },
    
    checkTCs: function (component, event, helper) {
        helper.isTCsAccepted(component, event);
    },
    
    
    placeOrder: function (component, event, helper) {

        helper.updateLead(component, event);
    },
    
    
})