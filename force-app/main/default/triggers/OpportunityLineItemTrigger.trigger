trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert) {
    new OpportunityLineItemTriggerHandler().run();
}