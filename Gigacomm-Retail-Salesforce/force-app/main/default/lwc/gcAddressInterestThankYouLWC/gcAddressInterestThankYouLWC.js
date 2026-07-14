import { LightningElement } from 'lwc';

export default class GigaCommAddressInterestThankYouLwc extends LightningElement {
    closeModal() {
        this.dispatchEvent(new CustomEvent('closethankyoumodal'));
    }
}