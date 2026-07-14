({
    navigateToHome: function(component, event, helper) {
        window.open('/', '_self');
    },

    toggleMobileSearch: function(component, event, helper) {
        component.set('v.showMobileSearch', !component.get('v.showMobileSearch'));
    }
})