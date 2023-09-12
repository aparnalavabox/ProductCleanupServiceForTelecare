/**
 * Created by aparnagopalakrishnan on 12/09/23.
 */

public class ProductCleanupServiceForTelecare  {
    public static void cleanupOrderProduct(String orderNo, String toProduct) {

        ProductFixForTelecare__c fix = [select Id,
                Name,
                ToProduct__c,
                Frequency__c,
                LineDiscountAmount__c,
                LineGSTAmount__c,
                LineTotalAmount__c,
                ListPrice__c,
                New_Product_Name__c,
                TotalPrice__c,
                UnitPrice__c
        from ProductFixForTelecare__c where Name = :orderNo Limit 1];

        toProduct = fix.ToProduct__c;

        Order baseOrder = [select Id,Status,OrderId__c from Order where OrderId__c = :orderNo LIMIT 1];
        String orderStatus = baseOrder.Status;
        baseOrder.Status = 'Draft';
        update baseOrder;
        List<OrderItem> orderItems = OrderItemController.getOrderItemsForUniqueOrder('OrderId__c', orderNo);
        OrderItem toBeRemoved = orderItems.get(0);
        OrderItem newOrderItem = toBeRemoved.clone();
        OrderItem oldOrderItem = [select Id,
        (select Id,Name, EventCode__c,OrderItem__c,ProductSKU__c,Product2Id,Product_Capability_Description__c from Assets__r),
        (select Id, Billing_Frequency__c, Order_Product__c, Product__c, Unit_Price__c from Billing_Schedules__r)
        from OrderItem where OrderId = :baseOrder.Id Limit 1];

        List<Asset> assets = oldOrderItem.Assets__r;//[select Id,Name, EventCode__c,OrderItem__c,ProductSKU__c from Asset ];
        List<Billing_Schedule__c> billingSchedules = oldOrderItem.Billing_Schedules__r;//[select Id, Billing_Frequency__c, Order_Product__c, Product__c, Unit_Price__c from Billing_Schedule__c];

        PricebookEntry pbe = [select Id,Product2Id,UnitPrice,Product2.Billing_Frequency__c from PricebookEntry where ProductCode =: toProduct LIMIT 1];
        newOrderItem.PricebookEntryId = pbe.Id;
        newOrderItem.Product2Id = pbe.Product2Id;
        newOrderItem.Billing_Frequency__c = fix.Frequency__c;
        newOrderItem.UnitPrice = fix.UnitPrice__c;
        newOrderItem.ListPrice = pbe.UnitPrice;//fix.ListPrice__c; calculated
        //newOrderItem.TotalPrice = 1; calculated
        newOrderItem.LineDiscountAmount__c = fix.LineDiscountAmount__c;
        newOrderItem.LineGSTAmount__c = fix.LineGSTAmount__c;
        //newOrderItem.LinePromoCode__c = 'x';
        newOrderItem.LineTotalAmount__c = fix.LineTotalAmount__c;
        //newOrderItem.ProductFamilyName__c = 'x';calculated
        //newOrderItem.ProductName__c = 'x';calculated
        //newOrderItem.ProductOfferName__c= 'x'; calculated
        //newOrderItem.ProductOptionName__c= 'x'; calculated
        //newOrderItem.ProductVariantName__c= 'x';calculated
        insert newOrderItem;

        for(Asset currentAsset: assets) {
            currentAsset.OrderItem__c = newOrderItem.Id;
            currentAsset.EventCode__c = toProduct;
            currentAsset.ProductSKU__c = toProduct;
            currentAsset.Product2ID = pbe.Product2Id;
            currentAsset.Name = fix.New_Product_Name__c + ' - ' + currentAsset.Product_Capability_Description__c;
        }
        if(!assets.isEmpty()) update assets;

        for(Billing_Schedule__c currentSchedule: billingSchedules) {
            currentSchedule.Order_Product__c = newOrderItem.Id;
            currentSchedule.Billing_Frequency__c = getFrequencyLabel(fix.Frequency__c);
            currentSchedule.Amount_to_be_billed__c = fix.LineTotalAmount__c;
            //currentSchedule.Unit_Price__c = pbe.UnitPrice; calculated
            //currentSchedule.Product__c = pbe.Product2Id; calculated
        }
        if(!billingSchedules.isEmpty()) update billingSchedules;

        List<Billing_Transaction__c> transactions = new List<Billing_Transaction__c>([select Id,Rate__c from Billing_Transaction__c where Order_No__c= :orderNo]);
        for(Billing_Transaction__c currentTransaction: transactions) {
            currentTransaction.Rate__c = fix.UnitPrice__c;
        }
        if(!transactions.isEmpty()) update transactions;
        delete toBeRemoved;
        baseOrder.Status = orderStatus;
        update baseOrder;
        OrderRestResource.publishFISOrderByOrderId(baseOrder.Id, OrderService.orderActions.UPDATE_DETAILS.name());
        ProductFixForTelecare__c toDelete = [select Id from ProductFixForTelecare__c where Name =: orderNo LIMIT 1];
        toDelete.Completed__c = TRUE;
        update toDelete;
    }

    private static String getFrequencyLabel(String frequency) {

        switch on frequency {
            when 'Fortnightly' {
                return '2W';
            }
            when 'One Payment' {
                return '1P';
            }
            when 'Weekly' {
                return '1W';
            }
            when 'Monthly' {
                return '1M';
            }
            when 'Quarterly' {
                return '3M';
            }
            when 'Six Monthly' {
                return '6M';
            }
            when 'Yearly' {
                return '12M';
            }
            when else {
                return '';
            }

        }

    }


}