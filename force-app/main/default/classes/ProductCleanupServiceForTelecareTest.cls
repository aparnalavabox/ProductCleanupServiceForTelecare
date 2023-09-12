/**
 * Created by aparnagopalakrishnan on 12/09/23.
 */

@isTest
public class ProductCleanupServiceForTelecareTest {
    @IsTest(SeeAllData = true)
    static void unitTest() {
        Order o = [select OrderId__c from Order where Type = 'recurring' LIMIT 1];
        insert new ProductFixForTelecare__c (Name = o.OrderId__c,
                ToProduct__c = 'TEL-ALM-BUN-MWF5-10',
                Frequency__c ='Fortnightly',
                LineDiscountAmount__c = null,
                LineGSTAmount__c = 115.66,
                LineTotalAmount__c = 1120,
                ListPrice__c = 1104.3478,
                New_Product_Name__c = 'Medical Alarm & Mobile Alarm - Wellington Free Area - Fortnightly',
                TotalPrice__c = 1104.34,
                UnitPrice__c= 1104.34);
        ProductCleanupServiceForTelecareBatch.startBatchProcessing(1);
    }

}