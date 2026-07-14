/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	March 22, 2021
 * Description: 	Class to run the Trigger Handler of an object
 * Test Class: 		N/A
 * History: 		Mar. 22, 2021 - Creation
					Mar. 25, 2021 - Added conditions to prevent trigger recursion
  						  		  - Segmented code to methods
 */
public class TriggerRunner 
{
	private static Boolean BeforeInsertHasExecuted = false; 
    private static Boolean BeforeUpdateHasExecuted = false;
    private static Boolean BeforeDeleteHasExecuted = false;
    private static Boolean AfterInsertHasExecuted = false;
    private static Boolean AfterUpdateHasExecuted = false;
    private static Boolean AfterDeleteHasExecuted = false;
    
    public static void RunTriggerHandler(String SObjectName)
    {
        List<TriggerHandler__mdt> TriggerHandlerSetting = [SELECT 
                                                           	TriggerHandlerClassName__c, BeforeInsert__c, BeforeUpdate__c,
                                                            BeforeDelete__c, AfterInsert__c, AfterUpdate__c, AfterDelete__c
                                                           FROM 
                                                           	TriggerHandler__mdt 
                                                           WHERE DeveloperName = :SObjectName];

        if(!TriggerHandlerSetting.isEmpty())
        {
            TriggerHandler Handler = InstantiateTriggerHandler(TriggerHandlerSetting[0].TriggerHandlerClassName__c);
            
            if(Handler == null)
            {
                for(SObject sObjectRecord : trigger.new)
                {
                    SObjectRecord.AddError(CONSTANTS_BRIC.ERROR_MESSAGE_TRIGGER_HANDLER_METADATA_DOES_NOT_EXIST(SObjectName));
                }
            	return;
            }

            ExecuteTriggerHandler(TriggerHandlerSetting[0] , Handler);
        }
        else
        {
            for(SObject sObjectRecord : trigger.new)
            {
                SObjectRecord.AddError(CONSTANTS_BRIC.ERROR_MESSAGE_TRIGGER_HANDLER_DOES_NOT_EXIST(SObjectName));
            }
            return;
        }
    }
    
    private static TriggerHandler InstantiateTriggerHandler(String triggerHandlerName)
    {
        Type HandlerClass = Type.forName(triggerHandlerName);
        TriggerHandler Handler;
        
        try
        {
            Handler = (TriggerHandler)HandlerClass.newInstance();
            return Handler;
        }
        catch(Exception err)
        {
            return null;
        }
    }
    
    private static void ExecuteTriggerHandler(TriggerHandler__mdt TriggerHandlerSetting , TriggerHandler Handler)
    {
        Handler.GenericInitialization(trigger.old , trigger.new , trigger.oldMap , trigger.newMap);
        
        Switch on trigger.OperationType
        {
            When BEFORE_INSERT 
            {
                if(TriggerHandlerSetting.BeforeInsert__c && !BeforeInsertHasExecuted)
                {
                    BeforeInsertHasExecuted = true;
                    Handler.BeforeInsertInitialization(trigger.new , trigger.newMap);
                    Handler.BeforeInsertProcess(trigger.new , trigger.newMap);
                }
            }
            When BEFORE_UPDATE 
            {
                if(TriggerHandlerSetting.BeforeUpdate__c && !BeforeUpdateHasExecuted)
                {
                    BeforeUpdateHasExecuted = true;
                    Handler.BeforeUpdateInitialization(trigger.old , trigger.new , trigger.oldMap , trigger.newMap);
                    Handler.BeforeUpdateProcess(trigger.old , trigger.new , trigger.oldMap , trigger.newMap);
                } 
            }
            When BEFORE_DELETE 
            {
                if(TriggerHandlerSetting.BeforeDelete__c && !BeforeDeleteHasExecuted)
                {
                    BeforeDeleteHasExecuted = true;
                    Handler.BeforeDeleteInitialization(trigger.old , trigger.oldMap);
                    Handler.BeforeDeleteProcess(trigger.old , trigger.oldMap);
                }
            }
            When AFTER_INSERT 
            {
                if(TriggerHandlerSetting.AfterInsert__c && !AfterInsertHasExecuted)
                {
                    AfterInsertHasExecuted = true;
                    Handler.AfterInsertInitialization(trigger.new , trigger.newMap);
                    Handler.AfterInsertProcess(trigger.new , trigger.newMap);
                    Handler.AfterInsertDMLOperations();
                }
            }
            When AFTER_UPDATE 
            {
                if(TriggerHandlerSetting.AfterUpdate__c && !AfterUpdateHasExecuted)
                { 
                    AfterUpdateHasExecuted = true;
                    Handler.AfterUpdateInitialization(trigger.old , trigger.new , trigger.oldMap , trigger.newMap);
                    Handler.AfterUpdateProcess(trigger.old , trigger.new , trigger.oldMap , trigger.newMap);
                    Handler.AfterUpdateDMLOperations();
                }
            }
            When AFTER_DELETE 
            {
                if(TriggerHandlerSetting.AfterDelete__c && !AfterDeleteHasExecuted)
                {
                    AfterDeleteHasExecuted = true;
                    Handler.AfterDeleteInitialization(trigger.old , trigger.oldMap);
                    Handler.AfterDeleteProcess(trigger.old , trigger.oldMap);
                    Handler.AfterDeleteDMLOperations();
                } 
            }
        }
    }
}