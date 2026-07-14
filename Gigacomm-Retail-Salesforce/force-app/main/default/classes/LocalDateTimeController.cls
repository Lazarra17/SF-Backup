/**
 * @description Controller for LocalDateTime vf component
 * @author Bricoleur Technologies
 * @date 01 Aug 2025
 */
public class LocalDateTimeController {
    public String timezoneName { get; set; }
    
    // Property to hold a potential error message for the component to display
    public String errorMessage { get; private set; }

    public DateTime getLocalDateTime() {
        // Manually check if the required attribute was passed
        if (String.isBlank(timezoneName)) {
            errorMessage = '[Error: The "timezone" attribute is required.]';
            return null; // Stop processing if the attribute is missing
        }

        Decimal offsetHours = 0; 
        try {
            Timezone_Configuration__mdt tzConfig = [
                SELECT UTC_Offset_Hours__c
                FROM Timezone_Configuration__mdt
                WHERE DeveloperName = :timezoneName
                LIMIT 1
            ];
            if (tzConfig != null && tzConfig.UTC_Offset_Hours__c != null) {
                offsetHours = tzConfig.UTC_Offset_Hours__c;
            }
        } catch (QueryException e) {
            System.debug('Timezone_Configuration__mdt for "' + timezoneName + '" not found. Using UTC.');
        }

        return Datetime.now().addHours(offsetHours.intValue());
    }
}