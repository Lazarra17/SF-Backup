import { ShowToastEvent } from 'lightning/platformShowToastEvent';

function FireToast(title, message , result)
{
    dispatchEvent(
        new ShowToastEvent({
            title : title,
            message : message,
            variant : result
        })
    )
}

export {
    FireToast
};