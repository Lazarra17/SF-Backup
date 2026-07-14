({
	closeModal : function(component, event, helper) {
		var cmpEvent = component.getEvent("cmpEvent");
        
        cmpEvent.setParams({
            "apiHasError" : false,
        });
        cmpEvent.fire();
        
        
	}
})