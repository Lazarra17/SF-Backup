/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May 21, 2021
 * Description: 	Data Structure for XeroInFieldMapTriggerHandler
 * Test Class: 		N/A
 * History: 		May  21, 2021 - Creation
 * 					July 2, 2021 - Added utility for Person account (anything with "Person")
*/
public class XeroInFieldMapTriggerHandlerObj 
{
	public class BeforeInsert
    {
        private Boolean ActiveContact;
        private String ActiveContactId;
        private Boolean ActivePersonContact;
        private String ActivePersonContactId;
        private Boolean ActiveInvoice;
        private String ActiveInvoiceId;
        private Boolean ActiveInvoiceLineItem;
        private String ActiveInvoiceLineItemId;
        
        public void Initialization()
        {
            this.ActiveContact = FALSE;
            this.ActiveContactId = CONSTANTS_BRIC.GENERIC_BLANK;
            this.ActivePersonContact = FALSE;
            this.ActivePersonContactId = CONSTANTS_BRIC.GENERIC_BLANK;
            this.ActiveInvoice = FALSE;
            this.ActiveInvoiceId = CONSTANTS_BRIC.GENERIC_BLANK;
            this.ActiveInvoiceLineItem = FALSE;
            this.ActiveInvoiceLineItemId = CONSTANTS_BRIC.GENERIC_BLANK;
        }
        
        public Boolean GetActiveContact()
        {
            return this.ActiveContact;
        }
        
        public String GetActiveContactId()
        {
            return this.ActiveContactId;
        }
        
        public Boolean GetActivePersonContact()
        {
            return this.ActivePersonContact;
        }
        
        public String GetActivePersonContactId()
        {
            return this.ActivePersonContactId;
        }
        
        public Boolean GetActiveInvoice()
        {
            return this.ActiveInvoice;
        }
        
        public String GetActiveInvoiceId()
        {
            return this.ActiveInvoiceId;
        }
        
        public Boolean GetActiveInvoiceLineItem()
        {
            return this.ActiveInvoiceLineItem;
        }
        
        public String GetActiveInvoiceLineItemId()
        {
            return this.ActiveInvoiceLineItemId;
        }
        
        public void SetActiveContact(Boolean foundActive)
        {
            this.ActiveContact = foundActive;
        }
        
        public void SetActiveContactId(String recordId)
        {
            this.ActiveContactId = recordId;
        }
        
        public void SetActivePersonContact(Boolean foundActive)
        {
            this.ActivePersonContact = foundActive;
        }
        
        public void SetActivePersonContactId(String recordId)
        {
            this.ActivePersonContactId = recordId;
        }
        
        public void SetActiveInvoice(Boolean foundActive)
        {
            this.ActiveInvoice = foundActive;
        }
        
        public void SetActiveInvoiceId(String recordId)
        {
            this.ActiveInvoiceId = recordId;
        }
        
        public void SetActiveInvoiceLineItem(Boolean foundActive)
        {
            this.ActiveInvoiceLineItem = foundActive;
        }
        
        public void SetActiveInvoiceLineItemId(String recordId)
        {
            this.ActiveInvoiceLineItemId = recordId;
        }
    }
    
    public class BeforeUpdate
    {
        private Boolean ActiveContact;
        private String ActiveContactId;
        private Boolean ActivePersonContact;
        private String ActivePersonContactId;
        private Boolean ActiveInvoice;
        private String ActiveInvoiceId;
        private Boolean ActiveInvoiceLineItem;
        private String ActiveInvoiceLineItemId;
        
        public void Initialization()
        {
            this.ActiveContact = FALSE;
            this.ActiveContactId = CONSTANTS_BRIC.GENERIC_BLANK;
            this.ActivePersonContact = FALSE;
            this.ActivePersonContactId = CONSTANTS_BRIC.GENERIC_BLANK;
            this.ActiveInvoice = FALSE;
            this.ActiveInvoiceId = CONSTANTS_BRIC.GENERIC_BLANK;
            this.ActiveInvoiceLineItem = FALSE;
            this.ActiveInvoiceLineItemId = CONSTANTS_BRIC.GENERIC_BLANK;
        }
        
        public Boolean GetActiveContact()
        {
            return this.ActiveContact;
        }
        
        public String GetActiveContactId()
        {
            return this.ActiveContactId;
        }
        
        public Boolean GetActivePersonContact()
        {
            return this.ActivePersonContact;
        }
        
        public String GetActivePersonContactId()
        {
            return this.ActivePersonContactId;
        }
        
        public Boolean GetActiveInvoice()
        {
            return this.ActiveInvoice;
        }
        
        public String GetActiveInvoiceId()
        {
            return this.ActiveInvoiceId;
        }
        
        public Boolean GetActiveInvoiceLineItem()
        {
            return this.ActiveInvoiceLineItem;
        }
        
        public String GetActiveInvoiceLineItemId()
        {
            return this.ActiveInvoiceLineItemId;
        }
        
        public void SetActiveContact(Boolean foundActive)
        {
            this.ActiveContact = foundActive;
        }
        
        public void SetActiveContactId(String recordId)
        {
            this.ActiveContactId = recordId;
        }
        
        public void SetActivePersonContact(Boolean foundActive)
        {
            this.ActivePersonContact = foundActive;
        }
        
        public void SetActivePersonContactId(String recordId)
        {
            this.ActivePersonContactId = recordId;
        }
        
        public void SetActiveInvoice(Boolean foundActive)
        {
            this.ActiveInvoice = foundActive;
        }
        
        public void SetActiveInvoiceId(String recordId)
        {
            this.ActiveInvoiceId = recordId;
        }
        
        public void SetActiveInvoiceLineItem(Boolean foundActive)
        {
            this.ActiveInvoiceLineItem = foundActive;
        }
        
        public void SetActiveInvoiceLineItemId(String recordId)
        {
            this.ActiveInvoiceLineItemId = recordId;
        }
    }
}