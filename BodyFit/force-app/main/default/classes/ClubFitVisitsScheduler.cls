global class ClubFitVisitsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Run the batch job; adjust batch size if needed.
        Database.executeBatch(new ClubFitVisitsBatch(), 1);
    }
}