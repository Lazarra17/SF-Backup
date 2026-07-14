({
	doInit : function(component, event, helper) {
		    helper.getStates(component, event);       
	},
    
    
    termClick : function(component, event, helper) {
        
       var btnVal = event.currentTarget.value;
        component.set('v.selectedTerm', btnVal);
           
    },    
    
})