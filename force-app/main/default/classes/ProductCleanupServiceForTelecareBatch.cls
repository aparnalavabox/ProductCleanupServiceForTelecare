/**
 * Created by aparnagopalakrishnan on 12/09/23.
 */

global class ProductCleanupServiceForTelecareBatch implements Database.Batchable<sObject> {
    private static Integer batchLimit = 1;
    global ProductCleanupServiceForTelecareBatch() {
    }
    global static ID startBatchProcessing() {
        return Database.executeBatch(new ProductCleanupServiceForTelecareBatch(), batchLimit);
    }
    global static ID startBatchProcessing(Integer batchLimit) {
        return Database.executeBatch(new ProductCleanupServiceForTelecareBatch(), batchLimit);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('select Id, Name, ToProduct__c from ProductFixForTelecare__c where Completed__c = FALSE');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<ProductFixForTelecare__c> toDelete = (List<ProductFixForTelecare__c>) scope;

        for(ProductFixForTelecare__c currentRecord : toDelete) {
            ProductCleanupServiceForTelecare.cleanupOrderProduct(currentRecord.Name, currentRecord.ToProduct__c);
        }

    }

    global void finish(Database.BatchableContext BC) {
        //delete [select Id from ProductFixForTelecare__c where Deleted__c = TRUE];
    }
}