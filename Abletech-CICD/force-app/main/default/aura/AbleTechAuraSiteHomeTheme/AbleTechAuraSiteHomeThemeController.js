({
    handleStatusChange : function (component, event, helper) {
        if (event.getParam('status') === 'FINISHED') {
            // Publish the message to the channel
            var payload = { refresh: true };
            component.find("refreshChannel").publish(payload);
        }
    }
})