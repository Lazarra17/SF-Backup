({

    
    removeRouter : function(component, event, helper) {
        component.set('v.showIncludeRouterDescription', false);
        helper.removeRouter(component, event);
        
    },
    
    addRouterDesc : function(component, event, helper) {
        helper.includeRouter(component, event);
    },
    
    addFreeRouter : function(component, event, helper) {
        
        helper.updateFreeRouter(component, event);
        
    },
    
    addToCart : function(component, event, helper) {
        //Dynamically chnage the add to cart button
        var qty = component.get('v.quantity');
        component.set('v.showButtons', true);
        
        helper.upsertLead(component, event, qty);
    },
    
    addOne : function(component, event, helper) {
        
        var lead = component.get('v.lead');
        var qty = lead.Router.Quantity_bric__c;
        qty = qty + 1;
        if(qty <= 9){
            helper.upsertLead(component, event, qty);
        }
        
    },
    
    
    minusOne : function(component, event, helper) {
        
        var lead = component.get('v.lead');
        var qty = lead.Router.Quantity_bric__c;
        qty = qty - 1;
        //console.log(qty);
        if(qty != 0){
            helper.upsertLead(component, event, qty);
        }else if(qty == 0){
            helper.removeRouter(component, event);
        }
        
    },
    
    selectCarouselItem : function (component, event, helper) {
        var item1 = document.getElementById("carouselItem1");
        var item2 = document.getElementById("carouselItem2");
        var item3 = document.getElementById("carouselItem3");
        
        item1.classList.remove("gc-carousel-item-active");
        item2.classList.remove("gc-carousel-item-active");
        item3.classList.remove("gc-carousel-item-active");
        
        
        var inputElement = event.currentTarget;
        $A.util.addClass(inputElement, 'gc-carousel-item-active');
    } 
    
    
    
    
    
})