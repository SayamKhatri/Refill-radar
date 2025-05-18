-- fact_inventory

CREATE OR REPLACE PROCEDURE hasp_dw.sp_merge_fact_inventory()
LANGUAGE plpgsql
AS $$
BEGIN
  MERGE INTO hasp_dw.fact_inventory
  USING public.stg_inventory AS s
    ON hasp_dw.fact_inventory.product_id = s.product_id
  WHEN MATCHED THEN
    UPDATE SET
      quantity_available = s.quantity_available,
      last_updated       = s.last_updated
  WHEN NOT MATCHED THEN
    INSERT (product_id, quantity_available, last_updated)
    VALUES (s.product_id, s.quantity_available, s.last_updated);

  DROP TABLE IF EXISTS public.stg_inventory;
END;
$$;

-- fact_sales_transactions 

CREATE OR REPLACE PROCEDURE hasp_dw.sp_load_fact_sales()
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO hasp_dw.fact_sales (
    transaction_id, product_id, cashier_id, store_id,
    promotion_id, payment_method_id, quantity_sold,
    discount_per_unit, sale_datetime
  )
  SELECT *
  FROM public.stg_sales_transactions;

  DROP TABLE IF EXISTS public.stg_sales_transactions;
END;
$$;
