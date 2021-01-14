create table cust2 as
select
      *,
      case
        when industry = 'Financial' and jurisdiction = 'Canada' then 'Domestic Banks'
        when industry <> 'Financial' and jurisdiction = 'Canada' then 'Other Domestic'
        else 'Foreign cpty'
      end as cpty_type
from customer
;

create table sec2 as
select
      *,
      case 
          when industry = 'Sovereign' and security_type = 'Bond' then 'Level_1_Asset'
          when industry not in ('Sovereign', 'Financial', 'Insurance') 
           and issuer_credit_rating like 'A%' 
           and issuer_credit_rating <> 'A-' then 'Level_2_Asset'
          else 'Level_3_Asset'
      end as asset_class
from sec
;

create table cust_join as
select a.*,
       b.cpty_type
from col_trans a
inner join cust2 b
on a.customer_id = b.customer_id
where a.product_type = 'Security'
;


create table sec_join as
select
      a.*,
      coalesce(b.asset_class, c.asset_class) as asset_class
from cust_join a
left join sec2 b
on a.security_id = b.security_id
left join sec2 c
on a.security_id = c.security_id_2
;


create table sec_join_2 as
select
      a.*,
      b.asset_class
from cust_join a
left join sec2 b
on a.security_id = b.security_id
  or a.security_id = b.security_id_2
;

create table sec_join_3 as
select
      a.*,
      (
       select b.asset_class from sec2 b
       where b.security_id = a.security_id 
          or b.security_id_2 = a.security_id 
      ) as asset_class
from cust_join a
;


create table output as
select
      cpty_type,
      case
          when post_direction = 'Deliv to Bank' then 'Collateral Received'
          else 'Collateral Pledged'
      end as direction,
      margin_type,
      sum(case when asset_class = 'Level_1_Asset' then pv_cde else 0 end) Level_1_Asset,
      sum(case when asset_class = 'Level_2_Asset' then pv_cde else 0 end) Level_2_Asset,
      sum(case when asset_class = 'Level_3_Asset' then pv_cde else 0 end) Level_3_Asset
from sec_join 
group by cpty_type, direction, margin_type
order by cpty_type, direction, margin_type
;

create table rep_struct as
select 
      a.cpty_type,
      b.direction,
      c.margin_type
from (select distinct cpty_type from output) a
 cross join (select distinct direction from output) b
 cross join (select distinct margin_type from output) c
order by a.cpty_type, b.direction, c.margin_type
;


create table col_trans_report as
select
      a.cpty_type,
      a.direction,
      a.margin_type "Collateral Type",
      coalesce(b.Level_1_Asset, 0) Level_1_Asset,
      coalesce(b.Level_2_Asset, 0) Level_2_Asset,
      coalesce(b.Level_3_Asset, 0) Level_3_Asset
from rep_struct a
left join output b
on a.cpty_type = b.cpty_type
   and a.direction = b.direction
   and a.margin_type = b.margin_type
;










