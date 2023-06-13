-- modify the type of the inspection check

with type_op as (
  select res_id as id from ir_model_data where module = 'customer_asset_freshfilter' and name = 'type_op'
),
q1 as (
  update customer_asset_inspection_type
  set type = 'op2'
  where id = (select id from type_op)
),
q2 as (
  delete from customer_asset_inspection_check
  where type_id = (select id from type_op)
  returning id
),
q3 as (
  delete from customer_asset_inspection_check_category
  where type_id = (select id from type_op)
),
q4 as (
  delete from customer_asset_inspection_check_rel
  where customer_asset_inspection_check_id in (select id from q2)
),
newcategory as (
  insert into customer_asset_inspection_check_category (
    create_uid, write_uid, create_date, write_date,
    name, sequence, type_id
  )
  select
  1, 1, now(), now(),
  'General',
  1,
  (select id from type_op)
  returning id
),
oldchecks as (
  select name as field_name, field_description as description
  from ir_model_fields where model_id in (
    select id from ir_model where model = 'customer_asset_inspection.inspection'
  ) and name ilike 'check%'
  and ttype = 'boolean'
),
-- migchecks as (
--   insert into customer_asset_inspection_check_rel
--   select * from _mig_customer_asset_inspection_check_rel
-- ),
newchecks as (
  insert into customer_asset_inspection_check (
    create_uid, write_uid, create_date, write_date,
    code, description, type_id, sequence, category_id, name
  )
  select
    1, 1, now(), now(),
    field_name,
    description,
    (select id from type_op),
    row_number() over (),
    (select id from newcategory),
    description
  from oldchecks
  returning id, code
),
newvalues1 as (
  insert into customer_asset_inspection_check_rel (
    customer_asset_inspection_inspection_id,
    customer_asset_inspection_check_id
  )
  select
    i.id,
    c.id
  from newchecks c, customer_asset_inspection_inspection i
  where i.type_id in (select id from type_op)
  and c.code != 'check_5ppm'
)
insert into customer_asset_inspection_check_rel (
  customer_asset_inspection_inspection_id,
  customer_asset_inspection_check_id
)
select
  i.id,
  c.id
from newchecks c, customer_asset_inspection_inspection i
where i.type_id in (select id from type_op)
and c.code = 'check_5ppm'
and i.check_5ppm = 't';
