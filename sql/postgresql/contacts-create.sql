-- this table will be split, moved into accounts-payroll package which will use the contacts package
create table qal_employee (
  id integer default nextval('qal_id'),
  login varchar(100),
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  workphone varchar(20),
  homephone varchar(20),
  startdate date default current_date,
  enddate date,
  notes text,
  role varchar(20),
  sales bool default 'f',
  email text,
  ssn varchar(20),
  iban varchar(34),
  bic varchar(11),
  managerid integer,
  employeenumber varchar(32),
  dob date
);
--
-- This table is to be *somehow* get integrated into contacts package
CREATE TABLE qal_vendor (
  id integer default nextval('qal_id'),
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  terms integer default 0,
  taxincluded bool default 'f',
  vendornumber varchar(32),
  cc text,
  bcc text,
  gifi_accno varchar(30),
  business_id integer,
  taxnumber varchar(32),
  sic_code varchar(15),
  discount numeric,
  creditlimit numeric default 0,
  iban varchar(34),
  bic varchar(11),
  employee_id integer,
  language_code varchar(6),
  pricegroup_id integer,
  curr char(3),
  startdate date,
  enddate date
);
--
-- SIC, NAICS codes
-- code has been extended to allow use of UNSPC (and other) categorizations
-- references:
--  NAICS codes http://www.census.gov/epcd/naics/naicscod.txt
--  SIC crossreferences  http://www.census.gov/pub/epcd/www/naicstab.htm
--  ISIC and others  http://unstats.un.org/unsd/cr/
CREATE TABLE qal_sic (
  code varchar(15),
  sictype varchar(3),
  description text
);

-- This table is to be *somehow* get integrated into contacts package
CREATE TABLE qal_customer (
  id integer default nextval('qal_id'),
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  discount numeric,
  taxincluded bool default 'f',
  creditlimit numeric default 0,
  terms integer default 0,
  customernumber varchar(32),
  cc text,
  bcc text,
  business_id integer,
  taxnumber varchar(32),
  sic_code varchar(6),
  iban varchar(34),
  bic varchar(11),
  employee_id integer,
  language_code varchar(6),
  pricegroup_id integer,
  curr char(3),
  startdate date,
  enddate date
);
--

--
CREATE TABLE qal_customertax (
  customer_id integer,
  chart_id integer
);

--
CREATE TABLE qal_vendortax (
  vendor_id integer,
  chart_id integer
);


create index qal_customer_id_key on qal_customer (id);
create index qal_customer_customernumber_key on qal_customer (customernumber);
create index qal_customer_name_key on qal_customer (lower(name));
create index qal_customer_contact_key on qal_customer (lower(contact));
create index qal_customer_customer_id_key on qal_customertax (customer_id);
--
create index qal_employee_id_key on qal_employee (id);
create unique index qal_employee_login_key on qal_employee (login);
create index qal_employee_name_key on qal_employee (lower(name));

--
create index qal_vendor_id_key on qal_vendor (id);
create index qal_vendor_name_key on qal_vendor (lower(name));
create index qal_vendor_vendornumber_key on qal_vendor (vendornumber);
create index qal_vendor_contact_key on qal_vendor (lower(contact));
create index qal_vendortax_vendor_id_key on qal_vendortax (vendor_id);


--
CREATE FUNCTION qal_del_customer() RETURNS OPAQUE AS '
begin
  delete from qal_shipto where trans_id = old.id;
  delete from qal_customertax where customer_id = old.id;
  delete from qal_partscustomer where customer_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER qal_del_customer AFTER DELETE ON qal_customer FOR EACH ROW EXECUTE PROCEDURE qal_del_customer();
-- end trigger
--
CREATE FUNCTION qal_del_vendor() RETURNS OPAQUE AS '
begin
  delete from ecst_shipto where trans_id = old.id;
  delete from qal_vendortax where vendor_id = old.id;
  delete from ecca_partsvendor where vendor_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER qal_del_vendor AFTER DELETE ON qal_vendor FOR EACH ROW EXECUTE PROCEDURE qal_del_vendor();
-- end trigger

--  following from ecommerce needs to be adapted to contacts etc.

create sequence ec_address_id_seq start 1; 
create view ec_address_id_sequence as select nextval('ec_address_id_seq') as nextval;

create table ec_addresses (
        address_id      integer not null primary key,
        user_id         integer not null references users,
        address_type    varchar(20) not null,   -- e.g., billing
        attn            varchar(100),
        line1           varchar(100),
        line2           varchar(100),
        city            varchar(100),
        -- state
        -- Jerry, we'll need to creat the states table as part of this
        usps_abbrev     char(2) references us_states(abbrev),
        -- big enough to hold zip+4 with dash
        zip_code        varchar(10),
        phone           varchar(30),
        -- for international addresses
        -- Jerry, same for country_codes
        country_code    char(2) references countries(iso),
        -- this can be the province or region for an international address
        full_state_name varchar(30),
        -- D for day, E for evening
        phone_time      varchar(10)
);

create index ec_addresses_by_user_idx on ec_addresses (user_id);

create sequence ec_creditcard_id_seq start 1;
create view ec_creditcard_id_sequence as select nextval('ec_creditcard_id_seq') as nextval;

create table ec_creditcards (
        creditcard_id           integer not null primary key,
        user_id                 integer not null references users,
        -- Some credit card gateways do not ask for this but we'll store it anyway
        creditcard_type         char(1),
        -- no spaces; always 16 digits (oops; except for AMEX, which is 15)
        -- depending on admin settings, after we get success from the credit card gateway, 
        -- we may bash this to NULL
        creditcard_number       varchar(16),
        -- just the last four digits for subsequent UI
        creditcard_last_four    char(4),
        -- ##/## 
        creditcard_expire       char(5),
	billing_address 	integer references ec_addresses(address_id),
        -- if it ever failed (conclusively), set this to 't' so we
        -- won't give them the option of using it again
        failed_p                boolean default 'f'
);

create index ec_creditcards_by_user_idx on ec_creditcards (user_id);

create sequence ec_user_class_id_seq start 1;
create view ec_user_class_id_sequence as select nextval('ec_user_class_id_seq') as nextval;

create table ec_user_classes (
        user_class_id           integer not null primary key,
        -- human-readable
        user_class_name         varchar(200), -- e.g., student
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null
);

create table ec_user_classes_audit (
        user_class_id           integer,
        user_class_name         varchar(200), -- e.g., student
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f'
);

create function ec_user_classes_audit_tr ()
returns opaque as '
begin
        insert into ec_user_classes_audit (
        user_class_id, user_class_name,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.user_class_id, old.user_class_name,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address      
        );
	return new;
end;' language 'plpgsql';

create trigger ec_user_classes_audit_tr
after update or delete on ec_user_classes
for each row execute procedure ec_user_classes_audit_tr ();

-- one row per customer-user; all the extra info that the ecommerce
-- system needs

create table ec_user_class_user_map (
        user_id                 integer not null references users,
        user_class_id           integer not null references ec_user_classes,
                                    primary key (user_id, user_class_id),
        user_class_approved_p   boolean,
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null
);

create index ec_user_class_user_map_idx on ec_user_class_user_map (user_class_id);
create index ec_user_class_user_map_idx2 on ec_user_class_user_map (user_class_approved_p);

create table ec_user_class_user_map_audit (
        user_id                 integer,
        user_class_id           integer,
        user_class_approved_p   boolean,
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f'
);


create function ec_user_class_user_audit_tr ()
returns opaque as '
begin
        insert into ec_user_class_user_map_audit (
        user_id, user_class_id, user_class_approved_p,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.user_id, old.user_class_id, old.user_class_approved_p,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address      
        );
	return new;
end;' language 'plpgsql';

create trigger ec_user_class_user_audit_tr
after update or delete on ec_user_class_user_map
for each row execute procedure ec_user_class_user_audit_tr ();


create sequence ec_user_session_seq;
create view ec_user_session_sequence as select nextval('ec_user_session_seq') as nextval;

create table ec_user_sessions (
        user_session_id         integer not null constraint ec_session_id_pk primary key,
        -- often will not be known
        user_id                 integer references users,
        ip_address              varchar(20) not null,
        start_time              timestamptz,
        http_user_agent         varchar(4000)
);

create index ec_user_sessions_idx on ec_user_sessions(user_id);

create table ec_user_session_info (
        user_session_id         integer not null references ec_user_sessions,
        product_id              integer references ec_products,
        category_id             integer references ec_categories,
        search_text             varchar(200)
);

create index ec_user_session_info_idx  on ec_user_session_info (user_session_id);
create index ec_user_session_info_idx2 on ec_user_session_info (product_id);
create index ec_user_session_info_idx3 on ec_user_session_info (category_id);

-- If a user comes to product.tcl with an offer_code in the url,
-- I'm going to shove it into this table and then check this
-- table each time I try to determine the price for the users'
-- products.  The alternative is to store the offer_codes in a
-- cookie and look at that each time I try to determine the price
-- for a product.  But I think this will be a little faster.

create table ec_user_session_offer_codes (
        user_session_id         integer not null references ec_user_sessions,
        product_id              integer not null references ec_products,
        offer_code              varchar(20) not null,
        primary key (user_session_id, product_id)
);

-- create some indices
create index ec_u_s_offer_codes_by_u_s_id on ec_user_session_offer_codes(user_session_id);
create index ec_u_s_offer_codes_by_p_id on ec_user_session_offer_codes(product_id);

create sequence ec_order_id_seq start 3000000;
create view ec_order_id_sequence as select nextval('ec_order_id_seq') as nextval;

create table ec_orders (
        order_id        	integer not null primary key,
        -- can be null, until they've checked out or saved their basket
        user_id			integer  references users,
        user_session_id		integer references ec_user_sessions,
        order_state		varchar(50) default 'in_basket' not null,
        tax_exempt_p            boolean default 'f',
        shipping_method		varchar(20),    -- express or standard or pickup or 'no shipping'
        shipping_address        integer references ec_addresses(address_id),
        -- store credit card info in a different table
        creditcard_id		integer references ec_creditcards(creditcard_id),
        -- information recorded upon FSM state changes
        -- we need this to figure out if order is stale
        -- and should be offered up for removal
        in_basket_date          timestamptz,
        confirmed_date          timestamptz,
        authorized_date         timestamptz,
        voided_date             timestamptz,
        expired_date            timestamptz,
        -- base shipping, which is added to the amount charged for each item
        shipping_charged        numeric,
        shipping_refunded       numeric,
        shipping_tax_charged    numeric,
        shipping_tax_refunded   numeric,
        -- entered by customer service
        cs_comments             varchar(4000),
        reason_for_void         varchar(4000),
        voided_by               integer references users,
        -- if the user chooses to save their shopping cart
        saved_p                 boolean
        check (user_id is not null or user_session_id is not null)
);

create index ec_orders_by_user_idx on ec_orders (user_id);
create index ec_orders_by_user_sess_idx on ec_orders (user_session_id);
create index ec_orders_by_credit_idx on ec_orders (creditcard_id);
create index ec_orders_by_addr_idx on ec_orders (shipping_address);
create index ec_orders_by_conf_idx on ec_orders (confirmed_date);
create index ec_orders_by_state_idx on ec_orders (order_state);

-- note that an order could essentially become uninteresting for financial
-- accounting if all the items underneath it are individually voided or returned

create view ec_orders_reportable
as 
select * 
from ec_orders 
where order_state <> 'in_basket'
and order_state <> 'void';

-- orders that have items which still need to be shipped
create view ec_orders_shippable
as
select *
from ec_orders
where order_state in ('authorized','partially_fulfilled');


-- this is needed because orders might be only partially shipped
create sequence ec_shipment_id_seq;
create view ec_shipment_id_sequence as select nextval('ec_shipment_id_seq') as nextval;

create table ec_shipments (
        shipment_id             integer not null primary key,
        order_id                integer not null references ec_orders,
        -- usually, but not necessarily, the same as the shipping_address
        -- in ec_orders because a customer may change their address between
        -- shipments.
        -- a trigger fills address_id in automatically if it's null
        address_id              integer references ec_addresses,
        shipment_date           timestamptz not null,
        expected_arrival_date   timestamptz,
        carrier                 varchar(50),    -- e.g., 'fedex'
        tracking_number         varchar(24),
        -- only if we get confirmation from carrier that the goods
        -- arrived on a specific date
        actual_arrival_date     timestamptz,
        -- arbitrary info from carrier, e.g., 'Joe Smith signed for it'
        actual_arrival_detail   varchar(4000),
        -- for things that aren't really shipped like services
        shippable_p             boolean default 't',
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20)
);

create index ec_shipments_by_order_id on ec_shipments(order_id);
create index ec_shipments_by_shipment_date on ec_shipments(shipment_date);

-- fills address_id into ec_shipments if it's missing
-- (using the shipping_address associated with the order)
create function ec_shipment_address_update_tr ()
returns opaque as '
declare
        v_address_id            ec_addresses.address_id%TYPE;
begin
        select into v_address_id shipping_address 
	from ec_orders where order_id=new.order_id;
        IF new.address_id is null THEN
                new.address_id := v_address_id;
        END IF;
	return new;
end;' language 'plpgsql';

create trigger ec_shipment_address_update_tr
before insert on ec_shipments
for each row execute procedure ec_shipment_address_update_tr ();

create table ec_shipments_audit (
        shipment_id             integer,
        order_id                integer,
        address_id              integer,
        shipment_date           timestamptz,
        expected_arrival_date   timestamptz,
        carrier                 varchar(50),
        tracking_number         varchar(24),
        actual_arrival_date     timestamptz,
        actual_arrival_detail   varchar(4000),
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f'
);

create function ec_shipments_audit_tr ()
returns opaque as '
begin
        insert into ec_shipments_audit (
        shipment_id, order_id, address_id,
        shipment_date, 
        expected_arrival_date,
        carrier, tracking_number,
        actual_arrival_date, actual_arrival_detail,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.shipment_id, old.order_id, old.address_id,
        old.shipment_date,
        old.expected_arrival_date,
        old.carrier, old.tracking_number,
        old.actual_arrival_date, old.actual_arrival_detail,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address      
        );
	return new;
end;' language 'plpgsql';

create trigger ec_shipments_audit_tr
after update or delete on ec_shipments
for each row execute procedure ec_shipments_audit_tr ();

create sequence refund_id_seq;
create view refund_id_sequence as select nextval('refund_id_seq') as nextval;

create table ec_refunds (
        refund_id       integer not null primary key,
        order_id        integer not null references ec_orders,
        -- not really necessary because it's in ec_financial_transactions
        refund_amount   numeric not null,
        refund_date     timestamptz not null,
        refunded_by     integer not null references users,
        refund_reasons  varchar(4000)
);

create index ec_refunds_by_order_idx on ec_refunds (order_id);

-- these are the items that make up each order
create sequence ec_item_id_seq start 1; 
create view ec_item_id_sequence as select nextval('ec_item_id_seq') as nextval;

create table ec_items (
        item_id         integer not null primary key,
        order_id        integer not null references ec_orders,
        product_id      integer not null references ec_products,
        color_choice    varchar(4000),
        size_choice     varchar(4000),
        style_choice    varchar(4000),
        shipment_id     integer references ec_shipments,
        -- this is the date that user put this item into their shopping basket
        in_cart_date    timestamptz,
        voided_date     timestamptz,
        voided_by       integer references users,
        expired_date    timestamptz,
        item_state      varchar(50) default 'in_basket',
        -- NULL if not received back
        received_back_date      timestamptz,
        -- columns for reporting (e.g., what was done, what was made)
        price_charged           numeric,
        price_refunded          numeric,
        shipping_charged        numeric,
        shipping_refunded       numeric,
        price_tax_charged       numeric,
        price_tax_refunded      numeric,
        shipping_tax_charged    numeric,
        shipping_tax_refunded   numeric,
        -- like Our Price or Sale Price or Introductory Price
        price_name              varchar(30),
        -- did we go through a merchant-initiated refund?
        refund_id               integer references ec_refunds,
        -- comments entered by customer service (CS)
        cs_comments             varchar(4000)
);

create index ec_items_by_product on ec_items(product_id);
create index ec_items_by_order on ec_items(order_id);
create index ec_items_by_shipment on ec_items(shipment_id);

create view ec_items_reportable 
as 
select * 
from ec_items
where item_state in ('to_be_shipped', 'shipped', 'arrived');

create view ec_items_refundable
as
select *
from ec_items
where item_state in ('shipped','arrived')
and refund_id is null;

create view ec_items_shippable
as
select *
from ec_items
where item_state in ('to_be_shipped');

-- This view displays:
-- order_id
-- shipment_date
-- bal_price_charged sum(price_charged - price_refunded) for all items in the shipment
-- bal_shipping_charged
-- bal_tax_charged
-- The purpose: payment is recognized when an item ships so this sums the various
-- parts of payment (price, shipping, tax) for all the items in each shipment

-- gilbertw - there is a note in OpenACS 3.2.5 from DRB:
-- DRB: this view is never used and blows out Postgres, which thinks
-- it's too large even with a block size of (gulp) 16384!
-- gilbertw - this view is used now. 

create view ec_items_money_view
as
select i.shipment_id, i.order_id, s.shipment_date, coalesce(sum(i.price_charged),0) - coalesce(sum(i.price_refunded),0) as bal_price_charged,
coalesce(sum(i.shipping_charged),0) - coalesce(sum(i.shipping_refunded),0) as bal_shipping_charged,
coalesce(sum(i.price_tax_charged),0) - coalesce(sum(i.price_tax_refunded),0) + coalesce(sum(i.shipping_tax_charged),0)
  - coalesce(sum(i.shipping_tax_refunded),0) as bal_tax_charged
from ec_items i, ec_shipments s
where i.shipment_id=s.shipment_id
and i.item_state <> 'void'
group by i.order_id, i.shipment_id, s.shipment_date;

-- a set of triggers to update order_state based on what happens
-- to the items in the order
-- partially_fulfilled: some but not all non-void items have shipped
-- fulfilled: all non-void items have shipped
-- returned: all non-void items received_back
-- void: all items void
-- We're not interested in partial returns.

-- this is hellish because you can't select a count of the items
-- in a given item_state from ec_items when you're updating ec_items,
-- so we have to do a horrid "trio" (temporary table, row level trigger,
-- system level trigger) as discussed in
-- http://photo.net/doc/site-wide-search.html (we use a temporary
-- table instead of a package because they're better)

-- I. temporary table to hold the order_ids that have to have their
-- state updated as a result of the item_state changes

-- gilbertw - this table is not needed in PostgreSQL
--create global temporary table ec_state_change_order_ids (
--        order_id        integer
--);

-- gilbertw - this trigger is not needed
-- II. row-level trigger which updates ec_state_change_order_ids 
-- so we know which rows to update in ec_orders
-- create function ec_order_state_before_tr ()
-- returns opaque as '
-- begin
--         insert into ec_state_change_order_ids (order_id) values (new.order_id);
-- 	return new;
-- end;' language 'plpgsql';

-- create trigger ec_order_state_before_tr
-- before update on ec_items
-- for each row execute procedure ec_order_state_before_tr ();

-- III. System level trigger to update all the rows that were changed
-- in the before trigger.

-- gilbertw - I took the trigger procedure from OpenACS 3.2.5.
create function ec_order_state_after_tr ()
returns opaque as '
declare
        -- v_order_id              integer;
        n_items                 integer;
        n_shipped_items         integer;
        n_received_back_items   integer;
        n_void_items            integer;
        n_nonvoid_items         integer;

begin
	select count(*) into n_items from ec_items where order_id=NEW.order_id;
        select count(*) into n_shipped_items from ec_items 
	    where order_id=NEW.order_id
	    and item_state=''shipped'' or item_state=''arrived'';
        select count(*) into n_received_back_items
	    from ec_items where order_id=NEW.order_id
	    and item_state=''received_back'';
        select count(*) into n_void_items from ec_items 
	    where order_id=NEW.order_id and item_state=''void'';

        IF n_items = n_void_items THEN
            update ec_orders set order_state=''void'', voided_date=now()
		where order_id=NEW.order_id;
        ELSE
            n_nonvoid_items := n_items - n_void_items;
            IF n_nonvoid_items = n_received_back_items THEN
                update ec_orders set order_state=''returned'' 
		    where order_id=NEW.order_id;
            ELSE 
		IF n_nonvoid_items = n_received_back_items + n_shipped_items THEN
		    update ec_orders set order_state=''fulfilled'' 
			where order_id=NEW.order_id;
            	ELSE
		    IF n_shipped_items >= 1 or n_received_back_items >=1 THEN
			update ec_orders set order_state=''partially_fulfilled''
			    where order_id=NEW.order_id;
            	    END IF;
        	END IF;
	    END IF;
	END IF;
	return new;
end;' language 'plpgsql';

create trigger ec_order_state_after_tr 
after update on ec_items 
for each row execute procedure ec_order_state_after_tr ();

-- this is a 1-row table
-- it contains all settings that the admin can change from the admin pages
-- most of the configuration is done using the parameters .ini file
-- wtem@olywa.net 03-10-2001
-- the following two tables probably need an additional column to support subsites
-- in which case it will have multiple rows, one for each instance of ecommerce
-- since these are really parameters for the instance of ecommerce, 
-- it might be better to move them to ad_parameters
create table ec_admin_settings (
        -- this is here just so that the insert statement (a page or
        -- so down) can't be executed twice
        admin_setting_id                integer not null primary key,   
        -- the following columns are related to shipping costs
        base_shipping_cost              numeric,
        default_shipping_per_item       numeric,
        weight_shipping_cost            numeric,
        add_exp_base_shipping_cost      numeric,
        add_exp_amount_per_item         numeric,
        add_exp_amount_by_weight        numeric,
        -- default template to use if the product isn't assigned to one
        -- (until the admin changes it, it will be 1, which will be
        -- the preloaded template)
        default_template        	integer default 1 not null 
					    references ec_templates,
        last_modified           	timestamptz not null,
        last_modifying_user     	integer not null references users,
        modified_ip_address     	varchar(20) not null
);

create table ec_admin_settings_audit (
        admin_setting_id                integer,
        base_shipping_cost              numeric,
        default_shipping_per_item       numeric,
        weight_shipping_cost            numeric,
        add_exp_base_shipping_cost      numeric,
        add_exp_amount_per_item         numeric,
        add_exp_amount_by_weight        numeric,
        default_template        	integer,
        last_modified           	timestamptz,
        last_modifying_user     	integer,
        modified_ip_address     	varchar(20),
        delete_p                	boolean default 'f'
);

create function ec_admin_settings_audit_tr ()
returns opaque as '
begin
        insert into ec_admin_settings_audit (
        admin_setting_id, base_shipping_cost, default_shipping_per_item,
        weight_shipping_cost, add_exp_base_shipping_cost,
        add_exp_amount_per_item, add_exp_amount_by_weight,
        default_template,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.admin_setting_id, old.base_shipping_cost, 
	old.default_shipping_per_item,
        old.weight_shipping_cost, old.add_exp_base_shipping_cost,
        old.add_exp_amount_per_item, old.add_exp_amount_by_weight,
        old.default_template,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address      
        );
	return new;
end;' language 'plpgsql';

create trigger ec_admin_settings_audit_tr
after update or delete on ec_admin_settings
for each row execute procedure ec_admin_settings_audit_tr ();

-- this is where the ec_amdin_settings insert was


-- put one row into ec_admin_settings so that I don't have to use 0or1row
insert into ec_admin_settings (
        admin_setting_id,
        default_template,
        last_modified,
        last_modifying_user,
        modified_ip_address
        ) values (
        1,
        1,
        now(), (select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1),
        'none');






-- this is populated by the rules the administrator sets in packages/ecommerce/www/admin]/sales-tax.tcl
create table ec_sales_tax_by_state (
       -- Jerry
        usps_abbrev             char(2) not null primary key references us_states(abbrev),
        -- this a decimal number equal to the percentage tax divided by 100
        tax_rate                numeric not null,
        -- charge tax on shipping?
        shipping_p              boolean not null,
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null
);

create table ec_sales_tax_by_state_audit (
        usps_abbrev             char(2),
        tax_rate                numeric,
        shipping_p              boolean,
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f'
);


-- Jerry - I removed usps_abbrev and/or state here
create function ec_sales_tax_by_state_audit_tr ()
returns opaque as '
begin
        insert into ec_sales_tax_by_state_audit (
        usps_abbrev, tax_rate,
        shipping_p,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.usps_abbrev, old.tax_rate,
        old.shipping_p,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address              
        );
	return new;
end;' language 'plpgsql';

create trigger ec_sales_tax_by_state_audit_tr
after update or delete on ec_sales_tax_by_state
for each row execute procedure ec_sales_tax_by_state_audit_tr ();

-- these tables are used if MultipleRetailersPerProductP is 1 in the
-- parameters .ini file

create sequence ec_retailer_seq start 1;
create view ec_retailer_sequence as select nextval('ec_retailer_seq') as nextval;

create table ec_retailers (
        retailer_id             integer not null primary key,
        retailer_name           varchar(300),
        primary_contact_name    varchar(100),
        secondary_contact_name  varchar(100),
        primary_contact_info    varchar(4000),
        secondary_contact_info  varchar(4000),
        line1                   varchar(100),
        line2                   varchar(100),
        city                    varchar(100),
        -- state
        -- Jerry
        usps_abbrev     	char(2) references us_states(abbrev),
        -- big enough to hold zip+4 with dash
        zip_code                varchar(10),
        phone                   varchar(30),
        fax                     varchar(30),
        -- for international addresses
        -- Jerry
        country_code            char(2) references countries(iso),
        --national, local, international
        reach                   varchar(15) check (reach in ('national','local','international','regional','web')),
        url                     varchar(200),
        -- space-separated list of states in which tax must be collected
        nexus_states            varchar(200),
        financing_policy        varchar(4000),
        return_policy           varchar(4000),
        price_guarantee_policy  varchar(4000),
        delivery_policy         varchar(4000),
        installation_policy     varchar(4000),
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null
);

create table ec_retailers_audit (
        retailer_id             integer,
        retailer_name           varchar(300),
        primary_contact_name    varchar(100),
        secondary_contact_name  varchar(100),
        primary_contact_info    varchar(4000),
        secondary_contact_info  varchar(4000),
        line1           	varchar(100),
        line2           	varchar(100),
        city            	varchar(100),
        usps_abbrev     	char(2),
        zip_code        	varchar(10),
        phone           	varchar(30),
        fax             	varchar(30),
        country_code    	char(2),
        reach           	varchar(15) check (reach in ('national','local','international','regional','web')),
        url             	varchar(200),
        nexus_states    	varchar(200),
        financing_policy        varchar(4000),
        return_policy           varchar(4000),
        price_guarantee_policy  varchar(4000),
        delivery_policy         varchar(4000),
        installation_policy     varchar(4000),
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f'
);

-- Jerry - I removed usps_abbrev and/or state here
create function ec_retailers_audit_tr ()
returns opaque as '
begin
        insert into ec_retailers_audit (
        retailer_id, retailer_name,
        primary_contact_name, secondary_contact_name,
        primary_contact_info, secondary_contact_info,
        line1, line2,
        city, usps_abbrev,
        zip_code, phone,
        fax, country_code,
        reach, url,
        nexus_states, financing_policy,
        return_policy, price_guarantee_policy,
        delivery_policy, installation_policy,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.retailer_id, old.retailer_name,
        old.primary_contact_name, old.secondary_contact_name,
        old.primary_contact_info, old.secondary_contact_info,
        old.line1, old.line2,
        old.city, old.usps_abbrev,
        old.zip_code, old.phone,
        old.fax, old.country_code,
        old.reach, old.url,
        old.nexus_states, old.financing_policy,
        old.return_policy, old.price_guarantee_policy,
        old.delivery_policy, old.installation_policy,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address      
        );
	return new;
end;' language 'plpgsql';

create trigger ec_retailers_audit_tr
after update or delete on ec_retailers
for each row execute procedure ec_retailers_audit_tr ();

create sequence ec_retailer_location_seq start 1;
create view ec_retailer_location_sequence as select nextval('ec_retailer_location_seq') as nextval;

create table ec_retailer_locations (
        retailer_location_id    integer not null primary key,
        retailer_id             integer not null references ec_retailers,
        location_name           varchar(300),
        primary_contact_name    varchar(100),
        secondary_contact_name  varchar(100),
        primary_contact_info    varchar(4000),
        secondary_contact_info  varchar(4000),
        line1                   varchar(100),
        line2                   varchar(100),
        city                    varchar(100),
        -- state
        -- Jerry
	-- usps_abbrev reinstated by wtem@olywa.net
        usps_abbrev     	char(2) references us_states(abbrev),
        -- big enough 0to hold zip+4 with dash
        zip_code                varchar(10),
        phone                   varchar(30),
        fax                     varchar(30),
        -- for international addresses
        -- Jerry
	-- country_code reinstated by wtem@olywa.net
        country_code            char(2) references countries(iso),
        url                     varchar(200),
        financing_policy        varchar(4000),
        return_policy           varchar(4000),
        price_guarantee_policy  varchar(4000),
        delivery_policy         varchar(4000),
        installation_policy     varchar(4000),
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null
);

create table ec_retailer_locations_audit (
        retailer_location_id    integer,
        retailer_id             integer,
        location_name           varchar(300),
        primary_contact_name    varchar(100),
        secondary_contact_name  varchar(100),
        primary_contact_info    varchar(4000),
        secondary_contact_info  varchar(4000),
        line1           	varchar(100),
        line2           	varchar(100),
        city            	varchar(100),
        usps_abbrev     	char(2),
        zip_code        	varchar(10),
        phone           	varchar(30),
        fax             	varchar(30),
        country_code    	char(2),
        url             	varchar(200),
        financing_policy        varchar(4000),
        return_policy           varchar(4000),
        price_guarantee_policy  varchar(4000),
        delivery_policy         varchar(4000),
        installation_policy     varchar(4000),
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f'
);


-- Jerry - I removed usps_abbrev and/or state here
create function ec_retailer_locations_audit_tr ()
returns opaque as '
begin
        insert into ec_retailer_locations_audit (
        retailer_location_id, retailer_id, location_name,
        primary_contact_name, secondary_contact_name,
        primary_contact_info, secondary_contact_info,
        line1, line2,
        city, usps_abbrev,
        zip_code, phone,
        fax, country_code,
        url, financing_policy,
        return_policy, price_guarantee_policy,
        delivery_policy, installation_policy,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.retailer_location_id,
        old.retailer_id, old.location_name,
        old.primary_contact_name, old.secondary_contact_name,
        old.primary_contact_info, old.secondary_contact_info,
        old.line1, old.line2,
        old.city, old.usps_abbrev,
        old.zip_code, old.phone,
        old.fax, old.country_code,
        old.url, old.financing_policy,
        old.return_policy, old.price_guarantee_policy,
        old.delivery_policy, old.installation_policy,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address
        );
	return new;
end;' language 'plpgsql';

create trigger ec_retailer_locations_audit_tr
after update or delete on ec_retailer_locations
for each row execute procedure ec_retailer_locations_audit_tr ();


create sequence ec_offer_seq start 1;
create view ec_offer_sequence as select nextval('ec_offer_seq') as nextval;

create table ec_offers (
        offer_id                integer not null primary key,
        product_id              integer not null references ec_products,
        retailer_location_id    integer not null references ec_retailer_locations,
        store_sku               integer,
        retailer_premiums       varchar(500),
        price                   numeric not null,
        shipping                numeric,
        shipping_unavailable_p  boolean,
        -- o = out of stock, q = ships quickly, m = ships
        -- moderately quickly, s = ships slowly, i = in stock
        -- with no message about the speed of the shipment (shipping
        -- messages are in parameters .ini file)
        stock_status            char(1) check (stock_status in ('o','q','m','s','i')),
        special_offer_p         boolean,
        special_offer_html      varchar(500),
        offer_begins            timestamptz not null,
        offer_ends              timestamptz not null,
        deleted_p               boolean default 'f',
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null
);

create view ec_offers_current
as
select * from ec_offers
where deleted_p='f'
and now() >= offer_begins
and now() <= offer_ends;


create table ec_offers_audit (
        offer_id                integer,
        product_id              integer,
        retailer_location_id    integer,
        store_sku               integer,
        retailer_premiums       varchar(500),
        price                   numeric,
        shipping                numeric,
        shipping_unavailable_p  boolean,
        stock_status            char(1) check (stock_status in ('o','q','m','s','i')),
        special_offer_p         boolean,
        special_offer_html      varchar(500),
        offer_begins            timestamptz,
        offer_ends              timestamptz,
        deleted_p               boolean default 'f',
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        -- This differs from the deleted_p column!
        -- deleted_p refers to the user request to stop offering
        -- delete_p indicates the row has been deleted from the main offers table
        delete_p                boolean default 'f'
);


create function ec_offers_audit_tr ()
returns opaque as '
begin
        insert into ec_offers_audit (
        offer_id,
        product_id, retailer_location_id,
        store_sku, retailer_premiums,
        price, shipping,
        shipping_unavailable_p, stock_status,
        special_offer_p, special_offer_html,
        offer_begins, offer_ends,
        deleted_p,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.offer_id,
        old.product_id, old.retailer_location_id,
        old.store_sku, old.retailer_premiums,
        old.price, old.shipping,
        old.shipping_unavailable_p, old.stock_status,
        old.special_offer_p, old.special_offer_html,
        old.offer_begins, old.offer_ends,
        old.deleted_p,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address
        );
	return new;
end;' language 'plpgsql';

create trigger ec_offers_audit_tr
after update or delete on ec_offers
for each row execute procedure ec_offers_audit_tr ();

-- Gift certificate stuff ----
------------------------------

create sequence ec_gift_cert_id_seq start 1000000;
create view ec_gift_cert_id_sequence as select nextval('ec_gift_cert_id_seq') as nextval;

create table ec_gift_certificates (
        gift_certificate_id     integer primary key,
        gift_certificate_state  varchar(50) not null,
        amount                  numeric not null,
        -- a trigger will update this to f if the
        -- entire amount is used up (to speed up
        -- queries)
        amount_remaining_p      boolean default 't',
        issue_date              timestamptz,
        authorized_date         timestamptz,
        claimed_date            timestamptz,
        -- customer service rep who issued it
        issued_by               integer references users,
        -- customer who purchased it
        purchased_by            integer references users,
        expires                 timestamptz,
        user_id                 integer references users,
        -- if it's unclaimed, claim_check will be filled in,
        -- and user_id won't be filled in
        -- claim check should be unique (one way to do this
        -- is to always begin it with "$gift_certificate_id-")
        claim_check             varchar(50),
        certificate_message     varchar(200),
        certificate_to          varchar(100),
        certificate_from        varchar(100),
        recipient_email         varchar(100),
        voided_date             timestamptz,
        voided_by               integer references users,
        reason_for_void         varchar(4000),
        last_modified           timestamptz not null,
        last_modifying_user     integer not null references users,
        modified_ip_address     varchar(20) not null,
        check (user_id is not null or claim_check is not null)
);

create index ec_gc_by_state on ec_gift_certificates(gift_certificate_state);
create index ec_gc_by_amount_remaining on ec_gift_certificates(amount_remaining_p);
create index ec_gc_by_user on ec_gift_certificates(user_id);
create index ec_gc_by_claim_check on ec_gift_certificates(claim_check);

-- note: there's a trigger in ecommerce-plsql.sql which updates amount_remaining_p
-- when a gift certificate is used

-- note2: there's a 1-1 correspondence between user-purchased gift certificates
-- and financial transactions.  ec_financial_transactions stores the corresponding
-- gift_certificate_id.

create view ec_gift_certificates_approved
as 
select * 
from ec_gift_certificates
where gift_certificate_state in ('authorized');

create view ec_gift_certificates_purchased
as
select *
from ec_gift_certificates
where gift_certificate_state in ('authorized');

create view ec_gift_certificates_issued
as
select *
from ec_gift_certificates
where gift_certificate_state in ('authorized')
  and issued_by is not null;


create table ec_gift_certificates_audit (
        gift_certificate_id     integer,
        gift_certificate_state  varchar(50),
        amount                  numeric,
        issue_date              timestamptz,
        authorized_date         timestamptz,
        issued_by               integer,
        purchased_by            integer,
        expires                 timestamptz,
        user_id                 integer,
        claim_check             varchar(50),
        certificate_message     varchar(200),
        certificate_to          varchar(100),
        certificate_from        varchar(100),
        recipient_email         varchar(100),
        voided_date             timestamptz,
        voided_by               integer,
        reason_for_void         varchar(4000),
        last_modified           timestamptz,
        last_modifying_user     integer,
        modified_ip_address     varchar(20),
        delete_p                boolean default 'f' 
);


create function ec_gift_certificates_audit_tr ()
returns opaque as '
begin
        insert into ec_gift_certificates_audit (
        gift_certificate_id, amount,
        issue_date, authorized_date, issued_by, purchased_by, expires,
        user_id, claim_check, certificate_message,
        certificate_to, certificate_from,
        recipient_email, voided_date, voided_by, reason_for_void,
        last_modified,
        last_modifying_user, modified_ip_address
        ) values (
        old.gift_certificate_id, old.amount,
        old.issue_date, old.authorized_date, old.issued_by, old.purchased_by, old.expires,
        old.user_id, old.claim_check, old.certificate_message,
        old.certificate_to, old.certificate_from,
        old.recipient_email, old.voided_date, old.voided_by, old.reason_for_void,
        old.last_modified,
        old.last_modifying_user, old.modified_ip_address      
        );
	return new;
end;' language 'plpgsql';

create trigger ec_gift_certificates_audit_tr
after update or delete on ec_gift_certificates
for each row execute procedure ec_gift_certificates_audit_tr ();


create table ec_gift_certificate_usage (
        gift_certificate_id     integer not null references ec_gift_certificates,
        order_id                integer references ec_orders,
        amount_used             numeric,
        used_date               timestamptz,
        amount_reinstated       numeric,
        reinstated_date         timestamp
);

create index ec_gift_cert_by_id on ec_gift_certificate_usage (gift_certificate_id);




-- keeps track of automatic emails (based on templates) that are sent out
create table ec_automatic_email_log (
        user_identification_id  integer not null references ec_user_identification,
        email_template_id       integer not null references ec_email_templates,
        order_id                integer references ec_orders,
        shipment_id             integer references ec_shipments,
        gift_certificate_id     integer references ec_gift_certificates,
        date_sent               timestamp
);

create index ec_auto_email_by_usr_id_idx on ec_automatic_email_log (user_identification_id);
create index ec_auto_email_by_temp_idx on ec_automatic_email_log (email_template_id);
create index ec_auto_email_by_order_idx on ec_automatic_email_log (order_id);
create index ec_auto_email_by_shipment_idx on ec_automatic_email_log (shipment_id);
create index ec_auto_email_by_gc_idx on ec_automatic_email_log (gift_certificate_id);




-- The following templates are predefined ecommerce-defaults.
-- The templates are
-- used in procedures which send out the email, so the template_ids
-- shouldn't be changed, although the text can be edited at
-- [ec_url_concat [ec_url] /admin]/email-templates/
--
-- email_template_id    used for
-- -----------------    ---------
--      1               new order
--      2               order shipped
--      3               delayed credit denied
--      4               new gift certificate order
--      5               gift certificate recipient
--      6               gift certificate order failure

-- set scan off

insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user, modified_ip_address)
values
(1, 'New Order', 'Your Order',
'Thank you for your order.  We received your order' || '\n'
|| 'on confirmed_date_here.' || '\n' || '\n'
|| 'The following is your order information:' || '\n' || '\n'
|| 'item_summary_here' || '\n' || '\n'
|| 'Shipping Address:' || '\n'
|| 'address_here' || '\n' || '\n'
|| 'price_summary_here' || '\n' || '\n'
|| 'Thank you.' || '\n' || '\n' 
|| 'Sincerely,' || '\n' 
|| 'customer_service_signature_here',
'confirmed_date_here, address_here, item_summary_here, price_here, shipping_here, tax_here, total_here, customer_service_signature_here',
'This email will automatically be sent out after an order has been authorized.',
'{new order}',
now(),
                 (select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1), 'none');

insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user, modified_ip_address)
values
(2, 'Order Shipped', 'Your Order Has Shipped',
'We shipped the following items on shipped_date_here:' || '\n' || '\n' 
|| 'item_summary_here' || '\n' || '\n' 
|| 'Your items were shipped to:' || '\n' || '\n' 
|| 'address_here' || '\n' || '\n' 
|| 'sentence_about_whether_this_completes_the_order_here' || '\n' || '\n' 
|| 'You can track your package by accessing' || '\n' 
|| '"Your Account" at system_url_here' || '\n' || '\n' 
|| 'Sincerely,' || '\n' 
|| 'customer_service_signature_here',
'shipped_date_here, item_summary_here, address_here, sentence_about_whether_this_completes_the_order_here, system_url_here, customer_service_signature_here',
'This email will automatically be sent out after an order or partial order has shipped.',
'{order shipped}',
now(),
(select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1),
'none');


insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user, modified_ip_address)
values
(3, 'Delayed Credit Denied', 'Your Order',
'At this time we are not able to receive' || '\n' 
|| 'authorization to charge your account.  We' || '\n' 
|| 'have saved your order so that you can come' || '\n' 
|| 'back to system_url_here' || '\n' 
|| 'and resubmit it.' || '\n' || '\n' 
|| 'Please go to your shopping cart and' || '\n' 
|| 'click on "Retrieve Saved Cart".' || '\n' || '\n' 
|| 'Thank you.' || '\n' || '\n' 
|| 'Sincerely,' || '\n' 
|| 'customer_service_signature_here',
'system_url_here, customer_service_signature_here',
'This email will automatically be sent out after a credit card authorization fails if it didn''t fail at the time the user initially submitted their order.',
'billing',
now(),
(select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1),
'none');


insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user, modified_ip_address)
values
(4, 'New Gift Certificate Order', 'Your Order',
'Thank you for your gift certificate order at system_name_here!' || '\n' || '\n' 
|| 'The gift certificate will be sent to:' || '\n' || '\n' 
|| 'recipient_email_here' || '\n' || '\n' 
|| 'Your order details:' || '\n' || '\n' 
|| 'Gift Certificate   certificate_amount_here' || '\n' 
|| 'Shipping           0.00' || '\n' 
|| 'Tax                0.00' || '\n' 
|| '------------       ------------' || '\n' 
|| 'TOTAL              certificate_amount_here' || '\n' || '\n' 
|| 'Sincerely,' || '\n' 
|| 'customer_service_signature_here',
'system_name_here, recipient_email_here, certificate_amount_here, customer_service_signature_here',
'This email will be sent after a customer orders a gift certificate.',
'{gift certificate}',
now(),
(select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1),
'none');


insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user, modified_ip_address)
values
(5, 'Gift Certificate Recipient', 'Gift Certificate',
'It''s our pleasure to inform you that someone' || '\n' 
|| 'has purchased a gift certificate for you at' || '\n' 
|| 'system_name_here!' || '\n' || '\n' 
|| 'Use the claim check below to retrieve your gift' || '\n' 
|| 'certificate at system_url_here' || '\n' || '\n' 
|| 'amount_and_message_summary_here' || '\n' || '\n' 
|| 'Claim Check: claim_check_here' || '\n' || '\n' 
|| 'To redeem it, just go to' || '\n' 
|| 'system_url_here' || '\n' 
|| 'choose the items you wish to purchase,' || '\n' 
|| 'and proceed to Checkout.  You''ll then have' || '\n' 
|| 'the opportunity to type in your claim code' || '\n' 
|| 'and redeem your certificate!  Any remaining' || '\n' 
|| 'balance must be paid for by credit card.' || '\n' || '\n' 
|| 'Sincerely,' || '\n' 
|| 'customer_service_signature_here',
'system_name_here, system_url_here, amount_and_message_summary_here, claim_check_here, customer_service_signature_here',
'This is sent to recipients of gift certificates.',
'{gift certificate}',
now(),
(select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1),
'none');

insert into ec_email_templates
(email_template_id, title, subject, message, variables, when_sent, issue_type_list, last_modified, last_modifying_user,  modified_ip_address)
values
(6, 'Gift Certificate Order Failure', 'Your Gift Certificate Order',
'We are sorry to report that the authorization' || '\n' 
|| 'for the gift certificate order you placed' || '\n' 
|| 'at system_name_here could not be made.' || '\n' 
|| 'Your order has been canceled.  Please' || '\n' 
|| 'come back and try your order again at:' || '\n' || '\n' 
|| 'system_url_here' || '\n' 
|| 'For your records, here is the order' || '\n' 
|| 'that you attempted to place:' || '\n' || '\n' 
|| 'Would have been sent to: recipient_email_here' || '\n' 
|| 'amount_and_message_summary_here' || '\n' 
|| 'We apologize for the inconvenience.' || '\n' 
|| 'Sincerely,' || '\n' 
|| 'customer_service_signature_here',
'system_name_here, system_url_here, recipient_email_here, amount_and_message_summary_here, customer_service_signature_here',
'This is sent to customers who tried to purchase a gift certificate but got no immediate response from the credit card gateway and we found out later the authorization failed.',
'{gift certificate}', now(),
                 (select grantee_id
                    from acs_permissions
                   where object_id = acs__magic_object_id('security_context_root')
                     and privilege = 'admin'
                     limit 1),
'none');

