/*
 * Author: 			Alfonso Maquilan
 * Created Date: 	January 04, 2021
 * Description: 	Trigger Handler abstract class
 * Test Class:	 	N/A
 * History: 		Jan. 04, 2021 - Creation
*/
public abstract class TriggerHandler
{
    public abstract void GenericInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap);
    public abstract void BeforeInsertInitialization(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap);
    public abstract void BeforeUpdateInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap);
    public abstract void BeforeDeleteInitialization(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap);
    public abstract void AfterInsertInitialization(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap);
    public abstract void AfterUpdateInitialization(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap);
    public abstract void AfterDeleteInitialization(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap);
    public abstract void BeforeInsertProcess(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap);
    public abstract void BeforeUpdateProcess(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap);
    public abstract void BeforeDeleteProcess(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap);
    public abstract void AfterInsertProcess(List<SObject> newSObjectList , Map<Id , SObject> newSObjectMap);
    public abstract void AfterUpdateProcess(List<SObject> oldSObjectList , List<SObject> newSObjectList , Map<Id , SObject> oldSObjectMap , Map<Id , SObject> newSObjectMap);
    public abstract void AfterDeleteProcess(List<SObject> oldSObjectList , Map<Id , SObject> oldSObjectMap);
    public abstract void AfterInsertDMLOperations();
    public abstract void AfterUpdateDMLOperations();
    public abstract void AfterDeleteDMLOperations();
}