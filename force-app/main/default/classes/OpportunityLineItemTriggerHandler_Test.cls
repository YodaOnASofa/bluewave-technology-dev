@isTest
private class OpportunityLineItemTriggerHandler_Test {
    @TestSetup
    static void setup() {
        List<Product2> products = new List<Product2> {
            new Product2(Name = 'Product 1', IsActive = true),
            new Product2(Name = 'Product 2', IsActive = true)
        };
        insert products;

        List<Stock_Count__c> stockCounts = new List<Stock_Count__c> {
            new Stock_Count__c(Name = 'Count 1', Product__c = products[0].Id, Stock_Count__c = 10),
            new Stock_Count__c(Name = 'Count 2', Product__c = products[1].Id, Stock_Count__c = 10)
        };
        insert stockCounts;

        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry> {
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, IsActive = true, UnitPrice = 10),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, IsActive = true, UnitPrice = 10)
        };
        insert pricebookEntries;

        Date closeDate = System.today().addDays(30);
        List<Opportunity> opportunities = new List<Opportunity> {
            new Opportunity(Name = 'Opportunity 1', StageName = 'Prospecting', CloseDate = closeDate, Pricebook2Id = pricebookId),
            new Opportunity(Name = 'Opportunity 2', StageName = 'Prospecting', CloseDate = closeDate, Pricebook2Id = pricebookId)
        };
        insert opportunities;
    }

    @isTest
    static void testInsertWithQuantity() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opportunity.Id, Product2Id = product.Id, Quantity = 4, TotalPrice = 40);

        Test.startTest();
        insert item;
        Test.stopTest();

        Stock_Count__c stockCount = [SELECT Stock_Count__c FROM Stock_Count__c WHERE Product__c = :product.Id];
        System.assertEquals(6, stockCount.Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');
    }

    @isTest
    static void testInsertWithNotEnoughStock() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opportunity.Id, Product2Id = product.Id, Quantity = 11, TotalPrice = 110);

        Boolean exceptionThrown = false;
        String exceptionMessage;
        Test.startTest();
        try {
            insert item;
        } catch (Exception ex) {
            exceptionThrown = true;
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should be thrown.');
        System.assertEquals(true, exceptionMessage.contains('Not enough stock'), 'The exception message should indicate the lack of stock.');
    }

    @isTest
    static void testInsertWithStockCountFieldNotSet() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Stock_Count__c stockCount = [SELECT Id, Product__c, Stock_Count__c FROM Stock_Count__c LIMIT 1];
        stockCount.Stock_Count__c = null;
        update stockCount;

        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opportunity.Id, Product2Id = stockCount.Product__c, Quantity = 4, TotalPrice = 40);

        Boolean exceptionThrown = false;
        String exceptionMessage;
        Test.startTest();
        try {
            insert item;
        } catch (Exception ex) {
            exceptionThrown = true;
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should be thrown.');
        System.assertEquals(true, exceptionMessage.contains('Stock Count field is not set on Stock Count record'), 'The exception message should indicate the Stock Count field is not set.');
    }

    @isTest
    static void testInsertWithMissingStockCountRecord() {
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Stock_Count__c stockCount = [SELECT Id, Product__c, Stock_Count__c FROM Stock_Count__c LIMIT 1];
        Id productId = stockCount.Product__c;
        delete stockCount;

        OpportunityLineItem item = new OpportunityLineItem(OpportunityId = opportunity.Id, Product2Id = productId, Quantity = 4, TotalPrice = 40);

        Boolean exceptionThrown = false;
        String exceptionMessage;
        Test.startTest();
        try {
            insert item;
        } catch (Exception ex) {
            exceptionThrown = true;
            exceptionMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'An exception should be thrown.');
        System.assertEquals(true, exceptionMessage.contains('Stock Count record is missing'), 'The exception message should indicate the Stock Count record is missing.');
    }

    // @isTest
    // static void testInsertWithDecimalQuantity() {

    // }

    // @isTest
    // static void testInsertWithNegativeQuantity() {

    // }

    // @isTest
    // static void testInsertWithMultipleItems() {

    // }

    // @isTest
    // static void testInsertWithValidProfile() {

    // }

    // @isTest
    // static void testInsertWithInvalidProfile() {
        
    // }

    // Helper methods
    // private static List<Product2> createProducts(Integer count) {
    //     List<Product2> products = new List<Product2>();
    //     for (Integer index = 1; index <= count; index++) {
    //         products.add(new Product2(
    //             Name = 'Product ' + index,
    //             IsActive = true
    //         ));
    //     }
    //     insert products;
    //     return products;
    // }

    // private static List<Stock_Count__c> createStockCounts(List<Product2> products) {
    //     List<Stock_Count__c> stockCounts = new List<Stock_Count__c>();
    //     for (Integer index = 0; index < products.size(); index++) {
    //         stockCounts.add(new Stock_Count__c(
    //             Name = 'Stock Count ' + (index + 1),
    //             Product__c = products[index].Id,
    //             Stock_Count__c = 10
    //         ));
    //     }
    //     insert stockCounts;
    //     return stockCounts;
    // }

    // private static List<Opportunity> createOpportunities(List<Product2> products) {
    //     List<Opportunity> opportunities = new List<Opportunity>();
    //     for (Product2 product : products) {
    //         opportunities.add(new Opportunity(
    //             Name = product.Name.replace('Product', 'Opportunity'),
    //         ));
    //     }
    //     insert opportunities;
    //     return opportunities;
    // }

    // private static List<OpportunityLineItem> createItemsFrame() {
    //     List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
    //     List<Product2> products = [SELECT Id FROM Product2];
    //     List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
    //     for (Integer index = 0; index < products.length(); index++) {
    //         lineItems.add(new OpportunityLineItem(
    //             Name = 'Item ' + (index + 1),
    //             Product2Id = products[index].Id,

    //         )
    //     }
    // }
}