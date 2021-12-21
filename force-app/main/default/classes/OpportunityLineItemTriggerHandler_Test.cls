@isTest
private class OpportunityLineItemTriggerHandler_Test {
    @TestSetup
    static void setup() {
        List<Product2> products = new List<Product2> {
            new Product2(Name = 'Product 1', IsActive = true),
            new Product2(Name = 'Product 2', IsActive = true),
            new Product2(Name = 'Product 3', IsActive = true)
        };
        insert products;

        List<Stock_Count__c> stockCounts = new List<Stock_Count__c> {
            new Stock_Count__c(Name = 'Count 1', Product__c = products[0].Id, Stock_Count__c = 10),
            new Stock_Count__c(Name = 'Count 2', Product__c = products[1].Id, Stock_Count__c = 10),
            new Stock_Count__c(Name = 'Count 3', Product__c = products[2].Id, Stock_Count__c = 10)
        };
        insert stockCounts;

        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry> {
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, IsActive = true, UnitPrice = 10),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, IsActive = true, UnitPrice = 10),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[2].Id, IsActive = true, UnitPrice = 10)
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
        List<Opportunity> opportunities = getOpportunities(1);
        List<Product2> products = getProducts(1);
        OpportunityLineItem item = createLineItem(opportunities[0], products[0], 4);

        Test.startTest();
        insert item;
        Test.stopTest();

        List<Stock_Count__c> stockCounts = getStockCounts(products);
        System.assertEquals(6, stockCounts[0].Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');
    }

    @isTest
    static void testInsertWithNotEnoughStock() {
        List<Opportunity> opportunities = getOpportunities(1);
        List<Product2> products = getProducts(1);
        OpportunityLineItem item = createLineItem(opportunities[0], products[0], 11);

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
        System.assertEquals(true, exceptionMessage.contains('Not enough stock'), 'The exception message should indicate the lack of stock. Actual message: ' + exceptionMessage);
    }

    @isTest
    static void testInsertWithStockCountFieldNotSet() {
        List<Opportunity> opportunities = getOpportunities(1);
        Stock_Count__c stockCount = [SELECT Id, Product__c, Stock_Count__c FROM Stock_Count__c LIMIT 1];
        stockCount.Stock_Count__c = null;
        update stockCount;

        Product2 product = new Product2(Id = stockCount.Product__c);
        OpportunityLineItem item = createLineItem(opportunities[0], product, 4);

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
        System.assertEquals(true, exceptionMessage.contains('Stock Count field is not set on Stock Count record'), 'The exception message should indicate the Stock Count field is not set. Actual message: ' + exceptionMessage);
    }

    @isTest
    static void testInsertWithMissingStockCountRecord() {
        List<Opportunity> opportunities = getOpportunities(1);
        Stock_Count__c stockCount = [SELECT Id, Product__c, Stock_Count__c FROM Stock_Count__c LIMIT 1];
        Id productId = stockCount.Product__c;
        delete stockCount;

        Product2 product = new Product2(Id = stockCount.Product__c);
        OpportunityLineItem item = createLineItem(opportunities[0], product, 4);

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
        System.assertEquals(true, exceptionMessage.contains('Stock Count record is missing'), 'The exception message should indicate the Stock Count record is missing. Actual message: ' + exceptionMessage);
    }

    @isTest
    static void testInsertWithUnknownQuantity() {
        List<Opportunity> opportunities = getOpportunities(1);
        List<Product2> products = getProducts(1);
        OpportunityLineItem item = createLineItem(opportunities[0], products[0], 4);
        item.Quantity = null;

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
        System.assertEquals(true, exceptionMessage.contains('Quantity is not set'), 'The exception message should indicate the requested quantity should be set. Actual message: ' + exceptionMessage);
    }

    @isTest
    static void testInsertWithNegativeQuantity() {
        List<Opportunity> opportunities = getOpportunities(1);
        List<Product2> products = getProducts(1);
        OpportunityLineItem item = createLineItem(opportunities[0], products[0], -4);

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
        System.assertEquals(true, exceptionMessage.contains('Quantity should not be negative'), 'The exception message should indicate the requested quantity should not be negative. Actual message: ' + exceptionMessage);
    }

    @isTest
    static void testInsertWithMultipleItems() {
        List<Opportunity> opportunities = getOpportunities(1);
        List<Product2> products = getProducts(2);
        List<OpportunityLineItem> items = new List<OpportunityLineItem> {
            createLineItem(opportunities[0], products[0], 4),
            createLineItem(opportunities[0], products[1], 4)
        };

        Test.startTest();
        insert items;
        Integer numOfDMLs = Limits.getDMLStatements();
        Test.stopTest();

        List<Stock_Count__c> stockCounts = getStockCounts(products);
        System.assertEquals(6, stockCounts[0].Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');
        System.assertEquals(6, stockCounts[1].Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');

        System.assertEquals(2, numOfDmls, 'There should only be 2 DMLs, one for inserting the line items, another for updating the Stock Count records.');
    }

    @isTest
    static void testInsertWithMultipleOpportunities() {
        List<Opportunity> opportunities = getOpportunities(2);
        List<Product2> products = getProducts(2);
        List<OpportunityLineItem> items = new List<OpportunityLineItem> {
            createLineItem(opportunities[0], products[0], 4),
            createLineItem(opportunities[1], products[1], 4)
        };

        Test.startTest();
        insert items;
        Integer numOfDMLs = Limits.getDMLStatements();
        Test.stopTest();

        List<Stock_Count__c> stockCounts = getStockCounts(products);
        System.assertEquals(6, stockCounts[0].Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');
        System.assertEquals(6, stockCounts[1].Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');

        System.assertEquals(2, numOfDmls, 'There should only be 2 DMLs, one for inserting the line items, another for updating the Stock Count records.');
    }

    @isTest
    static void testInsertWithMultipleOpportunitiesShareSameProduct() {
        List<Opportunity> opportunities = getOpportunities(2);
        List<Product2> products = getProducts(1);
        List<OpportunityLineItem> items = new List<OpportunityLineItem> {
            createLineItem(opportunities[0], products[0], 4),
            createLineItem(opportunities[1], products[0], 4)
        };

        Test.startTest();
        insert items;
        Integer numOfDMLs = Limits.getDMLStatements();
        Test.stopTest();

        List<Stock_Count__c> stockCounts = getStockCounts(products);
        System.assertEquals(2, stockCounts[0].Stock_Count__c, 'Stock count should be reduced by the total quantity on the line items against the same product.');

        System.assertEquals(2, numOfDmls, 'There should only be 2 DMLs, one for inserting the line items, another for updating the Stock Count records.');
    }

    @isTest
    static void testInsertWithMultipleOpportunitiesSomeCommonProduct() {
        List<Opportunity> opportunities = getOpportunities(2);
        List<Product2> products = getProducts(3);
        List<OpportunityLineItem> items = new List<OpportunityLineItem> {
            createLineItem(opportunities[0], products[0], 4),
            createLineItem(opportunities[0], products[1], 4),
            createLineItem(opportunities[1], products[0], 4),
            createLineItem(opportunities[1], products[2], 4)
        };

        Test.startTest();
        insert items;
        Integer numOfDMLs = Limits.getDMLStatements();
        Test.stopTest();

        List<Stock_Count__c> stockCounts = getStockCounts(products);
        System.assertEquals(2, stockCounts[0].Stock_Count__c, 'Stock count should be reduced by the total quantity on the line items against the same product.');
        System.assertEquals(6, stockCounts[1].Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');
        System.assertEquals(6, stockCounts[2].Stock_Count__c, 'Stock count should be reduced by the quantity on the line item.');

        System.assertEquals(2, numOfDmls, 'There should only be 2 DMLs, one for inserting the line items, another for updating the Stock Count records.');
    }

    @isTest
    static void testInsertWithValidProfile() {
        Id profileId = getProfileId('Custom: Sales Profile');
        User testUser = createUser(profileId);

        Boolean exceptionThrown = false;

        System.runAs(testUser) {
            List<Opportunity> opportunities = getOpportunities(1);
            List<Product2> products = getProducts(1);
            OpportunityLineItem item = createLineItem(opportunities[0], products[0], 4);

            Test.startTest();
            try {
                insert item;
            } catch (Exception ex) {
                exceptionThrown = true;
            }
            Test.stopTest();
        }

        System.assertEquals(false, exceptionThrown, 'No exception should be thrown.');
    }

    @isTest
    static void testInsertWithInvalidProfile() {
        Id profileId = getProfileId('Standard User');
        User testUser = createUser(profileId);

        Boolean exceptionThrown = false;
        String exceptionMessage;

        System.runAs(testUser) {
            List<Opportunity> opportunities = getOpportunities(1);
            List<Product2> products = getProducts(1);
            OpportunityLineItem item = createLineItem(opportunities[0], products[0], 4);

            Test.startTest();
            try {
                insert item;
            } catch (Exception ex) {
                exceptionThrown = true;
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();
        }

        System.assertEquals(true, exceptionThrown, 'An exception should be thrown as the user is not having the correct profile.');
        System.assertEquals(true, exceptionMessage.contains('Invalid user profile'), 'The exception message should indicate the user profile is invalid. Actual message: ' + exceptionMessage);
    }

    // Helper methods
    private static List<Opportunity> getOpportunities(Integer count) {
        return [SELECT Id FROM Opportunity LIMIT :count];
    }

    private static List<Product2> getProducts(Integer count) {
        return [SELECT Id FROM Product2 LIMIT :count];
    }

    private static OpportunityLineItem createLineItem(Opportunity opportunity, Product2 product, Decimal quantity) {
        return new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Product2Id = product.Id,
            Quantity = quantity,
            TotalPrice = 10 * quantity
        );
    }

    private static List<Stock_Count__c> getStockCounts(List<Product2> products) {
        return [SELECT Stock_Count__c FROM Stock_Count__c WHERE Product__c IN :products ORDER BY Name ASC];
    }

    private static Id getProfileId(String profileName) {
        return [SELECT Id FROM Profile WHERE Name = :profileName].Id;
    }

    private static User createUser(Id profileId) {
        return new User(
            Alias = 'tester',
            Email='apex.tester@example.com', 
            EmailEncodingKey='UTF-8',
            LastName='Tester',
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US',
            ProfileId = profileId, 
            TimeZoneSidKey='Europe/London',
            UserName='apex.tester@example.com'
        );
    }
}