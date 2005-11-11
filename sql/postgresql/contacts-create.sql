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
