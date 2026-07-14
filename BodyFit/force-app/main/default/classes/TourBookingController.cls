public class TourBookingController {
    public List<SelectOption> availableSlots { get; set; }
    public String selectedSlot { get; set; } // Changed from Id to String
    public Date selectedDate { get; set; }
    public Id clubId { get; set; }
    public Id leadId { get; set; } // New property for leadId
    public String clubName { get; set; } // Added property for club name

    public TourBookingController() {
        // Initialize available slots list
        availableSlots = new List<SelectOption>();

        // Capture the clubId and leadId from the URL
        clubId = ApexPages.currentPage().getParameters().get('clubId');
        leadId = ApexPages.currentPage().getParameters().get('leadId');

        // If clubId or leadId is not provided, add an error message
        if (String.isEmpty(clubId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Club ID is missing.'));
        }
        if (String.isEmpty(leadId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead ID is missing.'));
        }

        if (!String.isEmpty(clubId)) {
            // Query for the club name based on the clubId
            try {
                clubName = [SELECT Name FROM Club__c WHERE Id = :clubId].Name;
            } catch (Exception e) {
                clubName = 'Unknown Club';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error fetching club name.'));
            }
        }
    }

    // Helper method to compute day of week (1=Sun, 2=Mon, ... 7=Sat)
    private Integer getDayOfWeek(Date d) {
        // Known Sunday
        Date referenceSunday = Date.newInstance(1900, 1, 7);
        // Difference in days from that reference Sunday
        Integer diff = referenceSunday.daysBetween(d);
        // mod 7 yields which day of the week
        Integer mod7 = Math.mod(diff, 7);
        // If mod7=0 => Sunday => 1, if mod7=1 => Monday => 2, etc.
        return mod7 + 1;
    }

    // Method to load available time slots for the selected date and club
    public void loadAvailableSlots() {
        if (selectedDate != null && clubId != null) {
            // Clear previous available slots
            availableSlots.clear();
            System.debug('ClubId: ' + clubId);
            System.debug('Selected Date: ' + selectedDate);

            // Get day of week (1=Sun, 2=Mon, ... 7=Sat)
            Integer dayOfWeek = getDayOfWeek(selectedDate);

            Integer startHour;
            Integer closingHour;
            Integer lastBookingHour;
            Integer lastBookingMinute;

            // Monday–Friday => dayOfWeek 2..6
            if(dayOfWeek >= 2 && dayOfWeek <= 6) {
                // 8:00 AM to 7:00 PM
                startHour = 8;
                closingHour = 19;
                // Last slot starts at 6:30 PM
                lastBookingHour = 19;
                lastBookingMinute = 30;
            } else {
                // Saturday & Sunday => dayOfWeek = 1 or 7
                // 9:00 AM to 2:00 PM
                startHour = 9;
                closingHour = 14;
                // Last slot starts at 1:30 PM
                lastBookingHour = 13;
                lastBookingMinute = 30;
            }

            Datetime startOfDay = Datetime.newInstance(
                selectedDate.year(),
                selectedDate.month(),
                selectedDate.day(),
                startHour,
                0,
                0
            );
            Datetime endOfDay = Datetime.newInstance(
                selectedDate.year(),
                selectedDate.month(),
                selectedDate.day(),
                closingHour,
                0,
                0
            );

            // Query existing bookings for the selected club and date within the operating hours
            List<Club_Tour__c> existingTours = [
                SELECT Start_Time__c, End_Time__c
                FROM Club_Tour__c
                WHERE Club__c = :clubId
                AND Start_Time__c >= :startOfDay
                AND Start_Time__c < :endOfDay
            ];
            System.debug('Existing Tours: ' + existingTours);

            // Convert existing tours' times into a set of unavailable slot labels (HH:mm)
            Set<String> unavailableSlots = new Set<String>();
            for (Club_Tour__c tour : existingTours) {
                String timeSlot = tour.Start_Time__c.format('HH:mm');
                unavailableSlots.add(timeSlot);
            }

            // Loop through half-hour increments to generate available slots.
for (Integer hour = startHour; hour <= closingHour; hour++) {
    for (Integer minute = 0; minute < 60; minute += 30) {
        // Skip if past last booking time
        if (hour > lastBookingHour || (hour == lastBookingHour && minute > lastBookingMinute)) {
            continue;
        }
        // Format hour as two digits (e.g. "09" for 9)
        String formattedHour = (hour < 10 ? '0' + String.valueOf(hour) : String.valueOf(hour));
        String timeLabel = formattedHour + ':' + (minute == 0 ? '00' : '30');
        if (!unavailableSlots.contains(timeLabel)) {
            availableSlots.add(new SelectOption(timeLabel, timeLabel));
        }
    }
}

            System.debug('Available Slots: ' + availableSlots);
        }
    }

    // Method to handle the booking of the selected tour
    public PageReference bookTour() {
        if (selectedSlot != null) {
            try {
                // Parse selectedSlot into Hour and Minute
                String[] timeParts = selectedSlot.split(':');
                Integer hour = Integer.valueOf(timeParts[0]);
                Integer minute = Integer.valueOf(timeParts[1]);

                // Create a Time object using Time.newInstance
                Time selectedTime = Time.newInstance(hour, minute, 0, 0);

                // Create a new club tour record with the selected time slot
                Club_Tour__c newTour = new Club_Tour__c();
                newTour.Start_Time__c = Datetime.newInstance(selectedDate, selectedTime);
                newTour.Club__c = clubId;
                newTour.Lead__c = leadId; // Map the leadId to Lead__c field

                // Remove existing bookings for the same club, date, and time
                List<Club_Tour__c> conflictingTours = [
                    SELECT Id
                    FROM Club_Tour__c
                    WHERE Club__c = :clubId
                    AND Start_Time__c = :newTour.Start_Time__c
                ];

                if (!conflictingTours.isEmpty()) {
                    delete conflictingTours;
                    System.debug('Deleted conflicting tours: ' + conflictingTours);
                }

                // Insert the new tour
                insert newTour;

                // Add a confirmation message
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.CONFIRM,
                    'Tour booked successfully!'
                ));

                // Redirect to the thank-you page
                PageReference thankYouPage = new PageReference('https://bodyfit.com.au/thank-you/');
                thankYouPage.setRedirect(true);
                return thankYouPage;

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    'Error booking the tour: ' + e.getMessage()
                ));
                return null;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Please select a time slot.'
            ));
            return null;
        }
    }
}