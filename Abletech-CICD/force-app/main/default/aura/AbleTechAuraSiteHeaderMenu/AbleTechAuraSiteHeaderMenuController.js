({
   onClick : function(component, event, helper) {
       var id = event.target.dataset.menuItemId;
       if (id) {
           component.getSuper().navigate(id);
        }
  },
    
	clickMe : function(component, event, helper) {
       console.log(event.target.value);
  },    
    
})