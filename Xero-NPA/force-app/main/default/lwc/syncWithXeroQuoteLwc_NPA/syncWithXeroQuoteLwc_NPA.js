import { LightningElement , api } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import * as CONSTANTS from 'c/constants';
import { FireToast } from  'c/utilities';

import SendToXero from '@salesforce/apex/SyncWithXeroController_NoPersonAccount.SendToXero';

export default class SyncWithXeroLwc extends LightningElement 
{
    @api recordId;
    @api SObjectName;
    isLoading = true;

    connectedCallback()
    {
        this.isLoading = false;
        
        SendToXero({recordId : this.recordId , sObjectName : 'Quote'})
        .then(response =>{
            FireToast(response.Title , response.Message , response.Result);
            getRecordNotifyChange([
                {recordId : this.recordId}
            ]);
        })
        .catch(error =>{
            FireToast(CONSTANTS.GENERIC_UPPERCASE_ERROR , CONSTANTS.GENERIC_ERROR_OCCURRED , CONSTANTS.GENERIC_ERROR);
        });

        this.dispatchEvent(new CustomEvent(CONSTANTS.EVENT_CLOSE));
    }
}