/*
* @Author: Bricoleur Technology
* @Date: March 5, 2026
* @Desc:
*
*/
public class FlowObjectDetector {
    @InvocableMethod(label='Get Object Name From Record ID')
    public static List<String> getObjectName(List<Id> recordIds) {
        List<String> objectNames = new List<String>();
        for (Id currentId : recordIds) {
            // This line gets the SObjectType dynamically
            objectNames.add(currentId.getSObjectType().getDescribe().getName());
        }
        return objectNames;
    }
}