({
	doInit : function(component, event, helper) {
        try {
            var now = new Date();
            var start = new Date(2025, 11, 24, 0, 0, 0);   
            var end   = new Date(2026, 0, 1, 23, 59, 59);
            var inRange = (now >= start && now <= end);
            component.set("v.isChristmasHours", inRange);
        } catch (e) {
            console.error('Error computing isChristmasHours', e);
            component.set("v.isChristmasHours", false);
        }
    },
	navigateToHome : function(component, event, helper) {
		window.open('/', '_self');
	}
})
