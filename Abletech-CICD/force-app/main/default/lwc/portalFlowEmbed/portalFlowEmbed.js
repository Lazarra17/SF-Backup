import { LightningElement, api, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import REFRESH_CHANNEL from '@salesforce/messageChannel/RefreshChannel__c';

export default class PortalFlowEmbed extends LightningElement {
    @api flowApiName;
    @api flowArguments;

    @wire(MessageContext)
    messageContext;

    get parsedInputVariables() {
        if (!this.flowArguments || !this.flowArguments.trim()) {
            return [];
        }

        try {
            const parsed = JSON.parse(this.flowArguments);
            return Array.isArray(parsed) ? parsed : [];
        } catch (error) {
            console.error('portalFlowEmbed: invalid flowArguments JSON', error);
            return [];
        }
    }

    handleStatusChange(event) {
        const status = event.detail.status;
        if (status === 'FINISHED') {
            this.publishRefresh();
        }
    }

    publishRefresh() {
        if (!this.messageContext) {
            return;
        }

        publish(this.messageContext, REFRESH_CHANNEL, { refresh: true });
    }
}