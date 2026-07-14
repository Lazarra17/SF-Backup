/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	May  21, 2021
 * Description: 	Trigger Handler for Xero Inbound Field Mapping object
 * Test Class: 		XeroInFieldMapTriggerHandlerTest
 * History: 		May  22, 2021 - Creation
 * 					July 2, 2021 - Added checking for Person Account (anything with "Person")
 */
public class XeroInFieldMapTriggerHandler extends TriggerHandler
{
	private static XeroInFieldMapTriggerHandlerObj.BeforeInsert BeforeInsertObject;  
    private static XeroInFieldMapTriggerHandlerObj.BeforeUpdate BeforeUpdateObject;  
     
    private class ValidateFieldMappingActivationParams
    {
        private XeroInboundFieldMapping__c FieldMappingRecord;
        private Boolean ActiveContactFound;
        private Boolean ActivePersonContactFound;
        private Boolean ActiveInvoiceFound;
        private Boolean ActiveInvoiceLineItemFound;
        private String ActiveContactId;
        private String ActivePersonContactId;
        private String ActiveInvoiceId;
        private String ActiveInvoiceLineItemId;
    }
    
    public override void GenericInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
		BeforeInsertObject = new XeroInFieldMapTriggerHandlerObj.BeforeInsert();
        BeforeUpdateObject = new XeroInFieldMapTriggerHandlerObj.BeforeUpdate();
        BeforeInsertObject.Initialization();
		BeforeUpdateObject.Initialization();        
        
        Boolean activeContactFound = FALSE;
        String activeContactFoundId = CONSTANTS_BRIC.GENERIC_BLANK;
        Boolean activePersonContactFound = FALSE;
        String activePersonContactFoundId = CONSTANTS_BRIC.GENERIC_BLANK;
        Boolean activeInvoiceFound = FALSE;
        String activeInvoiceFoundId = CONSTANTS_BRIC.GENERIC_BLANK;
        Boolean activeInvoiceLineItemFound = FALSE;
        String activeInvoiceLineItemFoundId = CONSTANTS_BRIC.GENERIC_BLANK;
        
        for(XeroInboundFieldMapping__c fieldMappingRecord : [SELECT Id , Is_Person_Account_Bric__c, XeroObject__c FROM XeroInboundFieldMapping__c WHERE Active__c = TRUE])
        {
            Switch on fieldMappingRecord.XeroObject__c
            {
                When 'CONTACT'
                {                    
                    if(fieldMappingRecord.Is_Person_Account_Bric__c){
                        activePersonContactFoundId = fieldMappingRecord.Id;
                		activePersonContactFound = TRUE;
                    } else{                    
                        activeContactFoundId = fieldMappingRecord.Id;
                        activeContactFound = TRUE;
                    }
                }
                When 'INVOICE'
                {
                    activeInvoiceFoundId = fieldMappingRecord.Id;
                	activeInvoiceFound = TRUE;
                }
                When 'INVOICE LINE ITEM'
                {
                    activeInvoiceLineItemFoundId = fieldMappingRecord.Id;
                	activeInvoiceLineItemFound = TRUE;
                }
            }
                
            if(activeContactFound && activePersonContactFound && activeInvoiceFound && activeInvoiceLineItemFound) break;
        }
        
        BeforeInsertObject.SetActiveContact(activeContactFound);
        BeforeInsertObject.SetActiveContactId(activeContactFoundId);
        BeforeInsertObject.SetActivePersonContact(activePersonContactFound);
        BeforeInsertObject.SetActivePersonContactId(activePersonContactFoundId);
        BeforeInsertObject.SetActiveInvoice(activeInvoiceFound);
        BeforeInsertObject.SetActiveInvoiceId(activeInvoiceFoundId);
        BeforeInsertObject.SetActiveInvoiceLineItem(activeInvoiceLineItemFound);
        BeforeInsertObject.SetActiveInvoiceLineItemId(activeInvoiceLineItemFoundId);
        
        BeforeUpdateObject.SetActiveContact(activeContactFound);
        BeforeUpdateObject.SetActiveContactId(activeContactFoundId);
        BeforeUpdateObject.SetActivePersonContact(activePersonContactFound);
        BeforeUpdateObject.SetActivePersonContactId(activePersonContactFoundId);
        BeforeUpdateObject.SetActiveInvoice(activeInvoiceFound);
        BeforeUpdateObject.SetActiveInvoiceId(activeInvoiceFoundId);
        BeforeUpdateObject.SetActiveInvoiceLineItem(activeInvoiceLineItemFound);
        BeforeUpdateObject.SetActiveInvoiceLineItemId(activeInvoiceLineItemFoundId);
    }
    
    public override void BeforeInsertInitialization(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {
    }
    
    public override void BeforeUpdateInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
    }
    
    public override void BeforeDeleteInitialization(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
    }
    
    public override void AfterInsertInitialization(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {
    }
    
    public override void AfterUpdateInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
    }
    
    public override void AfterDeleteInitialization(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
    }
    
    public override void BeforeInsertProcess(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {        
        ValidateFieldMappingActivationParams validateMappingParams = new ValidateFieldMappingActivationParams();
        validateMappingParams.ActiveContactFound = BeforeInsertObject.GetActiveContact();
        validateMappingParams.ActivePersonContactFound = BeforeInsertObject.GetActivePersonContact();
        validateMappingParams.activeInvoiceFound = BeforeInsertObject.GetActiveInvoice();
        validateMappingParams.activeInvoiceLineItemFound = BeforeInsertObject.GetActiveInvoiceLineItem();
        validateMappingParams.activeContactId = BeforeInsertObject.GetActiveContactId();
        validateMappingParams.activePersonContactId = BeforeInsertObject.GetActivePersonContactId();
        validateMappingParams.activeInvoiceId = BeforeInsertObject.GetActiveInvoiceId();
        validateMappingParams.activeInvoiceLineItemId = BeforeInsertObject.GetActiveInvoiceLineItemId();
        
        for(XeroInboundFieldMapping__c fieldMappingRecord : (List<XeroInboundFieldMapping__c>)newSObjectList)
        {
            validateMappingParams.FieldMappingRecord = fieldMappingRecord;
            ValidateFieldMappingActivation(validateMappingParams);
        }
    }
    
    public override void BeforeUpdateProcess(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
        ValidateFieldMappingActivationParams validateMappingParams = new ValidateFieldMappingActivationParams();
        validateMappingParams.ActiveContactFound = BeforeUpdateObject.GetActiveContact();
        validateMappingParams.ActivePersonContactFound = BeforeUpdateObject.GetActivePersonContact();
        validateMappingParams.activeInvoiceFound = BeforeUpdateObject.GetActiveInvoice();
        validateMappingParams.activeInvoiceLineItemFound = BeforeUpdateObject.GetActiveInvoiceLineItem();
        validateMappingParams.activeContactId = BeforeUpdateObject.GetActiveContactId();
        validateMappingParams.activePersonContactId = BeforeUpdateObject.GetActivePersonContactId();
        validateMappingParams.activeInvoiceId = BeforeUpdateObject.GetActiveInvoiceId();
        validateMappingParams.activeInvoiceLineItemId = BeforeUpdateObject.GetActiveInvoiceLineItemId();
        
        for(XeroInboundFieldMapping__c fieldMappingRecord : (List<XeroInboundFieldMapping__c>)newSObjectList)
        {
            validateMappingParams.FieldMappingRecord = fieldMappingRecord;
            ValidateFieldMappingActivation(validateMappingParams);
        }
    }
    
    public override void BeforeDeleteProcess(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
        
    }
    
    public override void AfterInsertProcess(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap)
    {

    }
    
    public override void AfterUpdateProcess(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap)
    {
        
    }
    
    public override void AfterDeleteProcess(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap)
    {
        
    }
    
    public override void AfterInsertDMLOperations()
    {

    }
    
    public override void AfterUpdateDMLOperations()
    {
        
    }
    
    public override void AfterDeleteDMLOperations()
    {
        
    }
    
    private static void ValidateFieldMappingActivation(ValidateFieldMappingActivationParams params)
    {
                
		Switch on params.FieldMappingRecord.XeroObject__c
        {
            When 'CONTACT'
            {
                if(CheckIfActiveExist(params.ActiveContactFound , params.FieldMappingRecord.Active__c ,params.ActiveContactId , params.FieldMappingRecord.Id) && !params.FieldMappingRecord.Is_Person_Account_Bric__c) 
                {	
                    params.FieldMappingRecord.addError(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_CONTACT_MAPPING_EXIST);
                }
                else if(EvaluateToTagAsActive(params.ActiveContactFound , params.ActiveContactId , params.FieldMappingRecord.Active__c))
                {
                    params.ActiveContactFound = TRUE;
                    params.ActiveContactId = params.FieldMappingRecord.Id;
                }
                
                
                if(params.FieldMappingRecord.Is_Person_Account_Bric__c && !Utilities_Bric.CheckIfPersonAccountEnabled()){
                    params.FieldMappingRecord.addError(CONSTANTS_BRIC.PERSONACCOUNT_NOT_ENABLED);
                } else {
                    if(CheckIfActiveExist(params.ActivePersonContactFound , params.FieldMappingRecord.Active__c ,params.ActivePersonContactId , params.FieldMappingRecord.Id) && params.FieldMappingRecord.Is_Person_Account_Bric__c) 
                    {	
                        params.FieldMappingRecord.addError(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_CONTACT_MAPPING_EXIST_PERSONACCOUNT);
                    }
                    else if(EvaluateToTagAsActive(params.ActivePersonContactFound , params.ActivePersonContactId , params.FieldMappingRecord.Active__c))
                    {
                        params.ActivePersonContactFound = TRUE;
                        params.ActivePersonContactId = params.FieldMappingRecord.Id;
                    }
                }
                
                
            }
            When 'INVOICE'
            {
                if(CheckIfActiveExist(params.ActiveInvoiceFound , params.FieldMappingRecord.Active__c , params.ActiveInvoiceId , params.FieldMappingRecord.Id))
                {
                    params.FieldMappingRecord.addError(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_INVOICE_MAPPING_EXIST);
                }
                else if(EvaluateToTagAsActive(params.ActiveInvoiceFound , params.ActiveInvoiceId , params.FieldMappingRecord.Active__c))
                {
                    params.ActiveInvoiceFound = TRUE;
                    params.ActiveInvoiceId = params.FieldMappingRecord.Id;
                }
            }
            When 'INVOICE LINE ITEM'
            {
                if(CheckIfActiveExist(params.ActiveInvoiceLineItemFound , params.FieldMappingRecord.Active__c , params.ActiveInvoiceLineItemId , params.FieldMappingRecord.Id))
                {
                    params.FieldMappingRecord.addError(CONSTANTS_BRIC.VALIDATION_ACTIVE_XERO_INVOICE_LINE_ITEM_MAPPING_EXIST);
                }
                else if(EvaluateToTagAsActive(params.ActiveInvoiceLineItemFound , params.ActiveInvoiceLineItemId , params.FieldMappingRecord.Active__c))
                {
                    params.ActiveInvoiceLineItemFound = TRUE;
                    params.ActiveInvoiceLineItemId = params.FieldMappingRecord.Id;
                }
            }
        }
    }
    
    private static Boolean CheckIfActiveExist(Boolean activeRecordFound , Boolean currentRecordActive , String activeRecordId , String currentRecordId)
    {
        return activeRecordFound && currentRecordActive && activeRecordId != currentRecordId;
    }
    
    private static Boolean EvaluateToTagAsActive(Boolean activeRecordFound , String activeRecordId , Boolean currentRecordActive)
    {
        return !activeRecordFound && !Utilities_Bric.CheckStringIfNullOrBlank(activeRecordId) && currentRecordActive;
    }
}