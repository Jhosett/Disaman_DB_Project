toc.dat                                                                                             0000600 0004000 0002000 00000121353 15014672533 0014452 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP       6                }         
   DISAMAN_DB    17.4    17.4 e    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false         �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false         �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false         �           1262    73768 
   DISAMAN_DB    DATABASE     r   CREATE DATABASE "DISAMAN_DB" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'es-ES';
    DROP DATABASE "DISAMAN_DB";
                     postgres    false                     2615    73769    tienda    SCHEMA        CREATE SCHEMA tienda;
    DROP SCHEMA tienda;
                     postgres    false         �            1255    81964    fn_actualizar_total_orden()    FUNCTION     z  CREATE FUNCTION tienda.fn_actualizar_total_orden() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC(10, 2);
    v_total_discount NUMERIC(10, 2);
BEGIN
    -- Calcular el total y el total de descuento para la orden actual
    SELECT 
        SUM(subtotal),
        SUM(discount_value * quantity)
    INTO 
        v_total,
        v_total_discount
    FROM TIENDA.DETAIL_ORDERS
    WHERE odr_id = NEW.odr_id;

    -- Actualizar la orden con los nuevos totales
    UPDATE TIENDA.ORDERS
    SET total = v_total,
        discount_value = v_total_discount
    WHERE odr_id = NEW.odr_id;

    RETURN NEW;
END;
$$;
 2   DROP FUNCTION tienda.fn_actualizar_total_orden();
       tienda               postgres    false    6         �            1255    81962    fn_calcular_subtotal()    FUNCTION     �  CREATE FUNCTION tienda.fn_calcular_subtotal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_unit_price NUMERIC(10, 2);
    v_discount_value NUMERIC(10, 2) := 0;
    v_discount_type VARCHAR(10);
    v_percent NUMERIC(10, 2);
    v_fixed NUMERIC(10, 2);
    v_subtotal NUMERIC(10, 2);
    v_pmn_id INT;
BEGIN
    -- Validar cantidad
    IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor que cero. Producto: %', NEW.pdt_id;
    END IF;

    -- Obtener precio y promoción del producto
    SELECT p.unit_price, p.pmn_id INTO v_unit_price, v_pmn_id
    FROM TIENDA.PRODUCTS p
    WHERE p.pdt_id = NEW.pdt_id AND p.pdt_ctg_id = NEW.ctg_pdt_id;

    -- Si tiene promoción
    IF v_pmn_id IS NOT NULL THEN
        SELECT discount_type, disccount, discount_value
        INTO v_discount_type, v_percent, v_fixed
        FROM TIENDA.PROMOTIONS
        WHERE pmn_id = v_pmn_id AND state = 'active';

        IF FOUND THEN
            IF v_discount_type = 'PERCENT' THEN
                v_discount_value := ROUND((v_unit_price * v_percent / 100), 2);
            ELSIF v_discount_type = 'FIXED' THEN
                v_discount_value := v_fixed;
            END IF;
        END IF;
    END IF;

    -- Calcular subtotal
    v_subtotal := (v_unit_price - v_discount_value) * NEW.quantity;

    -- Asignar resultados al registro
    NEW.unit_price := v_unit_price;
    NEW.discount_value := v_discount_value;
    NEW.subtotal := v_subtotal;

    RETURN NEW;
END;
$$;
 -   DROP FUNCTION tienda.fn_calcular_subtotal();
       tienda               postgres    false    6         �            1259    73856    cities    TABLE     �  CREATE TABLE tienda.cities (
    cyy_id character varying(3) NOT NULL,
    name character varying(60),
    dpt_id character varying(3) NOT NULL,
    cty_id character varying(3) NOT NULL,
    CONSTRAINT nn_cities_cty CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_cities_dpt CHECK ((dpt_id IS NOT NULL)),
    CONSTRAINT nn_cities_id CHECK ((cyy_id IS NOT NULL)),
    CONSTRAINT nn_cities_name CHECK ((name IS NOT NULL))
);
    DROP TABLE tienda.cities;
       tienda         heap r       postgres    false    6         �            1259    73783 	   countries    TABLE     �   CREATE TABLE tienda.countries (
    cty_id character varying(3) NOT NULL,
    name character varying(60),
    CONSTRAINT nn_countries_cty_id CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_countries_name CHECK ((name IS NOT NULL))
);
    DROP TABLE tienda.countries;
       tienda         heap r       postgres    false    6         �            1259    73770 	   customers    TABLE     �  CREATE TABLE tienda.customers (
    document character varying(15) NOT NULL,
    first_name character varying(50),
    middle_name character varying(50),
    last_name character varying(50),
    middle_last_name character varying(50),
    phone_number character varying(15),
    address character varying(100),
    CONSTRAINT nn_customers_address CHECK ((address IS NOT NULL)),
    CONSTRAINT nn_customers_first_name CHECK ((first_name IS NOT NULL)),
    CONSTRAINT nn_customers_id CHECK ((document IS NOT NULL)),
    CONSTRAINT nn_customers_last_name CHECK ((last_name IS NOT NULL)),
    CONSTRAINT nn_customers_middle_last_name CHECK ((middle_last_name IS NOT NULL)),
    CONSTRAINT nn_customers_phone CHECK ((phone_number IS NOT NULL))
);
    DROP TABLE tienda.customers;
       tienda         heap r       postgres    false    6         �            1259    73798    departaments    TABLE     Z  CREATE TABLE tienda.departaments (
    dpt_id character varying(3) NOT NULL,
    name character varying(60),
    cty_id character varying(3) NOT NULL,
    CONSTRAINT nn_departaments_cty CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_departaments_id CHECK ((dpt_id IS NOT NULL)),
    CONSTRAINT nn_departaments_name CHECK ((name IS NOT NULL))
);
     DROP TABLE tienda.departaments;
       tienda         heap r       postgres    false    6         �            1259    74134    detail_orders    TABLE     �  CREATE TABLE tienda.detail_orders (
    odr_id integer NOT NULL,
    line_item_id integer NOT NULL,
    ctg_pdt_id integer,
    pdt_id integer,
    quantity numeric(10,2),
    unit_price numeric(10,2),
    subtotal numeric(10,2),
    discount_value numeric(10,2) DEFAULT 0,
    CONSTRAINT ck_dtl_odr_quantity CHECK ((quantity > (0)::numeric)),
    CONSTRAINT ck_dtl_odr_unit_price CHECK ((unit_price > (0)::numeric)),
    CONSTRAINT detail_orders_check CHECK (((discount_value >= (0)::numeric) AND (discount_value <= unit_price))),
    CONSTRAINT nn_dtl_odr_ctg_pdt CHECK ((ctg_pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_line_item CHECK ((line_item_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_odr_id CHECK ((odr_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_pdt_id CHECK ((pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_quantity CHECK ((quantity IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_subtotal CHECK ((subtotal IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_unit_price CHECK ((unit_price IS NOT NULL))
);
 !   DROP TABLE tienda.detail_orders;
       tienda         heap r       postgres    false    6         �            1259    74078    detail_purchases    TABLE     �  CREATE TABLE tienda.detail_purchases (
    prc_id integer NOT NULL,
    line_item_id integer NOT NULL,
    ctg_pdt_id integer,
    pdt_id integer,
    quantity numeric(10,2),
    unit_price numeric(10,2),
    subtotal numeric(10,2),
    CONSTRAINT ck_dtl_prc_quantity CHECK ((quantity > (0)::numeric)),
    CONSTRAINT ck_dtl_prc_subtotal CHECK ((subtotal = (quantity * unit_price))),
    CONSTRAINT ck_dtl_prc_unit_price CHECK ((unit_price > (0)::numeric)),
    CONSTRAINT nn_dtl_prc_ctg_pdt CHECK ((ctg_pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_line_item CHECK ((line_item_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_pdt_id CHECK ((pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_prc_id CHECK ((prc_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_quantity CHECK ((quantity IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_subtotal CHECK ((subtotal IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_unit_price CHECK ((unit_price IS NOT NULL))
);
 $   DROP TABLE tienda.detail_purchases;
       tienda         heap r       postgres    false    6         �            1259    74109    orders    TABLE     �  CREATE TABLE tienda.orders (
    odr_id integer NOT NULL,
    order_date date,
    total numeric(10,2),
    document character varying(15),
    stf_id character varying(4),
    description character varying(200),
    discount_value numeric(10,2) DEFAULT 0,
    CONSTRAINT ck_odr_staff_employee CHECK (((stf_id)::text ~~ 'EP%'::text)),
    CONSTRAINT ck_odr_total CHECK ((total > (0)::numeric)),
    CONSTRAINT nn_odr_document CHECK ((document IS NOT NULL)),
    CONSTRAINT nn_odr_order_date CHECK ((order_date IS NOT NULL)),
    CONSTRAINT nn_odr_stf_id CHECK ((stf_id IS NOT NULL)),
    CONSTRAINT nn_odr_total CHECK ((total IS NOT NULL)),
    CONSTRAINT orders_discount_value_check CHECK ((discount_value >= (0)::numeric))
);
    DROP TABLE tienda.orders;
       tienda         heap r       postgres    false    6         �            1259    74108    orders_odr_id_seq    SEQUENCE     �   CREATE SEQUENCE tienda.orders_odr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE tienda.orders_odr_id_seq;
       tienda               postgres    false    237    6         �           0    0    orders_odr_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE tienda.orders_odr_id_seq OWNED BY tienda.orders.odr_id;
          tienda               postgres    false    236         �            1259    73984    product_categories    TABLE     �   CREATE TABLE tienda.product_categories (
    pdt_ctg_id integer NOT NULL,
    name character varying(50),
    description character varying(200),
    CONSTRAINT nn_pdt_ctg_name CHECK ((name IS NOT NULL))
);
 &   DROP TABLE tienda.product_categories;
       tienda         heap r       postgres    false    6         �            1259    73983 !   product_categories_pdt_ctg_id_seq    SEQUENCE     �   CREATE SEQUENCE tienda.product_categories_pdt_ctg_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE tienda.product_categories_pdt_ctg_id_seq;
       tienda               postgres    false    226    6         �           0    0 !   product_categories_pdt_ctg_id_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE tienda.product_categories_pdt_ctg_id_seq OWNED BY tienda.product_categories.pdt_ctg_id;
          tienda               postgres    false    225         �            1259    73971    product_lot    TABLE     �   CREATE TABLE tienda.product_lot (
    pdt_lot_id character varying(4) NOT NULL,
    expiration_date date,
    CONSTRAINT nn_pdt_lot_expiration CHECK ((expiration_date IS NOT NULL)),
    CONSTRAINT nn_pdt_lot_id CHECK ((pdt_lot_id IS NOT NULL))
);
    DROP TABLE tienda.product_lot;
       tienda         heap r       postgres    false    6         �            1259    74021    products    TABLE     �  CREATE TABLE tienda.products (
    pdt_id integer NOT NULL,
    name character varying(50),
    description character varying(200),
    unit_price numeric(10,0),
    stock integer,
    pdt_ctg_id integer NOT NULL,
    lot_pdt_id character varying(4),
    pmn_id integer,
    ssn_id integer,
    CONSTRAINT ck_stock_range CHECK (((stock >= 0) AND (stock <= 999))),
    CONSTRAINT ck_unit_price CHECK ((unit_price > (0)::numeric)),
    CONSTRAINT nn_products_ctg_id CHECK ((pdt_ctg_id IS NOT NULL)),
    CONSTRAINT nn_products_lot_id CHECK ((lot_pdt_id IS NOT NULL)),
    CONSTRAINT nn_products_name CHECK ((name IS NOT NULL)),
    CONSTRAINT nn_products_stock CHECK ((stock IS NOT NULL)),
    CONSTRAINT nn_products_unit_price CHECK ((unit_price IS NOT NULL))
);
    DROP TABLE tienda.products;
       tienda         heap r       postgres    false    6         �            1259    74020    products_pdt_id_seq    SEQUENCE     �   CREATE SEQUENCE tienda.products_pdt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE tienda.products_pdt_id_seq;
       tienda               postgres    false    6    232         �           0    0    products_pdt_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE tienda.products_pdt_id_seq OWNED BY tienda.products.pdt_id;
          tienda               postgres    false    231         �            1259    73992 
   promotions    TABLE     �  CREATE TABLE tienda.promotions (
    pmn_id integer NOT NULL,
    start_date date,
    finish_date date,
    disccount numeric(2,0),
    discount_value numeric(10,0),
    state character varying(15),
    discount_type character varying(10),
    CONSTRAINT ck_discount_range CHECK (((disccount >= (0)::numeric) AND (disccount <= (100)::numeric))),
    CONSTRAINT ck_discount_value CHECK ((discount_value > (0)::numeric)),
    CONSTRAINT ck_finish_date CHECK ((finish_date >= start_date)),
    CONSTRAINT ck_pmn_state CHECK (((state)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'paused'::character varying])::text[]))),
    CONSTRAINT ck_promotion_discount_logic CHECK (((((discount_type)::text = 'PERCENT'::text) AND (disccount IS NOT NULL) AND (discount_value IS NULL)) OR (((discount_type)::text = 'FIXED'::text) AND (discount_value IS NOT NULL) AND (disccount IS NULL)))),
    CONSTRAINT nn_pmn_discount CHECK ((disccount IS NOT NULL)),
    CONSTRAINT nn_pmn_discount_value CHECK ((discount_value IS NOT NULL)),
    CONSTRAINT nn_pmn_finish_date CHECK ((finish_date IS NOT NULL)),
    CONSTRAINT nn_pmn_id CHECK ((pmn_id IS NOT NULL)),
    CONSTRAINT nn_pmn_start_date CHECK ((start_date IS NOT NULL)),
    CONSTRAINT nn_pmn_state CHECK ((state IS NOT NULL)),
    CONSTRAINT promotions_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['PERCENT'::character varying, 'FIXED'::character varying])::text[])))
);
    DROP TABLE tienda.promotions;
       tienda         heap r       postgres    false    6         �            1259    73991    promotions_pmn_id_seq    SEQUENCE     �   CREATE SEQUENCE tienda.promotions_pmn_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE tienda.promotions_pmn_id_seq;
       tienda               postgres    false    228    6         �           0    0    promotions_pmn_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE tienda.promotions_pmn_id_seq OWNED BY tienda.promotions.pmn_id;
          tienda               postgres    false    227         �            1259    74055 	   purchases    TABLE     �  CREATE TABLE tienda.purchases (
    prc_id integer NOT NULL,
    purchase_date date,
    total numeric(10,0),
    nit character varying(15),
    stf_id character varying(4),
    description character varying(200),
    CONSTRAINT ck_purchases_stf CHECK (((stf_id)::text ~ '^MG'::text)),
    CONSTRAINT ck_purchases_total CHECK ((total > (0)::numeric)),
    CONSTRAINT nn_purchases_date CHECK ((purchase_date IS NOT NULL)),
    CONSTRAINT nn_purchases_id CHECK ((prc_id IS NOT NULL)),
    CONSTRAINT nn_purchases_nit CHECK ((nit IS NOT NULL)),
    CONSTRAINT nn_purchases_stf CHECK ((stf_id IS NOT NULL)),
    CONSTRAINT nn_purchases_total CHECK ((total IS NOT NULL))
);
    DROP TABLE tienda.purchases;
       tienda         heap r       postgres    false    6         �            1259    74054    purchases_prc_id_seq    SEQUENCE     �   CREATE SEQUENCE tienda.purchases_prc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE tienda.purchases_prc_id_seq;
       tienda               postgres    false    234    6         �           0    0    purchases_prc_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE tienda.purchases_prc_id_seq OWNED BY tienda.purchases.prc_id;
          tienda               postgres    false    233         �            1259    74009    seasons    TABLE     �  CREATE TABLE tienda.seasons (
    ssn_id integer NOT NULL,
    name character varying(50),
    start_date date,
    finish_date date,
    CONSTRAINT ck_ssn_date CHECK ((finish_date >= start_date)),
    CONSTRAINT nn_ssn_finish_date CHECK ((finish_date IS NOT NULL)),
    CONSTRAINT nn_ssn_id CHECK ((ssn_id IS NOT NULL)),
    CONSTRAINT nn_ssn_name CHECK ((name IS NOT NULL)),
    CONSTRAINT nn_ssn_start_date CHECK ((start_date IS NOT NULL))
);
    DROP TABLE tienda.seasons;
       tienda         heap r       postgres    false    6         �            1259    74008    seasons_ssn_id_seq    SEQUENCE     �   CREATE SEQUENCE tienda.seasons_ssn_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE tienda.seasons_ssn_id_seq;
       tienda               postgres    false    230    6         �           0    0    seasons_ssn_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE tienda.seasons_ssn_id_seq OWNED BY tienda.seasons.ssn_id;
          tienda               postgres    false    229         �            1259    73949    staff    TABLE     w  CREATE TABLE tienda.staff (
    stf_id character varying(4) NOT NULL,
    first_name character varying(50),
    middle_name character varying(50),
    last_name character varying(50),
    middle_last_name character varying(50),
    phone_number character varying(15),
    address character varying(100),
    salary numeric(10,0),
    mgr_id character varying(4),
    type_worker character varying(50),
    sales integer,
    bonification numeric(10,0),
    employee_number integer,
    CONSTRAINT ck_employee_number CHECK (((((type_worker)::text = 'MANAGER'::text) AND (employee_number IS NOT NULL)) OR (((type_worker)::text = 'EMPLOYEE'::text) AND (employee_number IS NULL)))),
    CONSTRAINT ck_employee_sales_bonus CHECK (((((type_worker)::text = 'MANAGER'::text) AND (sales IS NULL) AND (bonification IS NULL)) OR ((type_worker)::text = 'EMPLOYEE'::text))),
    CONSTRAINT nn_staff_address CHECK ((address IS NOT NULL)),
    CONSTRAINT nn_staff_first_name CHECK ((first_name IS NOT NULL)),
    CONSTRAINT nn_staff_id CHECK ((stf_id IS NOT NULL)),
    CONSTRAINT nn_staff_last_name CHECK ((last_name IS NOT NULL)),
    CONSTRAINT nn_staff_middle_last_name CHECK ((middle_last_name IS NOT NULL)),
    CONSTRAINT nn_staff_phone CHECK ((phone_number IS NOT NULL)),
    CONSTRAINT nn_staff_salary CHECK ((salary IS NOT NULL)),
    CONSTRAINT nn_staff_type_worker CHECK ((type_worker IS NOT NULL))
);
    DROP TABLE tienda.staff;
       tienda         heap r       postgres    false    6         �            1259    73898 	   suppliers    TABLE     ~  CREATE TABLE tienda.suppliers (
    nit character varying(15) NOT NULL,
    first_name character varying(50),
    middle_name character varying(50),
    last_name character varying(50),
    phone_number character varying(15),
    address character varying(100),
    cyy_id character varying(3),
    dpt_id character varying(3),
    cty_id character varying(3),
    CONSTRAINT nn_suppliers_address CHECK ((address IS NOT NULL)),
    CONSTRAINT nn_suppliers_city CHECK ((cyy_id IS NOT NULL)),
    CONSTRAINT nn_suppliers_country CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_suppliers_dpt CHECK ((dpt_id IS NOT NULL)),
    CONSTRAINT nn_suppliers_first_name CHECK ((first_name IS NOT NULL)),
    CONSTRAINT nn_suppliers_last_name CHECK ((last_name IS NOT NULL)),
    CONSTRAINT nn_suppliers_nit CHECK ((nit IS NOT NULL)),
    CONSTRAINT nn_suppliers_phone CHECK ((phone_number IS NOT NULL))
);
    DROP TABLE tienda.suppliers;
       tienda         heap r       postgres    false    6         f           2604    74112    orders odr_id    DEFAULT     n   ALTER TABLE ONLY tienda.orders ALTER COLUMN odr_id SET DEFAULT nextval('tienda.orders_odr_id_seq'::regclass);
 <   ALTER TABLE tienda.orders ALTER COLUMN odr_id DROP DEFAULT;
       tienda               postgres    false    237    236    237         a           2604    73987    product_categories pdt_ctg_id    DEFAULT     �   ALTER TABLE ONLY tienda.product_categories ALTER COLUMN pdt_ctg_id SET DEFAULT nextval('tienda.product_categories_pdt_ctg_id_seq'::regclass);
 L   ALTER TABLE tienda.product_categories ALTER COLUMN pdt_ctg_id DROP DEFAULT;
       tienda               postgres    false    225    226    226         d           2604    74024    products pdt_id    DEFAULT     r   ALTER TABLE ONLY tienda.products ALTER COLUMN pdt_id SET DEFAULT nextval('tienda.products_pdt_id_seq'::regclass);
 >   ALTER TABLE tienda.products ALTER COLUMN pdt_id DROP DEFAULT;
       tienda               postgres    false    231    232    232         b           2604    73995    promotions pmn_id    DEFAULT     v   ALTER TABLE ONLY tienda.promotions ALTER COLUMN pmn_id SET DEFAULT nextval('tienda.promotions_pmn_id_seq'::regclass);
 @   ALTER TABLE tienda.promotions ALTER COLUMN pmn_id DROP DEFAULT;
       tienda               postgres    false    228    227    228         e           2604    74058    purchases prc_id    DEFAULT     t   ALTER TABLE ONLY tienda.purchases ALTER COLUMN prc_id SET DEFAULT nextval('tienda.purchases_prc_id_seq'::regclass);
 ?   ALTER TABLE tienda.purchases ALTER COLUMN prc_id DROP DEFAULT;
       tienda               postgres    false    234    233    234         c           2604    74012    seasons ssn_id    DEFAULT     p   ALTER TABLE ONLY tienda.seasons ALTER COLUMN ssn_id SET DEFAULT nextval('tienda.seasons_ssn_id_seq'::regclass);
 =   ALTER TABLE tienda.seasons ALTER COLUMN ssn_id DROP DEFAULT;
       tienda               postgres    false    230    229    230         �          0    73856    cities 
   TABLE DATA           >   COPY tienda.cities (cyy_id, name, dpt_id, cty_id) FROM stdin;
    tienda               postgres    false    221       5013.dat �          0    73783 	   countries 
   TABLE DATA           1   COPY tienda.countries (cty_id, name) FROM stdin;
    tienda               postgres    false    219       5011.dat �          0    73770 	   customers 
   TABLE DATA           z   COPY tienda.customers (document, first_name, middle_name, last_name, middle_last_name, phone_number, address) FROM stdin;
    tienda               postgres    false    218       5010.dat �          0    73798    departaments 
   TABLE DATA           <   COPY tienda.departaments (dpt_id, name, cty_id) FROM stdin;
    tienda               postgres    false    220       5012.dat �          0    74134    detail_orders 
   TABLE DATA           �   COPY tienda.detail_orders (odr_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal, discount_value) FROM stdin;
    tienda               postgres    false    238       5030.dat �          0    74078    detail_purchases 
   TABLE DATA           t   COPY tienda.detail_purchases (prc_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal) FROM stdin;
    tienda               postgres    false    235       5027.dat �          0    74109    orders 
   TABLE DATA           j   COPY tienda.orders (odr_id, order_date, total, document, stf_id, description, discount_value) FROM stdin;
    tienda               postgres    false    237       5029.dat �          0    73984    product_categories 
   TABLE DATA           K   COPY tienda.product_categories (pdt_ctg_id, name, description) FROM stdin;
    tienda               postgres    false    226       5018.dat �          0    73971    product_lot 
   TABLE DATA           B   COPY tienda.product_lot (pdt_lot_id, expiration_date) FROM stdin;
    tienda               postgres    false    224       5016.dat �          0    74021    products 
   TABLE DATA           x   COPY tienda.products (pdt_id, name, description, unit_price, stock, pdt_ctg_id, lot_pdt_id, pmn_id, ssn_id) FROM stdin;
    tienda               postgres    false    232       5024.dat �          0    73992 
   promotions 
   TABLE DATA           v   COPY tienda.promotions (pmn_id, start_date, finish_date, disccount, discount_value, state, discount_type) FROM stdin;
    tienda               postgres    false    228       5020.dat �          0    74055 	   purchases 
   TABLE DATA           [   COPY tienda.purchases (prc_id, purchase_date, total, nit, stf_id, description) FROM stdin;
    tienda               postgres    false    234       5026.dat �          0    74009    seasons 
   TABLE DATA           H   COPY tienda.seasons (ssn_id, name, start_date, finish_date) FROM stdin;
    tienda               postgres    false    230       5022.dat �          0    73949    staff 
   TABLE DATA           �   COPY tienda.staff (stf_id, first_name, middle_name, last_name, middle_last_name, phone_number, address, salary, mgr_id, type_worker, sales, bonification, employee_number) FROM stdin;
    tienda               postgres    false    223       5015.dat �          0    73898 	   suppliers 
   TABLE DATA           {   COPY tienda.suppliers (nit, first_name, middle_name, last_name, phone_number, address, cyy_id, dpt_id, cty_id) FROM stdin;
    tienda               postgres    false    222       5014.dat �           0    0    orders_odr_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('tienda.orders_odr_id_seq', 1, false);
          tienda               postgres    false    236         �           0    0 !   product_categories_pdt_ctg_id_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('tienda.product_categories_pdt_ctg_id_seq', 1, false);
          tienda               postgres    false    225         �           0    0    products_pdt_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('tienda.products_pdt_id_seq', 1, false);
          tienda               postgres    false    231         �           0    0    promotions_pmn_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('tienda.promotions_pmn_id_seq', 1, false);
          tienda               postgres    false    227         �           0    0    purchases_prc_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('tienda.purchases_prc_id_seq', 1, false);
          tienda               postgres    false    233         �           0    0    seasons_ssn_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('tienda.seasons_ssn_id_seq', 1, false);
          tienda               postgres    false    229         �           2606    73864    cities pk_cities 
   CONSTRAINT     b   ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT pk_cities PRIMARY KEY (cyy_id, dpt_id, cty_id);
 :   ALTER TABLE ONLY tienda.cities DROP CONSTRAINT pk_cities;
       tienda                 postgres    false    221    221    221         �           2606    73789    countries pk_countries 
   CONSTRAINT     X   ALTER TABLE ONLY tienda.countries
    ADD CONSTRAINT pk_countries PRIMARY KEY (cty_id);
 @   ALTER TABLE ONLY tienda.countries DROP CONSTRAINT pk_countries;
       tienda                 postgres    false    219         �           2606    73780    customers pk_customers 
   CONSTRAINT     Z   ALTER TABLE ONLY tienda.customers
    ADD CONSTRAINT pk_customers PRIMARY KEY (document);
 @   ALTER TABLE ONLY tienda.customers DROP CONSTRAINT pk_customers;
       tienda                 postgres    false    218         �           2606    73805    departaments pk_departaments 
   CONSTRAINT     f   ALTER TABLE ONLY tienda.departaments
    ADD CONSTRAINT pk_departaments PRIMARY KEY (dpt_id, cty_id);
 F   ALTER TABLE ONLY tienda.departaments DROP CONSTRAINT pk_departaments;
       tienda                 postgres    false    220    220         �           2606    74147    detail_orders pk_dtl_odr 
   CONSTRAINT     h   ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT pk_dtl_odr PRIMARY KEY (odr_id, line_item_id);
 B   ALTER TABLE ONLY tienda.detail_orders DROP CONSTRAINT pk_dtl_odr;
       tienda                 postgres    false    238    238         �           2606    74092    detail_purchases pk_dtl_prc 
   CONSTRAINT     k   ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT pk_dtl_prc PRIMARY KEY (prc_id, line_item_id);
 E   ALTER TABLE ONLY tienda.detail_purchases DROP CONSTRAINT pk_dtl_prc;
       tienda                 postgres    false    235    235         �           2606    74120    orders pk_odr 
   CONSTRAINT     O   ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT pk_odr PRIMARY KEY (odr_id);
 7   ALTER TABLE ONLY tienda.orders DROP CONSTRAINT pk_odr;
       tienda                 postgres    false    237         �           2606    73990    product_categories pk_pdt_ctg 
   CONSTRAINT     c   ALTER TABLE ONLY tienda.product_categories
    ADD CONSTRAINT pk_pdt_ctg PRIMARY KEY (pdt_ctg_id);
 G   ALTER TABLE ONLY tienda.product_categories DROP CONSTRAINT pk_pdt_ctg;
       tienda                 postgres    false    226         �           2606    73977    product_lot pk_pdt_lot 
   CONSTRAINT     \   ALTER TABLE ONLY tienda.product_lot
    ADD CONSTRAINT pk_pdt_lot PRIMARY KEY (pdt_lot_id);
 @   ALTER TABLE ONLY tienda.product_lot DROP CONSTRAINT pk_pdt_lot;
       tienda                 postgres    false    224         �           2606    74033    products pk_products 
   CONSTRAINT     b   ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT pk_products PRIMARY KEY (pdt_id, pdt_ctg_id);
 >   ALTER TABLE ONLY tienda.products DROP CONSTRAINT pk_products;
       tienda                 postgres    false    232    232         �           2606    74007    promotions pk_promotions 
   CONSTRAINT     Z   ALTER TABLE ONLY tienda.promotions
    ADD CONSTRAINT pk_promotions PRIMARY KEY (pmn_id);
 B   ALTER TABLE ONLY tienda.promotions DROP CONSTRAINT pk_promotions;
       tienda                 postgres    false    228         �           2606    74067    purchases pk_purchases 
   CONSTRAINT     X   ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT pk_purchases PRIMARY KEY (prc_id);
 @   ALTER TABLE ONLY tienda.purchases DROP CONSTRAINT pk_purchases;
       tienda                 postgres    false    234         �           2606    74019    seasons pk_ssn 
   CONSTRAINT     P   ALTER TABLE ONLY tienda.seasons
    ADD CONSTRAINT pk_ssn PRIMARY KEY (ssn_id);
 8   ALTER TABLE ONLY tienda.seasons DROP CONSTRAINT pk_ssn;
       tienda                 postgres    false    230         �           2606    73963    staff pk_staff 
   CONSTRAINT     P   ALTER TABLE ONLY tienda.staff
    ADD CONSTRAINT pk_staff PRIMARY KEY (stf_id);
 8   ALTER TABLE ONLY tienda.staff DROP CONSTRAINT pk_staff;
       tienda                 postgres    false    223         �           2606    73910    suppliers pk_suppliers 
   CONSTRAINT     U   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT pk_suppliers PRIMARY KEY (nit);
 @   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT pk_suppliers;
       tienda                 postgres    false    222         �           2606    73782    customers uk_customers_phone 
   CONSTRAINT     _   ALTER TABLE ONLY tienda.customers
    ADD CONSTRAINT uk_customers_phone UNIQUE (phone_number);
 F   ALTER TABLE ONLY tienda.customers DROP CONSTRAINT uk_customers_phone;
       tienda                 postgres    false    218         �           2606    73965    staff uk_staff_phone 
   CONSTRAINT     W   ALTER TABLE ONLY tienda.staff
    ADD CONSTRAINT uk_staff_phone UNIQUE (phone_number);
 >   ALTER TABLE ONLY tienda.staff DROP CONSTRAINT uk_staff_phone;
       tienda                 postgres    false    223         �           2606    73912    suppliers uk_suppliers_phone 
   CONSTRAINT     _   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT uk_suppliers_phone UNIQUE (phone_number);
 F   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT uk_suppliers_phone;
       tienda                 postgres    false    222         �           2620    81965 (   detail_orders trg_actualizar_total_orden    TRIGGER     �   CREATE TRIGGER trg_actualizar_total_orden AFTER INSERT OR UPDATE ON tienda.detail_orders FOR EACH ROW EXECUTE FUNCTION tienda.fn_actualizar_total_orden();
 A   DROP TRIGGER trg_actualizar_total_orden ON tienda.detail_orders;
       tienda               postgres    false    240    238                     2620    81963 #   detail_orders trg_calcular_subtotal    TRIGGER     �   CREATE TRIGGER trg_calcular_subtotal BEFORE INSERT OR UPDATE ON tienda.detail_orders FOR EACH ROW EXECUTE FUNCTION tienda.fn_calcular_subtotal();
 <   DROP TRIGGER trg_calcular_subtotal ON tienda.detail_orders;
       tienda               postgres    false    239    238         �           2606    73870    cities fk_cities_cty    FK CONSTRAINT     z   ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT fk_cities_cty FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);
 >   ALTER TABLE ONLY tienda.cities DROP CONSTRAINT fk_cities_cty;
       tienda               postgres    false    219    4812    221         �           2606    73865    cities fk_cities_dpt    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT fk_cities_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES tienda.departaments(dpt_id, cty_id);
 >   ALTER TABLE ONLY tienda.cities DROP CONSTRAINT fk_cities_dpt;
       tienda               postgres    false    220    4814    221    220    221         �           2606    73806 $   departaments fk_departaments_country    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.departaments
    ADD CONSTRAINT fk_departaments_country FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);
 N   ALTER TABLE ONLY tienda.departaments DROP CONSTRAINT fk_departaments_country;
       tienda               postgres    false    4812    219    220         �           2606    74148    detail_orders fk_dtl_odr_orders    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT fk_dtl_odr_orders FOREIGN KEY (odr_id) REFERENCES tienda.orders(odr_id);
 I   ALTER TABLE ONLY tienda.detail_orders DROP CONSTRAINT fk_dtl_odr_orders;
       tienda               postgres    false    237    4840    238         �           2606    74153 !   detail_orders fk_dtl_odr_products    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT fk_dtl_odr_products FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES tienda.products(pdt_id, pdt_ctg_id);
 K   ALTER TABLE ONLY tienda.detail_orders DROP CONSTRAINT fk_dtl_odr_products;
       tienda               postgres    false    238    232    238    232    4834         �           2606    74098 .   detail_purchases fk_dtl_prc_product_categories    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_product_categories FOREIGN KEY (ctg_pdt_id) REFERENCES tienda.product_categories(pdt_ctg_id);
 X   ALTER TABLE ONLY tienda.detail_purchases DROP CONSTRAINT fk_dtl_prc_product_categories;
       tienda               postgres    false    235    226    4828         �           2606    74103 $   detail_purchases fk_dtl_prc_products    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_products FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES tienda.products(pdt_id, pdt_ctg_id);
 N   ALTER TABLE ONLY tienda.detail_purchases DROP CONSTRAINT fk_dtl_prc_products;
       tienda               postgres    false    4834    235    232    235    232         �           2606    74093 %   detail_purchases fk_dtl_prc_purchases    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_purchases FOREIGN KEY (prc_id) REFERENCES tienda.purchases(prc_id);
 O   ALTER TABLE ONLY tienda.detail_purchases DROP CONSTRAINT fk_dtl_prc_purchases;
       tienda               postgres    false    235    4836    234         �           2606    74121    orders fk_odr_customer    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT fk_odr_customer FOREIGN KEY (document) REFERENCES tienda.customers(document);
 @   ALTER TABLE ONLY tienda.orders DROP CONSTRAINT fk_odr_customer;
       tienda               postgres    false    237    218    4808         �           2606    74126    orders fk_odr_staff    FK CONSTRAINT     u   ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT fk_odr_staff FOREIGN KEY (stf_id) REFERENCES tienda.staff(stf_id);
 =   ALTER TABLE ONLY tienda.orders DROP CONSTRAINT fk_odr_staff;
       tienda               postgres    false    223    4822    237         �           2606    74034    products fk_products_ctg    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_ctg FOREIGN KEY (pdt_ctg_id) REFERENCES tienda.product_categories(pdt_ctg_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_ctg;
       tienda               postgres    false    232    4828    226         �           2606    74039    products fk_products_lot    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_lot FOREIGN KEY (lot_pdt_id) REFERENCES tienda.product_lot(pdt_lot_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_lot;
       tienda               postgres    false    232    224    4826         �           2606    74044    products fk_products_pmn    FK CONSTRAINT        ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_pmn FOREIGN KEY (pmn_id) REFERENCES tienda.promotions(pmn_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_pmn;
       tienda               postgres    false    4830    228    232         �           2606    74049    products fk_products_ssn    FK CONSTRAINT     |   ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_ssn FOREIGN KEY (ssn_id) REFERENCES tienda.seasons(ssn_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_ssn;
       tienda               postgres    false    232    230    4832         �           2606    74073    purchases fk_purchases_staff    FK CONSTRAINT     ~   ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT fk_purchases_staff FOREIGN KEY (stf_id) REFERENCES tienda.staff(stf_id);
 F   ALTER TABLE ONLY tienda.purchases DROP CONSTRAINT fk_purchases_staff;
       tienda               postgres    false    223    234    4822         �           2606    74068    purchases fk_purchases_supplier    FK CONSTRAINT        ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT fk_purchases_supplier FOREIGN KEY (nit) REFERENCES tienda.suppliers(nit);
 I   ALTER TABLE ONLY tienda.purchases DROP CONSTRAINT fk_purchases_supplier;
       tienda               postgres    false    4818    222    234         �           2606    73966    staff fk_staff_mgr    FK CONSTRAINT     t   ALTER TABLE ONLY tienda.staff
    ADD CONSTRAINT fk_staff_mgr FOREIGN KEY (mgr_id) REFERENCES tienda.staff(stf_id);
 <   ALTER TABLE ONLY tienda.staff DROP CONSTRAINT fk_staff_mgr;
       tienda               postgres    false    4822    223    223         �           2606    73913    suppliers fk_suppliers_city    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_city FOREIGN KEY (cyy_id, dpt_id, cty_id) REFERENCES tienda.cities(cyy_id, dpt_id, cty_id);
 E   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT fk_suppliers_city;
       tienda               postgres    false    221    222    222    221    221    222    4816         �           2606    73923    suppliers fk_suppliers_country    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_country FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);
 H   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT fk_suppliers_country;
       tienda               postgres    false    4812    219    222         �           2606    73918    suppliers fk_suppliers_dpt    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES tienda.departaments(dpt_id, cty_id);
 D   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT fk_suppliers_dpt;
       tienda               postgres    false    220    220    222    222    4814                                                                                                                                                                                                                                                                                             5013.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014243 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5011.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014241 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5010.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014240 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5012.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5030.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5027.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5029.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5018.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5016.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014246 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5024.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5020.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014241 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5026.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014247 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5022.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014243 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5015.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5014.dat                                                                                            0000600 0004000 0002000 00000000005 15014672533 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           restore.sql                                                                                         0000600 0004000 0002000 00000103336 15014672533 0015400 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE "DISAMAN_DB";
--
-- Name: DISAMAN_DB; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE "DISAMAN_DB" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'es-ES';


ALTER DATABASE "DISAMAN_DB" OWNER TO postgres;

\connect "DISAMAN_DB"

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: tienda; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA tienda;


ALTER SCHEMA tienda OWNER TO postgres;

--
-- Name: fn_actualizar_total_orden(); Type: FUNCTION; Schema: tienda; Owner: postgres
--

CREATE FUNCTION tienda.fn_actualizar_total_orden() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total NUMERIC(10, 2);
    v_total_discount NUMERIC(10, 2);
BEGIN
    -- Calcular el total y el total de descuento para la orden actual
    SELECT 
        SUM(subtotal),
        SUM(discount_value * quantity)
    INTO 
        v_total,
        v_total_discount
    FROM TIENDA.DETAIL_ORDERS
    WHERE odr_id = NEW.odr_id;

    -- Actualizar la orden con los nuevos totales
    UPDATE TIENDA.ORDERS
    SET total = v_total,
        discount_value = v_total_discount
    WHERE odr_id = NEW.odr_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION tienda.fn_actualizar_total_orden() OWNER TO postgres;

--
-- Name: fn_calcular_subtotal(); Type: FUNCTION; Schema: tienda; Owner: postgres
--

CREATE FUNCTION tienda.fn_calcular_subtotal() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_unit_price NUMERIC(10, 2);
    v_discount_value NUMERIC(10, 2) := 0;
    v_discount_type VARCHAR(10);
    v_percent NUMERIC(10, 2);
    v_fixed NUMERIC(10, 2);
    v_subtotal NUMERIC(10, 2);
    v_pmn_id INT;
BEGIN
    -- Validar cantidad
    IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'La cantidad debe ser mayor que cero. Producto: %', NEW.pdt_id;
    END IF;

    -- Obtener precio y promoción del producto
    SELECT p.unit_price, p.pmn_id INTO v_unit_price, v_pmn_id
    FROM TIENDA.PRODUCTS p
    WHERE p.pdt_id = NEW.pdt_id AND p.pdt_ctg_id = NEW.ctg_pdt_id;

    -- Si tiene promoción
    IF v_pmn_id IS NOT NULL THEN
        SELECT discount_type, disccount, discount_value
        INTO v_discount_type, v_percent, v_fixed
        FROM TIENDA.PROMOTIONS
        WHERE pmn_id = v_pmn_id AND state = 'active';

        IF FOUND THEN
            IF v_discount_type = 'PERCENT' THEN
                v_discount_value := ROUND((v_unit_price * v_percent / 100), 2);
            ELSIF v_discount_type = 'FIXED' THEN
                v_discount_value := v_fixed;
            END IF;
        END IF;
    END IF;

    -- Calcular subtotal
    v_subtotal := (v_unit_price - v_discount_value) * NEW.quantity;

    -- Asignar resultados al registro
    NEW.unit_price := v_unit_price;
    NEW.discount_value := v_discount_value;
    NEW.subtotal := v_subtotal;

    RETURN NEW;
END;
$$;


ALTER FUNCTION tienda.fn_calcular_subtotal() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cities; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.cities (
    cyy_id character varying(3) NOT NULL,
    name character varying(60),
    dpt_id character varying(3) NOT NULL,
    cty_id character varying(3) NOT NULL,
    CONSTRAINT nn_cities_cty CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_cities_dpt CHECK ((dpt_id IS NOT NULL)),
    CONSTRAINT nn_cities_id CHECK ((cyy_id IS NOT NULL)),
    CONSTRAINT nn_cities_name CHECK ((name IS NOT NULL))
);


ALTER TABLE tienda.cities OWNER TO postgres;

--
-- Name: countries; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.countries (
    cty_id character varying(3) NOT NULL,
    name character varying(60),
    CONSTRAINT nn_countries_cty_id CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_countries_name CHECK ((name IS NOT NULL))
);


ALTER TABLE tienda.countries OWNER TO postgres;

--
-- Name: customers; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.customers (
    document character varying(15) NOT NULL,
    first_name character varying(50),
    middle_name character varying(50),
    last_name character varying(50),
    middle_last_name character varying(50),
    phone_number character varying(15),
    address character varying(100),
    CONSTRAINT nn_customers_address CHECK ((address IS NOT NULL)),
    CONSTRAINT nn_customers_first_name CHECK ((first_name IS NOT NULL)),
    CONSTRAINT nn_customers_id CHECK ((document IS NOT NULL)),
    CONSTRAINT nn_customers_last_name CHECK ((last_name IS NOT NULL)),
    CONSTRAINT nn_customers_middle_last_name CHECK ((middle_last_name IS NOT NULL)),
    CONSTRAINT nn_customers_phone CHECK ((phone_number IS NOT NULL))
);


ALTER TABLE tienda.customers OWNER TO postgres;

--
-- Name: departaments; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.departaments (
    dpt_id character varying(3) NOT NULL,
    name character varying(60),
    cty_id character varying(3) NOT NULL,
    CONSTRAINT nn_departaments_cty CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_departaments_id CHECK ((dpt_id IS NOT NULL)),
    CONSTRAINT nn_departaments_name CHECK ((name IS NOT NULL))
);


ALTER TABLE tienda.departaments OWNER TO postgres;

--
-- Name: detail_orders; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.detail_orders (
    odr_id integer NOT NULL,
    line_item_id integer NOT NULL,
    ctg_pdt_id integer,
    pdt_id integer,
    quantity numeric(10,2),
    unit_price numeric(10,2),
    subtotal numeric(10,2),
    discount_value numeric(10,2) DEFAULT 0,
    CONSTRAINT ck_dtl_odr_quantity CHECK ((quantity > (0)::numeric)),
    CONSTRAINT ck_dtl_odr_unit_price CHECK ((unit_price > (0)::numeric)),
    CONSTRAINT detail_orders_check CHECK (((discount_value >= (0)::numeric) AND (discount_value <= unit_price))),
    CONSTRAINT nn_dtl_odr_ctg_pdt CHECK ((ctg_pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_line_item CHECK ((line_item_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_odr_id CHECK ((odr_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_pdt_id CHECK ((pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_quantity CHECK ((quantity IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_subtotal CHECK ((subtotal IS NOT NULL)),
    CONSTRAINT nn_dtl_odr_unit_price CHECK ((unit_price IS NOT NULL))
);


ALTER TABLE tienda.detail_orders OWNER TO postgres;

--
-- Name: detail_purchases; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.detail_purchases (
    prc_id integer NOT NULL,
    line_item_id integer NOT NULL,
    ctg_pdt_id integer,
    pdt_id integer,
    quantity numeric(10,2),
    unit_price numeric(10,2),
    subtotal numeric(10,2),
    CONSTRAINT ck_dtl_prc_quantity CHECK ((quantity > (0)::numeric)),
    CONSTRAINT ck_dtl_prc_subtotal CHECK ((subtotal = (quantity * unit_price))),
    CONSTRAINT ck_dtl_prc_unit_price CHECK ((unit_price > (0)::numeric)),
    CONSTRAINT nn_dtl_prc_ctg_pdt CHECK ((ctg_pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_line_item CHECK ((line_item_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_pdt_id CHECK ((pdt_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_prc_id CHECK ((prc_id IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_quantity CHECK ((quantity IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_subtotal CHECK ((subtotal IS NOT NULL)),
    CONSTRAINT nn_dtl_prc_unit_price CHECK ((unit_price IS NOT NULL))
);


ALTER TABLE tienda.detail_purchases OWNER TO postgres;

--
-- Name: orders; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.orders (
    odr_id integer NOT NULL,
    order_date date,
    total numeric(10,2),
    document character varying(15),
    stf_id character varying(4),
    description character varying(200),
    discount_value numeric(10,2) DEFAULT 0,
    CONSTRAINT ck_odr_staff_employee CHECK (((stf_id)::text ~~ 'EP%'::text)),
    CONSTRAINT ck_odr_total CHECK ((total > (0)::numeric)),
    CONSTRAINT nn_odr_document CHECK ((document IS NOT NULL)),
    CONSTRAINT nn_odr_order_date CHECK ((order_date IS NOT NULL)),
    CONSTRAINT nn_odr_stf_id CHECK ((stf_id IS NOT NULL)),
    CONSTRAINT nn_odr_total CHECK ((total IS NOT NULL)),
    CONSTRAINT orders_discount_value_check CHECK ((discount_value >= (0)::numeric))
);


ALTER TABLE tienda.orders OWNER TO postgres;

--
-- Name: orders_odr_id_seq; Type: SEQUENCE; Schema: tienda; Owner: postgres
--

CREATE SEQUENCE tienda.orders_odr_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE tienda.orders_odr_id_seq OWNER TO postgres;

--
-- Name: orders_odr_id_seq; Type: SEQUENCE OWNED BY; Schema: tienda; Owner: postgres
--

ALTER SEQUENCE tienda.orders_odr_id_seq OWNED BY tienda.orders.odr_id;


--
-- Name: product_categories; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.product_categories (
    pdt_ctg_id integer NOT NULL,
    name character varying(50),
    description character varying(200),
    CONSTRAINT nn_pdt_ctg_name CHECK ((name IS NOT NULL))
);


ALTER TABLE tienda.product_categories OWNER TO postgres;

--
-- Name: product_categories_pdt_ctg_id_seq; Type: SEQUENCE; Schema: tienda; Owner: postgres
--

CREATE SEQUENCE tienda.product_categories_pdt_ctg_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE tienda.product_categories_pdt_ctg_id_seq OWNER TO postgres;

--
-- Name: product_categories_pdt_ctg_id_seq; Type: SEQUENCE OWNED BY; Schema: tienda; Owner: postgres
--

ALTER SEQUENCE tienda.product_categories_pdt_ctg_id_seq OWNED BY tienda.product_categories.pdt_ctg_id;


--
-- Name: product_lot; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.product_lot (
    pdt_lot_id character varying(4) NOT NULL,
    expiration_date date,
    CONSTRAINT nn_pdt_lot_expiration CHECK ((expiration_date IS NOT NULL)),
    CONSTRAINT nn_pdt_lot_id CHECK ((pdt_lot_id IS NOT NULL))
);


ALTER TABLE tienda.product_lot OWNER TO postgres;

--
-- Name: products; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.products (
    pdt_id integer NOT NULL,
    name character varying(50),
    description character varying(200),
    unit_price numeric(10,0),
    stock integer,
    pdt_ctg_id integer NOT NULL,
    lot_pdt_id character varying(4),
    pmn_id integer,
    ssn_id integer,
    CONSTRAINT ck_stock_range CHECK (((stock >= 0) AND (stock <= 999))),
    CONSTRAINT ck_unit_price CHECK ((unit_price > (0)::numeric)),
    CONSTRAINT nn_products_ctg_id CHECK ((pdt_ctg_id IS NOT NULL)),
    CONSTRAINT nn_products_lot_id CHECK ((lot_pdt_id IS NOT NULL)),
    CONSTRAINT nn_products_name CHECK ((name IS NOT NULL)),
    CONSTRAINT nn_products_stock CHECK ((stock IS NOT NULL)),
    CONSTRAINT nn_products_unit_price CHECK ((unit_price IS NOT NULL))
);


ALTER TABLE tienda.products OWNER TO postgres;

--
-- Name: products_pdt_id_seq; Type: SEQUENCE; Schema: tienda; Owner: postgres
--

CREATE SEQUENCE tienda.products_pdt_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE tienda.products_pdt_id_seq OWNER TO postgres;

--
-- Name: products_pdt_id_seq; Type: SEQUENCE OWNED BY; Schema: tienda; Owner: postgres
--

ALTER SEQUENCE tienda.products_pdt_id_seq OWNED BY tienda.products.pdt_id;


--
-- Name: promotions; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.promotions (
    pmn_id integer NOT NULL,
    start_date date,
    finish_date date,
    disccount numeric(2,0),
    discount_value numeric(10,0),
    state character varying(15),
    discount_type character varying(10),
    CONSTRAINT ck_discount_range CHECK (((disccount >= (0)::numeric) AND (disccount <= (100)::numeric))),
    CONSTRAINT ck_discount_value CHECK ((discount_value > (0)::numeric)),
    CONSTRAINT ck_finish_date CHECK ((finish_date >= start_date)),
    CONSTRAINT ck_pmn_state CHECK (((state)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'paused'::character varying])::text[]))),
    CONSTRAINT ck_promotion_discount_logic CHECK (((((discount_type)::text = 'PERCENT'::text) AND (disccount IS NOT NULL) AND (discount_value IS NULL)) OR (((discount_type)::text = 'FIXED'::text) AND (discount_value IS NOT NULL) AND (disccount IS NULL)))),
    CONSTRAINT nn_pmn_discount CHECK ((disccount IS NOT NULL)),
    CONSTRAINT nn_pmn_discount_value CHECK ((discount_value IS NOT NULL)),
    CONSTRAINT nn_pmn_finish_date CHECK ((finish_date IS NOT NULL)),
    CONSTRAINT nn_pmn_id CHECK ((pmn_id IS NOT NULL)),
    CONSTRAINT nn_pmn_start_date CHECK ((start_date IS NOT NULL)),
    CONSTRAINT nn_pmn_state CHECK ((state IS NOT NULL)),
    CONSTRAINT promotions_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['PERCENT'::character varying, 'FIXED'::character varying])::text[])))
);


ALTER TABLE tienda.promotions OWNER TO postgres;

--
-- Name: promotions_pmn_id_seq; Type: SEQUENCE; Schema: tienda; Owner: postgres
--

CREATE SEQUENCE tienda.promotions_pmn_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE tienda.promotions_pmn_id_seq OWNER TO postgres;

--
-- Name: promotions_pmn_id_seq; Type: SEQUENCE OWNED BY; Schema: tienda; Owner: postgres
--

ALTER SEQUENCE tienda.promotions_pmn_id_seq OWNED BY tienda.promotions.pmn_id;


--
-- Name: purchases; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.purchases (
    prc_id integer NOT NULL,
    purchase_date date,
    total numeric(10,0),
    nit character varying(15),
    stf_id character varying(4),
    description character varying(200),
    CONSTRAINT ck_purchases_stf CHECK (((stf_id)::text ~ '^MG'::text)),
    CONSTRAINT ck_purchases_total CHECK ((total > (0)::numeric)),
    CONSTRAINT nn_purchases_date CHECK ((purchase_date IS NOT NULL)),
    CONSTRAINT nn_purchases_id CHECK ((prc_id IS NOT NULL)),
    CONSTRAINT nn_purchases_nit CHECK ((nit IS NOT NULL)),
    CONSTRAINT nn_purchases_stf CHECK ((stf_id IS NOT NULL)),
    CONSTRAINT nn_purchases_total CHECK ((total IS NOT NULL))
);


ALTER TABLE tienda.purchases OWNER TO postgres;

--
-- Name: purchases_prc_id_seq; Type: SEQUENCE; Schema: tienda; Owner: postgres
--

CREATE SEQUENCE tienda.purchases_prc_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE tienda.purchases_prc_id_seq OWNER TO postgres;

--
-- Name: purchases_prc_id_seq; Type: SEQUENCE OWNED BY; Schema: tienda; Owner: postgres
--

ALTER SEQUENCE tienda.purchases_prc_id_seq OWNED BY tienda.purchases.prc_id;


--
-- Name: seasons; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.seasons (
    ssn_id integer NOT NULL,
    name character varying(50),
    start_date date,
    finish_date date,
    CONSTRAINT ck_ssn_date CHECK ((finish_date >= start_date)),
    CONSTRAINT nn_ssn_finish_date CHECK ((finish_date IS NOT NULL)),
    CONSTRAINT nn_ssn_id CHECK ((ssn_id IS NOT NULL)),
    CONSTRAINT nn_ssn_name CHECK ((name IS NOT NULL)),
    CONSTRAINT nn_ssn_start_date CHECK ((start_date IS NOT NULL))
);


ALTER TABLE tienda.seasons OWNER TO postgres;

--
-- Name: seasons_ssn_id_seq; Type: SEQUENCE; Schema: tienda; Owner: postgres
--

CREATE SEQUENCE tienda.seasons_ssn_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE tienda.seasons_ssn_id_seq OWNER TO postgres;

--
-- Name: seasons_ssn_id_seq; Type: SEQUENCE OWNED BY; Schema: tienda; Owner: postgres
--

ALTER SEQUENCE tienda.seasons_ssn_id_seq OWNED BY tienda.seasons.ssn_id;


--
-- Name: staff; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.staff (
    stf_id character varying(4) NOT NULL,
    first_name character varying(50),
    middle_name character varying(50),
    last_name character varying(50),
    middle_last_name character varying(50),
    phone_number character varying(15),
    address character varying(100),
    salary numeric(10,0),
    mgr_id character varying(4),
    type_worker character varying(50),
    sales integer,
    bonification numeric(10,0),
    employee_number integer,
    CONSTRAINT ck_employee_number CHECK (((((type_worker)::text = 'MANAGER'::text) AND (employee_number IS NOT NULL)) OR (((type_worker)::text = 'EMPLOYEE'::text) AND (employee_number IS NULL)))),
    CONSTRAINT ck_employee_sales_bonus CHECK (((((type_worker)::text = 'MANAGER'::text) AND (sales IS NULL) AND (bonification IS NULL)) OR ((type_worker)::text = 'EMPLOYEE'::text))),
    CONSTRAINT nn_staff_address CHECK ((address IS NOT NULL)),
    CONSTRAINT nn_staff_first_name CHECK ((first_name IS NOT NULL)),
    CONSTRAINT nn_staff_id CHECK ((stf_id IS NOT NULL)),
    CONSTRAINT nn_staff_last_name CHECK ((last_name IS NOT NULL)),
    CONSTRAINT nn_staff_middle_last_name CHECK ((middle_last_name IS NOT NULL)),
    CONSTRAINT nn_staff_phone CHECK ((phone_number IS NOT NULL)),
    CONSTRAINT nn_staff_salary CHECK ((salary IS NOT NULL)),
    CONSTRAINT nn_staff_type_worker CHECK ((type_worker IS NOT NULL))
);


ALTER TABLE tienda.staff OWNER TO postgres;

--
-- Name: suppliers; Type: TABLE; Schema: tienda; Owner: postgres
--

CREATE TABLE tienda.suppliers (
    nit character varying(15) NOT NULL,
    first_name character varying(50),
    middle_name character varying(50),
    last_name character varying(50),
    phone_number character varying(15),
    address character varying(100),
    cyy_id character varying(3),
    dpt_id character varying(3),
    cty_id character varying(3),
    CONSTRAINT nn_suppliers_address CHECK ((address IS NOT NULL)),
    CONSTRAINT nn_suppliers_city CHECK ((cyy_id IS NOT NULL)),
    CONSTRAINT nn_suppliers_country CHECK ((cty_id IS NOT NULL)),
    CONSTRAINT nn_suppliers_dpt CHECK ((dpt_id IS NOT NULL)),
    CONSTRAINT nn_suppliers_first_name CHECK ((first_name IS NOT NULL)),
    CONSTRAINT nn_suppliers_last_name CHECK ((last_name IS NOT NULL)),
    CONSTRAINT nn_suppliers_nit CHECK ((nit IS NOT NULL)),
    CONSTRAINT nn_suppliers_phone CHECK ((phone_number IS NOT NULL))
);


ALTER TABLE tienda.suppliers OWNER TO postgres;

--
-- Name: orders odr_id; Type: DEFAULT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.orders ALTER COLUMN odr_id SET DEFAULT nextval('tienda.orders_odr_id_seq'::regclass);


--
-- Name: product_categories pdt_ctg_id; Type: DEFAULT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.product_categories ALTER COLUMN pdt_ctg_id SET DEFAULT nextval('tienda.product_categories_pdt_ctg_id_seq'::regclass);


--
-- Name: products pdt_id; Type: DEFAULT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.products ALTER COLUMN pdt_id SET DEFAULT nextval('tienda.products_pdt_id_seq'::regclass);


--
-- Name: promotions pmn_id; Type: DEFAULT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.promotions ALTER COLUMN pmn_id SET DEFAULT nextval('tienda.promotions_pmn_id_seq'::regclass);


--
-- Name: purchases prc_id; Type: DEFAULT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.purchases ALTER COLUMN prc_id SET DEFAULT nextval('tienda.purchases_prc_id_seq'::regclass);


--
-- Name: seasons ssn_id; Type: DEFAULT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.seasons ALTER COLUMN ssn_id SET DEFAULT nextval('tienda.seasons_ssn_id_seq'::regclass);


--
-- Data for Name: cities; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.cities (cyy_id, name, dpt_id, cty_id) FROM stdin;
\.
COPY tienda.cities (cyy_id, name, dpt_id, cty_id) FROM '$$PATH$$/5013.dat';

--
-- Data for Name: countries; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.countries (cty_id, name) FROM stdin;
\.
COPY tienda.countries (cty_id, name) FROM '$$PATH$$/5011.dat';

--
-- Data for Name: customers; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.customers (document, first_name, middle_name, last_name, middle_last_name, phone_number, address) FROM stdin;
\.
COPY tienda.customers (document, first_name, middle_name, last_name, middle_last_name, phone_number, address) FROM '$$PATH$$/5010.dat';

--
-- Data for Name: departaments; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.departaments (dpt_id, name, cty_id) FROM stdin;
\.
COPY tienda.departaments (dpt_id, name, cty_id) FROM '$$PATH$$/5012.dat';

--
-- Data for Name: detail_orders; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.detail_orders (odr_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal, discount_value) FROM stdin;
\.
COPY tienda.detail_orders (odr_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal, discount_value) FROM '$$PATH$$/5030.dat';

--
-- Data for Name: detail_purchases; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.detail_purchases (prc_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal) FROM stdin;
\.
COPY tienda.detail_purchases (prc_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal) FROM '$$PATH$$/5027.dat';

--
-- Data for Name: orders; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.orders (odr_id, order_date, total, document, stf_id, description, discount_value) FROM stdin;
\.
COPY tienda.orders (odr_id, order_date, total, document, stf_id, description, discount_value) FROM '$$PATH$$/5029.dat';

--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.product_categories (pdt_ctg_id, name, description) FROM stdin;
\.
COPY tienda.product_categories (pdt_ctg_id, name, description) FROM '$$PATH$$/5018.dat';

--
-- Data for Name: product_lot; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.product_lot (pdt_lot_id, expiration_date) FROM stdin;
\.
COPY tienda.product_lot (pdt_lot_id, expiration_date) FROM '$$PATH$$/5016.dat';

--
-- Data for Name: products; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.products (pdt_id, name, description, unit_price, stock, pdt_ctg_id, lot_pdt_id, pmn_id, ssn_id) FROM stdin;
\.
COPY tienda.products (pdt_id, name, description, unit_price, stock, pdt_ctg_id, lot_pdt_id, pmn_id, ssn_id) FROM '$$PATH$$/5024.dat';

--
-- Data for Name: promotions; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.promotions (pmn_id, start_date, finish_date, disccount, discount_value, state, discount_type) FROM stdin;
\.
COPY tienda.promotions (pmn_id, start_date, finish_date, disccount, discount_value, state, discount_type) FROM '$$PATH$$/5020.dat';

--
-- Data for Name: purchases; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.purchases (prc_id, purchase_date, total, nit, stf_id, description) FROM stdin;
\.
COPY tienda.purchases (prc_id, purchase_date, total, nit, stf_id, description) FROM '$$PATH$$/5026.dat';

--
-- Data for Name: seasons; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.seasons (ssn_id, name, start_date, finish_date) FROM stdin;
\.
COPY tienda.seasons (ssn_id, name, start_date, finish_date) FROM '$$PATH$$/5022.dat';

--
-- Data for Name: staff; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.staff (stf_id, first_name, middle_name, last_name, middle_last_name, phone_number, address, salary, mgr_id, type_worker, sales, bonification, employee_number) FROM stdin;
\.
COPY tienda.staff (stf_id, first_name, middle_name, last_name, middle_last_name, phone_number, address, salary, mgr_id, type_worker, sales, bonification, employee_number) FROM '$$PATH$$/5015.dat';

--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.suppliers (nit, first_name, middle_name, last_name, phone_number, address, cyy_id, dpt_id, cty_id) FROM stdin;
\.
COPY tienda.suppliers (nit, first_name, middle_name, last_name, phone_number, address, cyy_id, dpt_id, cty_id) FROM '$$PATH$$/5014.dat';

--
-- Name: orders_odr_id_seq; Type: SEQUENCE SET; Schema: tienda; Owner: postgres
--

SELECT pg_catalog.setval('tienda.orders_odr_id_seq', 1, false);


--
-- Name: product_categories_pdt_ctg_id_seq; Type: SEQUENCE SET; Schema: tienda; Owner: postgres
--

SELECT pg_catalog.setval('tienda.product_categories_pdt_ctg_id_seq', 1, false);


--
-- Name: products_pdt_id_seq; Type: SEQUENCE SET; Schema: tienda; Owner: postgres
--

SELECT pg_catalog.setval('tienda.products_pdt_id_seq', 1, false);


--
-- Name: promotions_pmn_id_seq; Type: SEQUENCE SET; Schema: tienda; Owner: postgres
--

SELECT pg_catalog.setval('tienda.promotions_pmn_id_seq', 1, false);


--
-- Name: purchases_prc_id_seq; Type: SEQUENCE SET; Schema: tienda; Owner: postgres
--

SELECT pg_catalog.setval('tienda.purchases_prc_id_seq', 1, false);


--
-- Name: seasons_ssn_id_seq; Type: SEQUENCE SET; Schema: tienda; Owner: postgres
--

SELECT pg_catalog.setval('tienda.seasons_ssn_id_seq', 1, false);


--
-- Name: cities pk_cities; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT pk_cities PRIMARY KEY (cyy_id, dpt_id, cty_id);


--
-- Name: countries pk_countries; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.countries
    ADD CONSTRAINT pk_countries PRIMARY KEY (cty_id);


--
-- Name: customers pk_customers; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.customers
    ADD CONSTRAINT pk_customers PRIMARY KEY (document);


--
-- Name: departaments pk_departaments; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.departaments
    ADD CONSTRAINT pk_departaments PRIMARY KEY (dpt_id, cty_id);


--
-- Name: detail_orders pk_dtl_odr; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT pk_dtl_odr PRIMARY KEY (odr_id, line_item_id);


--
-- Name: detail_purchases pk_dtl_prc; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT pk_dtl_prc PRIMARY KEY (prc_id, line_item_id);


--
-- Name: orders pk_odr; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT pk_odr PRIMARY KEY (odr_id);


--
-- Name: product_categories pk_pdt_ctg; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.product_categories
    ADD CONSTRAINT pk_pdt_ctg PRIMARY KEY (pdt_ctg_id);


--
-- Name: product_lot pk_pdt_lot; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.product_lot
    ADD CONSTRAINT pk_pdt_lot PRIMARY KEY (pdt_lot_id);


--
-- Name: products pk_products; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT pk_products PRIMARY KEY (pdt_id, pdt_ctg_id);


--
-- Name: promotions pk_promotions; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.promotions
    ADD CONSTRAINT pk_promotions PRIMARY KEY (pmn_id);


--
-- Name: purchases pk_purchases; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT pk_purchases PRIMARY KEY (prc_id);


--
-- Name: seasons pk_ssn; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.seasons
    ADD CONSTRAINT pk_ssn PRIMARY KEY (ssn_id);


--
-- Name: staff pk_staff; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.staff
    ADD CONSTRAINT pk_staff PRIMARY KEY (stf_id);


--
-- Name: suppliers pk_suppliers; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT pk_suppliers PRIMARY KEY (nit);


--
-- Name: customers uk_customers_phone; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.customers
    ADD CONSTRAINT uk_customers_phone UNIQUE (phone_number);


--
-- Name: staff uk_staff_phone; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.staff
    ADD CONSTRAINT uk_staff_phone UNIQUE (phone_number);


--
-- Name: suppliers uk_suppliers_phone; Type: CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT uk_suppliers_phone UNIQUE (phone_number);


--
-- Name: detail_orders trg_actualizar_total_orden; Type: TRIGGER; Schema: tienda; Owner: postgres
--

CREATE TRIGGER trg_actualizar_total_orden AFTER INSERT OR UPDATE ON tienda.detail_orders FOR EACH ROW EXECUTE FUNCTION tienda.fn_actualizar_total_orden();


--
-- Name: detail_orders trg_calcular_subtotal; Type: TRIGGER; Schema: tienda; Owner: postgres
--

CREATE TRIGGER trg_calcular_subtotal BEFORE INSERT OR UPDATE ON tienda.detail_orders FOR EACH ROW EXECUTE FUNCTION tienda.fn_calcular_subtotal();


--
-- Name: cities fk_cities_cty; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT fk_cities_cty FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);


--
-- Name: cities fk_cities_dpt; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT fk_cities_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES tienda.departaments(dpt_id, cty_id);


--
-- Name: departaments fk_departaments_country; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.departaments
    ADD CONSTRAINT fk_departaments_country FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);


--
-- Name: detail_orders fk_dtl_odr_orders; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT fk_dtl_odr_orders FOREIGN KEY (odr_id) REFERENCES tienda.orders(odr_id);


--
-- Name: detail_orders fk_dtl_odr_products; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT fk_dtl_odr_products FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES tienda.products(pdt_id, pdt_ctg_id);


--
-- Name: detail_purchases fk_dtl_prc_product_categories; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_product_categories FOREIGN KEY (ctg_pdt_id) REFERENCES tienda.product_categories(pdt_ctg_id);


--
-- Name: detail_purchases fk_dtl_prc_products; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_products FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES tienda.products(pdt_id, pdt_ctg_id);


--
-- Name: detail_purchases fk_dtl_prc_purchases; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_purchases FOREIGN KEY (prc_id) REFERENCES tienda.purchases(prc_id);


--
-- Name: orders fk_odr_customer; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT fk_odr_customer FOREIGN KEY (document) REFERENCES tienda.customers(document);


--
-- Name: orders fk_odr_staff; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT fk_odr_staff FOREIGN KEY (stf_id) REFERENCES tienda.staff(stf_id);


--
-- Name: products fk_products_ctg; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_ctg FOREIGN KEY (pdt_ctg_id) REFERENCES tienda.product_categories(pdt_ctg_id);


--
-- Name: products fk_products_lot; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_lot FOREIGN KEY (lot_pdt_id) REFERENCES tienda.product_lot(pdt_lot_id);


--
-- Name: products fk_products_pmn; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_pmn FOREIGN KEY (pmn_id) REFERENCES tienda.promotions(pmn_id);


--
-- Name: products fk_products_ssn; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_ssn FOREIGN KEY (ssn_id) REFERENCES tienda.seasons(ssn_id);


--
-- Name: purchases fk_purchases_staff; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT fk_purchases_staff FOREIGN KEY (stf_id) REFERENCES tienda.staff(stf_id);


--
-- Name: purchases fk_purchases_supplier; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT fk_purchases_supplier FOREIGN KEY (nit) REFERENCES tienda.suppliers(nit);


--
-- Name: staff fk_staff_mgr; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.staff
    ADD CONSTRAINT fk_staff_mgr FOREIGN KEY (mgr_id) REFERENCES tienda.staff(stf_id);


--
-- Name: suppliers fk_suppliers_city; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_city FOREIGN KEY (cyy_id, dpt_id, cty_id) REFERENCES tienda.cities(cyy_id, dpt_id, cty_id);


--
-- Name: suppliers fk_suppliers_country; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_country FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);


--
-- Name: suppliers fk_suppliers_dpt; Type: FK CONSTRAINT; Schema: tienda; Owner: postgres
--

ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES tienda.departaments(dpt_id, cty_id);


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  