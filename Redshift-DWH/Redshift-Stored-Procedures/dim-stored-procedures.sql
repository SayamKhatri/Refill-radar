-- SCD TYPE 1 
-- dim_products
CREATE OR REPLACE PROCEDURE hasp_dw.sp_merge_dim_product()
LANGUAGE plpgsql
AS $$
BEGIN
  MERGE INTO hasp_dw.dim_product
  USING public.stg_products AS s
    ON hasp_dw.dim_product.product_id = s.product_id
  WHEN MATCHED THEN
    UPDATE SET
      sku_number    = s.sku_number,
      name          = s.name,
      brand         = s.brand,
      category      = s.category,
      regular_price = s.regular_price
  WHEN NOT MATCHED THEN
    INSERT (product_id, sku_number, name, brand, category, regular_price)
    VALUES (s.product_id, s.sku_number, s.name, s.brand, s.category, s.regular_price);

  DROP TABLE IF EXISTS public.stg_products;
END;
$$;

-- dim_store

CREATE OR REPLACE PROCEDURE hasp_dw.sp_merge_dim_store()
LANGUAGE plpgsql
AS $$
BEGIN
  MERGE INTO hasp_dw.dim_store
  USING public.stg_stores AS s
    ON hasp_dw.dim_store.store_id = s.store_id
  WHEN MATCHED THEN
    UPDATE SET
      store_number = s.store_number,
      store_name   = s.store_name,
      district     = s.district,
      region       = s.region
  WHEN NOT MATCHED THEN
    INSERT (store_id, store_number, store_name, district, region)
    VALUES (s.store_id, s.store_number, s.store_name, s.district, s.region);

  DROP TABLE IF EXISTS public.stg_stores;
END;
$$;

-- dim_cashier

CREATE OR REPLACE PROCEDURE hasp_dw.sp_merge_dim_cashier()
LANGUAGE plpgsql
AS $$
BEGIN
  MERGE INTO hasp_dw.dim_cashier
  USING public.stg_cashiers AS s
    ON hasp_dw.dim_cashier.cashier_id = s.cashier_id
  WHEN MATCHED THEN
    UPDATE SET
      employee_number = s.employee_number,
      name            = s.name
  WHEN NOT MATCHED THEN
    INSERT (cashier_id, employee_number, name)
    VALUES (s.cashier_id, s.employee_number, s.name);

  DROP TABLE IF EXISTS public.stg_cashiers;
END;
$$;


-- dim_promotion

CREATE OR REPLACE PROCEDURE hasp_dw.sp_merge_dim_promotion()
LANGUAGE plpgsql
AS $$
BEGIN
  MERGE INTO hasp_dw.dim_promotion
  USING public.stg_promotions AS s
    ON hasp_dw.dim_promotion.promotion_id = s.promotion_id
  WHEN MATCHED THEN
    UPDATE SET
      promotion_code = s.promotion_code,
      name           = s.name,
      media_type     = s.media_type,
      begin_date     = s.begin_date,
      end_date       = s.end_date
  WHEN NOT MATCHED THEN
    INSERT (promotion_id, promotion_code, name, media_type, begin_date, end_date)
    VALUES (s.promotion_id, s.promotion_code, s.name, s.media_type, s.begin_date, s.end_date);

  DROP TABLE IF EXISTS public.stg_promotions;
END;
$$;

-- dim_payment_method

CREATE OR REPLACE PROCEDURE hasp_dw.sp_merge_dim_payment_method()
LANGUAGE plpgsql
AS $$
BEGIN
  MERGE INTO hasp_dw.dim_payment_method
  USING public.stg_payment_methods AS s
    ON hasp_dw.dim_payment_method.payment_method_id = s.payment_method_id
  WHEN MATCHED THEN
    UPDATE SET
      payment_description = s.payment_description,
      payment_group       = s.payment_group
  WHEN NOT MATCHED THEN
    INSERT (payment_method_id, payment_description, payment_group)
    VALUES (s.payment_method_id, s.payment_description, s.payment_group);

  DROP TABLE IF EXISTS public.stg_payment_methods;
END;
$$;

