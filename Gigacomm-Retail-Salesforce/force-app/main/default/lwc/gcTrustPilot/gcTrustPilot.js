import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import trustpilotBootstrap from '@salesforce/resourceUrl/TrustPilotBootstrapJS'; // Import  static resource

export default class YourTrustpilotComponent extends LightningElement {
trustpilotInitialized = false; // Flag to ensure script is loaded only once

renderedCallback() {
    // Ensure the script is loaded only once
    if (!this.trustpilotInitialized) {
        this.trustpilotInitialized = true; // Set flag to true

        loadScript(this, trustpilotBootstrap)
            .then(() => {
              
                
                // Check if Trustpilot global object and its widget management module exist
                if (window.Trustpilot && window.Trustpilot.loadFromElement) {
                    // Select all Trustpilot widgets within THIS component's shadow DOM
                    const widgetElements = this.template.querySelectorAll('.trustpilot-widget');
                    if (widgetElements.length > 0) {
                        widgetElements.forEach(widgetElement => {
                            // Call loadFromElement for each widget to ensure it's initialized
                            window.Trustpilot.loadFromElement(widgetElement);
                        });
                      
                    }
                } else {
                    console.warn('Trustpilot global object or loadFromElement not found after script load.');
                }
            })
            .catch(error => {
                console.error('Error loading Trustpilot bootstrap script:', error);
            });
    }
}

// to handle cleanup if the component is removed from the DOM
disconnectedCallback() {
    if (window.Trustpilot && window.Trustpilot.Modules && window.Trustpilot.Modules.WidgetManagement) {
        }
}
}