-- migrate column from sale_production_links to mrp_sale_info
alter table mrp_production rename column sale_order_id to sale_id;
