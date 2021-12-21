public class OpportunityLineItemTriggerHandler extends TriggerHandler {
    private static final Set<String> VALID_PROFILES;
    private static final String USER_PROFILE;
    private static Map<Id, OpportunityLineItem> productToLineItemMap;
    private static Map<Id, Decimal> productToQuantityMap;
    private static Map<Id, Stock_Count__c> productToStockCountMap;
    private static List<OpportunityLineItem> missingQuantityItems;
    private static List<OpportunityLineItem> negativeQuantityItems;
    private static Set<Id> missingStockCountRecordProducts;
    private static Set<Id> missingStockCountFieldProducts;
    private static Set<Id> lackStockProducts;

    static {
        VALID_PROFILES = new Set<String> {'System Administrator', 'Custom: Sales Profile'};
        USER_PROFILE = getUserProfile();
        productToLineItemMap = new Map<Id, OpportunityLineItem>();
        productToQuantityMap = new Map<Id, Decimal>();
        productToStockCountMap = new Map<Id, Stock_Count__c>();
        missingQuantityItems = new List<OpportunityLineItem>();
        negativeQuantityItems = new List<OpportunityLineItem>();
        missingStockCountRecordProducts = new Set<Id>();
        missingStockCountFieldProducts = new Set<Id>();
        lackStockProducts = new Set<Id>();
    }

    public override void beforeInsert() {
        if (!validateProfile()) {
            addInvalidProfileError(Trigger.new);
            return;
        }

        createLineItemAndQuantityMaps(Trigger.new);

        addMissingQuantityItemError();
        addNegativeQuantityItemError();

        if (anyErrors()) return;

        createStockCountMap();

        List<Stock_Count__c> stockCountsToUpdate = getStockCountsToUpdate();

        addMissingStockCountRecordError();
        addMissingStockLevelError();
        addLackStockError();

        if (!anyErrors() && !stockCountsToUpdate.isEmpty()) {
            update stockCountsToUpdate;
        }
    }

    private void createLineItemAndQuantityMaps(List<SObject> items) {
        for(OpportunityLineItem item : (List<OpportunityLineItem>)items) {
            if (!validateItemQuanity(item)) continue;

            productToLineItemMap.put(item.Product2Id, item);

            Decimal currentQuantity = 0;
            if (productToQuantityMap.containsKey(item.Product2Id)) {
                currentQuantity = productToQuantityMap.get(item.Product2Id);
            }
            productToQuantityMap.put(item.Product2Id, currentQuantity + item.Quantity);
        }
    }

    private void createStockCountMap() {
        List<Stock_Count__c> stockCounts = [SELECT Id, Product__c, Stock_Count__c FROM Stock_Count__c WHERE Product__c IN :productToQuantityMap.keySet()];
        for (Stock_Count__c stockCount : stockCounts) {
            productToStockCountMap.put(stockCount.Product__c, stockCount);
        }
    }

    private List<Stock_Count__c> getStockCountsToUpdate() {
        List<Stock_Count__c> stockCountsToUpdate = new List<Stock_Count__c>();
        for (Id productId : productToQuantityMap.keySet()) {
            if (!validateStockCountRecordExist(productId)) continue;

            Decimal quantity = productToQuantityMap.get(productId);
            Stock_Count__c stockCount = productToStockCountMap.get(productId);

            if (!validateStockLevel(stockCount, quantity)) continue;

            stockCountsToUpdate.add(
                new Stock_Count__c(
                    Id = stockCount.Id,
                    Stock_Count__c = stockCount.Stock_Count__c - quantity
                )
            );
        }
        return stockCountsToUpdate;
    }

    private Boolean validateProfile() {
        return VALID_PROFILES.contains(USER_PROFILE);
    }

    private static String getUserProfile() {
        return [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
    }

    private Boolean validateItemQuanity(OpportunityLineItem item) {
        if (item.Quantity == null) {
            missingQuantityItems.add(item);
            return false;
        } else if (item.Quantity < 0) {
            negativeQuantityItems.add(item);
            return false;
        }
        return true;
    }

    private Boolean validateStockCountRecordExist(Id productId) {
        if (!productToStockCountMap.containsKey(productId)) {
            missingStockCountRecordProducts.add(productId);
            return false;
        }
        return true;
    }

    private Boolean validateStockLevel(Stock_Count__c stockCount, Decimal requestedQuantity) {
        if (stockCount.Stock_Count__c == null) {
            missingStockCountFieldProducts.add(stockCount.Product__c);
            return false;
        } else if (stockCount.Stock_Count__c < requestedQuantity) {
            lackStockProducts.add(stockCount.Product__c);
            return false;
        }
        return true;
    }

    private void addInvalidProfileError(List<SObject> items) {
        for (OpportunityLineItem item : (List<OpportunityLineItem>)items) item.addError('Invalid user profile');
    }

    private void addMissingQuantityItemError() {
        for (OpportunityLineItem item : missingQuantityItems) item.addError('Quantity is not set');
    }

    private void addNegativeQuantityItemError() {
        for (OpportunityLineItem item : negativeQuantityItems) item.addError('Quantity should not be negative');
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
        return !missingQuantityItems.isEmpty() || !negativeQuantityItems.isEmpty() || !missingStockCountRecordProducts.isEmpty() || !missingStockCountFieldProducts.isEmpty() || !lackStockProducts.isEmpty();
    }
}