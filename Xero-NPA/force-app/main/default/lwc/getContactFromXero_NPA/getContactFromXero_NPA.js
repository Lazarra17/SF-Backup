import { LightningElement , api } from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import * as CONSTANTS from 'c/constants';
import { FireToast } from  'c/utilities';

import GetFromXero from '@salesforce/apex/GetContactFromXeroController_NPA.GetFromXero';

export default class GetContactFromXero_NPA extends LightningElement 
{
    @api recordId;
    isLoading = true;

    connectedCallback()
    {
        this.isLoading = false;

        GetFromXero({recordId : this.recordId})
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