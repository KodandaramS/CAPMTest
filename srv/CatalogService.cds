using { EDM.db.master, EDM.db.transaction, EDM.db.CDSView } from '../db/datamodel';


service CatalogService@(path:'/CatalogService') 
    @(requires: 'authenticated-user')
{
    // @readonly
    @Capabilities : { Insertable, Updatable, Deletable: false }
    entity EmployeeSet 
    @(restrict : [
    { grant: ['READ'], to: 'Viewer',
        where: 'bankName = $user.BankName' },
    { grant: ['READ'], to: 'Admin' }
    ])
    as projection on master.employees;

    @Capabilities : { Readable: false }
    entity AddressSet as projection on master.address;

    entity ProductSet as projection on master.product;

    entity BPSet as projection on master.businesspartner;

    entity POs @(
        odata.draft.enabled: true,
        title: '{i18n>poHeader}'
    ) as projection on transaction.purchaseorder{
        *,
        Items: redirected to POItems,
        PO_ID as PO_ID: String(20),
        case OVERALL_STATUS
            when 'N' then 'New'
            when 'D' then 'Delivered'
            when 'B' then 'Blocked'
            when 'P' then 'Paid'
            end as OVERALL_STATUS : String(20),
        case OVERALL_STATUS
            when 'N' then 2
            when 'D' then 3
            when 'B' then 1
            when 'P' then 3
            end as Criticality: Integer
    }actions{
        function largestOrder() returns array of POs;
        action boost();
    }

    annotate POs with {
        PO_ID @title : '{i18n>PO_ID}'
    };
    
    entity POItems @( title : '{i18n>poItems}' )
    as projection on transaction.poitems{
        *,
        PARENT_KEY: redirected to POs,
        PRODUCT_GUID: redirected to ProductSet
    }

    entity POWorklist as projection on CDSView.POWorklist;
    entity ProductOrders as projection on CDSView.ProductViewSub;
    entity ProductAggregation as projection on CDSView.CProductValuesView excluding{
        ProductId
    };
    
}