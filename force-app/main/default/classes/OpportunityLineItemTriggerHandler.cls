public class OpportunityLineItemTriggerHandler extends TriggerHandler {
    // private static final Set<String> VALID_PROFILE_NAMES = new Set<String> {'System Administrator', 'Custom: Sales Profile'};
    private static Map<Id, OpportunityLineItem> productToLineItemMap;
    private static Map<Id, Decimal> productToQuantityMap;
    private static Map<Id, Stock_Count__c> productToStockCountMap;
    private static Set<Id> missingStockCountRecordProducts;
    private static Set<Id> missingStockCountFieldProducts;
    private static Set<Id> lackStockProducts;

    static {
        productToLineItemMap = new Map<Id, OpportunityLineItem>();
        productToQuantityMap = new Map<Id, Decimal>();
        productToStockCountMap = new Map<Id, Stock_Count__c>();
        missingStockCountRecordProducts = new Set<Id>();
        missingStockCountFieldProducts = new Set<Id>();
        lackStockProducts = new Set<Id>();
    }

    public override void beforeInsert() {
        for(OpportunityLineItem item : (List<OpportunityLineItem>) Trigger.new) {

            productToLineItemMap.put(item.Product2Id, item);

            Decimal currentQuantity = 0;
            if (productToQuantityMap.containsKey(item.Product2Id)) {
                currentQuantity = productToQuantityMap.get(item.Product2Id);
            }
            productToQuantityMap.put(item.Product2Id, currentQuantity + item.Quantity);
        }

        List<Stock_Count__c> stockCounts = [SELECT Id, Product__c, Stock_Count__c FROM Stock_Count__c WHERE Product__c IN :productToQuantityMap.keySet()];
        for (Stock_Count__c stockCount : stockCounts) {
            productToStockCountMap.put(stockCount.Product__c, stockCount);
        }

        List<Stock_Count__c> stockCountsToUpdate = new List<Stock_Count__c>();
        for (Id productId : productToQuantityMap.keySet()) {
            if (!validateStockCountRecordExist(productId)) continue;

            Decimal quantity = productToQuantityMap.get(productId);
            Stock_Count__c stockCount = productToStockCountMap.get(productId);

            if (!validateStockLevelIsSet(stockCount)) continue;
            if (!validateStockLevelIsEnough(stockCount, quantity)) continue;

            stockCountsToUpdate.add(
                new Stock_Count__c(
                    Id = stockCount.Id,
                    Stock_Count__c = stockCount.Stock_Count__c - quantity
                )
            );
        }

        addMissingStockCountRecordError();
        addMissingStockLevelError();
        addLackStockError();

        if (!anyErrors()) {
            update stockCountsToUpdate;
        }
    }

    private Boolean validateStockCountRecordExist(Id productId) {
        Boolean isValid = productToStockCountMap.containsKey(productId);
        if (!isValid) missingStockCountRecordProducts.add(productId);
        return isValid;
    }

    private Boolean validateStockLevelIsSet(Stock_Count__c stockCount) {
        Boolean isValid = stockCount.Stock_Count__c != null;
        if (!isValid) missingStockCountFieldProducts.add(stockCount.Product__c);
        return isValid;
    }

    private Boolean validateStockLevelIsEnough(Stock_Count__c stockCount, Decimal requestedQuantity) {
        Boolean isValid = stockCount.Stock_Count__c >= requestedQuantity;
        if (!isValid) lackStockProducts.add(stockCount.Product__c);
        return isValid;
    }

    private void addMissingStockCountRecordError() {
        for (Id productId : missingStockCountRecordProducts) {
            productToLineItemMap.get(productId).addError('Stock Count record is missing');
        }
    }

    private void addMissingStockLevelError() {
        for (Id productId : missingStockCountFieldProducts) {
            productToLineItemMap.get(productId).addError('Stock Count field is not set on Stock Count record');
        }
    }

    private void addLackStockError() {
        for (Id productId : lackStockProducts) {
            productToLineItemMap.get(productId).addError('Not enough stock');
        }
    }

    private Boolean anyErrors() {
        return !missingStockCountRecordProducts.isEmpty() && !missingStockCountFieldProducts.isEmpty() && !lackStockProducts.isEmpty();
    }

    // private Boolean isUserValid() {
    //     String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.ProfileId].Name;
    //     return 
    // }

    public class OpportunityLineItemTriggerHandlerException extends Exception {}
}