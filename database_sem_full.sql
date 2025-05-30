toc.dat                                                                                             0000600 0004000 0002000 00000121042 15015340177 0014442 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP       '                }         
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
       tienda               postgres    false    6    237         �           0    0    orders_odr_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE tienda.orders_odr_id_seq OWNED BY tienda.orders.odr_id;
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
       tienda               postgres    false    6    226         �           0    0 !   product_categories_pdt_ctg_id_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE tienda.product_categories_pdt_ctg_id_seq OWNED BY tienda.product_categories.pdt_ctg_id;
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
    CONSTRAINT ck_discount_logic CHECK (((((discount_type)::text = 'FIXED'::text) AND (discount_value > (0)::numeric) AND (disccount = (0)::numeric)) OR (((discount_type)::text = 'PERCENT'::text) AND (disccount > (0)::numeric) AND (discount_value = (0)::numeric)))),
    CONSTRAINT ck_discount_range CHECK (((disccount >= (0)::numeric) AND (disccount <= (100)::numeric))),
    CONSTRAINT ck_finish_date CHECK ((finish_date >= start_date)),
    CONSTRAINT ck_pmn_state CHECK (((state)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'paused'::character varying])::text[]))),
    CONSTRAINT ck_promotion_discount_logic CHECK (((((discount_type)::text = 'PERCENT'::text) AND (disccount IS NOT NULL) AND (discount_value IS NULL)) OR (((discount_type)::text = 'FIXED'::text) AND (discount_value IS NOT NULL) AND (disccount IS NULL)))),
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
       tienda               postgres    false    6    230         �           0    0    seasons_ssn_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE tienda.seasons_ssn_id_seq OWNED BY tienda.seasons.ssn_id;
          tienda               postgres    false    229         �            1259    73949    staff    TABLE     �  CREATE TABLE tienda.staff (
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
    employee_number integer,
    CONSTRAINT ck_employee_number CHECK (((((type_worker)::text = 'MANAGER'::text) AND (employee_number IS NOT NULL)) OR (((type_worker)::text = 'EMPLOYEE'::text) AND (employee_number IS NULL)))),
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
       tienda               postgres    false    232    231    232         b           2604    73995    promotions pmn_id    DEFAULT     v   ALTER TABLE ONLY tienda.promotions ALTER COLUMN pmn_id SET DEFAULT nextval('tienda.promotions_pmn_id_seq'::regclass);
 @   ALTER TABLE tienda.promotions ALTER COLUMN pmn_id DROP DEFAULT;
       tienda               postgres    false    228    227    228         e           2604    74058    purchases prc_id    DEFAULT     t   ALTER TABLE ONLY tienda.purchases ALTER COLUMN prc_id SET DEFAULT nextval('tienda.purchases_prc_id_seq'::regclass);
 ?   ALTER TABLE tienda.purchases ALTER COLUMN prc_id DROP DEFAULT;
       tienda               postgres    false    234    233    234         c           2604    74012    seasons ssn_id    DEFAULT     p   ALTER TABLE ONLY tienda.seasons ALTER COLUMN ssn_id SET DEFAULT nextval('tienda.seasons_ssn_id_seq'::regclass);
 =   ALTER TABLE tienda.seasons ALTER COLUMN ssn_id DROP DEFAULT;
       tienda               postgres    false    230    229    230         �          0    73856    cities 
   TABLE DATA           >   COPY tienda.cities (cyy_id, name, dpt_id, cty_id) FROM stdin;
    tienda               postgres    false    221       5010.dat �          0    73783 	   countries 
   TABLE DATA           1   COPY tienda.countries (cty_id, name) FROM stdin;
    tienda               postgres    false    219       5008.dat �          0    73770 	   customers 
   TABLE DATA           z   COPY tienda.customers (document, first_name, middle_name, last_name, middle_last_name, phone_number, address) FROM stdin;
    tienda               postgres    false    218       5007.dat �          0    73798    departaments 
   TABLE DATA           <   COPY tienda.departaments (dpt_id, name, cty_id) FROM stdin;
    tienda               postgres    false    220       5009.dat �          0    74134    detail_orders 
   TABLE DATA           �   COPY tienda.detail_orders (odr_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal, discount_value) FROM stdin;
    tienda               postgres    false    238       5027.dat �          0    74078    detail_purchases 
   TABLE DATA           t   COPY tienda.detail_purchases (prc_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal) FROM stdin;
    tienda               postgres    false    235       5024.dat �          0    74109    orders 
   TABLE DATA           j   COPY tienda.orders (odr_id, order_date, total, document, stf_id, description, discount_value) FROM stdin;
    tienda               postgres    false    237       5026.dat �          0    73984    product_categories 
   TABLE DATA           K   COPY tienda.product_categories (pdt_ctg_id, name, description) FROM stdin;
    tienda               postgres    false    226       5015.dat �          0    73971    product_lot 
   TABLE DATA           B   COPY tienda.product_lot (pdt_lot_id, expiration_date) FROM stdin;
    tienda               postgres    false    224       5013.dat �          0    74021    products 
   TABLE DATA           x   COPY tienda.products (pdt_id, name, description, unit_price, stock, pdt_ctg_id, lot_pdt_id, pmn_id, ssn_id) FROM stdin;
    tienda               postgres    false    232       5021.dat �          0    73992 
   promotions 
   TABLE DATA           v   COPY tienda.promotions (pmn_id, start_date, finish_date, disccount, discount_value, state, discount_type) FROM stdin;
    tienda               postgres    false    228       5017.dat �          0    74055 	   purchases 
   TABLE DATA           [   COPY tienda.purchases (prc_id, purchase_date, total, nit, stf_id, description) FROM stdin;
    tienda               postgres    false    234       5023.dat �          0    74009    seasons 
   TABLE DATA           H   COPY tienda.seasons (ssn_id, name, start_date, finish_date) FROM stdin;
    tienda               postgres    false    230       5019.dat �          0    73949    staff 
   TABLE DATA           �   COPY tienda.staff (stf_id, first_name, middle_name, last_name, middle_last_name, phone_number, address, salary, mgr_id, type_worker, employee_number) FROM stdin;
    tienda               postgres    false    223       5012.dat �          0    73898 	   suppliers 
   TABLE DATA           {   COPY tienda.suppliers (nit, first_name, middle_name, last_name, phone_number, address, cyy_id, dpt_id, cty_id) FROM stdin;
    tienda               postgres    false    222       5011.dat �           0    0    orders_odr_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('tienda.orders_odr_id_seq', 1, false);
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
       tienda               postgres    false    240    238         �           2620    81963 #   detail_orders trg_calcular_subtotal    TRIGGER     �   CREATE TRIGGER trg_calcular_subtotal BEFORE INSERT OR UPDATE ON tienda.detail_orders FOR EACH ROW EXECUTE FUNCTION tienda.fn_calcular_subtotal();
 <   DROP TRIGGER trg_calcular_subtotal ON tienda.detail_orders;
       tienda               postgres    false    238    239         �           2606    73870    cities fk_cities_cty    FK CONSTRAINT     z   ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT fk_cities_cty FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);
 >   ALTER TABLE ONLY tienda.cities DROP CONSTRAINT fk_cities_cty;
       tienda               postgres    false    4809    219    221         �           2606    73865    cities fk_cities_dpt    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.cities
    ADD CONSTRAINT fk_cities_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES tienda.departaments(dpt_id, cty_id);
 >   ALTER TABLE ONLY tienda.cities DROP CONSTRAINT fk_cities_dpt;
       tienda               postgres    false    221    4811    221    220    220         �           2606    73806 $   departaments fk_departaments_country    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.departaments
    ADD CONSTRAINT fk_departaments_country FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);
 N   ALTER TABLE ONLY tienda.departaments DROP CONSTRAINT fk_departaments_country;
       tienda               postgres    false    220    4809    219         �           2606    74148    detail_orders fk_dtl_odr_orders    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT fk_dtl_odr_orders FOREIGN KEY (odr_id) REFERENCES tienda.orders(odr_id);
 I   ALTER TABLE ONLY tienda.detail_orders DROP CONSTRAINT fk_dtl_odr_orders;
       tienda               postgres    false    4837    238    237         �           2606    74153 !   detail_orders fk_dtl_odr_products    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_orders
    ADD CONSTRAINT fk_dtl_odr_products FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES tienda.products(pdt_id, pdt_ctg_id);
 K   ALTER TABLE ONLY tienda.detail_orders DROP CONSTRAINT fk_dtl_odr_products;
       tienda               postgres    false    238    232    232    4831    238         �           2606    74098 .   detail_purchases fk_dtl_prc_product_categories    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_product_categories FOREIGN KEY (ctg_pdt_id) REFERENCES tienda.product_categories(pdt_ctg_id);
 X   ALTER TABLE ONLY tienda.detail_purchases DROP CONSTRAINT fk_dtl_prc_product_categories;
       tienda               postgres    false    226    235    4825         �           2606    74103 $   detail_purchases fk_dtl_prc_products    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_products FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES tienda.products(pdt_id, pdt_ctg_id);
 N   ALTER TABLE ONLY tienda.detail_purchases DROP CONSTRAINT fk_dtl_prc_products;
       tienda               postgres    false    235    232    232    4831    235         �           2606    74093 %   detail_purchases fk_dtl_prc_purchases    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.detail_purchases
    ADD CONSTRAINT fk_dtl_prc_purchases FOREIGN KEY (prc_id) REFERENCES tienda.purchases(prc_id);
 O   ALTER TABLE ONLY tienda.detail_purchases DROP CONSTRAINT fk_dtl_prc_purchases;
       tienda               postgres    false    234    4833    235         �           2606    74121    orders fk_odr_customer    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT fk_odr_customer FOREIGN KEY (document) REFERENCES tienda.customers(document);
 @   ALTER TABLE ONLY tienda.orders DROP CONSTRAINT fk_odr_customer;
       tienda               postgres    false    237    4805    218         �           2606    74126    orders fk_odr_staff    FK CONSTRAINT     u   ALTER TABLE ONLY tienda.orders
    ADD CONSTRAINT fk_odr_staff FOREIGN KEY (stf_id) REFERENCES tienda.staff(stf_id);
 =   ALTER TABLE ONLY tienda.orders DROP CONSTRAINT fk_odr_staff;
       tienda               postgres    false    4819    237    223         �           2606    74034    products fk_products_ctg    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_ctg FOREIGN KEY (pdt_ctg_id) REFERENCES tienda.product_categories(pdt_ctg_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_ctg;
       tienda               postgres    false    226    4825    232         �           2606    74039    products fk_products_lot    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_lot FOREIGN KEY (lot_pdt_id) REFERENCES tienda.product_lot(pdt_lot_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_lot;
       tienda               postgres    false    224    232    4823         �           2606    74044    products fk_products_pmn    FK CONSTRAINT        ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_pmn FOREIGN KEY (pmn_id) REFERENCES tienda.promotions(pmn_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_pmn;
       tienda               postgres    false    228    232    4827         �           2606    74049    products fk_products_ssn    FK CONSTRAINT     |   ALTER TABLE ONLY tienda.products
    ADD CONSTRAINT fk_products_ssn FOREIGN KEY (ssn_id) REFERENCES tienda.seasons(ssn_id);
 B   ALTER TABLE ONLY tienda.products DROP CONSTRAINT fk_products_ssn;
       tienda               postgres    false    232    4829    230         �           2606    74073    purchases fk_purchases_staff    FK CONSTRAINT     ~   ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT fk_purchases_staff FOREIGN KEY (stf_id) REFERENCES tienda.staff(stf_id);
 F   ALTER TABLE ONLY tienda.purchases DROP CONSTRAINT fk_purchases_staff;
       tienda               postgres    false    234    223    4819         �           2606    74068    purchases fk_purchases_supplier    FK CONSTRAINT        ALTER TABLE ONLY tienda.purchases
    ADD CONSTRAINT fk_purchases_supplier FOREIGN KEY (nit) REFERENCES tienda.suppliers(nit);
 I   ALTER TABLE ONLY tienda.purchases DROP CONSTRAINT fk_purchases_supplier;
       tienda               postgres    false    4815    234    222         �           2606    73966    staff fk_staff_mgr    FK CONSTRAINT     t   ALTER TABLE ONLY tienda.staff
    ADD CONSTRAINT fk_staff_mgr FOREIGN KEY (mgr_id) REFERENCES tienda.staff(stf_id);
 <   ALTER TABLE ONLY tienda.staff DROP CONSTRAINT fk_staff_mgr;
       tienda               postgres    false    223    4819    223         �           2606    73913    suppliers fk_suppliers_city    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_city FOREIGN KEY (cyy_id, dpt_id, cty_id) REFERENCES tienda.cities(cyy_id, dpt_id, cty_id);
 E   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT fk_suppliers_city;
       tienda               postgres    false    221    221    4813    221    222    222    222         �           2606    73923    suppliers fk_suppliers_country    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_country FOREIGN KEY (cty_id) REFERENCES tienda.countries(cty_id);
 H   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT fk_suppliers_country;
       tienda               postgres    false    222    219    4809         �           2606    73918    suppliers fk_suppliers_dpt    FK CONSTRAINT     �   ALTER TABLE ONLY tienda.suppliers
    ADD CONSTRAINT fk_suppliers_dpt FOREIGN KEY (dpt_id, cty_id) REFERENCES tienda.departaments(dpt_id, cty_id);
 D   ALTER TABLE ONLY tienda.suppliers DROP CONSTRAINT fk_suppliers_dpt;
       tienda               postgres    false    222    220    220    4811    222                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      5010.dat                                                                                            0000600 0004000 0002000 00000057031 15015340177 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	MEDELLIN	5	170
2	ABEJORRAL	5	170
4	ABRIAQUI	5	170
21	ALEJANDRIA	5	170
30	AMAGA	5	170
31	AMALFI	5	170
34	ANDES	5	170
36	ANGELOPOLIS	5	170
38	ANGOSTURA	5	170
40	ANORI	5	170
42	ANTIOQUIA	5	170
44	ANZA	5	170
45	APARTADO	5	170
51	ARBOLETES	5	170
55	ARGELIA	5	170
59	ARMENIA	5	170
79	BARBOSA	5	170
86	BELMIRA	5	170
88	BELLO	5	170
91	BETANIA	5	170
93	BETULIA	5	170
101	BOLIVAR	5	170
107	BRICEÑO	5	170
113	BURITICA	5	170
120	CACERES	5	170
125	CAICEDO	5	170
129	CALDAS	5	170
134	CAMPAMENTO	5	170
138	CAÑASGORDAS	5	170
142	CARACOLI	5	170
145	CARAMANTA	5	170
147	CAREPA	5	170
148	CARMEN DE VIBORAL	5	170
150	CAROLINA	5	170
154	CAUCASIA	5	170
172	CHIGORODO	5	170
190	CISNEROS	5	170
197	COCORNA	5	170
206	CONCEPCION	5	170
209	CONCORDIA	5	170
212	COPACABANA	5	170
234	DABEIBA	5	170
237	DON MATIAS	5	170
240	EBEJICO	5	170
250	EL BAGRE	5	170
264	ENTRERRIOS	5	170
266	ENVIGADO	5	170
282	FREDONIA	5	170
284	FRONTINO	5	170
306	GIRALDO	5	170
308	GIRARDOTA	5	170
310	GOMEZ PLATA	5	170
313	GRANADA	5	170
315	GUADALUPE	5	170
318	GUARNE	5	170
321	GUATAPE	5	170
347	HELICONIA	5	170
353	HISPANIA	5	170
360	ITAGUI	5	170
361	ITUANGO	5	170
364	JARDIN	5	170
368	JERICO	5	170
376	LA CEJA	5	170
380	LA ESTRELLA	5	170
390	LA PINTADA	5	170
400	LA UNION	5	170
411	LIBORINA	5	170
425	MACEO	5	170
440	MARINILLA	5	170
467	MONTEBELLO	5	170
475	MURINDO	5	170
480	MUTATA	5	170
483	NARIÑO	5	170
490	NECOCLI	5	170
495	NECHI	5	170
501	OLAYA	5	170
541	PEÑOL	5	170
543	PEQUE	5	170
576	PUEBLORRICO	5	170
579	PUERTO BERRIO	5	170
585	PUERTO NARE (LA\nMAGDALENA)	5	170
591	PUERTO TRIUNFO	5	170
604	REMEDIOS	5	170
607	RETIRO	5	170
615	RIONEGRO	5	170
628	SABANALARGA	5	170
631	SABANETA	5	170
642	SALGAR	5	170
647	SAN ANDRES	5	170
649	SAN CARLOS	5	170
652	SAN FRANCISCO	5	170
656	SAN JERONIMO	5	170
658	SAN JOSE DE LA MONTAÑA	5	170
659	SAN JUAN DE URABA	5	170
660	SAN LUIS	5	170
664	SAN PEDRO	5	170
665	SAN PEDRO DE URABA	5	170
667	SAN RAFAEL	5	170
670	SAN ROQUE	5	170
674	SAN VICENTE	5	170
679	SANTA BARBARA	5	170
686	SANTA ROSA DE OSOS	5	170
690	SANTO DOMINGO	5	170
697	SANTUARIO	5	170
736	SEGOVIA	5	170
756	SONSON	5	170
761	SOPETRAN	5	170
789	TAMESIS	5	170
790	TARAZA	5	170
792	TARSO	5	170
809	TITIRIBI	5	170
819	TOLEDO	5	170
837	TURBO	5	170
842	URAMITA	5	170
847	URRAO	5	170
854	VALDIVIA	5	170
856	VALPARAISO	5	170
858	VEGACHI	5	170
861	VENECIA	5	170
873	VIGIA DEL FUERTE	5	170
885	YALI	5	170
887	YARUMAL	5	170
890	YOLOMBO	5	170
893	YONDO	5	170
895	ZARAGOZA	5	170
1	BARRANQUILLA	8	170
78	BARANOA	8	170
137	CAMPO DE LA CRUZ	8	170
141	CANDELARIA	8	170
296	GALAPA	8	170
372	JUAN DE ACOSTA	8	170
421	LURUACO	8	170
433	MALAMBO	8	170
436	MANATI	8	170
520	PALMAR DE VARELA	8	170
549	PIOJO	8	170
558	POLO NUEVO	8	170
560	PONEDERA	8	170
573	PUERTO COLOMBIA	8	170
606	REPELON	8	170
634	SABANAGRANDE	8	170
638	SABANALARGA	8	170
675	SANTA LUCIA	8	170
685	SANTO TOMAS	8	170
758	SOLEDAD	8	170
770	SUAN	8	170
832	TUBARA	8	170
849	USIACURI	8	170
1	SANTAFE DE BOGOTA D.C.-\nUSAQUEN	11	170
2	SANTAFE DE BOGOTA D.C.-\nCHAPINERO	11	170
3	SANTAFE DE BOGOTA D.C.-\nSANTA FE	11	170
4	SANTAFE DE BOGOTA D.C.-\nSAN CRISTOBAL	11	170
5	SANTAFE DE BOGOTA D.C.-\nUSME	11	170
6	SANTAFE DE BOGOTA D.C.-\nTUNJUELITO	11	170
7	SANTAFE DE BOGOTA D.C.-\nBOSA	11	170
8	SANTAFE DE BOGOTA D.C.-\nKENNEDY	11	170
9	SANTAFE DE BOGOTA D.C.-\nFONTIBON	11	170
10	SANTAFE DE BOGOTA D.C.-\nENGATIVA	11	170
11	SANTAFE DE BOGOTA D.C.-\nSUBA	11	170
12	SANTAFE DE BOGOTA D.C.-\nBARRIOS UNIDOS	11	170
13	SANTAFE DE BOGOTA D.C.-\nTEUSAQUILLO	11	170
14	SANTAFE DE BOGOTA D.C.-\nMARTIRES	11	170
15	SANTAFE DE BOGOTA D.C.-\nANTONIO NARIÑO	11	170
16	SANTAFE DE BOGOTA D.C.-\nPUENTE ARANDA	11	170
17	SANTAFE DE BOGOTA D.C.-\nCANDELARIA	11	170
18	SANTAFE DE BOGOTA D.C.-\nRAFAEL URIBE	11	170
19	SANTAFE DE BOGOTA D.C.-\nCIUDAD BOLIVAR	11	170
20	SANTAFE DE BOGOTA D.C.-\nSUMAPAZ	11	170
1	CARTAGENA (DISTRITO TURISTICO Y CULTURAL DE\nCARTAGENA)	13	170
6	ACHI	13	170
30	ALTOS DEL ROSARIO	13	170
42	ARENAL	13	170
52	ARJONA	13	170
62	ARROYOHONDO	13	170
74	BARRANCO DE LOBA	13	170
140	CALAMAR	13	170
160	CANTAGALLO	13	170
188	CICUCO	13	170
212	CORDOBA	13	170
222	CLEMENCIA	13	170
244	EL CARMEN DE BOLIVAR	13	170
248	EL GUAMO	13	170
268	EL PEÑON	13	170
300	HATILLO DE LOBA	13	170
430	MAGANGUE	13	170
433	MAHATES	13	170
440	MARGARITA	13	170
442	MARIA LA BAJA	13	170
458	MONTECRISTO	13	170
468	MOMPOS	13	170
473	MORALES	13	170
549	PINILLOS	13	170
580	REGIDOR	13	170
600	RIO VIEJO	13	170
620	SAN CRISTOBAL	13	170
647	SAN ESTANISLAO	13	170
650	SAN FERNANDO	13	170
654	SAN JACINTO	13	170
655	SAN JACINTO DEL CAUCA	13	170
657	SAN JUAN NEPOMUCENO	13	170
667	SAN MARTIN DE LOBA	13	170
670	SAN PABLO	13	170
673	SANTA CATALINA	13	170
683	SANTA ROSA	13	170
688	SANTA ROSA DEL SUR	13	170
744	SIMITI	13	170
760	SOPLAVIENTO	13	170
780	TALAIGUA NUEVO	13	170
810	TIQUISIO (PUERTO RICO)	13	170
836	TURBACO	13	170
838	TURBANA	13	170
873	VILLANUEVA	13	170
894	ZAMBRANO	13	170
1	TUNJA	15	170
22	ALMEIDA	15	170
47	AQUITANIA	15	170
51	ARCABUCO	15	170
87	BELEN	15	170
90	BERBEO	15	170
92	BETEITIVA	15	170
97	BOAVITA	15	170
104	BOYACA	15	170
106	BRICEÑO	15	170
109	BUENAVISTA	15	170
114	BUSBANZA	15	170
131	CALDAS	15	170
135	CAMPOHERMOSO	15	170
162	CERINZA	15	170
172	CHINAVITA	15	170
176	CHIQUINQUIRA	15	170
180	CHISCAS	15	170
183	CHITA	15	170
185	CHITARAQUE	15	170
187	CHIVATA	15	170
189	CIENEGA	15	170
204	COMBITA	15	170
212	COPER	15	170
215	CORRALES	15	170
218	COVARACHIA	15	170
223	CUBARA	15	170
224	CUCAITA	15	170
226	CUITIVA	15	170
232	CHIQUIZA	15	170
236	CHIVOR	15	170
238	DUITAMA	15	170
244	EL COCUY	15	170
248	EL ESPINO	15	170
272	FIRAVITOBA	15	170
276	FLORESTA	15	170
293	GACHANTIVA	15	170
296	GAMEZA	15	170
299	GARAGOA	15	170
317	GUACAMAYAS	15	170
322	GUATEQUE	15	170
325	GUAYATA	15	170
332	GUICAN	15	170
362	IZA	15	170
367	JENESANO	15	170
368	JERICO	15	170
377	LABRANZAGRANDE	15	170
380	LA CAPILLA	15	170
401	LA VICTORIA	15	170
403	LA UVITA	15	170
407	VILLA DE LEIVA	15	170
425	MACANAL	15	170
442	MARIPI	15	170
455	MIRAFLORES	15	170
464	MONGUA	15	170
466	MONGUI	15	170
469	MONIQUIRA	15	170
476	MOTAVITA	15	170
480	MUZO	15	170
491	NOBSA	15	170
494	NUEVO COLON	15	170
500	OICATA	15	170
507	OTANCHE	15	170
511	PACHAVITA	15	170
514	PAEZ	15	170
516	PAIPA	15	170
518	PAJARITO	15	170
522	PANQUEBA	15	170
531	PAUNA	15	170
533	PAYA	15	170
537	PAZ DEL RIO	15	170
542	PESCA	15	170
550	PISBA	15	170
572	PUERTO BOYACA	15	170
580	QUIPAMA	15	170
599	RAMIRIQUI	15	170
600	RAQUIRA	15	170
621	RONDON	15	170
632	SABOYA	15	170
638	SACHICA	15	170
646	SAMACA	15	170
660	SAN EDUARDO	15	170
664	SAN JOSE DE PARE	15	170
667	SAN LUIS DE GACENO	15	170
673	SAN MATEO	15	170
676	SAN MIGUEL DE SEMA	15	170
681	SAN PABLO DE BORBUR	15	170
686	SANTANA	15	170
690	SANTA MARIA	15	170
693	SANTA ROSA DE VITERBO	15	170
696	SANTA SOFIA	15	170
720	SATIVANORTE	15	170
723	SATIVASUR	15	170
740	SIACHOQUE	15	170
753	SOATA	15	170
755	SOCOTA	15	170
757	SOCHA	15	170
759	SOGAMOSO	15	170
761	SOMONDOCO	15	170
762	SORA	15	170
763	SOTAQUIRA	15	170
764	SORACA	15	170
774	SUSACON	15	170
776	SUTAMARCHAN	15	170
778	SUTATENZA	15	170
790	TASCO	15	170
798	TENZA	15	170
804	TIBANA	15	170
806	TIBASOSA	15	170
808	TINJACA	15	170
810	TIPACOQUE	15	170
814	TOCA	15	170
816	TOGUI	15	170
820	TOPAGA	15	170
822	TOTA	15	170
832	TUNUNGUA	15	170
835	TURMEQUE	15	170
837	TUTA	15	170
839	TUTASA	15	170
842	UMBITA	15	170
861	VENTAQUEMADA	15	170
879	VIRACACHA	15	170
897	ZETAQUIRA	15	170
1	MANIZALES	17	170
13	AGUADAS	17	170
42	ANSERMA	17	170
50	ARANZAZU	17	170
88	BELALCAZAR	17	170
174	CHINCHINA	17	170
272	FILADELFIA	17	170
380	LA DORADA	17	170
388	LA MERCED	17	170
433	MANZANARES	17	170
442	MARMATO	17	170
444	MARQUETALIA	17	170
446	MARULANDA	17	170
486	NEIRA	17	170
495	NORCASIA	17	170
513	PACORA	17	170
524	PALESTINA	17	170
541	PENSILVANIA	17	170
614	RIOSUCIO	17	170
616	RISARALDA	17	170
653	SALAMINA	17	170
662	SAMANA	17	170
665	SAN JOSE	17	170
777	SUPIA	17	170
867	VICTORIA	17	170
873	VILLAMARIA	17	170
877	VITERBO	17	170
1	FLORENCIA	18	170
29	ALBANIA	18	170
94	BELEN DE LOS ANDAQUIES	18	170
150	CARTAGENA DEL CHAIRA	18	170
205	CURILLO	18	170
247	EL DONCELLO	18	170
256	EL PAUJIL	18	170
410	LA MONTAÑITA	18	170
460	MILAN	18	170
479	MORELIA	18	170
592	PUERTO RICO	18	170
610	SAN JOSE DE FRAGUA	18	170
753	SAN  VICENTE DEL CAGUAN	18	170
756	SOLANO	18	170
785	SOLITA	18	170
860	VALPARAISO	18	170
1	POPAYAN	19	170
22	ALMAGUER	19	170
50	ARGELIA	19	170
75	BALBOA	19	170
100	BOLIVAR	19	170
110	BUENOS AIRES	19	170
130	CAJIBIO	19	170
137	CALDONO	19	170
142	CALOTO	19	170
212	CORINTO	19	170
256	EL TAMBO	19	170
290	FLORENCIA	19	170
318	GUAPI	19	170
355	INZA	19	170
364	JAMBALO	19	170
392	LA SIERRA	19	170
397	LA VEGA	19	170
418	LOPEZ (MICAY)	19	170
450	MERCADERES	19	170
455	MIRANDA	19	170
473	MORALES	19	170
513	PADILLA	19	170
517	PAEZ (BELALCAZAR)	19	170
532	PATIA (EL BORDO)	19	170
533	PIAMONTE	19	170
548	PIENDAMO	19	170
573	PUERTO TEJADA	19	170
585	PURACE (COCONUCO)	19	170
622	ROSAS	19	170
693	SAN SEBASTIAN	19	170
698	SANTANDER DE QUILICHAO	19	170
701	SANTA ROSA	19	170
743	SILVIA	19	170
760	SOTARA (PAISPAMBA)	19	170
780	SUAREZ	19	170
807	TIMBIO	19	170
809	TIMBIQUI	19	170
821	TORIBIO	19	170
824	TOTORO	19	170
845	VILLARICA	19	170
1	VALLEDUPAR	20	170
11	AGUACHICA	20	170
13	AGUSTIN CODAZZI	20	170
32	ASTREA	20	170
45	BECERRIL	20	170
60	BOSCONIA	20	170
175	CHIMICHAGUA	20	170
178	CHIRIGUANA	20	170
228	CURUMANI	20	170
238	EL COPEY	20	170
250	EL PASO	20	170
295	GAMARRA	20	170
310	GONZALEZ	20	170
383	LA GLORIA	20	170
400	LA JAGUA IBIRICO	20	170
443	MANAURE (BALCON DEL\nCESAR)	20	170
517	PAILITAS	20	170
550	PELAYA	20	170
570	PUEBLO BELLO	20	170
614	RIO DE ORO	20	170
621	LA PAZ (ROBLES)	20	170
710	SAN ALBERTO	20	170
750	SAN DIEGO	20	170
770	SAN MARTIN	20	170
787	TAMALAMEQUE	20	170
1	MONTERIA	23	170
68	AYAPEL	23	170
79	BUENAVISTA	23	170
90	CANALETE	23	170
162	CERETE	23	170
168	CHIMA	23	170
182	CHINU	23	170
189	CIENAGA DE ORO	23	170
300	COTORRA	23	170
350	LA APARTADA	23	170
417	LORICA	23	170
419	LOS CORDOBAS	23	170
464	MOMIL	23	170
466	MONTELIBANO	23	170
500	MOÑITOS	23	170
555	PLANETA RICA	23	170
570	PUEBLO NUEVO	23	170
574	PUERTO ESCONDIDO	23	170
580	PUERTO LIBERTADOR	23	170
586	PURISIMA	23	170
660	SAHAGUN	23	170
670	SAN ANDRES SOTAVENTO	23	170
672	SAN ANTERO	23	170
675	SAN BERNARDO DEL\nVIENTO	23	170
678	SAN CARLOS	23	170
686	SAN PELAYO	23	170
807	TIERRALTA	23	170
855	VALENCIA	23	170
1	AGUA DE DIOS	25	170
19	ALBAN	25	170
35	ANAPOIMA	25	170
40	ANOLAIMA	25	170
53	ARBELAEZ	25	170
86	BELTRAN	25	170
95	BITUIMA	25	170
99	BOJACA	25	170
120	CABRERA	25	170
123	CACHIPAY	25	170
126	CAJICA	25	170
148	CAPARRAPI	25	170
151	CAQUEZA	25	170
154	CARMEN DE CARUPA	25	170
168	CHAGUANI	25	170
175	CHIA	25	170
178	CHIPAQUE	25	170
181	CHOACHI	25	170
183	CHOCONTA	25	170
200	COGUA	25	170
214	COTA	25	170
224	CUCUNUBA	25	170
245	EL COLEGIO	25	170
258	EL PEÑON	25	170
260	EL ROSAL	25	170
269	FACATATIVA	25	170
279	FOMEQUE	25	170
281	FOSCA	25	170
286	FUNZA	25	170
288	FUQUENE	25	170
290	FUSAGASUGA	25	170
293	GACHALA	25	170
295	GACHANCIPA	25	170
297	GACHETA	25	170
299	GAMA	25	170
307	GIRARDOT	25	170
312	GRANADA	25	170
317	GUACHETA	25	170
320	GUADUAS	25	170
322	GUASCA	25	170
324	GUATAQUI	25	170
326	GUATAVITA	25	170
328	GUAYABAL DE SIQUIMA	25	170
335	GUAYABETAL	25	170
339	GUTIERREZ	25	170
368	JERUSALEN	25	170
372	JUNIN	25	170
377	LA CALERA	25	170
386	LA MESA	25	170
394	LA PALMA	25	170
398	LA PEÑA	25	170
402	LA VEGA	25	170
407	LENGUAZAQUE	25	170
426	MACHETA	25	170
430	MADRID	25	170
436	MANTA	25	170
438	MEDINA	25	170
473	MOSQUERA	25	170
483	NARIÑO	25	170
486	NEMOCON	25	170
488	NILO	25	170
489	NIMAIMA	25	170
491	NOCAIMA	25	170
506	VENECIA (OSPINA PEREZ)	25	170
513	PACHO	25	170
518	PAIME	25	170
524	PANDI	25	170
530	PARATEBUENO	25	170
535	PASCA	25	170
572	PUERTO SALGAR	25	170
580	PULI	25	170
592	QUEBRADANEGRA	25	170
594	QUETAME	25	170
596	QUIPILE	25	170
599	APULO (RAFAEL REYES)	25	170
612	RICAURTE	25	170
645	SAN  ANTONIO DEL\nTEQUENDAMA	25	170
649	SAN BERNARDO	25	170
653	SAN CAYETANO	25	170
658	SAN FRANCISCO	25	170
662	SAN JUAN DE RIOSECO	25	170
718	SASAIMA	25	170
736	SESQUILE	25	170
740	SIBATE	25	170
743	SILVANIA	25	170
745	SIMIJACA	25	170
754	SOACHA	25	170
758	SOPO	25	170
769	SUBACHOQUE	25	170
772	SUESCA	25	170
777	SUPATA	25	170
779	SUSA	25	170
781	SUTATAUSA	25	170
785	TABIO	25	170
793	TAUSA	25	170
797	TENA	25	170
799	TENJO	25	170
805	TIBACUY	25	170
807	TIBIRITA	25	170
815	TOCAIMA	25	170
817	TOCANCIPA	25	170
823	TOPAIPI	25	170
839	UBALA	25	170
841	UBAQUE	25	170
843	UBATE	25	170
845	UNE	25	170
851	UTICA	25	170
862	VERGARA	25	170
867	VIANI	25	170
871	VILLAGOMEZ	25	170
873	VILLAPINZON	25	170
875	VILLETA	25	170
878	VIOTA	25	170
885	YACOPI	25	170
898	ZIPACON	25	170
899	ZIPAQUIRA	25	170
1	QUIBDO (SAN FRANCISCO\nDE QUIBDO)	27	170
6	ACANDI	27	170
25	ALTO BAUDO (PIE DE PATO)	27	170
50	ATRATO	27	170
73	BAGADO	27	170
75	BAHIA SOLANO (MUTIS)	27	170
77	BAJO BAUDO (PIZARRO)	27	170
99	BOJAYA (BELLAVISTA)	27	170
135	CANTON DE SAN PABLO\n(MANAGRU)	27	170
205	CONDOTO	27	170
245	EL CARMEN DE ATRATO	27	170
250	LITORAL DEL BAJO SAN JUAN (SANTA GENOVEVA DE\nDOCORDO)	27	170
361	ISTMINA	27	170
372	JURADO	27	170
413	LLORO	27	170
425	MEDIO ATRATO	27	170
430	MEDIO BAUDO	27	170
491	NOVITA	27	170
495	NUQUI	27	170
600	RIOQUITO	27	170
615	RIOSUCIO	27	170
660	SAN JOSE DEL PALMAR	27	170
745	SIPI	27	170
787	TADO	27	170
800	UNGUIA	27	170
810	UNION PANAMERICANA	27	170
1	NEIVA	41	170
6	ACEVEDO	41	170
13	AGRADO	41	170
16	AIPE	41	170
20	ALGECIRAS	41	170
26	ALTAMIRA	41	170
78	BARAYA	41	170
132	CAMPOALEGRE	41	170
206	COLOMBIA	41	170
244	ELIAS	41	170
298	GARZON	41	170
306	GIGANTE	41	170
319	GUADALUPE	41	170
349	HOBO	41	170
357	IQUIRA	41	170
359	ISNOS (SAN JOSE DE ISNOS)	41	170
378	LA ARGENTINA	41	170
396	LA PLATA	41	170
483	NATAGA	41	170
503	OPORAPA	41	170
518	PAICOL	41	170
524	PALERMO	41	170
530	PALESTINA	41	170
548	PITAL	41	170
551	PITALITO	41	170
615	RIVERA	41	170
660	SALADOBLANCO	41	170
668	SAN AGUSTIN	41	170
676	SANTA MARIA	41	170
770	SUAZA	41	170
791	TARQUI	41	170
797	TESALIA	41	170
799	TELLO	41	170
801	TERUEL	41	170
807	TIMANA	41	170
872	VILLAVIEJA	41	170
885	YAGUARA	41	170
1	RIOHACHA	44	170
78	BARRANCAS	44	170
90	DIBULLA	44	170
98	DISTRACCION	44	170
110	EL MOLINO	44	170
279	FONSECA	44	170
378	HATONUEVO	44	170
420	LA JAGUA DEL PILAR	44	170
430	MAICAO	44	170
560	MANAURE	44	170
650	SAN JUAN DEL CESAR	44	170
847	URIBIA	44	170
855	URUMITA	44	170
874	VILLANUEVA	44	170
1	SANTA MARTA	47	170
30	ALGARROBO	47	170
53	ARACATACA	47	170
58	ARIGUANI (EL DIFICIL)	47	170
161	CERRO SAN ANTONIO	47	170
170	CHIVOLO	47	170
189	CIENAGA	47	170
205	CONCORDIA	47	170
245	EL BANCO	47	170
258	EL PIÑON	47	170
268	EL RETEN	47	170
288	FUNDACION	47	170
318	GUAMAL	47	170
541	PEDRAZA	47	170
545	PIJIÑO DEL CARMEN\n(PIJIÑO)	47	170
551	PIVIJAY	47	170
555	PLATO	47	170
570	PUEBLOVIEJO	47	170
605	REMOLINO	47	170
660	SABANAS DE SAN ANGEL	47	170
675	SALAMINA	47	170
692	SAN SEBASTIAN DE\nBUENAVISTA	47	170
703	SAN ZENON	47	170
707	SANTA ANA	47	170
745	SITIONUEVO	47	170
798	TENERIFE	47	170
1	VILLAVICENCIO	50	170
6	ACACIAS	50	170
110	BARRANCA DE UPIA	50	170
124	CABUYARO	50	170
150	CASTILLA LA NUEVA	50	170
223	SAN LUIS DE CUBARRAL	50	170
226	CUMARAL	50	170
245	EL CALVARIO	50	170
251	EL CASTILLO	50	170
270	EL DORADO	50	170
287	FUENTE DE ORO	50	170
313	GRANADA	50	170
318	GUAMAL	50	170
325	MAPIRIPAN	50	170
330	MESETAS	50	170
350	LA MACARENA	50	170
370	LA URIBE	50	170
400	LEJANIAS	50	170
450	PUERTO CONCORDIA	50	170
568	PUERTO GAITAN	50	170
573	PUERTO LOPEZ	50	170
577	PUERTO LLERAS	50	170
590	PUERTO RICO	50	170
606	RESTREPO	50	170
680	SAN CARLOS DE GUAROA	50	170
683	SAN  JUAN DE ARAMA	50	170
686	SAN JUANITO	50	170
689	SAN MARTIN	50	170
711	VISTAHERMOSA	50	170
1	PASTO (SAN JUAN DE\nPASTO)	52	170
19	ALBAN (SAN JOSE)	52	170
22	ALDANA	52	170
36	ANCUYA	52	170
51	ARBOLEDA (BERRUECOS)	52	170
79	BARBACOAS	52	170
83	BELEN	52	170
110	BUESACO	52	170
203	COLON (GENOVA)	52	170
207	CONSACA	52	170
210	CONTADERO	52	170
215	CORDOBA	52	170
224	CUASPUD (CARLOSAMA)	52	170
227	CUMBAL	52	170
233	CUMBITARA	52	170
240	CHACHAGUI	52	170
250	EL CHARCO	52	170
254	EL PEÑOL	52	170
256	EL ROSARIO	52	170
258	EL TABLON	52	170
260	EL TAMBO	52	170
287	FUNES	52	170
317	GUACHUCAL	52	170
320	GUAITARILLA	52	170
323	GUALMATAN	52	170
352	ILES	52	170
354	IMUES	52	170
356	IPIALES	52	170
378	LA CRUZ	52	170
381	LA FLORIDA	52	170
385	LA LLANADA	52	170
390	LA TOLA	52	170
399	LA UNION	52	170
405	LEIVA	52	170
411	LINARES	52	170
418	LOS ANDES (SOTOMAYOR)	52	170
427	MAGUI (PAYAN)	52	170
435	MALLAMA (PIEDRANCHA)	52	170
473	MOSQUERA	52	170
490	OLAYA HERRERA (BOCAS\nDE SATINGA)	52	170
506	OSPINA	52	170
520	FRANCISCO PIZARRO\n(SALAHONDA)	52	170
540	POLICARPA	52	170
560	POTOSI	52	170
565	PROVIDENCIA	52	170
573	PUERRES	52	170
585	PUPIALES	52	170
612	RICAURTE	52	170
621	ROBERTO PAYAN (SAN\nJOSE)	52	170
678	SAMANIEGO	52	170
683	SANDONA	52	170
685	SAN BERNARDO	52	170
687	SAN LORENZO	52	170
693	SAN PABLO	52	170
694	SAN PEDRO DE CARTAGO	52	170
696	SANTA BARBARA\n(ISCUANDE)	52	170
699	SANTA CRUZ (GUACHAVES)	52	170
720	SAPUYES	52	170
786	TAMINANGO	52	170
788	TANGUA	52	170
835	TUMACO	52	170
838	TUQUERRES	52	170
885	YACUANQUER	52	170
1	CUCUTA	54	170
3	ABREGO	54	170
51	ARBOLEDAS	54	170
99	BOCHALEMA	54	170
109	BUCARASICA	54	170
125	CACOTA	54	170
128	CACHIRA	54	170
172	CHINACOTA	54	170
174	CHITAGA	54	170
206	CONVENCION	54	170
223	CUCUTILLA	54	170
239	DURANIA	54	170
245	EL CARMEN	54	170
250	EL TARRA	54	170
261	EL ZULIA	54	170
313	GRAMALOTE	54	170
344	HACARI	54	170
347	HERRAN	54	170
377	LABATECA	54	170
385	LA ESPERANZA	54	170
398	LA PLAYA	54	170
405	LOS PATIOS	54	170
418	LOURDES	54	170
480	MUTISCUA	54	170
498	OCAÑA	54	170
518	PAMPLONA	54	170
520	PAMPLONITA	54	170
553	PUERTO SANTANDER	54	170
599	RAGONVALIA	54	170
660	SALAZAR	54	170
670	SAN CALIXTO	54	170
673	SAN CAYETANO	54	170
680	SANTIAGO	54	170
720	SARDINATA	54	170
743	SILOS	54	170
800	TEORAMA	54	170
810	TIBU	54	170
820	TOLEDO	54	170
871	VILLACARO	54	170
874	VILLA DEL ROSARIO	54	170
1	ARMENIA	63	170
111	BUENAVISTA	63	170
130	CALARCA	63	170
190	CIRCASIA	63	170
212	CORDOBA	63	170
272	FILANDIA	63	170
302	GENOVA	63	170
401	LA TEBAIDA	63	170
470	MONTENEGRO	63	170
548	PIJAO	63	170
594	QUIMBAYA	63	170
690	SALENTO	63	170
1	PEREIRA	66	170
45	APIA	66	170
75	BALBOA	66	170
88	BELEN DE UMBRIA	66	170
170	DOS QUEBRADAS	66	170
318	GUATICA	66	170
383	LA CELIA	66	170
400	LA VIRGINIA	66	170
440	MARSELLA	66	170
456	MISTRATO	66	170
572	PUEBLO RICO	66	170
594	QUINCHIA	66	170
682	SANTA ROSA DE CABAL	66	170
687	SANTUARIO	66	170
1	BUCARAMANGA	68	170
13	AGUADA	68	170
20	ALBANIA	68	170
51	ARATOCA	68	170
77	BARBOSA	68	170
79	BARICHARA	68	170
81	BARRANCABERMEJA	68	170
92	BETULIA	68	170
101	BOLIVAR	68	170
121	CABRERA	68	170
132	CALIFORNIA	68	170
147	CAPITANEJO	68	170
152	CARCASI	68	170
160	CEPITA	68	170
162	CERRITO	68	170
167	CHARALA	68	170
169	CHARTA	68	170
176	CHIMA	68	170
179	CHIPATA	68	170
190	CIMITARRA	68	170
207	CONCEPCION	68	170
209	CONFINES	68	170
211	CONTRATACION	68	170
217	COROMORO	68	170
229	CURITI	68	170
235	EL CARMEN DE CHUCURY	68	170
245	EL GUACAMAYO	68	170
250	EL PEÑON	68	170
255	EL PLAYON	68	170
264	ENCINO	68	170
266	ENCISO	68	170
271	FLORIAN	68	170
276	FLORIDABLANCA	68	170
296	GALAN	68	170
298	GAMBITA	68	170
307	GIRON	68	170
318	GUACA	68	170
320	GUADALUPE	68	170
322	GUAPOTA	68	170
324	GUAVATA	68	170
327	GUEPSA	68	170
344	HATO	68	170
368	JESUS MARIA	68	170
370	JORDAN	68	170
377	LA BELLEZA	68	170
385	LANDAZURI	68	170
397	LA PAZ	68	170
406	LEBRIJA	68	170
418	LOS SANTOS	68	170
425	MACARAVITA	68	170
432	MALAGA	68	170
444	MATANZA	68	170
464	MOGOTES	68	170
468	MOLAGAVITA	68	170
498	OCAMONTE	68	170
500	OIBA	68	170
502	ONZAGA	68	170
522	PALMAR	68	170
524	PALMAS DEL SOCORRO	68	170
533	PARAMO	68	170
547	PIEDECUESTA	68	170
549	PINCHOTE	68	170
572	PUENTE NACIONAL	68	170
573	PUERTO PARRA	68	170
575	PUERTO WILCHES	68	170
615	RIONEGRO	68	170
655	SABANA DE TORRES	68	170
669	SAN ANDRES	68	170
673	SAN BENITO	68	170
679	SAN GIL	68	170
682	SAN JOAQUIN	68	170
684	SAN JOSE DE MIRANDA	68	170
686	SAN MIGUEL	68	170
689	SAN VICENTE DE CHUCURI	68	170
705	SANTA BARBARA	68	170
720	SANTA HELENA DEL OPON	68	170
745	SIMACOTA	68	170
755	SOCORRO	68	170
770	SUAITA	68	170
773	SUCRE	68	170
780	SURATA	68	170
820	TONA	68	170
855	VALLE SAN JOSE	68	170
861	VELEZ	68	170
867	VETAS	68	170
872	VILLANUEVA	68	170
895	ZAPATOCA	68	170
1	SINCELEJO	70	170
110	BUENAVISTA	70	170
124	CAIMITO	70	170
204	COLOSO (RICAURTE)	70	170
215	COROZAL	70	170
230	CHALAN	70	170
235	GALERAS (NUEVA\nGRANADA)	70	170
265	GUARANDA	70	170
400	LA UNION	70	170
418	LOS PALMITOS	70	170
429	MAJAGUAL	70	170
473	MORROA	70	170
508	OVEJAS	70	170
523	PALMITO	70	170
670	SAMPUES	70	170
678	SAN BENITO ABAD	70	170
702	SAN JUAN DE BETULIA	70	170
708	SAN MARCOS	70	170
713	SAN ONOFRE	70	170
717	SAN PEDRO	70	170
742	SINCE	70	170
771	SUCRE	70	170
820	TOLU	70	170
823	TOLUVIEJO	70	170
1	IBAGUE	73	170
24	ALPUJARRA	73	170
26	ALVARADO	73	170
30	AMBALEMA	73	170
43	ANZOATEGUI	73	170
55	ARMERO (GUAYABAL)	73	170
67	ATACO	73	170
124	CAJAMARCA	73	170
148	CARMEN APICALA	73	170
152	CASABIANCA	73	170
168	CHAPARRAL	73	170
200	COELLO	73	170
217	COYAIMA	73	170
226	CUNDAY	73	170
236	DOLORES	73	170
268	ESPINAL	73	170
270	FALAN	73	170
275	FLANDES	73	170
283	FRESNO	73	170
319	GUAMO	73	170
347	HERVEO	73	170
349	HONDA	73	170
352	ICONONZO	73	170
408	LERIDA	73	170
411	LIBANO	73	170
443	MARIQUITA	73	170
449	MELGAR	73	170
461	MURILLO	73	170
483	NATAGAIMA	73	170
504	ORTEGA	73	170
520	PALOCABILDO	73	170
547	PIEDRAS	73	170
555	PLANADAS	73	170
563	PRADO	73	170
585	PURIFICACION	73	170
616	RIOBLANCO	73	170
622	RONCESVALLES	73	170
624	ROVIRA	73	170
671	SALDAÑA	73	170
675	SAN ANTONIO	73	170
678	SAN LUIS	73	170
686	SANTA ISABEL	73	170
770	SUAREZ	73	170
854	VALLE DE SAN JUAN	73	170
861	VENADILLO	73	170
870	VILLAHERMOSA	73	170
873	VILLARRICA	73	170
1	CALI (SANTIAGO DE CALI)	76	170
20	ALCALA	76	170
36	ANDALUCIA	76	170
41	ANSERMANUEVO	76	170
54	ARGELIA	76	170
100	BOLIVAR	76	170
109	BUENAVENTURA	76	170
111	BUGA	76	170
113	BUGALAGRANDE	76	170
122	CAICEDONIA	76	170
126	CALIMA (DARIEN)	76	170
130	CANDELARIA	76	170
147	CARTAGO	76	170
233	DAGUA	76	170
243	EL AGUILA	76	170
246	EL CAIRO	76	170
248	EL CERRITO	76	170
250	EL DOVIO	76	170
275	FLORIDA	76	170
306	GINEBRA	76	170
318	GUACARI	76	170
364	JAMUNDI	76	170
377	LA CUMBRE	76	170
400	LA UNION	76	170
403	LA VICTORIA	76	170
497	OBANDO	76	170
520	PALMIRA	76	170
563	PRADERA	76	170
606	RESTREPO	76	170
616	RIOFRIO	76	170
622	ROLDANILLO	76	170
670	SAN PEDRO	76	170
736	SEVILLA	76	170
823	TORO	76	170
828	TRUJILLO	76	170
834	TULUA	76	170
845	ULLOA	76	170
863	VERSALLES	76	170
869	VIJES	76	170
890	YOTOCO	76	170
892	YUMBO	76	170
895	ZARZAL	76	170
1	ARAUCA	81	170
65	ARAUQUITA	81	170
220	CRAVO NORTE	81	170
300	FORTUL	81	170
591	PUERTO RONDON	81	170
736	SARAVENA	81	170
794	TAME	81	170
1	YOPAL	85	170
10	AGUAZUL	85	170
15	CHAMEZA	85	170
125	HATO COROZAL	85	170
136	LA SALINA	85	170
139	MANI	85	170
162	MONTERREY	85	170
225	NUNCHIA	85	170
230	OROCUE	85	170
250	PAZ DE ARIPORO	85	170
263	PORE	85	170
279	RECETOR	85	170
300	SABANALARGA	85	170
315	SACAMA	85	170
325	SAN LUIS DE PALENQUE	85	170
400	TAMARA	85	170
410	TAURAMENA	85	170
430	TRINIDAD	85	170
440	VILLANUEVA	85	170
1	MOCOA	86	170
219	COLON	86	170
320	ORITO	86	170
568	PUERTO ASIS	86	170
569	PUERTO CAICEDO	86	170
571	PUERTO GUZMAN	86	170
573	PUERTO LEGUIZAMO	86	170
749	SIBUNDOY	86	170
755	SAN FRANCISCO	86	170
757	SAN MIGUEL (LA DORADA)	86	170
760	SANTIAGO	86	170
865	LA HORMIGA (VALLE DEL\nGUAMUEZ)	86	170
885	VILLAGARZON	86	170
1	SAN ANDRES	88	170
564	PROVIDENCIA	88	170
1	LETICIA	91	170
263	EL ENCANTO	91	170
405	LA CHORRERA	91	170
407	LA PEDRERA	91	170
430	LA VICTORIA	91	170
460	MIRITI-PARANA	91	170
530	PUERTO ALEGRIA	91	170
536	PUERTO ARICA	91	170
540	PUERTO NARIÑO	91	170
669	PUERTO SANTANDER	91	170
798	TARAPACA	91	170
1	PUERTO INIRIDA	94	170
343	BARRANCO MINAS	94	170
883	SAN FELIPE	94	170
884	PUERTO COLOMBIA	94	170
885	LA GUADALUPE	94	170
886	CACAHUAL	94	170
887	PANA PANA (CAMPO\nALEGRE)	94	170
888	MORICHAL (MORICHAL\nNUEVO)	94	170
1	SAN JOSE DEL GUAVIARE	95	170
15	CALAMAR	95	170
25	EL RETORNO	95	170
200	MIRAFLORES	95	170
1	MITU	97	170
161	CARURU	97	170
511	PACOA	97	170
666	TARAIRA	97	170
777	PAPUNAUA (MORICHAL)	97	170
889	YAVARATE	97	170
1	PUERTO CARREÑO	99	170
524	LA PRIMAVERA	99	170
572	SANTA RITA	99	170
666	SANTA ROSALIA	99	170
760	SAN JOSE DE OCUNE	99	170
773	CUMARIBO	99	170
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       5008.dat                                                                                            0000600 0004000 0002000 00000005275 15015340177 0014262 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        ﻿4	AFGANISTAN
248	ALAND ISLANDS
8	ALBANIA
276	ALEMANIA
20	ANDORRA
24	ANGOLA
660	ANGUILA
10	ANTARTIDA
28	ANTIGUA Y BARBUDA
530	ANTILLAS NEERLANDESAS
682	ARABIA SAUDITA
12	ARGELIA
32	ARGENTINA
51	ARMENIA
533	ARUBA
36	AUSTRALIA
40	AUSTRIA
31	AZERBAIYAN
44	BAHAMAS
48	BAHREIN
50	BANGLADESH
52	BARBADOS
112	BELARUS
56	BELGICA
58	BELGICA-LUXEMBURGO
84	BELICE
204	BENIN
60	BERMUDAS
64	BHUTAN
68	BOLIVIA
535	BONAIRE
70	BOSNIA Y HERZEGOVINA
72	BOTSWANA
76	BRASIL
96	BRUNEI DARUSSALAM
100	BULGARIA
854	BURKINA FASO
108	BURUNDI
132	CABO VERDE
116	CAMBOYA
120	CAMERUN
124	CANADA
839	CATEGORIAS ESPECIALES
148	CHAD
200	CHECOSLOVAQUIA
152	CHILE
156	CHINA
196	CHIPRE
170	COLOMBIA
849	COMANDO I DEL PACIFICO DE ESTADOS UNIDOS
174	COMORAS
178	CONGO, REP. DEL
180	CONGO, REP. DEM. DEL
410	COREA, REP. DE
408	COREA, REP. DEM. DE
188	COSTA RICA
384	COTE D'IVOIRE
191	CROACIA
192	CUBA
531	CURACAO
208	DINAMARCA
262	DJIBOUTI
212	DOMINICA
218	ECUADOR
818	EGIPTO, REP. ARABE DE
222	EL SALVADOR
784	EMIRATOS ARABES UNIDOS
232	ERITREA
705	ESLOVENIA
724	ESPANA
840	ESTADOS UNIDOS
233	ESTONIA
231	ETIOPIA (EXCLUIDA ERITREA)
230	ETIOPIA (INCLUIDA ERITREA)
918	EUROPEAN UNION
736	EX SUDAN
643	FEDERACION DE RUSIA
242	FIJI
608	FILIPINAS
246	FINLANDIA
592	FM PANAMA CZ
717	FM RHOD NYAS
835	FM TANGANYIK
866	FM VIETNAM DR
868	FM VIETNAM RP
836	FM ZANZ-PEMB
250	FRANCIA
266	GABON
270	GAMBIA
274	GAZA STRIP
268	GEORGIA
288	GHANA
292	GIBRALTAR
308	GRANADA
300	GRECIA
304	GROENLANDIA
312	GUADALUPE
316	GUAM
320	GUATEMALA
254	GUAYANA FRANCESA
324	GUINEA
226	GUINEA ECUATORIAL
624	GUINEA-BISSAU
328	GUYANA
332	HAITI
340	HONDURAS
344	HONG KONG (CHINA)
348	HUNGRIA
356	INDIA
360	INDONESIA
364	IRAN, REP. ISLAMICA DEL
368	IRAQ
372	IRLANDA
74	ISLA BOUVET
837	ISLA BUNKER
162	ISLA DE NAVIDAD
574	ISLA NORFOLK
352	ISLANDIA
136	ISLAS CAIMAN
166	ISLAS COCOS (KEELING)
184	ISLAS COOK
582	ISLAS DEL PACIFICO
238	ISLAS FALKLAND
234	ISLAS FEROE
239	ISLAS GEORGIAS DEL SUR Y SANDWICH DEL SUR
334	ISLAS HEARD Y MCDONALD
584	ISLAS MARSHALL
90	ISLAS SALOMON
796	ISLAS TURCAS Y CAICOS
581	ISLAS ULTRAMARINAS MENORES DE ESTADOS UNIDOS
850	ISLAS VIRGENES (EE.UU.)
92	ISLAS VIRGENES BRITANICAS
876	ISLAS WALLIS Y FUTUNA
376	ISRAEL
380	ITALIA
388	JAMAICA
392	JAPON
396	JHONSTON ISLAND
400	JORDANIA
398	KAZAJSTAN
404	KENYA
417	KIRGUISTAN
296	KIRIBATI
412	KOSOVO
414	KUWAIT
426	LESOTHO
428	LETONIA
422	LIBANO
430	LIBERIA
434	LIBIA
438	LIECHTENSTEIN
440	LITUANIA
442	LUXEMBURGO
446	MACAO
807	MACEDONIA, EX REP. YUGOSLAVA DE
450	MADAGASCAR
458	MALASIA
454	MALAWI
462	MALDIVAS
466	MALI
470	MALTA
580	MARIANA
504	MARRUECOS
474	MARTINICA
480	MAURICIO
478	MAURITANIA
175	MAYOTTE
484	MEXICO
583	MICRONESIA, ESTADOS FED. DE
488	MIDWAY ISLANDS
492	MONACO
496	MONGOLIA
499	MONTENEGRO
500	MONTSERRAT
508	MOZAMBIQUE
\.


                                                                                                                                                                                                                                                                                                                                   5007.dat                                                                                            0000600 0004000 0002000 00000135205 15015340177 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        24671080	Manu	Eliana	Acedo	Aranda	3931675201	Urbanización de Rafael Barco 108 Piso 8  Barcelona, 15937
73531969	Sigfrido	\N	Querol	Barberá	3172559749	Urbanización Azahar Luque 728 Soria, 34207
59064462	Alejandra	Roldán	Barreda	Baró	3293769879	Glorieta Flora Espinosa 57 Santa Cruz de Tenerife, 45808
87052772	Juanita	Hernán	Prat	Polo	3797857910	Plaza Rómulo Leon 5 Puerta 6  Santa Cruz de Tenerife, 40202
73501969	Benjamín	Milagros	Rivas	Gutierrez	3791748408	Paseo de Isabela Pujol 747 Puerta 2  Salamanca, 64727
63471628	Clímaco	\N	Morales	Álamo	3397830640	Cañada Eusebio Zabaleta 46 Puerta 5  La Coruña, 49654
72871605	Victoria	Coral	Contreras	Sans	3815049063	Via Febe Pla 64 Tarragona, 31766
88763879	Calixto	\N	Ariza	Acosta	3342177773	Alameda de Mercedes Llorens 3 Granada, 64999
17888865	Carlito	Bárbara	Ayala	Salamanca	3100587279	Paseo de Encarna Perelló 91 Apt. 62  Huesca, 49782
43975562	Valero	\N	Manso	Piñol	3522012615	Avenida Leoncio Bauzà 1 Puerta 7  Soria, 34405
55899043	Cristina	\N	Suarez	Esteve	3290959027	Avenida de Alcides Cepeda 339 Piso 5  Navarra, 03371
65807623	Ofelia	\N	Ariño	Albero	3217527959	Pasadizo Florentino Rozas 39 Murcia, 72893
68900649	Teresita	Ángela	Bustamante	Palomares	3181165370	Cañada Luisa Miranda 3 Apt. 65  Valencia, 59593
57432876	Sebastian	\N	Rodríguez	Pedrero	3726552398	Calle de Amado Solé 4 Apt. 43  Guadalajara, 03824
10313796	Renato	Yésica	Castelló	Castell	3762174906	Via de Mario Canet 144 La Rioja, 28865
52529570	Rico	Clarisa	Mariscal	Andreu	3442314880	Via Victoriano Solís 32 Apt. 67  Álava, 53532
52904562	Salud	Cebrián	Escribano	Zabaleta	3684305903	Pasaje Rolando Palomar 548 Puerta 4  Castellón, 87782
97891423	Conrado	\N	Aguilera	Valverde	3404304312	Camino Milagros Mancebo 33 Piso 6  Ciudad, 02829
92117567	Gala	Josefa	Taboada	Robles	3290156717	C. Anselmo Ríos 89 Apt. 52  Girona, 58272
11975817	Chita	\N	Andres	Galiano	3506829573	Acceso Paz Barberá 70 Piso 0  Jaén, 98965
77504086	Mar	\N	Beltrán	Asensio	3189725183	Acceso de Melania Diez 55 Piso 4  Jaén, 58704
68119001	Octavio	Aurora	Peláez	Trillo	3966577961	Paseo Adelaida Bernal 39 Apt. 32  Melilla, 62470
98470287	Paulina	\N	Gallardo	Cabezas	3835024183	Cuesta Adolfo Gimeno 88 Burgos, 64682
47053132	Luisa	Narciso	Roma	Barceló	3675229320	C. Jordán Anglada 83 Puerta 0  Granada, 47122
65494361	José Manuel	Trini	Céspedes	Frías	3665895457	Vial Felicidad Benavente 42 Apt. 16  Melilla, 79675
73375419	Elisa	\N	Zamora	Goñi	3918315694	Alameda de Vidal Lasa 734 Cáceres, 69470
76869398	Javier	Luz	Sala	Fabra	3900990042	Paseo Vilma Tejada 21 La Rioja, 41000
78896222	Pastor	\N	Espada	Pont	3327296398	C. de Fabiola Gutierrez 23 Apt. 70  Tarragona, 57144
18884256	Dorotea	\N	Rodrigo	Codina	3568873471	Rambla Mireia Arranz 83 Valencia, 77920
76305633	Dan	\N	Laguna	Bayona	3911691129	Via de Sol Ródenas 1 Apt. 63  Alicante, 66592
11320251	Susana	\N	Garzón	Leon	3843679217	Ronda Crescencia Carvajal 31 Apt. 09  Castellón, 32412
72339383	Juliana	Lorenza	Bauzà	Duque	3208807634	Ronda de Dolores Pozo 83 Piso 9  Salamanca, 75525
67631004	Adán	\N	Higueras	Diaz	3596300178	Pasaje de Artemio Peñas 31 Apt. 07  Navarra, 57038
93514575	Sol	\N	Guerrero	Álvarez	3938473603	Via Chita Alcaraz 65 Barcelona, 42533
90855540	Amando	Duilio	Villa	Jara	3648924635	Camino Luis Ángel Tenorio 65 Apt. 74  Huesca, 21502
41317742	Urbano	\N	Barriga	Calderón	3887270249	Camino de Candelario Anaya 98 Pontevedra, 26479
49178640	Segismundo	Cayetano	Fernandez	Raya	3577108487	Pasadizo Teresita Iglesias 24 Sevilla, 80347
28587538	Rosa María	Octavio	Palmer	Barral	3804334969	Acceso de Adán Planas 362 Vizcaya, 02201
68460703	Abilio	Sandalio	Castells	Antúnez	3471398546	Calle de Rosenda Barco 95 Piso 3  Navarra, 63634
53551825	Jose Ignacio	Lidia	Llamas	Gordillo	3360628835	Alameda de Alex Bas 7 Cuenca, 43684
90188180	Benigno	\N	Amorós	Manzanares	3365747159	C. Macaria Alberola 61 La Coruña, 52939
59232397	Belen	Lina	Tovar	Martínez	3260886683	Vial de Remigio Nuñez 31 Córdoba, 70049
81658326	Leandra	\N	Villaverde	Arévalo	3562113789	Avenida Glauco Vilanova 877 Puerta 9  Cáceres, 37080
16539112	Germán	Vilma	Plaza	Dueñas	3678688507	Urbanización Marisa Julián 27 Las Palmas, 51704
43930641	Eleuterio	\N	Badía	Vilar	3190338577	Ronda de Francisco Javier Calvo 83 Cantabria, 53021
95098875	Augusto	Delfina	Borrego	Varela	3972061555	Urbanización Lidia Ricart 59 Navarra, 58462
56290766	Candela	Estrella	Acero	Navarro	3476912292	Plaza de Federico Marin 1 Teruel, 43879
48401070	Ruy	Gloria	Carrillo	Heredia	3271183501	C. de Clementina Tomás 96 Puerta 9  Sevilla, 28976
95696511	Reyna	Juanita	Grande	Losada	3861837138	Cañada de Sosimo Vallejo 425 Navarra, 56745
11827933	Joel	Geraldo	Frías	Aller	3341625935	Acceso de Poncio Aparicio 79 Puerta 0  Córdoba, 64816
98457493	Ale	\N	Ripoll	Teruel	3853176694	Ronda Estela Calderón 42 Piso 0  Albacete, 58591
27545804	Jesusa	Charo	Santiago	Briones	3535080316	Rambla Corona Barberá 66 Puerta 2  Lugo, 96610
28165055	Fortunata	\N	Múñiz	Morera	3754947408	Cuesta Cebrián Giralt 97 Ciudad, 16279
36444233	Octavio	\N	Galan	Borja	3799517089	Glorieta Victoriano Cañellas 670 Apt. 50  Ciudad, 97676
73353018	Cayetana	\N	Rincón	Codina	3599631739	Pasaje de Calisto Robles 45 La Coruña, 68276
66900909	Celestina	\N	Carnero	Luís	3811466324	Cuesta María Sánchez 991 Apt. 90  Cáceres, 95621
65653625	Azeneth	\N	Pintor	Prada	3531255493	Rambla Arturo Sebastián 17 Piso 6  Ávila, 66797
31115230	Modesta	\N	Sánchez	Riera	3185935244	Callejón Felipe Iniesta 1 La Rioja, 33906
41682942	Arcelia	\N	Morillo	Plana	3721810697	Acceso de Juan Manuel Salinas 83 Vizcaya, 16899
91856779	Noelia	\N	Casado	Fuente	3253916407	Cañada Ildefonso Rodrigo 16 Madrid, 56908
31354879	Nuria	Nico	Bejarano	Alcaraz	3167414919	Cañada Fabio Calvet 17 Cantabria, 10303
73187168	Evangelina	\N	Rosado	Salcedo	3145971595	Cañada Enrique Alberto 751 Puerta 7  La Coruña, 94185
21764739	Ruth	Maribel	Real	Matas	3461151225	Camino de Ramón Moll 11 Piso 6  Guipúzcoa, 93445
73974014	Ezequiel	Ezequiel	Ledesma	Jáuregui	3900570004	Camino Roldán Llobet 56 Puerta 0  Girona, 09645
26579117	Dani	\N	Guardia	Olivé	3309878076	C. Elvira Arnaiz 152 Jaén, 32801
74948645	Ramona	Jose Ramón	Pujol	Raya	3473867134	C. de Salud Villaverde 7 Puerta 8  Albacete, 86382
64147579	Efraín	Úrsula	Lara	Rios	3589112580	Cuesta Arsenio Barranco 20 Puerta 7  Alicante, 14068
42078464	María Pilar	\N	Hernandez	Gargallo	3133787104	Via Imelda Beltrán 44 Puerta 7  Jaén, 28135
12607314	Remigio	\N	Mena	López	3492281376	Alameda de Martin Zapata 62 Apt. 68  Ciudad, 27063
51938393	Isaac	Julie	Fuente	Tejada	3634734154	Vial de Mauricio Ramis 1 Cádiz, 50147
37007750	Dolores	Olga	Ferrero	Merino	3836186296	Callejón de Lupe Cámara 98 Puerta 8  Lugo, 30165
10226393	Diana	Venceslás	Barros	Gimeno	3895248148	Acceso de Aránzazu Castellanos 7 Cuenca, 05517
10804967	Mónica	María Ángeles	Leiva	Isern	3414162010	Plaza Julieta Comas 933 Madrid, 01784
77917196	Leyre	\N	Artigas	Leal	3731103952	Paseo de Griselda Báez 28 La Rioja, 79551
75631476	Eusebio	\N	Juárez	Gutierrez	3528036763	Acceso Sofía Álamo 9 Guipúzcoa, 86974
95775286	Josefa	\N	Maldonado	Monreal	3276655547	Alameda Iker Ariño 76 Apt. 41  Málaga, 41703
48096315	Roque	Flavia	Cáceres	Castro	3661540798	Rambla Luís Gelabert 2 Apt. 80  Ceuta, 82073
30334989	María Del Carmen	\N	Torrens	Toledo	3828130034	Alameda de Luz Pereira 16 Pontevedra, 16764
32946702	Teodoro	\N	Ugarte	Amigó	3140932829	Callejón de Mar Chaves 46 Lleida, 04374
22640746	César	\N	Almagro	Rico	3624848617	Rambla Camila Llamas 52 Puerta 1  Ciudad, 26454
38919139	Paca	\N	Campos	Alvarado	3177281991	Vial Anastasio Jove 87 Apt. 20  Soria, 94372
13361308	Loreto	Sofía	Aragón	Ramírez	3129809103	Plaza de Alfredo Diego 79 Toledo, 36770
95319802	Estefanía	Pía	Ricart	Noguera	3811847640	Glorieta de Valentina Osuna 2 Puerta 3  Cáceres, 44371
42592925	Maximino	Alfonso	Capdevila	Iriarte	3178094669	Via de Cándido Pineda 82 Piso 1  Almería, 51066
75092486	Lucía	\N	Díez	Villalonga	3701242515	Calle Sol Vallejo 119 Barcelona, 77754
80810193	Elías	Álvaro	Vergara	Peñalver	3600177321	Pasadizo José Vicens 16 Guadalajara, 20889
82633295	María Cristina	\N	Bayón	Dalmau	3276841651	Via Ignacio Arnal 65 La Coruña, 41819
29374978	Marcela	\N	Miró	Páez	3171429688	Acceso Rosalía Barco 95 Guipúzcoa, 83305
23105141	Jenaro	\N	Coello	Baena	3923490816	Glorieta Albina Acosta 1 Apt. 75  Guipúzcoa, 03211
60415409	Edu	Jesusa	Rebollo	Carpio	3597709833	Plaza de Nico Quintanilla 33 Valencia, 78836
84227070	Carmela	\N	Sarabia	Gimenez	3128447029	Pasaje de Calista Oller 489 Cuenca, 77582
32148682	Juan Bautista	\N	Arnau	Carro	3817847811	Avenida Saturnina Vara 663 Apt. 29  Ciudad, 93374
44381316	Alejandro	\N	Grande	Plaza	3946324687	Via de Carmelita Infante 1 Puerta 1  Las Palmas, 14557
10488754	Amado	Segismundo	Giner	Escolano	3798140033	Paseo Isabel Maldonado 9 Santa Cruz de Tenerife, 16135
98807491	Santiago	Maxi	Ortuño	Fernández	3929679304	C. Francisco Hernandez 21 Apt. 12  Navarra, 30390
71776709	Serafina	Magdalena	Criado	Mariscal	3694954328	Alameda de Salud Carnero 94 Granada, 07327
59842098	Encarnación	\N	Anguita	Solano	3518458795	Glorieta de Azucena Bermejo 87 Apt. 43  Zamora, 09237
77342840	Reyes	\N	Diez	Rubio	3877549369	Avenida Rosario Mata 506 Teruel, 86702
32277615	Teófila	Jesús	Borrego	Merino	3825769548	Glorieta de Gustavo Juan 88 Piso 0  Huelva, 97726
45438682	Ignacia	\N	Baños	Recio	3556293518	Pasadizo de Godofredo Castejón 58 Puerta 6  Badajoz, 01301
49548016	Edgardo	Custodio	Cazorla	Montserrat	3678221688	Calle Toribio Pedrosa 737 Teruel, 12707
87901239	Selena	Roberta	Gisbert	Viñas	3741697072	Callejón Telmo Montenegro 63 Puerta 5  Cuenca, 06315
20578166	Telmo	Abilio	Aller	Ayuso	3904506544	Cañada Rosendo Hervás 84 Apt. 94  Segovia, 12222
30319405	Adán	Piedad	Villa	Pallarès	3785098501	Pasadizo Isaura Torrens 65 Cantabria, 94441
96934895	Matías	\N	Morales	Benavent	3177579996	Callejón de Cebrián Pacheco 3 Jaén, 69454
35288138	Trinidad	\N	Mate	Samper	3640743921	Glorieta Emilio Leal 188 La Coruña, 45416
60859139	Matías	Paulina	Prat	Oller	3480587874	Vial de Abigaíl Marcos 80 Guadalajara, 09725
37389723	Amancio	Lorenza	Calzada	Morales	3671337241	Glorieta Federico Ferrándiz 5 La Rioja, 12900
26302240	Florinda	\N	Mas	Pelayo	3891195735	Vial Luciano Requena 50 Navarra, 32468
21455212	Ciro	\N	Olmedo	Chaparro	3403554272	Alameda de Duilio Méndez 1 Apt. 18  Girona, 19782
47908179	Victoriano	\N	Rebollo	Cañizares	3550358381	Avenida de Primitivo Marin 99 Toledo, 04912
18422677	Nydia	Nicolasa	Vera	Serna	3111374559	C. de José Manuel García 8 Piso 2  Valencia, 73920
45568604	Amada	Aurelia	Gallart	Abascal	3291753907	Vial de Catalina Sobrino 80 Zaragoza, 36785
91622231	Ignacio	Ildefonso	Neira	Carrera	3535544457	Glorieta de Edu Egea 74 Almería, 24690
80813825	Nerea	\N	Iglesias	Martí	3957268991	Vial Glauco Lladó 64 Ourense, 14554
34012645	Evelia	Pilar	Herrero	Rosa	3370907246	Camino Victorino Pazos 93 Apt. 98  Ciudad, 16161
75702987	José Mari	\N	López	Mayo	3213615411	Pasadizo Ildefonso Portillo 3 Cádiz, 47564
95333838	Severiano	\N	Cortina	Posada	3194499513	Alameda Cleto Gras 70 Ceuta, 50353
78471994	Pepe	María Manuela	Jordá	Oliveras	3809115691	Rambla Heraclio Tormo 48 Soria, 21453
30114744	Buenaventura	Gabriel	Sáez	Palmer	3406415826	Rambla de Nando Sanchez 75 Apt. 91  Sevilla, 79196
49692349	Encarnacion	\N	Molina	Serrano	3591215216	Ronda de Julie Cazorla 276 León, 36841
74025532	Isaura	\N	Saavedra	Noguera	3207369881	Vial de Rosario Valenzuela 34 Melilla, 77560
26587038	Aránzazu	Reynaldo	Campo	Cañellas	3518935148	Alameda de Ofelia Núñez 26 Apt. 26  Huelva, 58975
15339025	Clímaco	María Manuela	Plaza	Ricart	3686685908	Plaza Martin Verdejo 2 Apt. 14  Asturias, 99642
22158323	Anita	\N	Mulet	Iñiguez	3770808907	Calle Anunciación Azorin 69 Piso 9  Teruel, 61374
52137089	Micaela	\N	Muñoz	Gallo	3168841726	Pasaje Eugenio Juan 72 Apt. 61  Navarra, 36324
88357716	Marco	\N	Ramos	Garmendia	3406220535	Plaza de María Ángeles Gimeno 981 Piso 6  Las Palmas, 65798
92792049	Marita	\N	Barranco	Montes	3464833696	Rambla Silvestre Bautista 98 Puerta 8  Sevilla, 91797
53647552	Timoteo	Edelmiro	Saez	Nogueira	3423814268	Glorieta de Teobaldo Fuentes 3 Piso 0  Córdoba, 29468
36386086	Graciela	Selena	Segarra	Palmer	3461254475	Alameda Carlota Villalba 20 Puerta 5  La Rioja, 18450
86720230	Berto	\N	Sáez	Romero	3709056941	Ronda de Caridad Diéguez 251 Granada, 51425
26597205	Olimpia	\N	Gonzalez	Piquer	3475090269	Rambla Julio César Ricart 4 Murcia, 49310
21679514	Gaspar	Diana	Pozuelo	Ferrando	3203833956	Ronda Jose Ramón Arce 7 Melilla, 40885
13423935	Bernarda	Rosalina	Ruiz	Manso	3727658777	Avenida Ariel Alarcón 26 Piso 0  Cáceres, 86070
59383023	Gisela	\N	Casanova	Pol	3854430268	Via de Luna Vargas 76 Apt. 67  Zaragoza, 17240
25334579	Melchor	Leonardo	Haro	Vidal	3842395850	Plaza de Patricia Santiago 75 Apt. 48  Zaragoza, 12235
69566892	Marcial	\N	Tomé	Carnero	3473851135	C. de Lola Alberola 936 Puerta 5  Barcelona, 91295
64101667	Lupita	Miguel	Salmerón	Egea	3920316262	Calle Eusebia Sánchez 9 Alicante, 21537
98121155	Marc	\N	Botella	Estévez	3980833828	Ronda Reyes Galiano 25 Palencia, 25959
20517826	Aitana	Fernanda	Salazar	Fiol	3707342576	Ronda de Gloria Crespo 52 Badajoz, 71778
96024335	Íñigo	Pío	Jódar	Marco	3766872771	Acceso de Amílcar Córdoba 624 Puerta 8  Granada, 25313
64690893	Amparo	Violeta	Lluch	Iriarte	3611541378	C. Cristian Camacho 940 Ciudad, 72329
93074732	Oriana	\N	Jaume	Barberá	3909343893	Rambla Ildefonso Rocha 858 Puerta 0  Ciudad, 54416
48794825	Amanda	Lino	Bonilla	Andrade	3385519231	Calle Elba Varela 640 Apt. 81  Huelva, 84162
75008308	Santiago	\N	Llano	Torres	3607599222	C. de Santiago Andrade 52 Ourense, 87809
57146152	Felisa	\N	Arias	Salvà	3963444920	Glorieta de Lola Guijarro 18 Puerta 7  Baleares, 11718
99382537	Marcia	Isabel	Ugarte	Toro	3413261147	Cuesta Pepita Bolaños 78 Segovia, 14895
92801432	Sabina	\N	Gomez	Alsina	3363670345	Alameda Quirino Hurtado 22 Murcia, 08663
14498842	Sarita	\N	Batlle	Paredes	3557498061	Pasaje de Jonatan Ferrándiz 84 Lleida, 80687
71366530	Ana Sofía	\N	Uribe	Enríquez	3506690783	C. Jose Miguel Saavedra 9 Puerta 2  León, 13001
65205763	Heliodoro	Cayetano	Miró	Pallarès	3566862410	Pasaje Domingo Barranco 71 Piso 8  Cádiz, 10488
24603903	Ana Belén	\N	Alcalde	Rojas	3989314758	Callejón de Gaspar Pla 479 Castellón, 83067
64265555	Inmaculada	Roque	Manzanares	Macías	3918027635	Calle Candelaria Batalla 935 Teruel, 29161
31082672	Francisco	Ángel	Leal	Cueto	3923135375	Vial de Juan Pablo Franch 19 Puerta 3  Asturias, 46625
44981055	Abril	\N	Otero	Parra	3581513338	Glorieta Joaquín Vilar 4 Guipúzcoa, 67908
96769733	Pastor	María Luisa	Quero	Piquer	3952854878	Cañada Marcela Jara 836 Puerta 4  Cantabria, 68698
36025468	Raquel	\N	Campos	Cabeza	3234740832	Cañada de Belén Colomer 31 Ceuta, 20886
66708777	Marcia	Ágata	Oliveras	Baena	3205589883	Avenida de Estrella Narváez 9 Ourense, 69755
44118554	Sandalio	Camila	Torrens	Oliveras	3311993637	Alameda de Leandra Río 65 Soria, 26171
41502429	Isa	Simón	Santana	Rey	3226897107	Avenida Eustaquio Alegria 12 Ávila, 28197
21484177	María Del Carmen	Hernando	Teruel	Varela	3580979146	Alameda de Clemente Reina 71 Vizcaya, 74243
26606875	Evita	\N	Carro	Palma	3351429468	Calle Nieves Galiano 748 Córdoba, 24790
87245840	Nicolasa	\N	Villalonga	Manjón	3199118431	Urbanización Fidel Mayoral 470 Toledo, 68957
45085983	Ismael	Luna	Pineda	Rios	3729303468	Paseo de Casandra Fabregat 4 Piso 4  Ceuta, 78394
79835835	Isaura	Zoraida	Alfonso	Río	3624678399	Pasaje de Ezequiel Uribe 56 Puerta 8  Cantabria, 54091
62572471	Amaro	Ricardo	Anguita	Rueda	3486379574	Ronda Severo Cuéllar 55 Lugo, 74793
42626645	Tania	Lucila	Gibert	Angulo	3577075799	Paseo de Felisa Rocha 23 Cáceres, 21251
98059600	Raimundo	Micaela	Hierro	Borja	3222275425	Plaza Pepe Cid 86 Santa Cruz de Tenerife, 38029
83870023	Gabino	\N	Fajardo	Criado	3256486306	Cuesta Elías Almazán 67 Murcia, 33834
76367400	Chucho	Rufino	Falcón	Llorente	3601223191	C. Eladio Alcaraz 58 Guadalajara, 59301
57675038	Chelo	\N	Gabaldón	Lasa	3290153471	Rambla de Remedios Narváez 618 Valencia, 20392
89134517	Eligio	Ezequiel	Pacheco	Cantero	3120452391	Rambla de Ismael Valencia 12 Cádiz, 79049
54820670	Ildefonso	Amado	Chaparro	Llorente	3135896787	Callejón Modesta Gargallo 40 Piso 3  Melilla, 21702
70439251	Perlita	Eric	Suárez	Baeza	3899764755	Cuesta de Jesusa Leiva 222 Badajoz, 65284
66906646	Horacio	\N	Castillo	Valenciano	3261966784	Alameda de Heriberto Herranz 13 Toledo, 51050
75417142	Pastor	\N	Haro	Arrieta	3560831849	Calle de Amparo Armengol 97 Puerta 4  Valladolid, 40711
97850938	Edmundo	\N	Alcalde	Bernal	3879820813	Calle de Vicente Solera 13 Puerta 7  Las Palmas, 71033
84652213	Nayara	\N	Perea	Trillo	3261463911	Plaza Adán Torres 22 Málaga, 36724
92379045	Emilio	\N	Alarcón	Gallardo	3661151419	Alameda de Mayte Cabañas 5 Toledo, 29894
48440553	Jose Carlos	\N	Piñeiro	Ibañez	3154427407	Acceso de Maura Crespi 40 Las Palmas, 59914
94567108	Santiago	\N	Palau	Espada	3502844556	Acceso de Jeremías Rivas 63 Cuenca, 64153
92426237	Wálter	Arturo	Vicente	Franco	3316705616	Glorieta Hernando Roma 27 Puerta 5  Cáceres, 66383
73919086	Hector	\N	Vargas	Zamorano	3267838665	Alameda de Horacio Adadia 82 Piso 7  Zamora, 07065
52894036	Telmo	Hugo	Artigas	Castells	3806344349	Plaza Rosalva Agustín 71 Álava, 14830
51391052	Gala	Alejandro	Tur	Llanos	3300061773	Camino Esther Cortés 114 La Coruña, 36894
97056601	Visitación	Yaiza	Poza	Lucena	3713311036	Vial Rebeca Laguna 75 Málaga, 41340
78995066	Dionisia	Lorenzo	Ferreras	Ledesma	3122645996	Via Oriana Calvo 320 Apt. 24  Lugo, 49387
90468947	Sigfrido	Ámbar	Torrent	Guijarro	3336005299	Cañada Jeremías Rocha 42 Puerta 9  Teruel, 00231
38956330	Reinaldo	\N	Crespo	Naranjo	3551695801	Urbanización Maribel Barriga 701 Piso 7  Ciudad, 29623
74534213	Gonzalo	Ciro	Velázquez	Mata	3802855874	Plaza Maura Carbajo 27 Piso 3  Ceuta, 42627
44501933	Ramón	\N	Montenegro	Santamaría	3411541559	Via Pancho Salvador 42 Ceuta, 77911
48509276	Isidoro	Vicenta	Monreal	Soler	3318685143	Urbanización de Domitila Marco 513 Asturias, 08182
40003488	Gaspar	Quirino	Sarmiento	Silva	3430872900	Pasadizo Celestino Exposito 32 Apt. 05  Asturias, 22083
83633283	Reyes	\N	Ureña	Codina	3858562680	Cañada de Eliseo Bernat 9 Puerta 6  Guadalajara, 05724
90850928	Chucho	\N	Goicoechea	Royo	3438722353	Cañada Norberto Segovia 985 Puerta 3  La Coruña, 19786
15787800	Hermenegildo	Georgina	Varela	Córdoba	3635721540	Pasadizo de Anabel Bilbao 725 Lugo, 38579
22262938	Patricio	\N	Álamo	Figueras	3600653684	Urbanización Herminio Borrás 3 Almería, 58432
72671137	Cipriano	\N	Mir	Porcel	3117455459	Pasaje de Rufina Ros 1 Apt. 50  La Coruña, 53034
81573571	Micaela	\N	Casanovas	Jordá	3333674633	Via de Tiburcio Portillo 18 Zamora, 97157
90185282	Álvaro	\N	Feijoo	Poza	3139792359	Urbanización Lucila Cid 6 Apt. 93  Ávila, 43810
59605831	Patricia	\N	Tejero	Ponce	3177218334	Ronda José Antonio Roldán 67 Castellón, 73700
67041778	Dulce	Aitor	Castañeda	Girona	3230380409	Plaza de Anita Moraleda 94 Córdoba, 50443
93366145	Angélica	Gloria	Quiroga	Arnal	3340680153	Urbanización Brunilda Escalona 126 Murcia, 02651
87883038	Sabas	Pánfilo	Pinto	Marí	3741407521	Acceso de Saturnino Muro 33 Puerta 8  Guipúzcoa, 29858
13731954	Reyes	Florencia	Esteban	Mata	3262493930	Cuesta de Cosme Molins 3 Huesca, 58804
78486399	Mirta	Isidora	Anguita	Coronado	3546761080	Ronda de Dan Mendizábal 8 Lleida, 70014
19684002	América	\N	Quevedo	Gallego	3438422363	Via Fátima Mora 58 Melilla, 76733
32584758	Nerea	María Jesús	Martin	Lastra	3734980352	Via de Zaira Baquero 19 Tarragona, 83828
77936448	Saturnina	Loreto	Mateo	Lerma	3587201612	Ronda de Cruz Tena 92 Melilla, 05759
95726526	Hugo	\N	Gárate	Pi	3630747089	Urbanización Eusebio Grande 1 Apt. 58  Palencia, 44600
29616087	Javi	\N	Bernad	Gomez	3352150546	Callejón de Ernesto Querol 6 Guipúzcoa, 46555
20420446	Alexandra	Emigdio	Cantero	Piñeiro	3262968850	Rambla Lucas Gimenez 38 Apt. 09  Valencia, 80798
49479339	Leandro	\N	Garmendia	Roman	3753426026	Calle de Aroa Núñez 98 Apt. 94  Granada, 54469
73028721	Olegario	Ale	Roselló	Acevedo	3157499287	C. de Lope Tormo 39 Puerta 3  Cádiz, 74494
83434125	Manu	\N	Camino	Flores	3794160546	Cañada de Herminio Esparza 84 Valladolid, 83204
18772105	Imelda	\N	Amat	Casas	3478202557	Avenida Conrado Mendoza 741 Piso 0  Baleares, 41464
20890951	Consuela	\N	Saez	Ribes	3295825413	Cuesta de Alejo Mate 37 Puerta 6  Cádiz, 72569
96619433	Paulino	\N	Parra	Diez	3442214125	Cuesta de Maxi Gelabert 58 Apt. 98  Guipúzcoa, 07158
14127071	Calista	Josep	Gutierrez	Viana	3343042303	Vial de Julieta Gallardo 13 Sevilla, 39813
47532707	Pedro	\N	Recio	Jiménez	3337016358	Pasaje Saturnina Rosado 569 Puerta 3  Castellón, 79549
36660842	Adriana	\N	Carreras	Vives	3961054653	Pasaje de Yago Samper 234 Piso 8  Castellón, 83999
72708478	Judith	Alonso	Sastre	Roca	3661611932	Vial Amelia Pereira 78 Puerta 8  Burgos, 14853
40097562	Victor Manuel	\N	Campos	Peláez	3537111590	Ronda de Bernarda Español 383 Castellón, 50918
18510481	Severo	Ángel	Carmona	Álvarez	3290564600	Ronda Soledad Luz 11 Apt. 75  Granada, 93138
35097937	Buenaventura	\N	Domingo	Herrera	3348315953	Alameda Demetrio Rocamora 90 Piso 5  Salamanca, 81987
45517996	Anunciación	\N	Borrell	Nadal	3160799690	Avenida de Vinicio Calleja 98 Madrid, 24340
97500665	Natalia	\N	Amorós	Arco	3915014172	Cuesta Luis Ángel Salamanca 25 Puerta 9  La Coruña, 16761
22841161	Felicidad	Miriam	Morell	Palau	3779358778	Rambla Eugenia Riba 15 Almería, 47711
19898979	Geraldo	\N	Miranda	Iglesia	3851166479	Plaza de Fausto Pablo 75 Valladolid, 84024
99239324	Cloe	\N	Belda	Diego	3955172159	Rambla Ernesto Torralba 7 Apt. 70  Granada, 69928
40371978	Yésica	Rosa	Cañete	Colomer	3696560011	Cuesta Violeta Farré 48 León, 54683
33197960	Milagros	\N	Toro	Fuente	3293777923	Via Irma Nicolau 70 Apt. 42  Salamanca, 32571
54917025	Borja	\N	Catalá	Gual	3796021830	Via de Constanza Ureña 126 Puerta 5  Burgos, 43676
11407392	Vicente	\N	Rueda	Garcés	3242073197	Avenida de Leopoldo Dávila 21 Málaga, 69509
29175840	Wilfredo	\N	Cantón	Vallés	3591975692	Ronda de Julia Lobo 16 Apt. 69  Badajoz, 34476
18321669	Teobaldo	Eloísa	Muñoz	Ojeda	3632938299	Pasaje Inmaculada Prieto 34 Granada, 61120
89350126	Brígida	Benigna	Rivero	Cañizares	3142597270	Camino Gisela Valenciano 9 Puerta 3  Pontevedra, 85908
43766203	Fabiana	\N	Mas	Garzón	3889058252	Callejón de Edmundo Llamas 10 Zaragoza, 05990
90074381	Loida	Bonifacio	Alemany	Osuna	3164148712	Paseo de Ascensión Galván 930 Cantabria, 88747
63708345	Juanito	José Mari	Checa	Sosa	3758979454	Callejón de Hector Sandoval 3 Cuenca, 04516
96803020	Edgardo	\N	Ortega	Bello	3656259274	Acceso de Bonifacio Roselló 454 Apt. 46  Lleida, 62918
87976611	Juan	\N	Hoz	Buendía	3304106067	C. de Florentino Marti 467 Apt. 32  Ávila, 50310
99191740	Faustino	Desiderio	Gargallo	Mur	3730659603	Callejón Ágata Quesada 42 Piso 8  Navarra, 79126
21465615	Chus	\N	Ordóñez	Ropero	3989978748	Glorieta de Luis Ángel Salamanca 27 Apt. 33  Albacete, 37267
53556359	Almudena	\N	Roca	Ponce	3973476588	Pasadizo de Roberto Alvarez 10 Huesca, 89922
95045828	Almudena	Cosme	Barrena	Abad	3813872000	Cuesta de Sancho Vallés 28 Las Palmas, 36618
38848889	Cristóbal	\N	Porcel	Castro	3642973300	Pasadizo de Corona Santamaría 97 Piso 7  Tarragona, 35043
45010340	Ramona	Ciríaco	Requena	Mas	3285571867	Via de Chus Manuel 30 Piso 2  Cuenca, 31322
61211250	Purificación	Cebrián	Solsona	Fábregas	3549960813	Avenida Amílcar Barragán 9 Santa Cruz de Tenerife, 77713
77712727	Rosa María	Anastasia	Mayo	Francisco	3950687188	Callejón Eugenio Malo 4 Puerta 3  Valladolid, 25214
36635887	Miguel	\N	Terrón	Giralt	3342877341	Alameda de Ligia Borrás 7 Puerta 7  Córdoba, 09044
53042587	Reyna	\N	Malo	Nieto	3236596276	Plaza de Albano Torrens 1 Apt. 52  Cantabria, 02361
16312487	Victoriano	Hortensia	Salcedo	Serra	3782930408	Vial de Ciriaco Miró 54 Guipúzcoa, 90929
57050534	Rosa	Aura	Dalmau	Cabrera	3275517112	Glorieta de Ariel Gutierrez 1 Girona, 51296
88328449	Octavio	\N	Ojeda	Andrés	3592348404	Pasadizo Candela Navarrete 77 Piso 0  Zaragoza, 28464
92952186	Eusebio	Francisco Javier	Manrique	Girona	3113976540	Alameda Rico Godoy 77 Burgos, 70243
99507363	Nando	\N	Mesa	Montero	3802295431	Pasadizo de Virginia Cabello 35 Asturias, 02030
59275905	Juan Luis	\N	Machado	Cuevas	3696846750	Vial Íñigo Benítez 2 Puerta 2  Soria, 49826
45028641	Julieta	Iris	Rosselló	Chico	3591126834	Rambla Bartolomé Tenorio 2 Barcelona, 40660
39804577	Victorino	Ana Sofía	Andrés	Fortuny	3586453288	Cañada de Amarilis Neira 258 Badajoz, 88359
10111477	Marianela	Bernarda	Valle	Gelabert	3434987576	Alameda Hilario Iniesta 14 Apt. 03  Córdoba, 16363
92612552	Iris	\N	Ribas	Lledó	3308029149	Via Edmundo Cadenas 643 Apt. 23  Salamanca, 46829
56836415	Gregorio	Priscila	Garzón	Arregui	3149874727	C. Silvestre Tomás 77 Piso 4  Palencia, 58703
40685943	Artemio	\N	Expósito	Rodriguez	3642215463	Pasadizo de Teobaldo Plana 821 Palencia, 96967
68057810	Feliciano	Emiliana	Gallego	Sevillano	3250225082	Camino de Priscila Pi 34 Piso 3  Murcia, 42992
73121370	Melisa	\N	Trujillo	Acuña	3690670085	C. de María José Iñiguez 14 Albacete, 12997
71432299	Evaristo	\N	Corominas	Vera	3849986081	Alameda Ruy Barragán 1 Valladolid, 85571
48738998	Pepito	\N	Pujol	Tena	3303528562	C. de Alejo Izaguirre 4 Castellón, 52168
79272759	Anastasia	\N	Alarcón	Salom	3189849697	Urbanización Natanael Ferreras 25 Apt. 82  Huesca, 32930
71666564	Íngrid	Ruben	Juárez	Escamilla	3919813705	Vial Jesús Palomar 33 Córdoba, 41137
33587138	Belén	Armando	Trujillo	Marín	3192092999	Alameda de Nélida Jurado 46 Almería, 89057
92427279	Calixta	\N	Sáez	Vilanova	3468604795	Pasadizo de Daniel Escobar 562 Puerta 8  Valladolid, 46749
84059386	Eusebio	Manuela	Jiménez	Raya	3843732845	Pasaje de Borja Camino 18 Apt. 87  Las Palmas, 78345
77904836	Constanza	Angelina	Acedo	Castrillo	3536352848	Cuesta Sigfrido Borrás 44 Puerta 5  Zaragoza, 03199
83604072	Ágata	Isidoro	Díez	Soler	3298588211	Callejón Rafaela Mosquera 97 Apt. 40  Cantabria, 20531
58254643	Maricruz	\N	Escolano	Amorós	3476667229	Cuesta Tito Arjona 90 Piso 6  Lugo, 04434
56902842	Consuelo	\N	Gutiérrez	Poza	3579333579	Avenida Adrián Jódar 36 Apt. 66  La Rioja, 37011
35800359	Alfonso	Jose Ignacio	Cuadrado	Anglada	3335164517	Camino de Susana Mena 796 Puerta 3  Las Palmas, 52103
34909955	Zaira	Ascensión	Piñol	Porta	3730771910	Plaza de Iván Marqués 45 Piso 7  Zaragoza, 68689
31755782	Esther	\N	Amorós	Gonzalo	3223973847	Avenida de Águeda Peñas 2 Segovia, 86810
52447513	Genoveva	\N	Bauzà	Leon	3534460022	Urbanización de Jovita Blázquez 49 Ourense, 52244
73831221	Agustín	Brígida	Azorin	Baquero	3197413250	Calle de Nidia Noriega 76 Piso 0  Asturias, 88123
37620310	Jose Ignacio	Rosalinda	Menéndez	Moliner	3945802574	Paseo Azahara Niño 88 Badajoz, 85137
92142258	Chus	\N	Gracia	Olmo	3659125872	Via de Nilo Salvador 44 Ciudad, 97377
47490243	Glauco	\N	Cañas	Pedrosa	3151245046	Glorieta Severo Macias 35 Santa Cruz de Tenerife, 92167
64773195	Carolina	\N	Martín	Jerez	3816131268	Alameda de Emilia Dominguez 32 Ciudad, 11449
91362584	María Carmen	Chus	Serna	Pedro	3587148889	Cuesta Febe Agustí 3 Cantabria, 71140
52037750	Celestina	\N	Delgado	Salas	3940682016	Avenida Marisela Bayo 29 Santa Cruz de Tenerife, 75481
42489169	Ariel	Sandra	Gracia	Borrell	3527588430	Calle Aristides Ojeda 1 Tarragona, 19089
74791293	Ainara	Andrés	Busquets	Cervantes	3221392058	Glorieta Máxima Valencia 33 Apt. 04  Asturias, 78421
34285264	Amílcar	\N	Novoa	Tur	3555220414	Avenida de Iris Zabala 11 Apt. 10  Lleida, 24548
47279838	Tristán	\N	Ros	Cordero	3299294231	Rambla de Pepito Canals 69 Huelva, 68925
62904882	Luciano	Fortunata	Landa	Hervia	3897146485	Camino de Isa Ibáñez 90 Barcelona, 72960
24820454	Angélica	Luisina	Frutos	Escobar	3784536411	Avenida Régulo Piña 18 Puerta 6  Cádiz, 16755
96566774	Cándido	Ester	Escalona	Luís	3437691429	C. de Evita Bastida 11 La Coruña, 93896
30985446	Hector	\N	Cañizares	Hurtado	3956706270	Urbanización Adela Ricart 24 Piso 7  Navarra, 17789
10989151	Eva	\N	Cerdá	Mascaró	3267434870	Paseo de Isabel Galan 58 Apt. 35  Melilla, 19890
23419062	Nayara	Miguela	Tirado	Cordero	3394748437	Callejón Ramón Gabaldón 72 Apt. 31  Las Palmas, 37862
63192208	Ariadna	Adoración	Torrijos	Cuadrado	3780684250	Rambla de Rafaela Llano 68 Cantabria, 67836
34161974	Ruperta	\N	Aznar	Pascual	3850746195	Vial de Martín Estrada 563 Piso 6  Lugo, 17943
58673603	Florentina	Tomasa	Álvarez	Bolaños	3395456000	Via Teobaldo Moraleda 949 Apt. 20  Girona, 70737
34208787	Esmeralda	Manu	Vigil	Bermúdez	3515942870	Rambla de Febe Matas 49 Piso 3  Melilla, 29301
98676382	Florina	Miguel Ángel	Román	Soriano	3575787842	Via de Guadalupe Moles 72 Piso 7  Lleida, 50317
43717941	Pancho	Reinaldo	Barberá	Vidal	3934456110	Pasaje de Concha Lledó 94 Zaragoza, 99303
97504696	Valeria	Ramona	Tena	Madrid	3632346479	Vial de Reinaldo Fabra 17 Lleida, 82535
15291111	Bárbara	Aureliano	Pineda	Salcedo	3457207478	Camino de Samu Escrivá 330 Puerta 5  Pontevedra, 11430
34651472	Rufino	\N	Bellido	Rey	3598998302	Via Leire Vaquero 98 Apt. 01  Salamanca, 59100
72091926	Constanza	\N	Soto	Rocamora	3120170037	Via Micaela Pellicer 43 Sevilla, 44540
73381746	Vicente	\N	Villaverde	Nebot	3668569610	Paseo María Fernanda Guardiola 4 Piso 2  Murcia, 66835
51124972	Berto	Manuelita	Viana	Santamaría	3233725281	Glorieta de Iván Rico 20 Guipúzcoa, 86906
39629092	Marcio	\N	Gomis	Quero	3700412031	Via Mayte Aranda 72 Palencia, 93079
86595704	Rómulo	\N	Iniesta	Llamas	3841204949	C. Estrella Álamo 45 Puerta 5  Murcia, 99970
92002256	Juan Francisco	Roxana	Iglesias	Jiménez	3633688585	Via Catalina Puente 74 Huelva, 47429
73940826	Silvia	Delfina	Iglesia	Lopez	3338811708	Plaza José Antonio Antúnez 63 Baleares, 89049
92300614	Ángeles	Nereida	Casado	Vara	3593107389	Urbanización Wálter Blanco 98 Girona, 50351
67949942	Dimas	Eugenia	Diéguez	Amores	3529906425	C. de Enrique Huerta 37 Apt. 48  Asturias, 58235
56506182	Héctor	\N	Jover	Abella	3171058837	Pasadizo de Encarna Elías 33 Guipúzcoa, 77918
17360901	Saturnino	\N	Acuña	Garcés	3940414034	Vial Eusebia Lobo 649 Salamanca, 83589
31130420	Trinidad	\N	Mata	Torrijos	3331525716	Camino de María Carmen Bellido 9 Pontevedra, 41856
44932218	Carlos	\N	Plana	Alcalde	3730999309	Urbanización de Nicanor Marqués 14 Apt. 43  Asturias, 87171
53621575	Sandra	Cornelio	Arroyo	Cobos	3207698918	Vial de Enrique Miguel 47 Puerta 0  Asturias, 61448
83106649	Albano	Sara	Carlos	Sacristán	3872109364	Plaza de Sarita Cabo 41 Palencia, 25709
71057314	Camilo	Merche	Olivares	Gallardo	3785606385	C. Magdalena Mosquera 672 Murcia, 57927
36483984	Jimena	Augusto	Batalla	Viñas	3296771603	Avenida de Cloe Robles 411 Apt. 43  Zamora, 33408
99415387	Teobaldo	\N	Colom	Porcel	3137172513	Plaza Maite Cárdenas 364 Piso 3  Las Palmas, 55688
60370313	Olga	\N	Oliveras	Gallo	3833645584	Avenida de Mohamed Pont 73 Guadalajara, 87056
13527761	Anita	\N	Sobrino	Cabo	3887863033	Pasaje de Ruth Vazquez 40 Toledo, 14350
47010839	Estela	Vasco	Cabrera	Falcó	3946607632	Paseo Epifanio Calzada 692 Apt. 09  Madrid, 60576
62226799	Tecla	Lina	Pereira	Amo	3304880142	C. de Ámbar Mariño 559 Puerta 5  Alicante, 96325
63957644	Remedios	Ascensión	Pombo	Osuna	3604028525	Glorieta Florencia Acero 64 Piso 0  Álava, 45705
96438990	Cebrián	\N	Núñez	Feliu	3746615675	Avenida de Adriana Salgado 407 Zaragoza, 69210
92818753	Griselda	\N	Gual	Baeza	3105516425	C. de Fabricio Pou 501 Apt. 82  Huesca, 20151
15396320	Iris	Tiburcio	Pla	Arenas	3283965740	Plaza Espiridión Vizcaíno 5 Girona, 75860
30567173	Joan	\N	Simó	Ballesteros	3715925866	Paseo Ciro Aznar 72 Madrid, 13774
48739976	Clotilde	Aránzazu	Martínez	López	3576322869	Camino de Belén Alvarado 370 Puerta 4  Sevilla, 69865
20059196	Plácido	Martina	Tena	Coca	3599346066	Avenida Silvestre Bello 329 Puerta 5  Baleares, 89568
24478058	Socorro	Javiera	Castejón	Cuevas	3468718107	Rambla de Bernardita Cerezo 74 Valencia, 43002
55162157	Morena	Nydia	Ferrándiz	Ramis	3639206539	C. de Susana Díaz 343 Puerta 7  Albacete, 98944
99744616	Bienvenida	Charo	Arribas	Robledo	3193386508	Glorieta Cebrián Jaume 95 Piso 2  Álava, 13737
52462374	Blas	\N	Fernández	Giménez	3771824812	Plaza de María José Mateos 38 Puerta 6  Ourense, 07473
93437116	Severino	\N	Blazquez	Suárez	3857240926	Cuesta Abril Ferrera 955 Apt. 12  Zamora, 87744
93240789	Eduardo	\N	Elías	Cano	3783281915	Urbanización Irene Acosta 36 Apt. 89  Pontevedra, 66802
81616065	Jovita	Gonzalo	Camino	Viña	3634242380	Pasadizo Nydia Aragón 622 Zaragoza, 19524
36753193	Odalys	Genoveva	Valenzuela	Escamilla	3448348712	Calle de Donato Solera 18 Piso 5  Cuenca, 53477
76608881	Dora	Mónica	Font	Valcárcel	3817654346	Avenida Román Saura 40 Apt. 62  Murcia, 57252
39276633	Amada	\N	Vilanova	Raya	3259007256	Plaza de Wálter Salamanca 105 Segovia, 37460
48235889	Chelo	\N	Vega	Gascón	3250637173	Avenida de Blanca Pareja 50 Apt. 17  Málaga, 83016
84277933	Lilia	\N	Fajardo	Tejera	3434655733	Glorieta Flora Esteve 90 Cantabria, 73285
88705046	Angelino	Santos	Palomino	Azorin	3213963217	Calle Brunilda Pulido 44 Apt. 95  Soria, 71514
18548493	Benigna	Ambrosio	Ariño	Pina	3818857638	Camino Jesusa Benavides 9 Baleares, 38137
52214654	Teo	\N	Ródenas	Sales	3703004960	Via Pacífica Toro 82 Guadalajara, 52463
30276592	Cecilia	\N	Olivares	Solé	3915623476	Camino de Juan Moles 95 Apt. 37  Cuenca, 33964
64972964	Albina	\N	Rico	Alberto	3352735512	Pasadizo de Severiano Badía 11 Piso 6  Jaén, 27057
68321045	Ariel	Lalo	Raya	Ayuso	3820486502	Acceso Clímaco Sotelo 64 La Rioja, 12323
18519932	María	\N	Arnaiz	Robles	3849484170	Avenida de María Manuela Cerdá 114 Salamanca, 24203
28776521	Loreto	\N	Huertas	Saldaña	3425645137	Glorieta de Felisa Atienza 835 La Coruña, 33476
76479972	Alberto	\N	Pedraza	Conesa	3163761142	Callejón de Julio César Sarmiento 28 Guadalajara, 11334
27134017	Marcelino	Moisés	Arrieta	Pons	3361982823	Callejón Darío Coronado 51 Piso 8  Córdoba, 99131
59711019	Tomasa	Débora	Pol	Maza	3176390161	Plaza de Sofía Durán 58 Puerta 1  Guipúzcoa, 74356
39209894	Priscila	\N	Pizarro	Arregui	3507414701	Vial de Olga Agudo 60 Almería, 19823
29159589	Valentina	Chelo	Hervás	Mercader	3515938689	Ronda de Rosalina Falcón 2 Cuenca, 17094
85389469	Amado	Demetrio	Plaza	Rovira	3825109547	Camino Águeda Velázquez 454 Apt. 43  Huesca, 41961
67637624	Gala	\N	Hoz	Almansa	3121814782	Cañada de Gisela Chaves 71 Piso 2  Cantabria, 90446
99679824	Ambrosio	\N	Nogueira	Baños	3275893936	Cuesta Joan Ramírez 3 Piso 6  Málaga, 50941
54882687	Carolina	Jose Miguel	Hervia	Quirós	3157024487	Pasadizo de Reinaldo Cano 66 Madrid, 08583
87795566	Isidoro	Emilio	Malo	Vargas	3525185963	Camino Catalina Torrijos 18 Piso 7  Alicante, 31636
68806648	Nélida	\N	Rivero	Alcaraz	3300875333	Camino de Imelda Anglada 35 Segovia, 02138
49763640	Santos	Yaiza	Moreno	Cuervo	3489580164	Rambla Jose Miguel Santamaria 64 Puerta 8  Girona, 74249
64826295	Ildefonso	\N	Vilanova	Isern	3284740372	Urbanización de Hernán Oller 62 Puerta 3  Soria, 04014
76861122	Buenaventura	Consuela	Corbacho	Perera	3628478579	Cuesta de Aránzazu Font 75 Puerta 0  Asturias, 74755
27654414	Pedro	\N	Olivares	Mateo	3216098077	Alameda de Carlito Gracia 55 Las Palmas, 12666
62285381	Ángela	Pedro	Pellicer	Llobet	3819171393	Ronda Abraham Rubio 289 Salamanca, 30015
69243195	Ana Belén	\N	Garriga	Collado	3959473771	Paseo de Rogelio Coca 476 Apt. 97  Burgos, 32710
80987640	Melania	\N	Adán	Prado	3555470841	Via Aurelio Viana 38 Apt. 53  Cáceres, 40974
19778222	José Antonio	\N	Hidalgo	Borrell	3942002107	Glorieta Julio César Caballero 5 Puerta 3  Zaragoza, 80985
28529887	Onofre	\N	Abellán	Porta	3427964104	Camino José María Alsina 728 Ourense, 67386
87631236	Saturnina	\N	Gimeno	Badía	3841247197	Via Albina Rosselló 21 Apt. 97  Lleida, 80506
54252306	Natanael	\N	Chaparro	Dominguez	3909983798	Acceso de Daniel Sosa 75 Puerta 6  Badajoz, 14621
98092291	Corona	Francisco	Nevado	Ródenas	3285441587	Cuesta de Jose Miguel Fiol 693 Piso 0  Murcia, 27756
49701906	Chelo	\N	Busquets	Benito	3365677910	C. Eleuterio Caballero 329 Piso 3  Segovia, 92711
25586737	Mohamed	Pelayo	Badía	Plana	3698609968	C. Maricruz Taboada 94 Apt. 53  Baleares, 39741
37232440	Cristina	Rosaura	Redondo	Luís	3841223014	Pasaje de Encarna Cantón 76 Tarragona, 00574
14653928	Javier	Feliciano	Noguera	Ibarra	3619037844	Pasadizo Haydée Alfonso 12 Puerta 5  Pontevedra, 24739
50551138	Visitación	Florentina	Escamilla	Camps	3182759177	Vial de Juan Bautista Losa 746 Madrid, 28920
87205041	Lina	\N	Gutiérrez	Ángel	3898955389	Glorieta de Ani Alba 39 Apt. 24  Cantabria, 66147
97940757	Filomena	\N	Galvez	Ariza	3519586171	Calle Macarena Amador 75 Burgos, 45857
63462355	Otilia	Nilo	Santamaria	Nieto	3910096858	Ronda Ana Monreal 923 Apt. 95  Toledo, 05054
68455495	Ester	\N	Valls	Esteve	3709476986	Via José Manuel Mosquera 21 Burgos, 67821
43439936	Manu	Maxi	Diego	Landa	3745156936	Urbanización Leandro Saavedra 81 Apt. 13  Ávila, 51745
44051108	Milagros	Jessica	Mendizábal	Lumbreras	3908480314	Alameda Perla Juliá 47 Puerta 9  Cádiz, 29875
60504428	Teresa	Carmen	Zapata	Martínez	3735294047	Via de Octavia Granados 81 Valladolid, 30983
12981038	Carlota	\N	Vicens	Bernat	3591778471	Alameda de Cayetana Barrena 15 Guadalajara, 70756
10824957	Lilia	\N	Giménez	Jimenez	3902580568	Plaza de Soraya Barranco 688 Alicante, 96636
34457215	Olegario	\N	Olivé	Agullo	3494668522	Urbanización Domitila Sedano 8 Santa Cruz de Tenerife, 58480
24249956	Esperanza	\N	Iborra	Marin	3398959820	Ronda de Chita Escobar 58 Puerta 2  Lleida, 23701
30096589	Andrés	\N	Fabra	Zabaleta	3599837387	Glorieta Alexandra Jove 8 León, 01589
27867352	Noelia	Aureliano	Berenguer	Riba	3188301476	Via de Teobaldo Becerra 30 Apt. 30  Cádiz, 41585
89535908	Cayetano	Jose Angel	Arce	Burgos	3888143538	Avenida Melisa Abellán 539 Toledo, 94742
83960532	Román	Ambrosio	Coca	Barbero	3294321171	Avenida Araceli Quiroga 562 Apt. 18  Córdoba, 04493
76817721	Ciríaco	\N	Conesa	Pombo	3978468017	Camino de Luisa Hernández 10 Apt. 96  Sevilla, 44901
39015912	Rafaela	\N	Blazquez	Diéguez	3481271201	Calle de Agapito Alonso 28 Cuenca, 02657
86959282	Nydia	Morena	Bejarano	Tomás	3253333782	Vial Vicenta Carlos 82 Baleares, 12969
72884591	Victoriano	\N	Rodriguez	Coronado	3947272923	Avenida de Nadia Verdejo 77 Piso 4  Córdoba, 55055
10255746	Martín	\N	Quiroga	Contreras	3861626445	C. Merche Bernad 14 Puerta 4  Vizcaya, 62915
51308977	Jenny	\N	Martin	Llamas	3560314633	Vial Lalo Bustamante 76 Cuenca, 84030
45863185	Javi	\N	Méndez	Clemente	3623057815	Glorieta de Agustín López 4 Piso 3  La Rioja, 57818
87474195	Julie	Sara	Cerro	Benet	3742384449	Avenida Juan Manuel Cantero 87 Piso 0  Madrid, 32390
83980798	Dolores	Reynaldo	Cabeza	Jáuregui	3546430873	Pasaje Lupita Corominas 816 Apt. 78  Huesca, 57782
49075152	Amalia	\N	Garriga	Vergara	3390939337	Cuesta de Emelina Garrido 380 Huelva, 18348
20394920	Micaela	Isabel	Rosell	Sarabia	3866380081	Alameda de Ariadna Ariño 90 Piso 0  Barcelona, 77726
34146779	Francisca	Carolina	Marco	Sans	3390614382	Acceso Julieta Abril 33 Ourense, 27838
68613921	Rico	Roxana	Antón	Cuenca	3353007339	Callejón de Anastasio Castell 58 Lugo, 87563
38657790	Lázaro	Olegario	Laguna	Planas	3161170435	Camino Lucas Bernad 69 Puerta 4  Cádiz, 73473
89556786	Amarilis	Néstor	Galiano	Peral	3649288643	Pasadizo de Alondra Araujo 88 Valladolid, 93772
59750565	Guadalupe	Benjamín	Arcos	Pedraza	3816244611	Callejón Victor Piquer 2 Apt. 15  La Coruña, 51337
50575991	Zacarías	\N	Llamas	Peña	3220187402	Rambla Milagros Menendez 497 Piso 4  Palencia, 62223
89476491	Osvaldo	\N	Girón	Velasco	3385354764	Calle de Jose Manuel Martin 309 Puerta 5  Cuenca, 01276
28077997	Tomasa	Carina	Andrade	Mancebo	3137694524	Via de Carla Sola 55 Piso 8  Pontevedra, 39556
95294234	Loida	Apolinar	Villalba	Aramburu	3326322960	Urbanización Atilio Correa 14 Cáceres, 03780
16660549	Marino	Montserrat	Barberá	Rodríguez	3162128785	Avenida Graciana Dalmau 21 Álava, 52453
20998153	Georgina	\N	Sacristán	Cortina	3604930711	Glorieta Feliciana Almazán 43 Guipúzcoa, 07815
32938506	Bernardo	Jovita	Villegas	Llanos	3306822741	Rambla de Nicanor Aguilar 54 Guadalajara, 61991
68654786	Seve	Edelmiro	Isern	Mora	3702071745	Rambla Socorro Garay 75 Puerta 4  Huelva, 50525
63719062	Ovidio	\N	Serra	Almazán	3530064275	Pasaje de Esther Torrens 7 Zaragoza, 98637
16664496	Santos	Ofelia	Alemany	Aragón	3412215925	Cañada de Rolando González 43 Piso 7  Huesca, 01256
36622777	Vito	\N	Uría	Lerma	3143636997	Calle Fabricio Zorrilla 7 Puerta 2  Castellón, 57097
57048632	Rosendo	\N	Giralt	Palma	3956273851	Plaza Elisa Rojas 51 Puerta 3  Soria, 74147
76857581	Angelita	Alejo	Canals	Soria	3853443258	Via Aurelio Pou 117 Salamanca, 98726
53040687	Albina	Calisto	Lladó	Gómez	3194320304	Acceso de Silvia Perera 86 Huelva, 61564
80273751	Erasmo	\N	Lasa	Vazquez	3331970742	Cuesta Javier Tolosa 574 Murcia, 13109
89778176	Haroldo	\N	España	Trillo	3944279534	Via Manu Pinto 74 Ourense, 30180
84115953	Manola	Jose Manuel	Pons	Castañeda	3602042030	C. Samuel Estevez 727 Teruel, 29245
58199989	Paca	\N	Arrieta	Cardona	3369571118	Acceso Toni Pereira 48 Ourense, 69687
69344915	Leocadia	\N	Pizarro	Pablo	3110806573	C. de Maricela Sans 8 Lugo, 26025
90226009	Ciriaco	\N	Gallart	Tena	3384353254	Vial de Augusto Burgos 77 Piso 3  Valladolid, 02911
74560252	Leonor	\N	Valero	Gallart	3524965191	Calle Manuel Corominas 46 Apt. 19  Ourense, 24411
17554831	Aarón	\N	Garay	Verdejo	3240388011	Callejón Candelaria Galván 24 Puerta 8  Burgos, 23172
34888458	Elisabet	Marco	Córdoba	Macías	3952789526	Callejón Úrsula Lozano 36 Piso 5  Huesca, 52941
54908650	Rafaela	Sabas	Arellano	Estrada	3272311243	Cañada Luz Coello 37 Puerta 4  Navarra, 59113
89929183	Virginia	Juliana	Ballester	Berenguer	3181404681	Paseo Charo Larrea 72 Piso 0  Madrid, 09248
13540219	Nando	\N	Iriarte	Iborra	3582094268	Ronda Amancio Merino 81 Apt. 11  Salamanca, 57777
88696014	Perla	Cándida	Bilbao	Leal	3345575515	Urbanización Marina Lopez 42 Huelva, 46440
19531314	Encarnita	Mayte	Royo	Mata	3319470464	Avenida de Cecilia Villa 27 Piso 8  Valencia, 45086
76462292	Nazaret	Nayara	Alcázar	Rueda	3915182159	Cuesta de Nuria Guzmán 57 Guadalajara, 40218
78870059	Susana	\N	Domingo	Serrano	3434284214	Glorieta Amelia Valencia 65 Cádiz, 11023
17027961	Cristóbal	\N	Vallejo	Rivas	3977295874	Callejón Maximino Aguirre 15 Álava, 49669
48454022	Kike	Isaac	Campo	Delgado	3495959755	Plaza de Adora Arteaga 491 Cantabria, 53758
93313812	Danilo	\N	Morata	Carrión	3209000552	C. de Dan Arribas 53 Lleida, 93805
62042873	Perlita	\N	Arteaga	Perales	3161436000	Cañada Jennifer Campoy 76 Piso 6  Cuenca, 67455
63824135	Eliseo	\N	Blázquez	Martin	3679400183	Avenida Ángeles Luna 57 Apt. 94  Albacete, 36337
14704115	Lina	Natalia	Caparrós	Manso	3952285368	Urbanización de Reina Bonet 3 Puerta 4  Guipúzcoa, 07013
51443517	Severino	Yéssica	Ledesma	Diez	3133754008	Plaza Teodora Córdoba 928 Apt. 33  Almería, 96931
92189641	Estrella	Rafaela	Alvarado	Flor	3314757394	Acceso Inocencio Pereira 950 Asturias, 47818
37192031	Consuela	\N	Rodrigo	Páez	3507883009	Plaza Marta Berrocal 53 Valladolid, 88085
21547319	Sara	\N	Arnaiz	Amat	3624534622	Pasadizo de Amor Tello 27 Huesca, 94804
15442259	Ale	\N	Paredes	Fabregat	3166779548	Avenida de Íñigo Juan 41 Puerta 9  Valladolid, 51295
47220407	Rebeca	\N	Martin	Mendez	3587971581	Urbanización de Mónica Armas 18 Badajoz, 72179
51371722	Eric	Bautista	Cuervo	Rozas	3616318406	Urbanización de Nerea Guardiola 25 Piso 0  Zamora, 10047
24737567	Roberto	Andrés Felipe	Chamorro	Leiva	3751553190	Urbanización Inés Galan 46 Piso 6  León, 62959
41317389	Dorita	Nacio	Palomo	Gibert	3276182522	Via de José Ángel González 56 Apt. 26  Jaén, 56442
92467440	Fabricio	\N	Catalá	Serra	3555879445	Plaza de Maxi Cabo 20 Apt. 53  Segovia, 42739
24848664	Rosario	\N	Arnau	Nuñez	3803295568	Alameda África Olivares 20 Huesca, 48952
15384725	Amor	\N	Viñas	Calvo	3567910750	Glorieta de Narciso Hoz 254 Apt. 29  Álava, 12242
83348156	Esther	\N	Prado	Iñiguez	3501276543	Callejón de Severino Falcó 11 Piso 8  Badajoz, 15906
29698150	Bautista	\N	Tejada	Fuentes	3390154964	Callejón Noa Navarro 74 Puerta 5  Asturias, 18164
36694463	Chucho	Lorenza	Donoso	Pascual	3987572471	Urbanización Asdrubal Ávila 87 Piso 1  Salamanca, 87558
74182499	Carlito	Itziar	Feliu	Cerdá	3987778953	Cañada de Narciso Bello 19 Alicante, 22474
90264366	Roldán	Espiridión	Arco	Morillo	3785642378	Pasaje Dominga Arroyo 33 Valladolid, 05602
42259513	Leire	Julie	Mateos	Naranjo	3746196462	Calle de Candelaria Costa 255 Apt. 17  Segovia, 02902
13443183	Emperatriz	\N	Sierra	Galiano	3462213546	Camino de Mauricio Bellido 94 Apt. 71  Palencia, 54620
45270539	Nilo	\N	Campillo	Manzanares	3304789759	Vial Marisa Borrego 48 Huelva, 57655
64089728	Leire	\N	Piñol	Valencia	3742762359	Ronda Amor Figueras 55 Barcelona, 45964
70473069	Rita	Anunciación	Valera	Morillo	3277648530	Via Víctor Colomer 776 Segovia, 40162
98911307	Curro	Cipriano	Bartolomé	Feliu	3913119980	Urbanización Lupe Estévez 356 Apt. 33  Sevilla, 78461
46256936	Perlita	\N	Cifuentes	Giner	3799202306	Rambla de Beatriz Díaz 1 Puerta 6  Cáceres, 19025
88946381	Lola	\N	Crespo	Simó	3437881708	Vial de Abril Bautista 70 Málaga, 86797
97471748	Aureliano	\N	Saavedra	Martorell	3296176925	Pasadizo Trinidad Tenorio 678 Piso 4  Lleida, 70201
94923432	Reyes	Lourdes	Sebastián	Arnal	3150197387	C. Mauricio Peñas 86 León, 99571
57026905	Norberto	\N	Osuna	Gras	3903677254	Vial de Corona Uribe 20 Lleida, 84986
30124446	Asunción	\N	Esteve	Salgado	3228682275	Cuesta de Lorena Gelabert 7 Puerta 7  Cádiz, 86196
84490679	Olimpia	Nazaret	Bonet	Ferrera	3264595236	Paseo Jose Antonio Seguí 60 Piso 0  Teruel, 61448
31797913	José Ángel	Yésica	Villaverde	Pedro	3210204435	Callejón de Cornelio Benitez 61 Madrid, 15213
67563715	Flavio	Bibiana	Uriarte	Tejedor	3389923278	Paseo de Rosenda Carnero 3 Lleida, 95850
51799484	Victorino	\N	Álvarez	Gallart	3669728024	C. Román Macías 875 Pontevedra, 60917
29803975	Alejandra	Diana	Valbuena	Delgado	3460108367	Cuesta de Guadalupe Ariza 185 Apt. 99  Sevilla, 72058
18278979	Delfina	Xavier	Nadal	Moraleda	3882179185	Pasadizo Teresita Escobar 92 Piso 5  Navarra, 65412
32342818	Amaro	\N	Prada	Amigó	3199624288	Plaza Plácido Segura 3 Albacete, 95783
55643878	Valero	Haroldo	Pagès	Puerta	3885921226	Pasaje Jovita Cortes 572 Piso 0  Palencia, 45001
16401494	Jesusa	Tecla	Daza	Marín	3970907663	Cañada Inocencio Berrocal 30 Lleida, 27474
76795808	Luis Miguel	Amílcar	Escolano	Catalán	3882935080	Glorieta Abraham Mendoza 6 Apt. 49  Huesca, 98370
11211064	Mar	\N	Almansa	Coello	3819150606	Pasadizo de Jerónimo Iglesias 29 Piso 7  Vizcaya, 12788
47725313	Dominga	Clímaco	Godoy	Portero	3545992430	Callejón de Apolonia Cortina 68 Piso 8  Segovia, 63055
67396604	Anselmo	\N	Morera	Expósito	3462632262	Calle de Úrsula Quintana 5 Ciudad, 73151
96253687	Salomón	\N	Cervantes	Leiva	3383872427	Glorieta Macario Nebot 89 Cádiz, 93195
16964183	Dorotea	Rosa María	Narváez	Escalona	3795919995	Pasadizo Jovita Sarmiento 6 Piso 1  Murcia, 68765
53915539	Ale	\N	Calzada	Portero	3491270594	Pasaje Efraín Monreal 8 Apt. 51  Asturias, 01793
13156015	Leonor	Tere	Nogueira	Talavera	3524179878	Plaza de Ciro Almeida 4 Ávila, 24284
51892316	Esther	\N	Blazquez	Valls	3160345986	Vial de Anastasia Millán 31 Jaén, 43722
15917809	Bautista	\N	Barrios	Escobar	3574839397	Acceso de Ruperto Sedano 7 Apt. 19  Teruel, 51571
75819207	Segismundo	Norberto	Peiró	Angulo	3602164574	Plaza Merche Díaz 5 Teruel, 42150
\.


                                                                                                                                                                                                                                                                                                                                                                                           5009.dat                                                                                            0000600 0004000 0002000 00000000776 15015340177 0014264 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        8	ATLANTICO	170
11	BOGOTA	170
13	BOLIVAR	170
15	BOYACA	170
17	CALDAS	170
18	CAQUETA	170
19	CAUCA	170
20	CESAR	170
23	CORDOBA	170
25	CUNDINAMARCA	170
27	CHOCO	170
41	HUILA	170
44	LA GUAJIRA	170
47	MAGDALENA	170
50	META	170
52	NARIÑO	170
54	NORTE SANTANDER	170
63	QUINDIO	170
66	RISARALDA	170
68	SANTANDER	170
70	SUCRE	170
73	TOLIMA	170
76	VALLE	170
81	ARAUCA	170
85	CASANARE	170
86	PUTUMAYO	170
88	SAN ANDRES	170
91	AMAZONAS	170
94	GUAINIA	170
95	GUAVIARE	170
97	VAUPES	170
99	VICHADA	170
5	ANTIOQUIA	170
\.


  5027.dat                                                                                            0000600 0004000 0002000 00000000005 15015340177 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5024.dat                                                                                            0000600 0004000 0002000 00000000005 15015340177 0014242 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5026.dat                                                                                            0000600 0004000 0002000 00000000005 15015340177 0014244 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5015.dat                                                                                            0000600 0004000 0002000 00000002565 15015340177 0014257 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	DULCES	Productos azucarados como chocolates, caramelos, gomitas y chicles.
2	FRITURAS	Snacks salados: papas fritas, choclitos, nachos, y otros productos similares.
3	BEBIDAS NO ALCOHÓLICAS	Refrescos, jugos, aguas embotelladas, tés y bebidas energéticas.
4	LICORES	Bebidas alcohólicas: whisky, vodka, ron, cervezas artesanales, etc.
5	PRODUCTOS DE LIMPIEZA	Detergentes, desinfectantes, jabones para ropa, limpiadores multiusos.
6	ENLATADOS	Alimentos en conserva: atún, frijoles, vegetales, sopas y frutas en lata.
7	CUIDADO PERSONAL	Artículos de higiene: jabones, shampoos, pasta dental y pañales.
8	PANADERÍA	Productos horneados empaquetados: pan de caja, galletas, pasteles.
9	LÁCTEOS	Leche, yogur, quesos, mantequilla y otros productos derivados de la leche.
11	PASTAS Y ARROCES	Fideos, macarrones, arroz blanco, integral y otras variedades.
12	CEREALES	Cereales de desayuno: hojuelas, granola, avena y similares.
13	CONDIMENTOS Y SALSAS	Mayonesa, mostaza, salsas de tomate, soya, picantes y vinagretas.
15	BEBIDAS ALCOHÓLICAS ARTESANALES	Cervezas y licores producidos artesanalmente, de origen local o importado.
16	HIGIENE DEL HOGAR	Papel higiénico, servilletas, toallas de cocina, esponjas, guantes.
17	PRODUCTOS RELIGIOSOS	Velas, inciensos, imágenes religiosas, biblias y artículos devocionales.
18	DESECHABLES	Vasos, platos, cubiertos y otros utensilios de un solo uso.
\.


                                                                                                                                           5013.dat                                                                                            0000600 0004000 0002000 00000017505 15015340177 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        A554	2026-02-24
Q670	2027-12-31
L797	2027-04-10
S673	2028-02-19
P885	2028-04-26
L976	2027-10-26
B835	2028-08-08
E613	2028-04-04
Z557	2028-03-31
M112	2028-10-11
D445	2028-05-13
S957	2026-12-16
B265	2025-12-25
P555	2027-07-21
D823	2028-04-21
Q178	2026-05-10
C102	2028-03-07
F894	2029-05-30
F246	2028-10-26
C494	2026-06-23
U982	2028-08-02
Y195	2029-03-27
Z109	2028-09-10
I105	2027-12-27
L390	2027-05-31
I067	2026-02-18
N023	2028-11-12
V999	2026-01-31
X080	2025-12-04
V477	2028-09-21
B148	2026-12-27
Z018	2029-01-17
V411	2026-03-28
R300	2028-02-23
K985	2026-01-14
E622	2028-10-11
R019	2026-12-07
M934	2026-01-05
C635	2028-06-13
R333	2029-01-14
U372	2028-09-09
H925	2027-07-31
Y291	2026-06-01
F333	2028-04-13
C965	2028-12-19
O608	2025-12-06
P075	2026-06-03
Z666	2026-05-10
Y795	2025-12-24
G628	2027-04-26
Z688	2026-06-23
K095	2027-02-02
H053	2026-09-30
M981	2026-01-31
D098	2027-06-23
N989	2026-05-31
P044	2026-10-22
I750	2027-04-30
X573	2027-08-03
I617	2026-03-21
P727	2028-06-03
H156	2028-11-06
O114	2027-03-16
L757	2027-06-05
H927	2027-07-29
E909	2028-07-31
D105	2026-03-26
H707	2026-06-17
M116	2026-01-03
S207	2027-12-19
U007	2028-01-18
B276	2029-05-16
S426	2026-09-18
A065	2025-12-21
X510	2027-02-12
T250	2026-10-29
Q986	2027-10-08
Q815	2026-07-16
X552	2028-12-19
D578	2029-01-27
W054	2029-02-11
A454	2029-03-31
K951	2029-06-30
F269	2027-01-11
H902	2027-05-29
R237	2027-02-18
U010	2028-10-25
W210	2027-01-22
V178	2027-03-19
V995	2029-05-08
N424	2027-11-24
F506	2027-11-02
N250	2028-09-03
S866	2028-05-14
A780	2028-12-07
E364	2026-04-15
H582	2027-10-15
U367	2027-07-03
P827	2027-03-08
R143	2027-04-18
L278	2029-04-13
M905	2028-04-14
U949	2027-09-01
B102	2027-04-27
C337	2026-07-23
T444	2028-07-23
O685	2027-03-18
T596	2026-02-03
I806	2028-07-19
Q993	2027-07-12
G073	2027-07-25
V454	2027-03-18
D769	2028-05-05
R397	2026-04-24
B727	2026-01-29
F716	2028-07-30
X537	2028-02-06
D630	2027-10-09
Z975	2026-10-28
G777	2029-01-06
D201	2026-02-18
L100	2027-03-29
E258	2029-06-02
C699	2027-04-18
E073	2027-08-11
K592	2028-05-16
D094	2028-02-03
X090	2029-02-15
H146	2026-04-02
Q595	2027-11-20
A247	2029-01-16
D796	2027-07-21
S078	2028-10-31
B716	2028-08-17
C502	2028-07-03
K382	2026-07-04
U816	2028-08-13
K358	2029-01-31
P531	2027-01-22
J960	2028-04-11
T967	2027-02-08
X574	2027-09-28
C819	2028-12-14
I735	2027-08-07
K318	2026-02-24
I023	2027-06-12
C918	2026-01-15
Q246	2028-03-11
N246	2026-06-05
F701	2028-12-07
E422	2028-07-29
U274	2027-04-15
D215	2028-07-02
Z323	2027-09-12
W510	2028-06-21
C783	2029-04-07
S237	2027-07-07
C052	2028-03-28
F058	2027-10-06
S720	2026-05-04
D882	2027-05-26
X032	2028-04-18
H680	2028-04-20
Z710	2029-02-11
Z912	2026-04-29
K798	2028-08-13
C839	2028-03-29
O239	2027-08-09
X470	2026-10-02
L574	2028-07-09
X483	2029-02-21
C261	2026-06-25
E322	2028-06-01
O692	2029-05-17
Q636	2027-08-19
V256	2026-10-07
H769	2026-08-16
F022	2028-02-29
L080	2027-03-09
B512	2029-01-20
H080	2028-04-04
Z344	2025-12-20
H158	2029-06-28
K059	2026-12-31
L923	2025-12-08
N561	2028-04-25
A467	2029-06-07
U994	2026-11-03
P392	2026-01-02
I461	2027-06-15
S354	2025-12-05
M290	2026-02-28
A209	2028-05-11
C300	2028-09-23
I242	2026-09-14
T259	2027-02-27
F799	2027-03-26
F163	2026-06-21
M557	2027-08-04
M475	2028-02-22
Q203	2027-11-11
V911	2028-06-15
X208	2027-04-06
X909	2028-07-18
Q493	2028-06-06
U708	2028-12-01
Q168	2029-04-21
V835	2028-12-07
A618	2029-05-04
A046	2028-01-18
Y749	2028-07-26
U835	2028-07-18
V331	2028-09-12
Q275	2028-09-22
B406	2027-12-25
U126	2027-07-10
V898	2025-12-12
I623	2026-12-01
Y981	2026-05-18
G152	2028-07-29
K916	2026-02-22
O230	2028-02-21
U103	2026-12-28
J047	2029-05-30
C314	2028-11-06
B353	2025-12-09
R901	2027-02-20
G665	2029-04-10
J482	2029-05-16
U133	2027-03-05
X085	2027-01-31
A767	2026-12-01
A264	2025-12-04
P790	2028-10-22
C148	2027-05-13
E644	2026-12-31
B039	2026-05-06
G085	2027-03-05
B841	2029-03-25
S789	2026-12-31
W025	2029-01-05
F845	2027-07-12
D037	2026-06-14
D311	2028-08-08
C899	2029-03-13
Y031	2026-07-24
E021	2027-07-31
I115	2026-11-18
M930	2027-03-02
N948	2028-11-12
Q871	2027-12-03
B460	2028-05-11
J137	2028-03-01
V834	2028-11-07
S541	2029-05-17
Z003	2029-04-03
J244	2029-01-26
W826	2026-04-06
T332	2029-06-12
O383	2027-03-19
N474	2028-09-08
T300	2027-07-04
X986	2029-06-22
T397	2028-03-04
U784	2026-08-06
R027	2028-12-19
E636	2026-10-25
K661	2026-05-28
O539	2027-09-25
D173	2029-02-16
J313	2028-11-01
D846	2026-06-13
C272	2028-02-28
H010	2026-12-11
O207	2026-08-05
R475	2027-11-22
C339	2026-07-29
U922	2029-02-15
H241	2028-04-14
A110	2026-07-08
J454	2029-05-25
C297	2028-06-15
W701	2028-02-09
M950	2026-07-13
F204	2025-12-15
F249	2028-07-02
R982	2029-05-20
D229	2026-05-31
A036	2028-08-10
Y224	2027-05-10
J411	2028-07-15
R275	2029-05-31
N083	2027-10-01
M680	2026-08-16
L302	2026-09-25
I225	2027-07-14
B211	2028-12-09
M559	2028-04-17
I421	2026-07-19
R878	2028-10-15
Z014	2027-01-26
I371	2026-09-12
J839	2028-05-14
K976	2027-02-25
J082	2026-10-25
T988	2027-03-06
E470	2028-11-20
B056	2027-12-10
O047	2028-04-16
W940	2026-03-23
K240	2028-05-31
E140	2026-08-08
F710	2027-11-29
G781	2026-09-30
O715	2026-10-22
L326	2029-03-05
X270	2028-09-17
L332	2029-06-30
I842	2025-12-21
H424	2029-05-16
K495	2026-09-01
U085	2028-12-29
N646	2027-01-13
G303	2028-10-24
L611	2027-07-01
M271	2027-03-13
M743	2029-02-02
I881	2027-12-16
B666	2026-10-18
N982	2026-07-17
T082	2028-01-23
D905	2028-07-03
S094	2026-03-18
D939	2027-12-06
G724	2027-02-03
W759	2027-02-26
C983	2027-02-27
L131	2027-03-17
U198	2028-08-15
V449	2026-01-27
V754	2027-05-30
R304	2028-10-14
G544	2027-07-14
A470	2027-11-03
X193	2028-02-06
F952	2026-09-24
D872	2029-06-19
G714	2026-02-17
F362	2026-05-10
B488	2028-07-02
R742	2028-10-20
E876	2028-05-01
P309	2027-09-10
Q144	2027-02-07
A123	2027-02-17
Q892	2027-07-25
X435	2029-06-15
F031	2025-12-11
C590	2027-12-19
O901	2026-05-28
J526	2028-10-20
U460	2026-11-17
X332	2027-02-28
E239	2026-07-30
H322	2029-03-29
I046	2026-11-18
E936	2028-07-25
A960	2026-02-10
E038	2026-05-23
B818	2026-10-04
N192	2028-03-29
H098	2028-06-04
R942	2027-07-15
E057	2027-05-12
D533	2027-06-25
B307	2027-11-12
N434	2027-01-16
K595	2029-06-22
I318	2026-02-14
F202	2029-07-03
Z056	2027-01-05
C596	2026-08-16
D567	2026-04-16
C284	2029-03-06
G265	2027-09-10
R810	2026-09-05
V797	2026-03-16
G762	2027-06-01
A063	2026-11-07
I202	2029-03-03
R500	2029-06-28
T461	2028-09-30
S634	2027-05-20
P687	2028-12-21
J603	2027-03-19
X314	2028-12-03
B019	2028-01-31
H370	2028-04-28
G694	2027-05-25
V711	2028-02-18
N291	2028-02-03
A077	2026-12-25
U130	2027-01-07
Y516	2026-12-27
S943	2027-11-14
U188	2025-12-28
P917	2029-02-12
D978	2028-06-22
L251	2029-03-01
E051	2027-09-25
R384	2026-06-02
L725	2026-02-23
H556	2028-01-19
O201	2025-12-30
R960	2027-07-05
W392	2027-12-21
N010	2029-04-19
D400	2028-10-13
H068	2029-06-24
X213	2027-10-08
S680	2025-11-30
R752	2029-02-24
D660	2028-10-16
N870	2027-01-15
O876	2026-11-17
K196	2027-07-24
Z624	2027-09-09
S126	2026-11-11
I975	2028-01-27
Q795	2029-06-12
Z773	2029-06-02
B903	2028-10-04
H473	2027-03-06
L222	2028-06-24
H630	2027-12-29
O850	2028-05-02
L458	2028-05-10
E188	2027-01-23
Z504	2026-08-04
O561	2029-02-08
W229	2027-07-07
U630	2029-02-11
T952	2026-01-20
P105	2026-12-15
P139	2026-01-08
O520	2025-12-21
Q789	2027-09-19
D788	2027-04-19
F675	2029-01-02
K218	2028-09-15
U347	2027-06-02
F405	2028-09-21
G627	2029-06-20
O994	2027-04-29
H588	2027-10-08
B309	2029-04-18
C472	2026-01-10
X653	2029-01-02
E030	2027-07-20
Z141	2027-12-11
E779	2029-02-05
Q102	2026-09-12
H165	2029-01-09
B747	2028-03-28
X043	2029-04-02
K136	2026-06-20
R735	2028-08-05
G712	2026-08-14
Y426	2028-12-04
C770	2028-04-09
C311	2026-10-07
G256	2027-01-28
Z050	2028-06-20
T767	2029-01-07
H204	2028-12-17
T721	2026-02-01
Q104	2026-11-26
C508	2028-05-08
O607	2028-04-10
J480	2028-07-11
J001	2026-01-30
H620	2028-09-26
M662	2026-04-13
V310	2026-09-14
I350	2029-01-14
E933	2028-05-05
G548	2026-07-26
U908	2026-11-29
F465	2029-04-14
A722	2029-03-19
L274	2026-05-12
N727	2027-10-27
C867	2027-05-29
X412	2028-03-02
J745	2026-11-08
M371	2027-08-08
Z825	2028-02-22
J573	2027-09-05
E826	2027-01-03
I263	2027-09-26
\.


                                                                                                                                                                                           5021.dat                                                                                            0000600 0004000 0002000 00000303203 15015340177 0014245 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        289	Bebida energética Max 582	Bebida energética de alta calidad. Ideal para el hogar o negocio.	28354	288	3	H680	146	\N
290	Genérico Plus 174	Genérico de alta calidad. Ideal para el hogar o negocio.	48860	167	13	C590	\N	2
291	Genérico Selecto 630	Genérico de alta calidad. Ideal para el hogar o negocio.	15503	316	13	M905	455	\N
292	Genérico Eco 596	Genérico de alta calidad. Ideal para el hogar o negocio.	19696	618	17	P075	133	\N
293	Genérico Ligero 360	Genérico de alta calidad. Ideal para el hogar o negocio.	33089	585	8	P105	\N	2
294	Genérico Ligero 672	Genérico de alta calidad. Ideal para el hogar o negocio.	98924	660	17	M271	498	\N
295	Tequila Selecto 206	Tequila de alta calidad. Ideal para el hogar o negocio.	17684	240	4	O207	457	\N
296	Vino Max 297	Vino de alta calidad. Ideal para el hogar o negocio.	75856	386	4	I105	\N	10
297	Platanitos Fresco 870	Platanitos de alta calidad. Ideal para el hogar o negocio.	24487	270	2	M290	346	\N
298	Genérico Clásico 846	Genérico de alta calidad. Ideal para el hogar o negocio.	73516	24	17	G628	276	\N
299	Genérico Premium 290	Genérico de alta calidad. Ideal para el hogar o negocio.	43289	993	7	S673	\N	10
300	Jabón Plus 544	Jabón de alta calidad. Ideal para el hogar o negocio.	1084	136	5	H146	175	\N
301	Genérico Premium 163	Genérico de alta calidad. Ideal para el hogar o negocio.	50855	987	15	Y195	415	\N
302	Genérico Max 157	Genérico de alta calidad. Ideal para el hogar o negocio.	45807	510	11	L458	\N	6
303	Genérico Deluxe 959	Genérico de alta calidad. Ideal para el hogar o negocio.	70404	893	8	F362	\N	8
304	Bebida energética Max 286	Bebida energética de alta calidad. Ideal para el hogar o negocio.	21395	827	3	U708	\N	5
305	Cloro Premium 904	Cloro de alta calidad. Ideal para el hogar o negocio.	42834	770	5	J411	\N	1
306	Suavizante Premium 759	Suavizante de alta calidad. Ideal para el hogar o negocio.	85233	173	5	H156	199	\N
307	Turrón Ligero 937	Turrón de alta calidad. Ideal para el hogar o negocio.	5705	160	1	Z825	\N	4
308	Brandy Clásico 297	Brandy de alta calidad. Ideal para el hogar o negocio.	60328	250	4	G256	\N	9
309	Genérico Ligero 368	Genérico de alta calidad. Ideal para el hogar o negocio.	82967	578	16	P917	188	\N
310	Genérico Selecto 715	Genérico de alta calidad. Ideal para el hogar o negocio.	83597	553	12	X537	\N	1
311	Genérico Deluxe 598	Genérico de alta calidad. Ideal para el hogar o negocio.	58655	888	18	M112	\N	7
312	Genérico Selecto 275	Genérico de alta calidad. Ideal para el hogar o negocio.	83139	11	16	L923	\N	9
313	Genérico Ligero 856	Genérico de alta calidad. Ideal para el hogar o negocio.	30627	708	16	S957	\N	9
314	Genérico Premium 534	Genérico de alta calidad. Ideal para el hogar o negocio.	32697	638	13	G152	32	\N
315	Bocadillo Selecto 36	Bocadillo de alta calidad. Ideal para el hogar o negocio.	61131	800	1	C502	\N	3
316	Genérico Eco 851	Genérico de alta calidad. Ideal para el hogar o negocio.	79878	483	17	R019	\N	9
317	Genérico Clásico 662	Genérico de alta calidad. Ideal para el hogar o negocio.	31672	342	13	F675	\N	2
318	Desengrasante Plus 259	Desengrasante de alta calidad. Ideal para el hogar o negocio.	73083	897	5	U103	180	\N
319	Genérico Deluxe 784	Genérico de alta calidad. Ideal para el hogar o negocio.	38537	526	13	N246	\N	1
320	Yucas Eco 887	Yucas de alta calidad. Ideal para el hogar o negocio.	41862	686	2	V178	301	\N
321	Platanitos Premium 231	Platanitos de alta calidad. Ideal para el hogar o negocio.	97764	964	2	U010	\N	10
322	Multiusos Premium 881	Multiusos de alta calidad. Ideal para el hogar o negocio.	11451	235	5	P309	26	\N
323	Genérico Deluxe 821	Genérico de alta calidad. Ideal para el hogar o negocio.	93445	814	9	I105	342	\N
324	Genérico Premium 748	Genérico de alta calidad. Ideal para el hogar o negocio.	53230	343	6	F022	\N	1
325	Tostacos Selecto 64	Tostacos de alta calidad. Ideal para el hogar o negocio.	22210	855	2	H620	302	\N
326	Chicle Premium 943	Chicle de alta calidad. Ideal para el hogar o negocio.	88138	913	1	R810	\N	8
327	Genérico Plus 76	Genérico de alta calidad. Ideal para el hogar o negocio.	81515	64	7	U372	143	\N
328	Genérico Eco 717	Genérico de alta calidad. Ideal para el hogar o negocio.	53296	575	8	Z141	\N	9
329	Genérico Selecto 916	Genérico de alta calidad. Ideal para el hogar o negocio.	32185	266	7	G544	187	\N
330	Genérico Deluxe 506	Genérico de alta calidad. Ideal para el hogar o negocio.	98445	723	17	D311	50	\N
331	Genérico Ligero 899	Genérico de alta calidad. Ideal para el hogar o negocio.	8558	239	17	F952	\N	3
332	Genérico Plus 147	Genérico de alta calidad. Ideal para el hogar o negocio.	54163	112	18	T952	\N	7
333	Genérico Ligero 269	Genérico de alta calidad. Ideal para el hogar o negocio.	26256	433	13	B039	132	\N
334	Papas Eco 107	Papas de alta calidad. Ideal para el hogar o negocio.	82420	390	2	U460	\N	3
335	Genérico Deluxe 379	Genérico de alta calidad. Ideal para el hogar o negocio.	10390	777	12	B666	479	\N
336	Desinfectante Clásico 609	Desinfectante de alta calidad. Ideal para el hogar o negocio.	61024	410	5	N023	\N	5
337	Genérico Clásico 934	Genérico de alta calidad. Ideal para el hogar o negocio.	53019	245	12	T250	\N	6
338	Genérico Premium 833	Genérico de alta calidad. Ideal para el hogar o negocio.	18203	266	11	D905	261	\N
339	Genérico Express 144	Genérico de alta calidad. Ideal para el hogar o negocio.	36814	281	7	Z141	174	\N
340	Gomitas Max 822	Gomitas de alta calidad. Ideal para el hogar o negocio.	49368	418	1	B307	\N	3
341	Genérico Fresco 102	Genérico de alta calidad. Ideal para el hogar o negocio.	46139	914	7	R942	383	\N
342	Genérico Ligero 402	Genérico de alta calidad. Ideal para el hogar o negocio.	36554	188	15	O207	\N	7
343	Genérico Express 998	Genérico de alta calidad. Ideal para el hogar o negocio.	62966	196	17	Z018	74	\N
344	Genérico Fresco 110	Genérico de alta calidad. Ideal para el hogar o negocio.	70444	857	16	A046	492	\N
345	Genérico Clásico 612	Genérico de alta calidad. Ideal para el hogar o negocio.	97005	972	7	F710	\N	7
346	Desengrasante Clásico 41	Desengrasante de alta calidad. Ideal para el hogar o negocio.	19765	915	5	D846	\N	6
347	Genérico Ligero 979	Genérico de alta calidad. Ideal para el hogar o negocio.	99401	156	12	O607	333	\N
348	Detergente Express 868	Detergente de alta calidad. Ideal para el hogar o negocio.	76195	970	5	B903	\N	5
349	Gaseosa Express 735	Gaseosa de alta calidad. Ideal para el hogar o negocio.	83274	648	3	F249	325	\N
350	Genérico Ligero 44	Genérico de alta calidad. Ideal para el hogar o negocio.	96245	10	8	G762	\N	8
351	Gomitas Clásico 425	Gomitas de alta calidad. Ideal para el hogar o negocio.	40395	652	1	V411	10	\N
352	Limonada Eco 392	Limonada de alta calidad. Ideal para el hogar o negocio.	45817	132	3	D823	313	\N
353	Mix de maíz Fresco 425	Mix de maíz de alta calidad. Ideal para el hogar o negocio.	30011	939	2	P687	155	\N
354	Genérico Eco 593	Genérico de alta calidad. Ideal para el hogar o negocio.	5162	193	18	X085	324	\N
355	Multiusos Fresco 632	Multiusos de alta calidad. Ideal para el hogar o negocio.	83646	584	5	H010	436	\N
356	Genérico Plus 696	Genérico de alta calidad. Ideal para el hogar o negocio.	69140	172	18	C918	266	\N
357	Genérico Max 468	Genérico de alta calidad. Ideal para el hogar o negocio.	90761	732	7	S720	\N	8
358	Genérico Max 71	Genérico de alta calidad. Ideal para el hogar o negocio.	53613	372	11	C297	431	\N
359	Genérico Ligero 560	Genérico de alta calidad. Ideal para el hogar o negocio.	81084	580	15	K358	\N	4
360	Genérico Express 267	Genérico de alta calidad. Ideal para el hogar o negocio.	31412	407	9	N250	194	\N
361	Té Clásico 850	Té de alta calidad. Ideal para el hogar o negocio.	16263	772	3	X483	\N	6
362	Yucas Eco 197	Yucas de alta calidad. Ideal para el hogar o negocio.	46581	388	2	Z141	\N	1
363	Cerveza Ligero 69	Cerveza de alta calidad. Ideal para el hogar o negocio.	41701	780	4	V995	4	\N
364	Genérico Premium 569	Genérico de alta calidad. Ideal para el hogar o negocio.	23637	577	9	Q178	443	\N
365	Gomitas Express 954	Gomitas de alta calidad. Ideal para el hogar o negocio.	77623	924	1	J573	462	\N
366	Genérico Premium 990	Genérico de alta calidad. Ideal para el hogar o negocio.	66434	306	6	N474	\N	10
367	Genérico Ligero 746	Genérico de alta calidad. Ideal para el hogar o negocio.	99043	107	7	F710	\N	5
368	Genérico Premium 25	Genérico de alta calidad. Ideal para el hogar o negocio.	71251	461	6	U835	470	\N
369	Mix de maíz Clásico 976	Mix de maíz de alta calidad. Ideal para el hogar o negocio.	13608	278	2	P555	\N	1
370	Genérico Deluxe 453	Genérico de alta calidad. Ideal para el hogar o negocio.	25337	908	8	W229	\N	2
371	Genérico Ligero 282	Genérico de alta calidad. Ideal para el hogar o negocio.	74621	974	7	J480	\N	3
372	Genérico Deluxe 144	Genérico de alta calidad. Ideal para el hogar o negocio.	47446	12	9	C472	162	\N
373	Genérico Express 831	Genérico de alta calidad. Ideal para el hogar o negocio.	44272	579	16	Q144	\N	10
374	Genérico Ligero 6611	Genérico de alta calidad. Ideal para el hogar o negocio.	54593	36	15	Q203	473	\N
375	Yucas Express 544	Yucas de alta calidad. Ideal para el hogar o negocio.	61693	433	2	W701	\N	4
376	Caramelo Premium 919	Caramelo de alta calidad. Ideal para el hogar o negocio.	37585	634	1	Z141	\N	2
377	Genérico Express 754	Genérico de alta calidad. Ideal para el hogar o negocio.	54050	7	16	M950	58	\N
378	Vino Plus 283	Vino de alta calidad. Ideal para el hogar o negocio.	85104	738	4	L611	\N	9
379	Genérico Plus 36	Genérico de alta calidad. Ideal para el hogar o negocio.	14457	97	9	M934	\N	9
380	Genérico Max 976	Genérico de alta calidad. Ideal para el hogar o negocio.	95071	545	16	V449	\N	1
381	Ron Express 542	Ron de alta calidad. Ideal para el hogar o negocio.	32632	555	4	U460	39	\N
382	Genérico Deluxe 59	Genérico de alta calidad. Ideal para el hogar o negocio.	58209	803	16	Q670	333	\N
383	Genérico Deluxe 577	Genérico de alta calidad. Ideal para el hogar o negocio.	2837	643	18	D578	\N	9
384	Genérico Ligero 596	Genérico de alta calidad. Ideal para el hogar o negocio.	13364	925	13	F249	\N	3
385	Genérico Ligero 515	Genérico de alta calidad. Ideal para el hogar o negocio.	42392	376	18	K495	\N	6
386	Limonada Plus 179	Limonada de alta calidad. Ideal para el hogar o negocio.	83368	150	3	L574	\N	10
387	Genérico Selecto 778	Genérico de alta calidad. Ideal para el hogar o negocio.	55228	309	11	T250	\N	2
388	Bocadillo Plus 548	Bocadillo de alta calidad. Ideal para el hogar o negocio.	43113	338	1	R300	\N	5
389	Suavizante Plus 738	Suavizante de alta calidad. Ideal para el hogar o negocio.	10408	6	5	X653	440	\N
390	Genérico Premium 700	Genérico de alta calidad. Ideal para el hogar o negocio.	29774	664	7	J313	\N	5
391	Genérico Ligero 665	Genérico de alta calidad. Ideal para el hogar o negocio.	91815	219	7	U460	287	\N
392	Tequila Selecto 79	Tequila de alta calidad. Ideal para el hogar o negocio.	60806	890	4	G777	\N	4
393	Gomitas Clásico 449	Gomitas de alta calidad. Ideal para el hogar o negocio.	37773	368	1	U188	\N	9
394	Genérico Premium 804	Genérico de alta calidad. Ideal para el hogar o negocio.	65414	282	16	B666	139	\N
395	Genérico Clásico 445	Genérico de alta calidad. Ideal para el hogar o negocio.	59881	87	6	Q871	\N	4
396	Desengrasante Premium 841	Desengrasante de alta calidad. Ideal para el hogar o negocio.	55753	96	5	I881	\N	3
397	Champaña Clásico 343	Champaña de alta calidad. Ideal para el hogar o negocio.	38306	385	4	I023	326	\N
398	Genérico Deluxe 760	Genérico de alta calidad. Ideal para el hogar o negocio.	22417	257	6	M905	470	\N
399	Genérico Premium 1964	Genérico de alta calidad. Ideal para el hogar o negocio.	58834	269	18	H146	\N	4
400	Genérico Premium 60	Genérico de alta calidad. Ideal para el hogar o negocio.	38820	423	8	W229	\N	9
401	Limpiador Eco 529	Limpiador de alta calidad. Ideal para el hogar o negocio.	96029	82	5	E051	\N	10
402	Genérico Deluxe 333	Genérico de alta calidad. Ideal para el hogar o negocio.	86263	543	18	A209	29	\N
403	Tequila Express 279	Tequila de alta calidad. Ideal para el hogar o negocio.	3816	1	4	W392	372	\N
404	Genérico Ligero 425	Genérico de alta calidad. Ideal para el hogar o negocio.	82483	6	18	X085	292	\N
405	Genérico Clásico 879	Genérico de alta calidad. Ideal para el hogar o negocio.	50673	552	16	U460	\N	5
406	Genérico Eco 255	Genérico de alta calidad. Ideal para el hogar o negocio.	64381	85	6	M559	\N	2
407	Genérico Express 102	Genérico de alta calidad. Ideal para el hogar o negocio.	61984	838	13	G265	\N	6
408	Genérico Express 140	Genérico de alta calidad. Ideal para el hogar o negocio.	38046	539	7	V797	\N	2
409	Genérico Premium 268	Genérico de alta calidad. Ideal para el hogar o negocio.	46471	744	15	B841	\N	7
410	Genérico Clásico 158	Genérico de alta calidad. Ideal para el hogar o negocio.	99082	231	8	X552	248	\N
411	Agua Max 87	Agua de alta calidad. Ideal para el hogar o negocio.	60174	368	3	E057	\N	9
412	Genérico Max 579	Genérico de alta calidad. Ideal para el hogar o negocio.	18273	362	16	J526	\N	2
413	Pastillas Max 898	Pastillas de alta calidad. Ideal para el hogar o negocio.	21963	122	1	K136	\N	2
414	Genérico Eco 832	Genérico de alta calidad. Ideal para el hogar o negocio.	81813	30	6	C311	\N	6
415	Genérico Premium 129	Genérico de alta calidad. Ideal para el hogar o negocio.	17292	837	8	I105	\N	9
416	Genérico Plus 222	Genérico de alta calidad. Ideal para el hogar o negocio.	24706	842	16	B666	82	\N
417	Cerveza Express 781	Cerveza de alta calidad. Ideal para el hogar o negocio.	36887	763	4	Z003	350	\N
418	Genérico Clásico 25	Genérico de alta calidad. Ideal para el hogar o negocio.	18278	687	7	B512	424	\N
419	Genérico Selecto 422	Genérico de alta calidad. Ideal para el hogar o negocio.	61362	414	13	X314	\N	5
420	Bocadillo Ligero 494	Bocadillo de alta calidad. Ideal para el hogar o negocio.	99311	377	1	G777	\N	6
421	Energizante Fresco 106	Energizante de alta calidad. Ideal para el hogar o negocio.	86024	450	3	I067	\N	1
422	Vodka Selecto 563	Vodka de alta calidad. Ideal para el hogar o negocio.	33176	274	4	K318	\N	9
423	Genérico Premium 710	Genérico de alta calidad. Ideal para el hogar o negocio.	92075	579	13	Q102	368	\N
424	Genérico Ligero 873	Genérico de alta calidad. Ideal para el hogar o negocio.	2713	382	16	X208	339	\N
425	Genérico Express 819	Genérico de alta calidad. Ideal para el hogar o negocio.	92118	239	8	S426	\N	1
426	Genérico Premium 655	Genérico de alta calidad. Ideal para el hogar o negocio.	99993	346	15	X537	\N	3
427	Desodorizante Selecto 476	Desodorizante de alta calidad. Ideal para el hogar o negocio.	68232	851	5	J839	458	\N
428	Gaseosa Plus 501	Gaseosa de alta calidad. Ideal para el hogar o negocio.	87285	585	3	X270	\N	10
429	Jugo Eco 889	Jugo de alta calidad. Ideal para el hogar o negocio.	35342	973	3	J960	352	\N
430	Genérico Fresco 129	Genérico de alta calidad. Ideal para el hogar o negocio.	14713	777	13	L976	463	\N
431	Genérico Eco 484	Genérico de alta calidad. Ideal para el hogar o negocio.	87908	879	13	Q595	\N	8
432	Genérico Ligero 719	Genérico de alta calidad. Ideal para el hogar o negocio.	56288	419	13	J244	34	\N
433	Desengrasante Max 446	Desengrasante de alta calidad. Ideal para el hogar o negocio.	28014	700	5	B666	\N	6
434	Malta Clásico 213	Malta de alta calidad. Ideal para el hogar o negocio.	8673	570	3	P727	\N	8
435	Genérico Deluxe 612	Genérico de alta calidad. Ideal para el hogar o negocio.	66841	42	13	J482	273	\N
436	Limpiavidrios Max 820	Limpiavidrios de alta calidad. Ideal para el hogar o negocio.	58189	208	5	B841	\N	9
437	Bebida energética Express 379	Bebida energética de alta calidad. Ideal para el hogar o negocio.	68717	266	3	Q246	14	\N
438	Brandy Express 813	Brandy de alta calidad. Ideal para el hogar o negocio.	16221	423	4	S426	164	\N
439	Genérico Clásico 697	Genérico de alta calidad. Ideal para el hogar o negocio.	55231	372	12	Z014	\N	5
440	Detergente Deluxe 846	Detergente de alta calidad. Ideal para el hogar o negocio.	56561	574	5	B903	\N	5
441	Chocolate Eco 687	Chocolate de alta calidad. Ideal para el hogar o negocio.	38805	778	1	A722	45	\N
442	Genérico Ligero 147	Genérico de alta calidad. Ideal para el hogar o negocio.	73117	822	18	K985	460	\N
443	Pastillas Premium 626	Pastillas de alta calidad. Ideal para el hogar o negocio.	3442	327	1	U460	220	\N
444	Genérico Eco 678	Genérico de alta calidad. Ideal para el hogar o negocio.	80231	248	17	L251	68	\N
445	Genérico Fresco 799	Genérico de alta calidad. Ideal para el hogar o negocio.	34922	356	9	F894	266	\N
446	Genérico Plus 953	Genérico de alta calidad. Ideal para el hogar o negocio.	29552	957	13	I263	\N	8
447	Multiusos Selecto 187	Multiusos de alta calidad. Ideal para el hogar o negocio.	44783	944	5	G694	\N	2
448	Genérico Plus 513	Genérico de alta calidad. Ideal para el hogar o negocio.	84233	359	12	Q102	237	\N
449	Genérico Fresco 869	Genérico de alta calidad. Ideal para el hogar o negocio.	44218	775	11	Q993	\N	1
450	Genérico Eco 4	Genérico de alta calidad. Ideal para el hogar o negocio.	32767	824	18	V754	\N	1
451	Genérico Ligero 430	Genérico de alta calidad. Ideal para el hogar o negocio.	20823	65	15	Y749	\N	4
452	Genérico Clásico 1160	Genérico de alta calidad. Ideal para el hogar o negocio.	22181	749	16	W054	\N	4
453	Genérico Clásico 148	Genérico de alta calidad. Ideal para el hogar o negocio.	43556	174	8	F506	\N	4
454	Multiusos Ligero 675	Multiusos de alta calidad. Ideal para el hogar o negocio.	64695	839	5	H010	\N	3
455	Mazapán Plus 272	Mazapán de alta calidad. Ideal para el hogar o negocio.	97261	721	1	C148	\N	1
456	Genérico Plus 51	Genérico de alta calidad. Ideal para el hogar o negocio.	50862	241	11	A470	211	\N
457	Genérico Plus 124	Genérico de alta calidad. Ideal para el hogar o negocio.	38791	478	15	B903	426	\N
458	Genérico Max 9	Genérico de alta calidad. Ideal para el hogar o negocio.	89211	736	18	I842	367	\N
459	Genérico Deluxe 473	Genérico de alta calidad. Ideal para el hogar o negocio.	88005	996	6	U816	80	\N
460	Limonada Deluxe 885	Limonada de alta calidad. Ideal para el hogar o negocio.	30979	346	3	Z344	\N	6
461	Bebida de frutas Max 427	Bebida de frutas de alta calidad. Ideal para el hogar o negocio.	10987	508	3	F058	\N	6
462	Genérico Clásico 767	Genérico de alta calidad. Ideal para el hogar o negocio.	99418	162	15	R027	377	\N
463	Genérico Premium 611	Genérico de alta calidad. Ideal para el hogar o negocio.	5416	588	11	V454	\N	10
464	Cloro Selecto 702	Cloro de alta calidad. Ideal para el hogar o negocio.	55313	200	5	V754	52	\N
465	Genérico Fresco 508	Genérico de alta calidad. Ideal para el hogar o negocio.	43074	422	12	S634	65	\N
466	Genérico Eco 982	Genérico de alta calidad. Ideal para el hogar o negocio.	47262	77	18	Z504	430	\N
467	Genérico Max 216	Genérico de alta calidad. Ideal para el hogar o negocio.	58721	618	11	D846	270	\N
468	Malvavisco Deluxe 924	Malvavisco de alta calidad. Ideal para el hogar o negocio.	98100	538	1	H927	\N	9
469	Vodka Clásico 778	Vodka de alta calidad. Ideal para el hogar o negocio.	73959	940	4	X332	118	\N
470	Genérico Plus 566	Genérico de alta calidad. Ideal para el hogar o negocio.	28506	963	7	H241	\N	5
471	Ginebra Plus 677	Ginebra de alta calidad. Ideal para el hogar o negocio.	84140	835	4	V711	32	\N
472	Desengrasante Premium 479	Desengrasante de alta calidad. Ideal para el hogar o negocio.	20232	8	5	M934	\N	8
473	Genérico Premium 659	Genérico de alta calidad. Ideal para el hogar o negocio.	70362	550	17	M905	366	\N
474	Genérico Deluxe 117	Genérico de alta calidad. Ideal para el hogar o negocio.	79095	593	17	B211	359	\N
475	Genérico Deluxe 587	Genérico de alta calidad. Ideal para el hogar o negocio.	30742	62	12	S207	\N	2
476	Multiusos Max 335	Multiusos de alta calidad. Ideal para el hogar o negocio.	53978	629	5	U085	372	\N
477	Genérico Eco 148	Genérico de alta calidad. Ideal para el hogar o negocio.	58101	472	9	W510	111	\N
478	Genérico Fresco 895	Genérico de alta calidad. Ideal para el hogar o negocio.	80457	494	11	O685	\N	5
479	Genérico Ligero 422	Genérico de alta calidad. Ideal para el hogar o negocio.	54713	596	18	Y795	\N	9
480	Genérico Selecto 495	Genérico de alta calidad. Ideal para el hogar o negocio.	55564	20	13	G303	\N	7
481	Gaseosa Ligero 55	Gaseosa de alta calidad. Ideal para el hogar o negocio.	78294	71	3	I461	\N	9
482	Genérico Plus 927	Genérico de alta calidad. Ideal para el hogar o negocio.	12192	750	6	F710	\N	8
483	Limpiador Fresco 418	Limpiador de alta calidad. Ideal para el hogar o negocio.	54845	650	5	O994	\N	6
484	Genérico Eco 417	Genérico de alta calidad. Ideal para el hogar o negocio.	68205	569	12	X314	134	\N
485	Genérico Selecto 975	Genérico de alta calidad. Ideal para el hogar o negocio.	18819	767	9	N023	344	\N
486	Genérico Premium 684	Genérico de alta calidad. Ideal para el hogar o negocio.	33869	699	16	S426	\N	1
487	Genérico Selecto 821	Genérico de alta calidad. Ideal para el hogar o negocio.	54361	693	11	P075	189	\N
488	Genérico Selecto 160	Genérico de alta calidad. Ideal para el hogar o negocio.	63864	357	16	R942	\N	6
489	Genérico Fresco 277	Genérico de alta calidad. Ideal para el hogar o negocio.	11289	570	7	J480	291	\N
490	Chocolate Eco 324	Chocolate de alta calidad. Ideal para el hogar o negocio.	1878	700	1	O239	\N	7
491	Genérico Eco 920	Genérico de alta calidad. Ideal para el hogar o negocio.	76592	990	12	Q636	205	\N
492	Genérico Ligero 880	Genérico de alta calidad. Ideal para el hogar o negocio.	35784	21	18	G628	30	\N
493	Genérico Premium 430	Genérico de alta calidad. Ideal para el hogar o negocio.	38511	591	17	X412	489	\N
494	Genérico Express 415	Genérico de alta calidad. Ideal para el hogar o negocio.	11673	535	6	M271	\N	1
495	Jugo Deluxe 243	Jugo de alta calidad. Ideal para el hogar o negocio.	16489	156	3	J603	\N	2
496	Suavizante Fresco 989	Suavizante de alta calidad. Ideal para el hogar o negocio.	21455	57	5	D796	\N	2
497	Genérico Clásico 507	Genérico de alta calidad. Ideal para el hogar o negocio.	96171	40	6	N989	\N	7
498	Nachos Ligero 615	Nachos de alta calidad. Ideal para el hogar o negocio.	76326	838	2	L251	\N	7
499	Genérico Max 53	Genérico de alta calidad. Ideal para el hogar o negocio.	96127	402	17	B019	97	\N
500	Genérico Deluxe 864	Genérico de alta calidad. Ideal para el hogar o negocio.	1372	839	18	D445	\N	6
501	Suavizante Clásico 501	Suavizante de alta calidad. Ideal para el hogar o negocio.	28331	462	5	K976	262	\N
502	Genérico Selecto 621	Genérico de alta calidad. Ideal para el hogar o negocio.	58248	264	17	I735	\N	10
503	Genérico Premium 69	Genérico de alta calidad. Ideal para el hogar o negocio.	54212	139	6	H902	\N	3
504	Cloro Fresco 53	Cloro de alta calidad. Ideal para el hogar o negocio.	76067	759	5	U347	\N	4
505	Genérico Premium 832	Genérico de alta calidad. Ideal para el hogar o negocio.	66942	911	12	X270	176	\N
506	Tequila Plus 548	Tequila de alta calidad. Ideal para el hogar o negocio.	94371	290	4	U372	367	\N
507	Genérico Eco 974	Genérico de alta calidad. Ideal para el hogar o negocio.	50154	359	6	W054	\N	5
508	Desodorizante Deluxe 379	Desodorizante de alta calidad. Ideal para el hogar o negocio.	20492	962	5	Q993	203	\N
509	Genérico Max 485	Genérico de alta calidad. Ideal para el hogar o negocio.	72164	114	9	Y426	\N	8
510	Genérico Premium 55	Genérico de alta calidad. Ideal para el hogar o negocio.	4028	477	9	J573	373	\N
511	Genérico Eco 515	Genérico de alta calidad. Ideal para el hogar o negocio.	98359	189	9	V449	\N	8
512	Arepitas Clásico 472	Arepitas de alta calidad. Ideal para el hogar o negocio.	94096	516	2	K595	\N	4
513	Genérico Eco 18	Genérico de alta calidad. Ideal para el hogar o negocio.	66263	488	15	D788	\N	10
514	Genérico Express 95	Genérico de alta calidad. Ideal para el hogar o negocio.	60764	549	11	P885	444	\N
515	Genérico Plus 72	Genérico de alta calidad. Ideal para el hogar o negocio.	96436	881	13	E876	\N	6
516	Caramelo Plus 727	Caramelo de alta calidad. Ideal para el hogar o negocio.	6509	225	1	U133	\N	7
517	Genérico Deluxe 616	Genérico de alta calidad. Ideal para el hogar o negocio.	87958	793	7	A960	198	\N
518	Genérico Plus 676	Genérico de alta calidad. Ideal para el hogar o negocio.	91429	69	9	W510	\N	10
519	Genérico Fresco 630	Genérico de alta calidad. Ideal para el hogar o negocio.	52639	566	6	C102	\N	4
520	Tostacos Ligero 145	Tostacos de alta calidad. Ideal para el hogar o negocio.	14642	987	2	O201	209	\N
521	Caramelo Express 118	Caramelo de alta calidad. Ideal para el hogar o negocio.	18716	317	1	E779	\N	7
522	Yucas Plus 217	Yucas de alta calidad. Ideal para el hogar o negocio.	34040	853	2	V178	274	\N
523	Genérico Fresco 850	Genérico de alta calidad. Ideal para el hogar o negocio.	86950	189	18	W510	\N	5
524	Genérico Ligero 858	Genérico de alta calidad. Ideal para el hogar o negocio.	3893	431	18	X510	79	\N
525	Genérico Clásico 684	Genérico de alta calidad. Ideal para el hogar o negocio.	17303	186	7	X909	372	\N
526	Ron Clásico 345	Ron de alta calidad. Ideal para el hogar o negocio.	36255	895	4	R500	29	\N
527	Limonada Max 17	Limonada de alta calidad. Ideal para el hogar o negocio.	19575	631	3	W826	346	\N
528	Genérico Plus 974	Genérico de alta calidad. Ideal para el hogar o negocio.	24822	840	17	R143	49	\N
529	Platanitos Fresco 602	Platanitos de alta calidad. Ideal para el hogar o negocio.	70609	187	2	R384	82	\N
530	Genérico Clásico 143	Genérico de alta calidad. Ideal para el hogar o negocio.	73508	454	8	F675	412	\N
1	Jabón corporal	Jabón corporal premium para uso diario	55129	352	7	W940	382	\N
2	Shampoo anticaspa	Shampoo anticaspa natural para uso diario	81362	996	7	E470	\N	7
3	Chocolate con leche	Chocolate con leche eficaz para uso diario	45390	643	1	M680	205	\N
4	Producto Genérico	Producto Genérico premium para uso diario	8782	233	12	L611	\N	8
5	Producto Genérico	Producto Genérico de calidad para uso diario	130240	389	12	S094	325	\N
6	Producto Genérico	Producto Genérico fresco para uso diario	56787	214	16	P727	\N	5
7	Leche entera	Leche entera popular para uso diario	95977	546	9	Q595	464	\N
8	Producto Genérico	Producto Genérico natural para uso diario	58159	947	15	V911	\N	2
9	Ron oscuro	Ron oscuro duradero para uso diario	126742	794	4	I735	326	\N
10	Shampoo anticaspa	Shampoo anticaspa duradero para uso diario	61372	67	7	K951	\N	7
11	Jabón en barra	Jabón en barra de calidad para uso diario	99005	405	5	R143	248	\N
12	Producto Genérico	Producto Genérico fresco para uso diario	41202	252	15	E636	\N	5
13	Malvaviscos	Malvaviscos nuevo para uso diario	112558	438	1	N434	481	\N
14	Mantequilla	Mantequilla duradero para uso diario	34459	141	9	M662	\N	8
15	Producto Genérico	Producto Genérico económico para uso diario	129443	156	17	U126	471	\N
16	Cucharas plásticas	Cucharas plásticas popular para uso diario	11402	390	18	X574	\N	5
17	Producto Genérico	Producto Genérico eficaz para uso diario	129395	11	17	A467	381	\N
18	Desinfectante	Desinfectante nuevo para uso diario	115753	348	5	C635	\N	4
19	Producto Genérico	Producto Genérico fresco para uso diario	69151	976	15	J313	58	\N
20	Desinfectante	Desinfectante fresco para uso diario	77137	108	5	X270	\N	1
21	Producto Genérico	Producto Genérico eficaz para uso diario	92128	156	16	U010	472	\N
22	Producto Genérico	Producto Genérico popular para uso diario	49975	19	13	S078	\N	4
23	Maíz dulce	Maíz dulce de calidad para uso diario	10573	899	6	M290	296	\N
24	Producto Genérico	Producto Genérico natural para uso diario	122771	778	12	N989	\N	4
25	Frijoles enlatados	Frijoles enlatados natural para uso diario	142134	169	6	G712	336	\N
26	Tenedores plásticos	Tenedores plásticos importado para uso diario	144726	951	18	H630	\N	3
27	Producto Genérico	Producto Genérico importado para uso diario	149282	665	15	K798	181	\N
28	Malvaviscos	Malvaviscos natural para uso diario	19909	230	1	X435	\N	5
29	Whisky escocés	Whisky escocés popular para uso diario	83980	602	4	V711	206	\N
30	Detergente líquido	Detergente líquido económico para uso diario	35883	927	5	W210	\N	6
31	Atún en agua	Atún en agua eficaz para uso diario	37225	685	6	B460	208	\N
32	Bebida energética	Bebida energética fresco para uso diario	109056	903	3	Y795	\N	1
33	Producto Genérico	Producto Genérico de calidad para uso diario	118124	826	16	M290	115	\N
34	Producto Genérico	Producto Genérico premium para uso diario	99529	362	17	G152	\N	7
35	Sopa de vegetales	Sopa de vegetales económico para uso diario	101658	661	6	A077	455	\N
36	Croissant	Croissant duradero para uso diario	120488	111	8	G544	\N	3
37	Producto Genérico	Producto Genérico eficaz para uso diario	68395	432	15	R275	490	\N
38	Mantequilla	Mantequilla de calidad para uso diario	131424	77	9	W759	\N	4
39	Jugo de naranja	Jugo de naranja económico para uso diario	98517	553	3	P392	440	\N
40	Atún en agua	Atún en agua de calidad para uso diario	26614	497	6	K318	\N	6
41	Limpiador multiusos	Limpiador multiusos económico para uso diario	26366	2	5	V834	369	\N
42	Chicles	Chicles nuevo para uso diario	64605	980	1	V449	\N	7
43	Arroz integral	Arroz integral fresco para uso diario	30105	222	11	B307	364	\N
44	Tenedores plásticos	Tenedores plásticos eficaz para uso diario	11022	321	18	F204	\N	1
45	Malvaviscos	Malvaviscos natural para uso diario	76422	873	1	N083	166	\N
46	Pan tajado	Pan tajado eficaz para uso diario	13857	190	8	S078	\N	1
47	Leche entera	Leche entera de calidad para uso diario	61759	964	9	C590	217	\N
48	Producto Genérico	Producto Genérico popular para uso diario	89989	634	16	Q493	\N	2
49	Producto Genérico	Producto Genérico nuevo para uso diario	32230	733	17	E057	120	\N
50	Té helado	Té helado importado para uso diario	21370	660	3	R742	\N	7
51	Maíz dulce	Maíz dulce premium para uso diario	3379	636	6	K240	176	\N
52	Producto Genérico	Producto Genérico eficaz para uso diario	33547	271	13	B019	\N	7
53	Leche entera	Leche entera de calidad para uso diario	56690	161	9	Q595	403	\N
54	Nachos con queso	Nachos con queso popular para uso diario	147610	826	2	O692	\N	7
55	Producto Genérico	Producto Genérico eficaz para uso diario	46308	679	17	X412	206	\N
56	Galletas de avena	Galletas de avena premium para uso diario	133677	760	8	E936	\N	2
57	Nachos con queso	Nachos con queso nuevo para uso diario	91515	734	2	B488	38	\N
58	Gomitas frutales	Gomitas frutales eficaz para uso diario	74303	927	1	Z825	\N	1
59	Chocolate con leche	Chocolate con leche importado para uso diario	124744	45	1	X208	196	\N
60	Platos de cartón	Platos de cartón nuevo para uso diario	25914	452	18	A767	\N	3
61	Fideos orientales	Fideos orientales económico para uso diario	18557	967	11	D229	289	\N
62	Tostones	Tostones económico para uso diario	125520	596	2	N948	\N	8
63	Arroz integral	Arroz integral fresco para uso diario	8191	373	11	B903	486	\N
64	Producto Genérico	Producto Genérico de calidad para uso diario	102946	682	15	A722	\N	6
65	Leche deslactosada	Leche deslactosada importado para uso diario	146128	767	9	E057	272	\N
66	Pan de queso	Pan de queso fresco para uso diario	132450	25	8	X080	\N	7
67	Producto Genérico	Producto Genérico de calidad para uso diario	41487	806	12	L302	16	\N
68	Sopa de vegetales	Sopa de vegetales económico para uso diario	129072	227	6	E364	\N	4
69	Queso campesino	Queso campesino nuevo para uso diario	123439	892	9	Q993	166	\N
70	Jugo de naranja	Jugo de naranja de calidad para uso diario	60973	285	3	W940	\N	7
71	Producto Genérico	Producto Genérico duradero para uso diario	96939	409	15	N870	471	\N
72	Té helado	Té helado económico para uso diario	19071	993	3	R019	\N	2
73	Tenedores plásticos	Tenedores plásticos nuevo para uso diario	7662	610	18	M934	58	\N
74	Desodorante	Desodorante importado para uso diario	91719	523	7	R942	\N	5
75	Tostones	Tostones de calidad para uso diario	39699	725	2	B039	258	\N
76	Pastel de vainilla	Pastel de vainilla eficaz para uso diario	103655	962	8	V331	\N	6
77	Choclitos	Choclitos duradero para uso diario	65832	971	2	Q892	1	\N
78	Desinfectante	Desinfectante duradero para uso diario	100181	127	5	S094	\N	6
79	Toallas húmedas	Toallas húmedas nuevo para uso diario	100700	334	7	Z141	232	\N
80	Producto Genérico	Producto Genérico de calidad para uso diario	64226	962	16	G265	\N	3
81	Producto Genérico	Producto Genérico popular para uso diario	86228	415	16	I115	445	\N
82	Desodorante	Desodorante nuevo para uso diario	33107	804	7	M271	\N	2
83	Cerveza artesanal	Cerveza artesanal natural para uso diario	67384	691	4	N870	358	\N
84	Mantequilla	Mantequilla fresco para uso diario	99510	290	9	D796	\N	4
85	Producto Genérico	Producto Genérico premium para uso diario	123127	769	17	C102	497	\N
86	Cerveza artesanal	Cerveza artesanal de calidad para uso diario	121371	150	4	N561	\N	6
87	Pan de queso	Pan de queso natural para uso diario	92469	786	8	I023	225	\N
88	Producto Genérico	Producto Genérico popular para uso diario	30776	713	15	B460	\N	3
89	Producto Genérico	Producto Genérico de calidad para uso diario	23841	704	12	Q104	79	\N
90	Jabón corporal	Jabón corporal de calidad para uso diario	28031	980	7	X332	\N	2
91	Producto Genérico	Producto Genérico económico para uso diario	84496	939	13	S126	246	\N
92	Jabón corporal	Jabón corporal fresco para uso diario	120610	683	7	B835	\N	5
93	Vino tinto	Vino tinto duradero para uso diario	142606	912	4	X986	224	\N
94	Producto Genérico	Producto Genérico eficaz para uso diario	67995	162	12	Z018	\N	3
95	Producto Genérico	Producto Genérico nuevo para uso diario	113263	860	16	C339	350	\N
96	Duraznos en almíbar	Duraznos en almíbar natural para uso diario	94759	281	6	W392	\N	3
97	Jabón en barra	Jabón en barra de calidad para uso diario	42214	327	5	B406	489	\N
98	Atún en agua	Atún en agua fresco para uso diario	24323	392	6	M662	\N	2
99	Choclitos	Choclitos premium para uso diario	63400	338	2	H010	41	\N
100	Agua mineral	Agua mineral económico para uso diario	32611	430	3	V178	\N	8
101	Producto Genérico	Producto Genérico popular para uso diario	58296	6	15	P309	156	\N
102	Desodorante	Desodorante importado para uso diario	128310	976	7	C590	\N	8
103	Pastel de vainilla	Pastel de vainilla eficaz para uso diario	120380	919	8	S237	484	\N
104	Gaseosa cola	Gaseosa cola nuevo para uso diario	66504	29	3	D098	\N	6
105	Cucharas plásticas	Cucharas plásticas fresco para uso diario	126395	941	18	Q493	4	\N
106	Desinfectante	Desinfectante económico para uso diario	136225	606	5	D905	\N	6
107	Papas fritas	Papas fritas premium para uso diario	97127	138	2	S673	199	\N
108	Producto Genérico	Producto Genérico económico para uso diario	40503	335	13	Q595	\N	8
109	Maíz dulce	Maíz dulce duradero para uso diario	114662	388	6	F710	57	\N
110	Queso campesino	Queso campesino premium para uso diario	71605	767	9	S943	\N	8
111	Servilletas	Servilletas de calidad para uso diario	98221	799	18	H370	485	\N
112	Detergente líquido	Detergente líquido económico para uso diario	142543	204	5	V178	\N	5
113	Tostones	Tostones fresco para uso diario	37305	484	2	S354	223	\N
114	Producto Genérico	Producto Genérico natural para uso diario	105521	785	17	C839	\N	1
115	Leche deslactosada	Leche deslactosada popular para uso diario	144633	735	9	Z773	457	\N
116	Galletas de avena	Galletas de avena premium para uso diario	87645	951	8	S354	\N	2
117	Limpiador multiusos	Limpiador multiusos importado para uso diario	141338	203	5	D872	263	\N
118	Producto Genérico	Producto Genérico premium para uso diario	105185	308	16	O715	\N	8
119	Producto Genérico	Producto Genérico popular para uso diario	117830	355	12	O539	47	\N
120	Arroz blanco	Arroz blanco premium para uso diario	76882	349	11	D098	\N	1
121	Cucharas plásticas	Cucharas plásticas premium para uso diario	66161	370	18	V911	321	\N
122	Pan de queso	Pan de queso importado para uso diario	28068	534	8	H556	\N	6
123	Nachos con queso	Nachos con queso popular para uso diario	121613	551	2	Q102	368	\N
124	Canchita	Canchita importado para uso diario	124209	606	2	K382	\N	2
125	Producto Genérico	Producto Genérico premium para uso diario	43281	461	13	U133	146	\N
126	Producto Genérico	Producto Genérico duradero para uso diario	6248	871	15	N246	\N	2
127	Arroz integral	Arroz integral de calidad para uso diario	54514	264	11	Z344	183	\N
128	Fideos orientales	Fideos orientales nuevo para uso diario	84257	529	11	N982	\N	7
129	Vasos plásticos	Vasos plásticos de calidad para uso diario	108571	500	18	R237	156	\N
130	Cucharas plásticas	Cucharas plásticas natural para uso diario	68330	17	18	D533	\N	1
131	Producto Genérico	Producto Genérico importado para uso diario	104385	313	12	F202	47	\N
132	Producto Genérico	Producto Genérico natural para uso diario	83914	352	16	O692	\N	4
133	Queso campesino	Queso campesino duradero para uso diario	106023	277	9	B102	37	\N
134	Producto Genérico	Producto Genérico premium para uso diario	108750	323	16	T250	\N	8
135	Producto Genérico	Producto Genérico de calidad para uso diario	34025	495	17	L797	440	\N
136	Malvaviscos	Malvaviscos popular para uso diario	43884	102	1	K095	\N	3
137	Desodorante	Desodorante de calidad para uso diario	55410	309	7	R300	305	\N
138	Producto Genérico	Producto Genérico nuevo para uso diario	8736	55	16	Z825	\N	8
139	Gaseosa cola	Gaseosa cola natural para uso diario	17183	12	3	B903	112	\N
140	Vodka premium	Vodka premium natural para uso diario	67189	188	4	A722	\N	6
141	Jabón en barra	Jabón en barra natural para uso diario	18885	66	5	Q493	66	\N
142	Chocolate con leche	Chocolate con leche popular para uso diario	95158	54	1	X573	\N	2
143	Leche deslactosada	Leche deslactosada nuevo para uso diario	14607	254	9	I023	312	\N
144	Cucharas plásticas	Cucharas plásticas popular para uso diario	90227	633	18	F333	\N	3
145	Arroz integral	Arroz integral natural para uso diario	136459	304	11	H424	452	\N
146	Arroz integral	Arroz integral nuevo para uso diario	86157	61	11	J047	\N	4
147	Platos de cartón	Platos de cartón de calidad para uso diario	41168	83	18	X909	403	\N
148	Producto Genérico	Producto Genérico eficaz para uso diario	13110	2	13	U630	\N	8
149	Desinfectante	Desinfectante natural para uso diario	45106	237	5	C102	174	\N
150	Arroz integral	Arroz integral premium para uso diario	103733	946	11	V834	\N	3
151	Toallas húmedas	Toallas húmedas de calidad para uso diario	64921	557	7	Y981	482	\N
152	Cloro	Cloro nuevo para uso diario	124341	73	5	C590	\N	6
153	Servilletas	Servilletas popular para uso diario	112846	582	18	X208	340	\N
154	Vodka premium	Vodka premium premium para uso diario	71367	311	4	E933	\N	7
155	Producto Genérico	Producto Genérico eficaz para uso diario	81917	448	16	E057	435	\N
156	Producto Genérico	Producto Genérico importado para uso diario	110711	618	12	U367	\N	6
157	Producto Genérico	Producto Genérico de calidad para uso diario	144363	856	13	M116	481	\N
158	Tenedores plásticos	Tenedores plásticos económico para uso diario	149937	688	18	I617	\N	1
159	Producto Genérico	Producto Genérico fresco para uso diario	71634	667	17	G694	483	\N
160	Yogur natural	Yogur natural popular para uso diario	66511	833	9	I461	\N	6
161	Limpiador multiusos	Limpiador multiusos duradero para uso diario	62436	328	5	B353	348	\N
162	Pasta dental	Pasta dental duradero para uso diario	62923	507	7	L100	\N	6
163	Producto Genérico	Producto Genérico eficaz para uso diario	7431	90	17	N989	276	\N
164	Jabón en barra	Jabón en barra premium para uso diario	145587	413	5	O539	\N	7
165	Vasos plásticos	Vasos plásticos eficaz para uso diario	70373	55	18	T259	340	\N
166	Maíz dulce	Maíz dulce popular para uso diario	113954	640	6	L274	\N	5
167	Producto Genérico	Producto Genérico nuevo para uso diario	83285	949	16	I806	229	\N
168	Chicles	Chicles premium para uso diario	6273	645	1	B276	\N	3
169	Producto Genérico	Producto Genérico nuevo para uso diario	83524	565	15	K240	356	\N
170	Macarrones	Macarrones premium para uso diario	70294	120	11	Q144	\N	2
171	Producto Genérico	Producto Genérico nuevo para uso diario	77313	279	13	H010	467	\N
172	Canchita	Canchita de calidad para uso diario	69604	148	2	I750	\N	3
173	Tenedores plásticos	Tenedores plásticos eficaz para uso diario	112451	139	18	A036	225	\N
174	Producto Genérico	Producto Genérico importado para uso diario	52302	806	16	X270	\N	5
175	Jugo de naranja	Jugo de naranja nuevo para uso diario	109456	857	3	I263	20	\N
176	Producto Genérico	Producto Genérico fresco para uso diario	68089	495	12	Z050	\N	7
177	Pastel de vainilla	Pastel de vainilla eficaz para uso diario	57827	955	8	R878	127	\N
178	Producto Genérico	Producto Genérico popular para uso diario	58680	876	15	M934	\N	2
179	Detergente líquido	Detergente líquido duradero para uso diario	112216	722	5	S541	263	\N
180	Chicles	Chicles fresco para uso diario	75309	37	1	C311	\N	7
181	Tostones	Tostones duradero para uso diario	130716	895	2	P392	351	\N
182	Jugo de naranja	Jugo de naranja eficaz para uso diario	136745	15	3	Z014	\N	6
183	Producto Genérico	Producto Genérico fresco para uso diario	13075	800	16	M290	50	\N
184	Cerveza artesanal	Cerveza artesanal popular para uso diario	104520	665	4	E038	\N	2
185	Pastel de vainilla	Pastel de vainilla importado para uso diario	143213	641	8	K358	146	\N
186	Producto Genérico	Producto Genérico popular para uso diario	12126	646	12	L923	\N	7
187	Cloro	Cloro premium para uso diario	66228	100	5	N561	80	\N
188	Leche entera	Leche entera natural para uso diario	26622	306	9	R500	\N	6
189	Chocolate con leche	Chocolate con leche duradero para uso diario	119829	300	1	K661	142	\N
190	Producto Genérico	Producto Genérico fresco para uso diario	38141	421	16	H204	\N	6
191	Producto Genérico	Producto Genérico fresco para uso diario	27910	624	12	L278	263	\N
192	Leche deslactosada	Leche deslactosada de calidad para uso diario	75655	597	9	C102	\N	3
193	Croissant	Croissant nuevo para uso diario	70016	682	8	R333	175	\N
194	Producto Genérico	Producto Genérico eficaz para uso diario	25380	452	13	S680	\N	6
195	Producto Genérico	Producto Genérico importado para uso diario	104166	467	13	X270	336	\N
196	Yogur natural	Yogur natural importado para uso diario	128294	109	9	M371	\N	8
197	Duraznos en almíbar	Duraznos en almíbar duradero para uso diario	87072	716	6	N192	67	\N
198	Vodka premium	Vodka premium nuevo para uso diario	3199	885	4	Q815	\N	4
199	Desinfectante	Desinfectante natural para uso diario	125260	924	5	H630	226	\N
200	Toallas húmedas	Toallas húmedas duradero para uso diario	34413	194	7	Z666	\N	3
201	Producto Genérico	Producto Genérico premium para uso diario	135704	661	12	Q203	445	\N
202	Sopa de vegetales	Sopa de vegetales económico para uso diario	87777	749	6	S943	\N	5
203	Producto Genérico	Producto Genérico duradero para uso diario	112627	179	15	A722	32	\N
204	Producto Genérico	Producto Genérico eficaz para uso diario	76266	279	13	L797	\N	1
205	Arroz blanco	Arroz blanco natural para uso diario	145173	302	11	H769	382	\N
206	Producto Genérico	Producto Genérico natural para uso diario	144508	144	15	B835	\N	6
207	Canchita	Canchita eficaz para uso diario	56135	809	2	B265	336	\N
208	Maíz dulce	Maíz dulce eficaz para uso diario	20291	377	6	C272	\N	3
209	Producto Genérico	Producto Genérico popular para uso diario	58392	653	12	A767	496	\N
210	Producto Genérico	Producto Genérico de calidad para uso diario	71779	634	17	H165	\N	7
211	Gomitas frutales	Gomitas frutales popular para uso diario	34762	64	1	B512	374	\N
212	Maíz dulce	Maíz dulce importado para uso diario	19268	46	6	C148	\N	3
213	Desodorante	Desodorante natural para uso diario	19186	240	7	S634	160	\N
214	Producto Genérico	Producto Genérico importado para uso diario	69139	686	17	B265	\N	3
215	Producto Genérico	Producto Genérico popular para uso diario	111856	158	15	S673	301	\N
216	Whisky escocés	Whisky escocés natural para uso diario	93117	961	4	D872	\N	8
217	Papas fritas	Papas fritas duradero para uso diario	34156	455	2	N561	381	\N
218	Té helado	Té helado premium para uso diario	147177	376	3	H556	\N	7
219	Galletas de avena	Galletas de avena económico para uso diario	60925	194	8	U784	482	\N
220	Cucharas plásticas	Cucharas plásticas premium para uso diario	100090	657	18	X032	\N	4
221	Jugo de naranja	Jugo de naranja económico para uso diario	118446	249	3	Z825	485	\N
222	Macarrones	Macarrones premium para uso diario	124813	567	11	E644	\N	5
223	Caramelo duro	Caramelo duro de calidad para uso diario	50627	151	1	M271	211	\N
224	Whisky escocés	Whisky escocés nuevo para uso diario	129044	148	4	T259	\N	8
225	Desodorante	Desodorante fresco para uso diario	18269	887	7	R901	52	\N
226	Pan tajado	Pan tajado duradero para uso diario	118918	243	8	S207	\N	4
227	Producto Genérico	Producto Genérico fresco para uso diario	41274	129	12	D769	263	\N
228	Vino tinto	Vino tinto premium para uso diario	112358	487	4	C508	\N	8
229	Producto Genérico	Producto Genérico natural para uso diario	76568	968	17	L725	67	\N
230	Desinfectante	Desinfectante nuevo para uso diario	69790	987	5	U103	\N	6
231	Producto Genérico	Producto Genérico importado para uso diario	65089	110	17	G265	481	\N
232	Atún en agua	Atún en agua premium para uso diario	49673	151	6	T988	\N	8
233	Jabón en barra	Jabón en barra popular para uso diario	95695	561	5	R304	156	\N
234	Sopa de vegetales	Sopa de vegetales popular para uso diario	80522	464	6	U994	\N	5
235	Agua mineral	Agua mineral premium para uso diario	119378	117	3	V256	232	\N
236	Producto Genérico	Producto Genérico importado para uso diario	68830	233	12	B039	\N	7
237	Arroz integral	Arroz integral importado para uso diario	63566	97	11	H769	440	\N
238	Producto Genérico	Producto Genérico nuevo para uso diario	57397	156	16	T767	\N	7
239	Producto Genérico	Producto Genérico premium para uso diario	125102	95	12	O561	29	\N
240	Jabón en barra	Jabón en barra fresco para uso diario	84343	600	5	E644	\N	4
241	Fideos orientales	Fideos orientales duradero para uso diario	101162	420	11	V999	350	\N
242	Chicles	Chicles económico para uso diario	145323	614	1	X193	\N	3
243	Papas fritas	Papas fritas popular para uso diario	77097	158	2	J313	116	\N
244	Platos de cartón	Platos de cartón premium para uso diario	53817	569	18	C699	\N	1
245	Arroz blanco	Arroz blanco popular para uso diario	35472	439	11	C148	351	\N
246	Tenedores plásticos	Tenedores plásticos popular para uso diario	101897	570	18	V754	\N	8
247	Cerveza artesanal	Cerveza artesanal económico para uso diario	28702	719	4	S943	65	\N
248	Galletas de avena	Galletas de avena duradero para uso diario	2904	890	8	L757	\N	2
249	Producto Genérico	Producto Genérico premium para uso diario	22997	648	16	K985	66	\N
250	Papas fritas	Papas fritas eficaz para uso diario	33840	429	2	J411	\N	2
251	Genérico Deluxe 845	Genérico de alta calidad. Ideal para el hogar o negocio.	84976	784	16	O607	73	\N
252	Turrón Ligero 401	Turrón de alta calidad. Ideal para el hogar o negocio.	26520	759	1	N982	\N	6
253	Genérico Eco 305	Genérico de alta calidad. Ideal para el hogar o negocio.	38049	800	17	K592	63	\N
254	Genérico Fresco 768	Genérico de alta calidad. Ideal para el hogar o negocio.	78563	302	6	W054	\N	9
255	Genérico Ligero 432	Genérico de alta calidad. Ideal para el hogar o negocio.	35873	943	9	D400	\N	6
256	Genérico Fresco 16	Genérico de alta calidad. Ideal para el hogar o negocio.	78252	700	13	V911	244	\N
257	Genérico Premium 356	Genérico de alta calidad. Ideal para el hogar o negocio.	25624	500	11	L976	\N	7
258	Genérico Deluxe 394	Genérico de alta calidad. Ideal para el hogar o negocio.	78322	301	6	I617	\N	10
259	Jabón Deluxe 424	Jabón de alta calidad. Ideal para el hogar o negocio.	53621	869	5	W054	\N	10
260	Genérico Deluxe 270	Genérico de alta calidad. Ideal para el hogar o negocio.	91837	666	7	Q102	237	\N
261	Jugo Deluxe 869	Jugo de alta calidad. Ideal para el hogar o negocio.	83308	345	3	S957	\N	5
262	Genérico Premium 169	Genérico de alta calidad. Ideal para el hogar o negocio.	4768	172	17	T259	\N	5
263	Bocadillo Max 520	Bocadillo de alta calidad. Ideal para el hogar o negocio.	79886	121	1	W210	\N	8
264	Genérico Express 395	Genérico de alta calidad. Ideal para el hogar o negocio.	49516	165	8	V256	303	\N
265	Genérico Deluxe 319	Genérico de alta calidad. Ideal para el hogar o negocio.	62926	143	16	N646	240	\N
266	Suavizante Deluxe 439	Suavizante de alta calidad. Ideal para el hogar o negocio.	40281	776	5	Q993	7	\N
267	Genérico Eco 634	Genérico de alta calidad. Ideal para el hogar o negocio.	67451	367	7	L326	290	\N
268	Genérico Clásico 395	Genérico de alta calidad. Ideal para el hogar o negocio.	27726	548	6	E258	191	\N
269	Genérico Selecto 510	Genérico de alta calidad. Ideal para el hogar o negocio.	11821	891	7	Z344	\N	6
270	Chips Selecto 778	Chips de alta calidad. Ideal para el hogar o negocio.	78926	530	2	M290	\N	2
271	Chips Clásico 823	Chips de alta calidad. Ideal para el hogar o negocio.	23345	198	2	F022	\N	2
272	Genérico Eco 667	Genérico de alta calidad. Ideal para el hogar o negocio.	45421	105	16	I421	351	\N
273	Genérico Plus 75	Genérico de alta calidad. Ideal para el hogar o negocio.	7221	542	16	E422	\N	7
274	Choclitos Ligero 775	Choclitos de alta calidad. Ideal para el hogar o negocio.	86035	351	2	C983	\N	2
275	Genérico Ligero 322	Genérico de alta calidad. Ideal para el hogar o negocio.	27198	359	9	B835	\N	3
276	Genérico Deluxe 775	Genérico de alta calidad. Ideal para el hogar o negocio.	46898	966	15	V835	411	\N
277	Genérico Premium 148	Genérico de alta calidad. Ideal para el hogar o negocio.	9252	522	6	I750	496	\N
278	Genérico Eco 585	Genérico de alta calidad. Ideal para el hogar o negocio.	65028	804	15	H053	\N	8
279	Genérico Express 618	Genérico de alta calidad. Ideal para el hogar o negocio.	40935	875	6	Z014	444	\N
280	Limpiador Ligero 532	Limpiador de alta calidad. Ideal para el hogar o negocio.	88131	910	5	X510	144	\N
281	Genérico Ligero 212	Genérico de alta calidad. Ideal para el hogar o negocio.	38125	630	8	N246	\N	2
282	Genérico Deluxe 462	Genérico de alta calidad. Ideal para el hogar o negocio.	65228	154	11	Q104	454	\N
283	Genérico Clásico 294	Genérico de alta calidad. Ideal para el hogar o negocio.	64903	478	15	R237	\N	10
284	Genérico Premium 595	Genérico de alta calidad. Ideal para el hogar o negocio.	73619	419	11	L725	359	\N
285	Genérico Express 782	Genérico de alta calidad. Ideal para el hogar o negocio.	74957	745	7	A065	\N	1
286	Genérico Premium 357	Genérico de alta calidad. Ideal para el hogar o negocio.	55306	819	18	D846	366	\N
287	Genérico Deluxe 998	Genérico de alta calidad. Ideal para el hogar o negocio.	46111	939	13	U460	321	\N
288	Mix de maíz Max 638	Mix de maíz de alta calidad. Ideal para el hogar o negocio.	73922	628	2	X435	\N	7
531	Genérico Ligero 451	Genérico de alta calidad. Ideal para el hogar o negocio.	27317	586	15	Q795	309	\N
532	Choclitos Max 113	Choclitos de alta calidad. Ideal para el hogar o negocio.	98860	508	2	U922	\N	10
533	Genérico Premium 664	Genérico de alta calidad. Ideal para el hogar o negocio.	31007	727	18	E322	\N	6
534	Desengrasante Max 240	Desengrasante de alta calidad. Ideal para el hogar o negocio.	19518	48	5	A618	\N	7
535	Yucas Selecto 237	Yucas de alta calidad. Ideal para el hogar o negocio.	81415	530	2	C494	233	\N
536	Malvavisco Eco 428	Malvavisco de alta calidad. Ideal para el hogar o negocio.	56609	964	1	K318	\N	8
537	Genérico Eco 381	Genérico de alta calidad. Ideal para el hogar o negocio.	3270	446	12	I242	350	\N
538	Brandy Selecto 193	Brandy de alta calidad. Ideal para el hogar o negocio.	97432	922	4	B818	\N	9
539	Genérico Express 263	Genérico de alta calidad. Ideal para el hogar o negocio.	33830	687	13	U007	482	\N
540	Choclitos Eco 49	Choclitos de alta calidad. Ideal para el hogar o negocio.	27067	45	2	Y795	\N	4
541	Genérico Max 618	Genérico de alta calidad. Ideal para el hogar o negocio.	25729	818	12	H098	\N	7
542	Aguardiente Deluxe 173	Aguardiente de alta calidad. Ideal para el hogar o negocio.	26759	864	4	S207	60	\N
543	Chifles Eco 971	Chifles de alta calidad. Ideal para el hogar o negocio.	38708	958	2	C918	\N	5
544	Genérico Selecto 722	Genérico de alta calidad. Ideal para el hogar o negocio.	88704	857	12	Y516	303	\N
545	Genérico Deluxe 788	Genérico de alta calidad. Ideal para el hogar o negocio.	11652	721	11	F894	\N	1
546	Genérico Express 623	Genérico de alta calidad. Ideal para el hogar o negocio.	4917	366	12	C783	277	\N
547	Vino Max 820	Vino de alta calidad. Ideal para el hogar o negocio.	52895	671	4	R397	186	\N
548	Genérico Clásico 412	Genérico de alta calidad. Ideal para el hogar o negocio.	2355	351	15	D105	\N	5
549	Genérico Premium 451	Genérico de alta calidad. Ideal para el hogar o negocio.	65747	626	17	K916	\N	10
550	Genérico Fresco 908	Genérico de alta calidad. Ideal para el hogar o negocio.	58799	996	8	L458	333	\N
551	Genérico Premium 358	Genérico de alta calidad. Ideal para el hogar o negocio.	81879	50	8	G152	409	\N
552	Genérico Plus 392	Genérico de alta calidad. Ideal para el hogar o negocio.	74146	375	15	X510	434	\N
553	Genérico Express 368	Genérico de alta calidad. Ideal para el hogar o negocio.	28656	330	7	U007	\N	6
554	Genérico Express 604	Genérico de alta calidad. Ideal para el hogar o negocio.	97658	535	15	X412	\N	3
555	Genérico Eco 868	Genérico de alta calidad. Ideal para el hogar o negocio.	61870	878	7	D823	\N	3
556	Ron Plus 927	Ron de alta calidad. Ideal para el hogar o negocio.	21060	43	4	N870	93	\N
557	Genérico Plus 853	Genérico de alta calidad. Ideal para el hogar o negocio.	68218	627	11	Y426	\N	10
558	Genérico Fresco 692	Genérico de alta calidad. Ideal para el hogar o negocio.	9343	614	15	K592	200	\N
559	Genérico Fresco 255	Genérico de alta calidad. Ideal para el hogar o negocio.	10755	197	16	K318	266	\N
560	Desinfectante Express 963	Desinfectante de alta calidad. Ideal para el hogar o negocio.	40582	229	5	D846	\N	4
561	Genérico Fresco 73	Genérico de alta calidad. Ideal para el hogar o negocio.	36035	897	12	W025	20	\N
562	Genérico Express 666	Genérico de alta calidad. Ideal para el hogar o negocio.	84160	689	16	T461	\N	8
563	Genérico Max 988	Genérico de alta calidad. Ideal para el hogar o negocio.	63048	811	16	L278	\N	3
564	Multiusos Max 940	Multiusos de alta calidad. Ideal para el hogar o negocio.	42209	682	5	E779	\N	8
565	Champaña Max 788	Champaña de alta calidad. Ideal para el hogar o negocio.	65023	659	4	L757	\N	6
566	Genérico Clásico 69	Genérico de alta calidad. Ideal para el hogar o negocio.	7212	403	11	L100	315	\N
567	Nachos Clásico 127	Nachos de alta calidad. Ideal para el hogar o negocio.	32426	794	2	D660	138	\N
568	Genérico Max 669	Genérico de alta calidad. Ideal para el hogar o negocio.	18284	715	16	U085	\N	3
569	Pastillas Deluxe 507	Pastillas de alta calidad. Ideal para el hogar o negocio.	24444	587	1	A960	352	\N
570	Turrón Ligero 324	Turrón de alta calidad. Ideal para el hogar o negocio.	41489	790	1	G724	341	\N
571	Caramelo Deluxe 347	Caramelo de alta calidad. Ideal para el hogar o negocio.	53852	666	1	D400	\N	9
572	Genérico Selecto 520	Genérico de alta calidad. Ideal para el hogar o negocio.	14683	525	13	C899	\N	2
573	Genérico Fresco 408	Genérico de alta calidad. Ideal para el hogar o negocio.	15241	110	17	F506	\N	1
574	Genérico Express 183	Genérico de alta calidad. Ideal para el hogar o negocio.	81399	217	16	K976	75	\N
575	Genérico Plus 442	Genérico de alta calidad. Ideal para el hogar o negocio.	49933	17	18	V797	339	\N
576	Genérico Clásico 627	Genérico de alta calidad. Ideal para el hogar o negocio.	63397	19	11	I225	488	\N
577	Genérico Eco 877	Genérico de alta calidad. Ideal para el hogar o negocio.	26010	803	18	C839	\N	3
578	Desodorizante Selecto 756	Desodorizante de alta calidad. Ideal para el hogar o negocio.	52780	567	5	S207	116	\N
579	Arepitas Express 340	Arepitas de alta calidad. Ideal para el hogar o negocio.	52831	76	2	D311	71	\N
580	Cloro Express 394	Cloro de alta calidad. Ideal para el hogar o negocio.	51200	355	5	Z912	251	\N
581	Suavizante Selecto 691	Suavizante de alta calidad. Ideal para el hogar o negocio.	95988	949	5	F058	78	\N
582	Genérico Express 293	Genérico de alta calidad. Ideal para el hogar o negocio.	32981	287	11	D445	\N	5
583	Limpiavidrios Clásico 548	Limpiavidrios de alta calidad. Ideal para el hogar o negocio.	87339	869	5	T721	\N	2
584	Tequila Clásico 910	Tequila de alta calidad. Ideal para el hogar o negocio.	5192	250	4	U784	307	\N
585	Genérico Premium 976	Genérico de alta calidad. Ideal para el hogar o negocio.	28381	693	9	R742	75	\N
586	Gaseosa Max 494	Gaseosa de alta calidad. Ideal para el hogar o negocio.	2081	446	3	Q815	303	\N
587	Bebida energética Ligero 73	Bebida energética de alta calidad. Ideal para el hogar o negocio.	61357	112	3	X043	440	\N
588	Turrón Fresco 455	Turrón de alta calidad. Ideal para el hogar o negocio.	57225	599	1	Q670	\N	10
589	Genérico Fresco 749	Genérico de alta calidad. Ideal para el hogar o negocio.	24411	919	11	Q178	\N	8
590	Yucas Deluxe 588	Yucas de alta calidad. Ideal para el hogar o negocio.	18024	394	2	N727	200	\N
591	Genérico Selecto 854	Genérico de alta calidad. Ideal para el hogar o negocio.	11336	266	6	J573	\N	10
592	Genérico Plus 598	Genérico de alta calidad. Ideal para el hogar o negocio.	47835	983	9	D578	\N	2
593	Genérico Clásico 633	Genérico de alta calidad. Ideal para el hogar o negocio.	40608	842	6	M112	440	\N
594	Genérico Deluxe 543	Genérico de alta calidad. Ideal para el hogar o negocio.	42227	951	9	K218	334	\N
595	Refresco Fresco 763	Refresco de alta calidad. Ideal para el hogar o negocio.	24708	319	3	S866	287	\N
596	Pastillas Max 614	Pastillas de alta calidad. Ideal para el hogar o negocio.	80680	614	1	R500	\N	3
597	Jabón Express 951	Jabón de alta calidad. Ideal para el hogar o negocio.	8174	827	5	S673	\N	4
598	Genérico Ligero 362	Genérico de alta calidad. Ideal para el hogar o negocio.	22586	680	12	H165	\N	10
599	Genérico Fresco 575	Genérico de alta calidad. Ideal para el hogar o negocio.	1779	568	16	T444	106	\N
600	Genérico Express 295	Genérico de alta calidad. Ideal para el hogar o negocio.	90210	723	12	F465	\N	1
601	Genérico Plus 140	Genérico de alta calidad. Ideal para el hogar o negocio.	18643	349	18	A123	224	\N
602	Cloro Express 508	Cloro de alta calidad. Ideal para el hogar o negocio.	83058	42	5	L131	451	\N
603	Genérico Selecto 197	Genérico de alta calidad. Ideal para el hogar o negocio.	29777	475	12	K196	\N	7
604	Genérico Selecto 992	Genérico de alta calidad. Ideal para el hogar o negocio.	46034	393	16	V310	359	\N
605	Genérico Eco 266	Genérico de alta calidad. Ideal para el hogar o negocio.	25223	189	18	H010	\N	7
606	Genérico Eco 588	Genérico de alta calidad. Ideal para el hogar o negocio.	70315	230	11	C311	\N	9
607	Genérico Premium 636	Genérico de alta calidad. Ideal para el hogar o negocio.	72130	918	12	F249	394	\N
608	Turrón Premium 498	Turrón de alta calidad. Ideal para el hogar o negocio.	85560	670	1	Z688	\N	8
609	Genérico Plus 836	Genérico de alta calidad. Ideal para el hogar o negocio.	38218	758	11	I623	260	\N
610	Aguardiente Fresco 89	Aguardiente de alta calidad. Ideal para el hogar o negocio.	97412	320	4	G777	\N	1
611	Genérico Ligero 210	Genérico de alta calidad. Ideal para el hogar o negocio.	71523	768	17	N291	\N	7
612	Genérico Ligero 705	Genérico de alta calidad. Ideal para el hogar o negocio.	47945	219	16	T967	\N	4
613	Genérico Fresco 849	Genérico de alta calidad. Ideal para el hogar o negocio.	40637	442	12	R878	\N	1
614	Genérico Max 77	Genérico de alta calidad. Ideal para el hogar o negocio.	47210	157	9	K196	\N	3
615	Genérico Selecto 2100	Genérico de alta calidad. Ideal para el hogar o negocio.	8862	570	8	E073	\N	9
616	Papas Plus 724	Papas de alta calidad. Ideal para el hogar o negocio.	34182	340	2	E322	\N	1
617	Genérico Premium 269	Genérico de alta calidad. Ideal para el hogar o negocio.	10272	870	13	Q871	\N	3
618	Genérico Selecto 58	Genérico de alta calidad. Ideal para el hogar o negocio.	98238	914	8	J082	211	\N
619	Genérico Premium 769	Genérico de alta calidad. Ideal para el hogar o negocio.	35251	688	9	B835	\N	3
620	Genérico Clásico 928	Genérico de alta calidad. Ideal para el hogar o negocio.	27442	742	12	G073	275	\N
621	Ginebra Eco 733	Ginebra de alta calidad. Ideal para el hogar o negocio.	1344	258	4	B056	283	\N
622	Gaseosa Fresco 124	Gaseosa de alta calidad. Ideal para el hogar o negocio.	91235	889	3	Y195	483	\N
623	Ginebra Clásico 893	Ginebra de alta calidad. Ideal para el hogar o negocio.	85348	648	4	E826	\N	7
624	Gaseosa Ligero 945	Gaseosa de alta calidad. Ideal para el hogar o negocio.	44300	47	3	D311	\N	4
625	Choclitos Clásico 246	Choclitos de alta calidad. Ideal para el hogar o negocio.	62530	728	2	X574	173	\N
626	Genérico Deluxe 284	Genérico de alta calidad. Ideal para el hogar o negocio.	13794	87	16	I318	250	\N
627	Genérico Premium 718	Genérico de alta calidad. Ideal para el hogar o negocio.	80293	431	17	R942	\N	5
628	Genérico Ligero 810	Genérico de alta calidad. Ideal para el hogar o negocio.	19287	886	8	C102	362	\N
629	Genérico Deluxe 540	Genérico de alta calidad. Ideal para el hogar o negocio.	62315	879	17	I461	\N	9
630	Mazapán Deluxe 864	Mazapán de alta calidad. Ideal para el hogar o negocio.	53609	687	1	Z624	376	\N
631	Genérico Fresco 492	Genérico de alta calidad. Ideal para el hogar o negocio.	41903	853	17	F506	183	\N
632	Gaseosa Express 922	Gaseosa de alta calidad. Ideal para el hogar o negocio.	93528	313	3	Z710	498	\N
633	Genérico Max 150	Genérico de alta calidad. Ideal para el hogar o negocio.	2510	470	12	F249	235	\N
634	Genérico Deluxe 684	Genérico de alta calidad. Ideal para el hogar o negocio.	93582	757	17	M112	297	\N
635	Genérico Plus 893	Genérico de alta calidad. Ideal para el hogar o negocio.	43178	49	8	A767	\N	6
636	Genérico Clásico 323	Genérico de alta calidad. Ideal para el hogar o negocio.	50631	636	17	X090	\N	3
637	Té Premium 557	Té de alta calidad. Ideal para el hogar o negocio.	73814	635	3	P687	276	\N
638	Arepitas Selecto 453	Arepitas de alta calidad. Ideal para el hogar o negocio.	43547	742	2	B307	\N	2
639	Genérico Clásico 745	Genérico de alta calidad. Ideal para el hogar o negocio.	33984	690	17	H588	55	\N
640	Genérico Premium 108	Genérico de alta calidad. Ideal para el hogar o negocio.	92679	408	13	D823	\N	6
641	Mazapán Fresco 947	Mazapán de alta calidad. Ideal para el hogar o negocio.	68265	719	1	Z109	42	\N
642	Genérico Deluxe 694	Genérico de alta calidad. Ideal para el hogar o negocio.	58881	447	7	C314	\N	8
643	Malta Express 468	Malta de alta calidad. Ideal para el hogar o negocio.	17309	689	3	R942	355	\N
644	Malvavisco Selecto 591	Malvavisco de alta calidad. Ideal para el hogar o negocio.	5522	187	1	C300	\N	7
645	Genérico Plus 548	Genérico de alta calidad. Ideal para el hogar o negocio.	77689	762	7	I461	84	\N
646	Jabón Plus 882	Jabón de alta calidad. Ideal para el hogar o negocio.	85178	244	5	R742	304	\N
647	Gomitas Max 543	Gomitas de alta calidad. Ideal para el hogar o negocio.	42169	220	1	H925	346	\N
648	Genérico Selecto 460	Genérico de alta calidad. Ideal para el hogar o negocio.	96337	612	17	H098	266	\N
649	Genérico Fresco 593	Genérico de alta calidad. Ideal para el hogar o negocio.	3481	999	11	D445	329	\N
650	Agua Selecto 846	Agua de alta calidad. Ideal para el hogar o negocio.	96975	770	3	N250	\N	5
651	Genérico Express 783	Genérico de alta calidad. Ideal para el hogar o negocio.	64848	809	15	I617	431	\N
652	Chifles Ligero 307	Chifles de alta calidad. Ideal para el hogar o negocio.	80328	615	2	U133	98	\N
653	Bebida de frutas Selecto 924	Bebida de frutas de alta calidad. Ideal para el hogar o negocio.	13721	79	3	S720	71	\N
654	Genérico Max 750	Genérico de alta calidad. Ideal para el hogar o negocio.	96134	573	18	L274	\N	8
655	Genérico Premium 719	Genérico de alta calidad. Ideal para el hogar o negocio.	47275	468	8	D978	\N	9
656	Genérico Premium 345	Genérico de alta calidad. Ideal para el hogar o negocio.	48382	167	7	Z504	32	\N
657	Whisky Deluxe 938	Whisky de alta calidad. Ideal para el hogar o negocio.	50311	280	4	E057	388	\N
658	Genérico Premium 2638	Genérico de alta calidad. Ideal para el hogar o negocio.	91143	678	7	N948	377	\N
659	Genérico Eco 428	Genérico de alta calidad. Ideal para el hogar o negocio.	77771	399	9	P044	\N	7
660	Genérico Fresco 196	Genérico de alta calidad. Ideal para el hogar o negocio.	64418	911	16	Q144	184	\N
661	Genérico Express 137	Genérico de alta calidad. Ideal para el hogar o negocio.	60176	264	9	U835	12	\N
662	Yucas Plus 212	Yucas de alta calidad. Ideal para el hogar o negocio.	70772	703	2	V754	\N	10
663	Genérico Ligero 505	Genérico de alta calidad. Ideal para el hogar o negocio.	48611	374	16	H902	434	\N
664	Genérico Deluxe 898	Genérico de alta calidad. Ideal para el hogar o negocio.	7307	882	15	U188	\N	8
665	Genérico Fresco 882	Genérico de alta calidad. Ideal para el hogar o negocio.	28482	441	7	R475	75	\N
666	Genérico Ligero 265	Genérico de alta calidad. Ideal para el hogar o negocio.	77237	987	7	P727	403	\N
667	Bebida energética Deluxe 770	Bebida energética de alta calidad. Ideal para el hogar o negocio.	11706	483	3	T332	\N	7
668	Genérico Ligero 558	Genérico de alta calidad. Ideal para el hogar o negocio.	76169	244	16	V310	\N	5
669	Desinfectante Plus 948	Desinfectante de alta calidad. Ideal para el hogar o negocio.	21996	447	5	R397	\N	10
670	Genérico Deluxe 136	Genérico de alta calidad. Ideal para el hogar o negocio.	20700	934	18	I046	\N	2
671	Genérico Clásico 157	Genérico de alta calidad. Ideal para el hogar o negocio.	9360	838	13	H080	159	\N
672	Tostacos Express 855	Tostacos de alta calidad. Ideal para el hogar o negocio.	17850	641	2	M930	75	\N
673	Genérico Plus 426	Genérico de alta calidad. Ideal para el hogar o negocio.	78785	987	13	J745	\N	8
674	Genérico Eco 605	Genérico de alta calidad. Ideal para el hogar o negocio.	92770	54	12	G152	\N	3
675	Genérico Plus 942	Genérico de alta calidad. Ideal para el hogar o negocio.	63072	658	8	U460	\N	3
676	Genérico Deluxe 865	Genérico de alta calidad. Ideal para el hogar o negocio.	91083	224	18	T259	388	\N
677	Chicle Fresco 463	Chicle de alta calidad. Ideal para el hogar o negocio.	42249	493	1	D978	437	\N
678	Genérico Ligero 427	Genérico de alta calidad. Ideal para el hogar o negocio.	65292	383	7	D823	\N	9
679	Genérico Fresco 887	Genérico de alta calidad. Ideal para el hogar o negocio.	55430	187	8	I115	79	\N
680	Genérico Plus 930	Genérico de alta calidad. Ideal para el hogar o negocio.	31792	430	13	T967	\N	3
681	Genérico Selecto 792	Genérico de alta calidad. Ideal para el hogar o negocio.	42869	172	17	C339	\N	5
682	Jabón Premium 212	Jabón de alta calidad. Ideal para el hogar o negocio.	93372	465	5	U708	\N	4
683	Genérico Ligero 15	Genérico de alta calidad. Ideal para el hogar o negocio.	76235	202	16	M475	\N	2
684	Jugo Eco 57	Jugo de alta calidad. Ideal para el hogar o negocio.	36167	536	3	E826	\N	10
685	Genérico Plus 613	Genérico de alta calidad. Ideal para el hogar o negocio.	88252	151	9	C494	55	\N
686	Genérico Max 166	Genérico de alta calidad. Ideal para el hogar o negocio.	73581	45	11	L332	\N	9
687	Desodorizante Plus 123	Desodorizante de alta calidad. Ideal para el hogar o negocio.	60745	668	5	Q871	298	\N
688	Mazapán Premium 361	Mazapán de alta calidad. Ideal para el hogar o negocio.	90812	918	1	O230	362	\N
689	Genérico Max 5778	Genérico de alta calidad. Ideal para el hogar o negocio.	44873	340	17	I067	339	\N
690	Limpiador Clásico 753	Limpiador de alta calidad. Ideal para el hogar o negocio.	11939	147	5	F799	\N	8
691	Genérico Eco 188	Genérico de alta calidad. Ideal para el hogar o negocio.	74500	798	12	G628	79	\N
692	Genérico Deluxe 19	Genérico de alta calidad. Ideal para el hogar o negocio.	62318	796	9	I461	\N	10
693	Mazapán Express 963	Mazapán de alta calidad. Ideal para el hogar o negocio.	33440	907	1	X314	\N	5
694	Chifles Deluxe 49	Chifles de alta calidad. Ideal para el hogar o negocio.	90114	655	2	I105	\N	4
695	Aguardiente Express 875	Aguardiente de alta calidad. Ideal para el hogar o negocio.	16149	494	4	D846	49	\N
696	Genérico Selecto 66	Genérico de alta calidad. Ideal para el hogar o negocio.	93289	267	9	Y426	\N	9
697	Genérico Express 895	Genérico de alta calidad. Ideal para el hogar o negocio.	5199	52	7	F249	31	\N
698	Jugo Fresco 208	Jugo de alta calidad. Ideal para el hogar o negocio.	61841	847	3	N646	\N	5
699	Genérico Deluxe 170	Genérico de alta calidad. Ideal para el hogar o negocio.	44048	9	8	M290	\N	10
700	Genérico Deluxe 33	Genérico de alta calidad. Ideal para el hogar o negocio.	16519	903	18	H707	95	\N
701	Genérico Deluxe 200	Genérico de alta calidad. Ideal para el hogar o negocio.	75765	960	12	L326	\N	3
702	Bebida energética Clásico 533	Bebida energética de alta calidad. Ideal para el hogar o negocio.	48842	700	3	R397	\N	3
703	Genérico Ligero 644	Genérico de alta calidad. Ideal para el hogar o negocio.	38270	222	15	B841	240	\N
704	Genérico Clásico 327	Genérico de alta calidad. Ideal para el hogar o negocio.	42983	458	13	L278	217	\N
705	Pastillas Ligero 771	Pastillas de alta calidad. Ideal para el hogar o negocio.	55517	919	1	B841	281	\N
706	Genérico Plus 373	Genérico de alta calidad. Ideal para el hogar o negocio.	98418	51	13	U103	338	\N
707	Genérico Plus 629	Genérico de alta calidad. Ideal para el hogar o negocio.	13331	57	9	P790	\N	8
708	Genérico Selecto 347	Genérico de alta calidad. Ideal para el hogar o negocio.	41267	909	7	M116	184	\N
709	Genérico Max 446	Genérico de alta calidad. Ideal para el hogar o negocio.	93017	934	12	U460	\N	2
710	Whisky Deluxe 204	Whisky de alta calidad. Ideal para el hogar o negocio.	19283	870	4	F845	\N	9
711	Brandy Clásico 370	Brandy de alta calidad. Ideal para el hogar o negocio.	64202	633	4	M680	\N	6
712	Bocadillo Premium 21	Bocadillo de alta calidad. Ideal para el hogar o negocio.	1674	847	1	F952	\N	7
713	Limpiador Express 850	Limpiador de alta calidad. Ideal para el hogar o negocio.	19733	265	5	E038	\N	8
714	Mazapán Premium 731	Mazapán de alta calidad. Ideal para el hogar o negocio.	38798	817	1	L100	352	\N
715	Genérico Premium 946	Genérico de alta calidad. Ideal para el hogar o negocio.	17431	340	15	S789	63	\N
716	Energizante Clásico 541	Energizante de alta calidad. Ideal para el hogar o negocio.	72482	132	3	V256	348	\N
717	Turrón Express 279	Turrón de alta calidad. Ideal para el hogar o negocio.	85976	759	1	D788	\N	2
718	Genérico Eco 745	Genérico de alta calidad. Ideal para el hogar o negocio.	35223	292	12	M557	\N	3
719	Desodorizante Deluxe 325	Desodorizante de alta calidad. Ideal para el hogar o negocio.	39088	952	5	M662	69	\N
720	Genérico Fresco 781	Genérico de alta calidad. Ideal para el hogar o negocio.	48049	217	15	B265	\N	9
721	Suavizante Selecto 678	Suavizante de alta calidad. Ideal para el hogar o negocio.	62736	830	5	Q993	389	\N
722	Genérico Plus 46	Genérico de alta calidad. Ideal para el hogar o negocio.	27836	374	8	G548	\N	5
723	Genérico Premium 731	Genérico de alta calidad. Ideal para el hogar o negocio.	2498	101	16	E933	62	\N
724	Genérico Clásico 905	Genérico de alta calidad. Ideal para el hogar o negocio.	54883	372	6	Y426	166	\N
725	Desinfectante Eco 561	Desinfectante de alta calidad. Ideal para el hogar o negocio.	56988	168	5	A209	176	\N
726	Genérico Deluxe 424	Genérico de alta calidad. Ideal para el hogar o negocio.	55379	57	12	F246	\N	4
727	Genérico Premium 400	Genérico de alta calidad. Ideal para el hogar o negocio.	87966	7	18	L458	376	\N
728	Bebida de frutas Premium 589	Bebida de frutas de alta calidad. Ideal para el hogar o negocio.	71910	595	3	G694	\N	7
729	Jabón Premium 582	Jabón de alta calidad. Ideal para el hogar o negocio.	55533	203	5	T721	\N	10
730	Genérico Deluxe 554	Genérico de alta calidad. Ideal para el hogar o negocio.	71573	91	8	X043	390	\N
731	Genérico Plus 7	Genérico de alta calidad. Ideal para el hogar o negocio.	10977	524	15	J411	\N	2
732	Genérico Clásico 150	Genérico de alta calidad. Ideal para el hogar o negocio.	14159	171	6	Z688	481	\N
733	Genérico Express 741	Genérico de alta calidad. Ideal para el hogar o negocio.	66554	515	8	C052	\N	2
734	Genérico Ligero 228	Genérico de alta calidad. Ideal para el hogar o negocio.	72882	519	18	O850	\N	8
735	Genérico Eco 360	Genérico de alta calidad. Ideal para el hogar o negocio.	2786	765	18	F022	\N	4
736	Genérico Max 823	Genérico de alta calidad. Ideal para el hogar o negocio.	36667	796	13	I421	357	\N
737	Genérico Clásico 786	Genérico de alta calidad. Ideal para el hogar o negocio.	71984	883	11	B716	\N	6
738	Genérico Clásico 112	Genérico de alta calidad. Ideal para el hogar o negocio.	9376	644	15	R384	295	\N
739	Turrón Max 390	Turrón de alta calidad. Ideal para el hogar o negocio.	29747	344	1	R878	201	\N
740	Genérico Plus 308	Genérico de alta calidad. Ideal para el hogar o negocio.	93466	895	8	R237	409	\N
741	Genérico Selecto 336	Genérico de alta calidad. Ideal para el hogar o negocio.	91972	622	15	H925	\N	6
742	Nachos Max 286	Nachos de alta calidad. Ideal para el hogar o negocio.	9331	520	2	B835	464	\N
743	Genérico Fresco 95	Genérico de alta calidad. Ideal para el hogar o negocio.	32985	307	8	K976	\N	6
744	Agua Max 590	Agua de alta calidad. Ideal para el hogar o negocio.	99325	909	3	S541	\N	4
745	Genérico Eco 746	Genérico de alta calidad. Ideal para el hogar o negocio.	23848	634	17	Y195	300	\N
746	Genérico Ligero 255	Genérico de alta calidad. Ideal para el hogar o negocio.	52311	73	12	G256	\N	4
747	Suavizante Eco 531	Suavizante de alta calidad. Ideal para el hogar o negocio.	56300	984	5	A467	301	\N
748	Vino Max 713	Vino de alta calidad. Ideal para el hogar o negocio.	27348	854	4	Z666	102	\N
749	Genérico Fresco 764	Genérico de alta calidad. Ideal para el hogar o negocio.	67940	31	6	G627	422	\N
750	Genérico Plus 725	Genérico de alta calidad. Ideal para el hogar o negocio.	70978	808	7	G265	291	\N
751	Genérico Ligero 65	Genérico de alta calidad. Ideal para el hogar o negocio.	32021	518	12	M662	\N	4
752	Genérico Express 776	Genérico de alta calidad. Ideal para el hogar o negocio.	79932	444	6	W510	396	\N
753	Genérico Deluxe 368	Genérico de alta calidad. Ideal para el hogar o negocio.	22811	928	6	I735	192	\N
754	Refresco Clásico 557	Refresco de alta calidad. Ideal para el hogar o negocio.	71249	171	3	R942	\N	1
755	Arepitas Selecto 918	Arepitas de alta calidad. Ideal para el hogar o negocio.	62656	293	2	G628	\N	2
756	Desinfectante Ligero 952	Desinfectante de alta calidad. Ideal para el hogar o negocio.	77556	346	5	G628	\N	5
757	Genérico Fresco 907	Genérico de alta calidad. Ideal para el hogar o negocio.	22286	501	16	G152	\N	2
758	Genérico Clásico 89	Genérico de alta calidad. Ideal para el hogar o negocio.	70571	844	11	K358	149	\N
759	Genérico Selecto 335	Genérico de alta calidad. Ideal para el hogar o negocio.	51626	81	17	X080	\N	9
760	Caramelo Plus 392	Caramelo de alta calidad. Ideal para el hogar o negocio.	88416	742	1	B818	\N	7
761	Genérico Eco 263	Genérico de alta calidad. Ideal para el hogar o negocio.	40067	188	12	E051	339	\N
762	Genérico Ligero 926	Genérico de alta calidad. Ideal para el hogar o negocio.	35664	708	8	L302	\N	1
763	Genérico Max 87	Genérico de alta calidad. Ideal para el hogar o negocio.	78075	440	8	A209	401	\N
764	Gomitas Selecto 200	Gomitas de alta calidad. Ideal para el hogar o negocio.	3083	957	1	W229	\N	3
765	Caramelo Premium 198	Caramelo de alta calidad. Ideal para el hogar o negocio.	91761	173	1	H473	125	\N
766	Pastillas Selecto 726	Pastillas de alta calidad. Ideal para el hogar o negocio.	78519	993	1	G724	\N	1
767	Genérico Eco 443	Genérico de alta calidad. Ideal para el hogar o negocio.	96774	507	17	J137	388	\N
768	Genérico Ligero 561	Genérico de alta calidad. Ideal para el hogar o negocio.	85387	67	8	I115	351	\N
769	Desengrasante Express 823	Desengrasante de alta calidad. Ideal para el hogar o negocio.	11253	134	5	E826	\N	2
770	Papas Premium 3	Papas de alta calidad. Ideal para el hogar o negocio.	32097	48	2	R384	105	\N
771	Malvavisco Express 61	Malvavisco de alta calidad. Ideal para el hogar o negocio.	85484	157	1	I806	213	\N
772	Genérico Ligero 524	Genérico de alta calidad. Ideal para el hogar o negocio.	2803	976	13	N948	258	\N
773	Genérico Clásico 345	Genérico de alta calidad. Ideal para el hogar o negocio.	57325	482	17	F506	\N	6
774	Genérico Selecto 764	Genérico de alta calidad. Ideal para el hogar o negocio.	46567	225	12	A077	\N	4
775	Genérico Ligero 232	Genérico de alta calidad. Ideal para el hogar o negocio.	72750	954	15	R942	\N	9
776	Genérico Eco 245	Genérico de alta calidad. Ideal para el hogar o negocio.	12189	574	17	U347	422	\N
777	Gomitas Premium 599	Gomitas de alta calidad. Ideal para el hogar o negocio.	93804	810	1	F716	\N	4
778	Genérico Express 816	Genérico de alta calidad. Ideal para el hogar o negocio.	5805	356	11	Y516	205	\N
779	Cloro Eco 113	Cloro de alta calidad. Ideal para el hogar o negocio.	1768	105	5	N291	\N	3
780	Genérico Plus 477	Genérico de alta calidad. Ideal para el hogar o negocio.	8184	357	15	S957	469	\N
781	Genérico Selecto 568	Genérico de alta calidad. Ideal para el hogar o negocio.	81433	971	17	U949	302	\N
782	Genérico Eco 686	Genérico de alta calidad. Ideal para el hogar o negocio.	39413	747	12	J480	244	\N
783	Genérico Ligero 758	Genérico de alta calidad. Ideal para el hogar o negocio.	12038	203	7	C297	\N	4
784	Genérico Plus 664	Genérico de alta calidad. Ideal para el hogar o negocio.	69021	451	15	Z056	191	\N
785	Genérico Selecto 674	Genérico de alta calidad. Ideal para el hogar o negocio.	79804	121	6	F163	\N	3
786	Genérico Eco 391	Genérico de alta calidad. Ideal para el hogar o negocio.	80452	871	18	I881	15	\N
787	Genérico Selecto 866	Genérico de alta calidad. Ideal para el hogar o negocio.	14662	263	7	G781	112	\N
788	Genérico Max 276	Genérico de alta calidad. Ideal para el hogar o negocio.	83012	995	15	X332	\N	6
789	Genérico Selecto 75	Genérico de alta calidad. Ideal para el hogar o negocio.	89839	131	17	T300	\N	4
790	Genérico Plus 771	Genérico de alta calidad. Ideal para el hogar o negocio.	32374	574	15	D905	113	\N
791	Suavizante Deluxe 267	Suavizante de alta calidad. Ideal para el hogar o negocio.	79023	905	5	G152	3	\N
792	Genérico Eco 204	Genérico de alta calidad. Ideal para el hogar o negocio.	58052	565	18	D037	51	\N
793	Genérico Fresco 229	Genérico de alta calidad. Ideal para el hogar o negocio.	62038	928	7	X080	\N	10
794	Pastillas Premium 431	Pastillas de alta calidad. Ideal para el hogar o negocio.	53789	769	1	G712	\N	1
795	Genérico Max 676	Genérico de alta calidad. Ideal para el hogar o negocio.	95069	522	18	O539	32	\N
796	Genérico Clásico 297	Genérico de alta calidad. Ideal para el hogar o negocio.	53728	127	16	K985	\N	5
797	Genérico Clásico 353	Genérico de alta calidad. Ideal para el hogar o negocio.	95121	769	8	C699	92	\N
798	Genérico Selecto 388	Genérico de alta calidad. Ideal para el hogar o negocio.	97747	301	12	M743	\N	6
799	Genérico Fresco 495	Genérico de alta calidad. Ideal para el hogar o negocio.	9478	116	18	D037	101	\N
800	Cloro Fresco 9	Cloro de alta calidad. Ideal para el hogar o negocio.	18458	890	5	S354	500	\N
801	Genérico Fresco 21	Genérico de alta calidad. Ideal para el hogar o negocio.	73811	28	6	V835	\N	9
802	Yucas Selecto 89	Yucas de alta calidad. Ideal para el hogar o negocio.	78780	466	2	E622	146	\N
803	Genérico Fresco 618	Genérico de alta calidad. Ideal para el hogar o negocio.	46593	299	18	B841	131	\N
804	Genérico Deluxe 833	Genérico de alta calidad. Ideal para el hogar o negocio.	27032	355	7	P392	\N	7
805	Genérico Ligero 52	Genérico de alta calidad. Ideal para el hogar o negocio.	66151	900	7	N083	\N	9
806	Genérico Max 337	Genérico de alta calidad. Ideal para el hogar o negocio.	30483	715	15	L080	\N	4
807	Mix de maíz Plus 907	Mix de maíz de alta calidad. Ideal para el hogar o negocio.	93339	578	2	R384	329	\N
808	Genérico Selecto 269	Genérico de alta calidad. Ideal para el hogar o negocio.	18594	74	17	T967	\N	5
809	Genérico Clásico 734	Genérico de alta calidad. Ideal para el hogar o negocio.	93393	418	11	X032	288	\N
810	Genérico Selecto 137	Genérico de alta calidad. Ideal para el hogar o negocio.	40848	757	12	C494	\N	6
811	Genérico Express 266	Genérico de alta calidad. Ideal para el hogar o negocio.	47866	183	15	I806	\N	2
812	Genérico Selecto 458	Genérico de alta calidad. Ideal para el hogar o negocio.	39262	703	15	P044	331	\N
813	Genérico Plus 948	Genérico de alta calidad. Ideal para el hogar o negocio.	98581	767	18	D094	\N	8
814	Genérico Premium 838	Genérico de alta calidad. Ideal para el hogar o negocio.	71189	939	17	T082	\N	7
815	Limonada Clásico 992	Limonada de alta calidad. Ideal para el hogar o negocio.	95493	538	3	U198	\N	8
816	Genérico Premium 419	Genérico de alta calidad. Ideal para el hogar o negocio.	23327	937	16	F506	\N	3
817	Genérico Clásico 814	Genérico de alta calidad. Ideal para el hogar o negocio.	38824	716	12	U367	450	\N
818	Genérico Premium 259	Genérico de alta calidad. Ideal para el hogar o negocio.	11933	721	7	O047	\N	1
819	Suavizante Ligero 583	Suavizante de alta calidad. Ideal para el hogar o negocio.	80686	960	5	F246	3	\N
820	Genérico Premium 211	Genérico de alta calidad. Ideal para el hogar o negocio.	95236	331	8	C635	414	\N
821	Arepitas Premium 520	Arepitas de alta calidad. Ideal para el hogar o negocio.	70165	694	2	D037	10	\N
822	Té Fresco 591	Té de alta calidad. Ideal para el hogar o negocio.	37943	586	3	E140	93	\N
823	Genérico Deluxe 588	Genérico de alta calidad. Ideal para el hogar o negocio.	72375	823	16	A554	312	\N
824	Caramelo Express 9	Caramelo de alta calidad. Ideal para el hogar o negocio.	6939	369	1	J082	54	\N
825	Jugo Fresco 742	Jugo de alta calidad. Ideal para el hogar o negocio.	58902	574	3	C272	\N	8
826	Genérico Max 787	Genérico de alta calidad. Ideal para el hogar o negocio.	47182	367	12	Y795	\N	5
827	Genérico Plus 878	Genérico de alta calidad. Ideal para el hogar o negocio.	96137	755	17	J411	347	\N
828	Genérico Express 652	Genérico de alta calidad. Ideal para el hogar o negocio.	87539	913	16	G665	\N	7
829	Genérico Clásico 589	Genérico de alta calidad. Ideal para el hogar o negocio.	38392	819	15	E073	110	\N
830	Genérico Fresco 753	Genérico de alta calidad. Ideal para el hogar o negocio.	88864	708	6	F362	352	\N
831	Genérico Fresco 221	Genérico de alta calidad. Ideal para el hogar o negocio.	83726	99	13	O994	482	\N
832	Genérico Premium 414	Genérico de alta calidad. Ideal para el hogar o negocio.	41951	250	17	T461	499	\N
833	Mix de maíz Max 390	Mix de maíz de alta calidad. Ideal para el hogar o negocio.	16752	78	2	P309	64	\N
834	Genérico Plus 183	Genérico de alta calidad. Ideal para el hogar o negocio.	68647	613	17	F845	\N	7
835	Limonada Deluxe 786	Limonada de alta calidad. Ideal para el hogar o negocio.	11112	293	3	O520	\N	6
836	Genérico Plus 896	Genérico de alta calidad. Ideal para el hogar o negocio.	62987	16	6	G712	\N	2
837	Genérico Deluxe 3647	Genérico de alta calidad. Ideal para el hogar o negocio.	93909	576	7	M930	\N	4
838	Genérico Plus 71	Genérico de alta calidad. Ideal para el hogar o negocio.	56722	771	16	P531	242	\N
839	Genérico Max 92	Genérico de alta calidad. Ideal para el hogar o negocio.	31216	29	9	Z912	351	\N
840	Genérico Clásico 187	Genérico de alta calidad. Ideal para el hogar o negocio.	80706	653	7	I115	169	\N
841	Genérico Fresco 289	Genérico de alta calidad. Ideal para el hogar o negocio.	11875	176	11	A618	322	\N
842	Genérico Selecto 834	Genérico de alta calidad. Ideal para el hogar o negocio.	18236	690	7	F031	368	\N
843	Genérico Ligero 588	Genérico de alta calidad. Ideal para el hogar o negocio.	5189	155	17	D173	\N	2
844	Genérico Ligero 545	Genérico de alta calidad. Ideal para el hogar o negocio.	84297	251	17	S207	263	\N
845	Genérico Clásico 207	Genérico de alta calidad. Ideal para el hogar o negocio.	19743	363	18	O876	389	\N
846	Genérico Express 161	Genérico de alta calidad. Ideal para el hogar o negocio.	26414	605	18	V310	\N	9
847	Genérico Selecto 173	Genérico de alta calidad. Ideal para el hogar o negocio.	21613	382	18	T082	285	\N
848	Malvavisco Max 262	Malvavisco de alta calidad. Ideal para el hogar o negocio.	49003	730	1	V477	\N	5
849	Genérico Premium 572	Genérico de alta calidad. Ideal para el hogar o negocio.	18988	898	7	I225	\N	9
850	Jugo Premium 266	Jugo de alta calidad. Ideal para el hogar o negocio.	9293	824	3	T332	\N	4
851	Genérico Deluxe 927	Genérico de alta calidad. Ideal para el hogar o negocio.	12014	949	16	H424	415	\N
852	Genérico Plus 419	Genérico de alta calidad. Ideal para el hogar o negocio.	30468	204	15	C867	120	\N
853	Genérico Clásico 373	Genérico de alta calidad. Ideal para el hogar o negocio.	31305	97	12	Z912	424	\N
854	Agua Ligero 112	Agua de alta calidad. Ideal para el hogar o negocio.	39211	454	3	M905	168	\N
855	Jabón Eco 539	Jabón de alta calidad. Ideal para el hogar o negocio.	76385	638	5	T952	\N	3
856	Ginebra Express 496	Ginebra de alta calidad. Ideal para el hogar o negocio.	70484	67	4	C783	417	\N
857	Genérico Clásico 238	Genérico de alta calidad. Ideal para el hogar o negocio.	52817	770	17	N192	\N	3
858	Genérico Plus 257	Genérico de alta calidad. Ideal para el hogar o negocio.	40753	182	15	W826	40	\N
859	Genérico Express 705	Genérico de alta calidad. Ideal para el hogar o negocio.	66383	519	9	W940	297	\N
860	Genérico Selecto 893	Genérico de alta calidad. Ideal para el hogar o negocio.	30962	816	16	Q595	314	\N
861	Genérico Express 227	Genérico de alta calidad. Ideal para el hogar o negocio.	87918	953	11	T952	\N	6
862	Genérico Eco 657	Genérico de alta calidad. Ideal para el hogar o negocio.	24629	890	11	A722	494	\N
863	Genérico Plus 338	Genérico de alta calidad. Ideal para el hogar o negocio.	87431	680	17	J603	\N	3
864	Desinfectante Express 668	Desinfectante de alta calidad. Ideal para el hogar o negocio.	42640	482	5	C596	212	\N
865	Genérico Clásico 3	Genérico de alta calidad. Ideal para el hogar o negocio.	12794	429	12	U010	\N	9
866	Genérico Deluxe 764	Genérico de alta calidad. Ideal para el hogar o negocio.	85437	140	7	C965	129	\N
867	Genérico Express 463	Genérico de alta calidad. Ideal para el hogar o negocio.	63108	478	18	T967	158	\N
868	Genérico Deluxe 287	Genérico de alta calidad. Ideal para el hogar o negocio.	95877	241	12	B039	\N	1
869	Chocolate Clásico 372	Chocolate de alta calidad. Ideal para el hogar o negocio.	80357	738	1	U460	\N	2
870	Genérico Fresco 737	Genérico de alta calidad. Ideal para el hogar o negocio.	28499	779	17	A780	428	\N
871	Aguardiente Fresco 522	Aguardiente de alta calidad. Ideal para el hogar o negocio.	5138	122	4	E876	\N	3
872	Pastillas Express 53	Pastillas de alta calidad. Ideal para el hogar o negocio.	50560	190	1	E364	51	\N
873	Genérico Max 261	Genérico de alta calidad. Ideal para el hogar o negocio.	5726	954	17	U007	\N	2
874	Refresco Plus 475	Refresco de alta calidad. Ideal para el hogar o negocio.	33707	72	3	H156	\N	2
875	Choclitos Deluxe 969	Choclitos de alta calidad. Ideal para el hogar o negocio.	21266	282	2	B512	61	\N
876	Genérico Express 78	Genérico de alta calidad. Ideal para el hogar o negocio.	8082	261	13	C300	\N	4
877	Genérico Fresco 879	Genérico de alta calidad. Ideal para el hogar o negocio.	21763	901	17	K218	170	\N
878	Genérico Max 491	Genérico de alta calidad. Ideal para el hogar o negocio.	49843	852	17	D229	\N	1
879	Genérico Eco 620	Genérico de alta calidad. Ideal para el hogar o negocio.	36032	23	13	E030	\N	10
880	Gaseosa Plus 553	Gaseosa de alta calidad. Ideal para el hogar o negocio.	43995	54	3	H370	252	\N
881	Genérico Eco 453	Genérico de alta calidad. Ideal para el hogar o negocio.	70064	770	12	C300	421	\N
882	Genérico Clásico 130	Genérico de alta calidad. Ideal para el hogar o negocio.	82330	240	12	A264	373	\N
883	Genérico Plus 112	Genérico de alta calidad. Ideal para el hogar o negocio.	25204	434	16	A046	\N	10
884	Bebida de frutas Clásico 822	Bebida de frutas de alta calidad. Ideal para el hogar o negocio.	26861	435	3	G265	\N	2
885	Genérico Premium 699	Genérico de alta calidad. Ideal para el hogar o negocio.	63772	507	6	D882	17	\N
886	Genérico Selecto 42	Genérico de alta calidad. Ideal para el hogar o negocio.	52673	388	18	B818	\N	6
887	Genérico Max 6357	Genérico de alta calidad. Ideal para el hogar o negocio.	42000	788	7	I461	\N	5
888	Genérico Express 181	Genérico de alta calidad. Ideal para el hogar o negocio.	5415	911	12	P687	90	\N
889	Jugo Premium 206	Jugo de alta calidad. Ideal para el hogar o negocio.	38505	822	3	Y224	\N	3
890	Genérico Clásico 898	Genérico de alta calidad. Ideal para el hogar o negocio.	47162	651	17	P917	\N	9
891	Genérico Express 242	Genérico de alta calidad. Ideal para el hogar o negocio.	17099	516	16	H630	67	\N
892	Limpiador Eco 824	Limpiador de alta calidad. Ideal para el hogar o negocio.	63361	236	5	X193	384	\N
893	Genérico Eco 281	Genérico de alta calidad. Ideal para el hogar o negocio.	29058	531	18	D201	4	\N
894	Pastillas Fresco 831	Pastillas de alta calidad. Ideal para el hogar o negocio.	11058	538	1	X483	\N	1
895	Genérico Express 303	Genérico de alta calidad. Ideal para el hogar o negocio.	98200	373	18	D311	\N	1
896	Té Clásico 757	Té de alta calidad. Ideal para el hogar o negocio.	87093	753	3	F701	62	\N
897	Genérico Max 999	Genérico de alta calidad. Ideal para el hogar o negocio.	29443	982	13	H769	\N	1
898	Genérico Deluxe 232	Genérico de alta calidad. Ideal para el hogar o negocio.	50307	174	17	T596	359	\N
899	Gaseosa Plus 800	Gaseosa de alta calidad. Ideal para el hogar o negocio.	87777	774	3	F022	\N	2
900	Genérico Express 920	Genérico de alta calidad. Ideal para el hogar o negocio.	21908	379	9	I735	208	\N
901	Genérico Eco 213	Genérico de alta calidad. Ideal para el hogar o negocio.	20098	803	17	C899	\N	9
902	Genérico Ligero 259	Genérico de alta calidad. Ideal para el hogar o negocio.	43385	290	11	I242	\N	5
903	Genérico Eco 689	Genérico de alta calidad. Ideal para el hogar o negocio.	12732	670	7	D978	194	\N
904	Aguardiente Eco 432	Aguardiente de alta calidad. Ideal para el hogar o negocio.	72963	268	4	N982	51	\N
905	Desengrasante Deluxe 876	Desengrasante de alta calidad. Ideal para el hogar o negocio.	80587	188	5	Y795	\N	9
906	Ginebra Deluxe 272	Ginebra de alta calidad. Ideal para el hogar o negocio.	47879	297	4	H010	323	\N
907	Genérico Express 207	Genérico de alta calidad. Ideal para el hogar o negocio.	57107	142	9	R735	\N	10
908	Ginebra Max 46	Ginebra de alta calidad. Ideal para el hogar o negocio.	11796	389	4	P105	108	\N
909	Genérico Plus 154	Genérico de alta calidad. Ideal para el hogar o negocio.	24901	403	16	Y031	\N	6
910	Nachos Max 315	Nachos de alta calidad. Ideal para el hogar o negocio.	82698	569	2	E622	\N	8
911	Genérico Selecto 241	Genérico de alta calidad. Ideal para el hogar o negocio.	39221	368	16	D978	241	\N
912	Genérico Eco 467	Genérico de alta calidad. Ideal para el hogar o negocio.	37094	447	8	V834	\N	10
913	Detergente Eco 991	Detergente de alta calidad. Ideal para el hogar o negocio.	75389	335	5	U347	408	\N
914	Desengrasante Max 452	Desengrasante de alta calidad. Ideal para el hogar o negocio.	39518	803	5	I461	\N	8
915	Multiusos Clásico 632	Multiusos de alta calidad. Ideal para el hogar o negocio.	28026	380	5	I105	260	\N
916	Arepitas Ligero 312	Arepitas de alta calidad. Ideal para el hogar o negocio.	97258	577	2	Z344	444	\N
917	Genérico Ligero 475	Genérico de alta calidad. Ideal para el hogar o negocio.	77741	952	15	E613	359	\N
918	Genérico Eco 232	Genérico de alta calidad. Ideal para el hogar o negocio.	49530	467	8	O201	\N	3
919	Genérico Ligero 879	Genérico de alta calidad. Ideal para el hogar o negocio.	35807	636	18	S634	140	\N
920	Genérico Plus 718	Genérico de alta calidad. Ideal para el hogar o negocio.	35147	309	17	I461	263	\N
921	Genérico Premium 570	Genérico de alta calidad. Ideal para el hogar o negocio.	72864	63	11	J313	\N	1
922	Malta Plus 698	Malta de alta calidad. Ideal para el hogar o negocio.	13080	129	3	C918	\N	3
923	Genérico Selecto 526	Genérico de alta calidad. Ideal para el hogar o negocio.	46058	487	15	O239	166	\N
924	Genérico Deluxe 288	Genérico de alta calidad. Ideal para el hogar o negocio.	44960	101	9	F333	\N	6
925	Genérico Fresco 270	Genérico de alta calidad. Ideal para el hogar o negocio.	56311	786	15	J960	121	\N
926	Genérico Premium 830	Genérico de alta calidad. Ideal para el hogar o negocio.	91185	312	16	X573	\N	10
927	Genérico Ligero 965	Genérico de alta calidad. Ideal para el hogar o negocio.	30064	426	11	M475	\N	9
928	Genérico Premium 421	Genérico de alta calidad. Ideal para el hogar o negocio.	76685	200	6	Z050	\N	5
929	Genérico Premium 737	Genérico de alta calidad. Ideal para el hogar o negocio.	28220	347	15	L302	423	\N
930	Genérico Deluxe 411	Genérico de alta calidad. Ideal para el hogar o negocio.	4067	946	15	B841	\N	2
931	Genérico Clásico 840	Genérico de alta calidad. Ideal para el hogar o negocio.	27562	544	6	I115	\N	2
932	Genérico Plus 803	Genérico de alta calidad. Ideal para el hogar o negocio.	80711	284	18	X270	\N	1
933	Jugo Express 293	Jugo de alta calidad. Ideal para el hogar o negocio.	70592	826	3	H204	261	\N
934	Genérico Max 846	Genérico de alta calidad. Ideal para el hogar o negocio.	29692	644	18	H080	\N	7
935	Genérico Plus 730	Genérico de alta calidad. Ideal para el hogar o negocio.	50964	114	11	O201	\N	10
936	Malvavisco Clásico 303	Malvavisco de alta calidad. Ideal para el hogar o negocio.	25627	871	1	C867	\N	9
937	Genérico Max 574	Genérico de alta calidad. Ideal para el hogar o negocio.	84271	300	16	E258	184	\N
938	Agua Ligero 171	Agua de alta calidad. Ideal para el hogar o negocio.	6906	703	3	P392	303	\N
939	Cerveza Premium 286	Cerveza de alta calidad. Ideal para el hogar o negocio.	4460	39	4	H080	482	\N
940	Genérico Premium 448	Genérico de alta calidad. Ideal para el hogar o negocio.	30993	986	9	P044	164	\N
941	Genérico Max 546	Genérico de alta calidad. Ideal para el hogar o negocio.	85124	353	18	L326	\N	2
942	Tequila Premium 383	Tequila de alta calidad. Ideal para el hogar o negocio.	13978	509	4	Z018	\N	9
943	Genérico Express 746	Genérico de alta calidad. Ideal para el hogar o negocio.	44326	98	11	F249	136	\N
944	Genérico Eco 788	Genérico de alta calidad. Ideal para el hogar o negocio.	64821	80	12	T259	395	\N
945	Toffee Ligero 670	Toffee de alta calidad. Ideal para el hogar o negocio.	15155	76	1	D578	\N	8
946	Genérico Deluxe 970	Genérico de alta calidad. Ideal para el hogar o negocio.	17656	742	8	K916	\N	2
947	Genérico Ligero 878	Genérico de alta calidad. Ideal para el hogar o negocio.	68191	24	8	R960	228	\N
948	Yucas Max 772	Yucas de alta calidad. Ideal para el hogar o negocio.	70025	560	2	D578	\N	1
949	Genérico Ligero 6871	Genérico de alta calidad. Ideal para el hogar o negocio.	68769	838	11	O692	477	\N
950	Genérico Eco 1	Genérico de alta calidad. Ideal para el hogar o negocio.	58810	236	11	T082	436	\N
951	Genérico Eco 415	Genérico de alta calidad. Ideal para el hogar o negocio.	13570	289	13	M950	\N	1
952	Genérico Premium 327	Genérico de alta calidad. Ideal para el hogar o negocio.	26101	933	17	S237	\N	9
953	Genérico Deluxe 852	Genérico de alta calidad. Ideal para el hogar o negocio.	3333	892	7	O561	27	\N
954	Genérico Max 917	Genérico de alta calidad. Ideal para el hogar o negocio.	17074	619	6	R275	19	\N
955	Genérico Premium 960	Genérico de alta calidad. Ideal para el hogar o negocio.	60483	286	17	U126	\N	6
956	Genérico Selecto 263	Genérico de alta calidad. Ideal para el hogar o negocio.	53744	585	9	I371	356	\N
957	Genérico Eco 157	Genérico de alta calidad. Ideal para el hogar o negocio.	2734	368	16	N083	\N	7
958	Genérico Fresco 608	Genérico de alta calidad. Ideal para el hogar o negocio.	32182	542	6	X193	337	\N
959	Genérico Clásico 6650	Genérico de alta calidad. Ideal para el hogar o negocio.	79058	517	6	F269	\N	7
960	Gaseosa Plus 816	Gaseosa de alta calidad. Ideal para el hogar o negocio.	28685	457	3	O607	118	\N
961	Ginebra Selecto 422	Ginebra de alta calidad. Ideal para el hogar o negocio.	47562	17	4	J603	464	\N
962	Platanitos Express 128	Platanitos de alta calidad. Ideal para el hogar o negocio.	20624	41	2	N982	432	\N
963	Genérico Max 765	Genérico de alta calidad. Ideal para el hogar o negocio.	46528	248	11	C819	\N	1
964	Genérico Fresco 581	Genérico de alta calidad. Ideal para el hogar o negocio.	60169	62	18	Y195	442	\N
965	Multiusos Express 214	Multiusos de alta calidad. Ideal para el hogar o negocio.	57230	435	5	R143	\N	3
966	Brandy Selecto 177	Brandy de alta calidad. Ideal para el hogar o negocio.	37001	268	4	O561	\N	9
967	Genérico Premium 298	Genérico de alta calidad. Ideal para el hogar o negocio.	91092	28	8	S541	77	\N
968	Energizante Eco 704	Energizante de alta calidad. Ideal para el hogar o negocio.	93569	455	3	P727	190	\N
969	Genérico Deluxe 164	Genérico de alta calidad. Ideal para el hogar o negocio.	96890	551	9	M680	229	\N
970	Tostacos Plus 602	Tostacos de alta calidad. Ideal para el hogar o negocio.	63608	122	2	E140	\N	1
971	Genérico Eco 319	Genérico de alta calidad. Ideal para el hogar o negocio.	98894	137	18	O383	\N	1
972	Multiusos Selecto 486	Multiusos de alta calidad. Ideal para el hogar o negocio.	88460	256	5	A722	\N	2
973	Jabón Ligero 432	Jabón de alta calidad. Ideal para el hogar o negocio.	99794	196	5	A065	93	\N
974	Arepitas Clásico 938	Arepitas de alta calidad. Ideal para el hogar o negocio.	66448	432	2	F022	\N	9
975	Bebida de frutas Plus 823	Bebida de frutas de alta calidad. Ideal para el hogar o negocio.	61158	991	3	O850	455	\N
976	Genérico Premium 679	Genérico de alta calidad. Ideal para el hogar o negocio.	52656	91	13	L757	\N	9
977	Pastillas Fresco 958	Pastillas de alta calidad. Ideal para el hogar o negocio.	50361	683	1	D037	431	\N
978	Genérico Selecto 177	Genérico de alta calidad. Ideal para el hogar o negocio.	37464	92	12	N192	\N	2
979	Gaseosa Ligero 157	Gaseosa de alta calidad. Ideal para el hogar o negocio.	4649	202	3	V834	95	\N
980	Genérico Clásico 72	Genérico de alta calidad. Ideal para el hogar o negocio.	95313	572	18	B211	181	\N
981	Genérico Plus 525	Genérico de alta calidad. Ideal para el hogar o negocio.	32239	725	16	X573	436	\N
982	Genérico Deluxe 748	Genérico de alta calidad. Ideal para el hogar o negocio.	33939	793	17	B747	\N	3
983	Genérico Max 845	Genérico de alta calidad. Ideal para el hogar o negocio.	80257	355	18	O114	80	\N
984	Genérico Premium 639	Genérico de alta calidad. Ideal para el hogar o negocio.	76582	909	9	N010	320	\N
985	Genérico Plus 151	Genérico de alta calidad. Ideal para el hogar o negocio.	16248	344	6	C867	\N	1
986	Desengrasante Premium 689	Desengrasante de alta calidad. Ideal para el hogar o negocio.	64094	573	5	T397	371	\N
987	Genérico Max 562	Genérico de alta calidad. Ideal para el hogar o negocio.	86462	468	7	S720	192	\N
988	Té Plus 203	Té de alta calidad. Ideal para el hogar o negocio.	99338	210	3	R942	249	\N
989	Vino Selecto 158	Vino de alta calidad. Ideal para el hogar o negocio.	13132	808	4	E909	\N	5
990	Genérico Selecto 991	Genérico de alta calidad. Ideal para el hogar o negocio.	37038	364	15	H707	460	\N
991	Desinfectante Express 986	Desinfectante de alta calidad. Ideal para el hogar o negocio.	12040	244	5	J454	496	\N
992	Genérico Eco 384	Genérico de alta calidad. Ideal para el hogar o negocio.	14454	694	12	A618	237	\N
993	Genérico Express 867	Genérico de alta calidad. Ideal para el hogar o negocio.	7484	455	9	B309	415	\N
994	Genérico Ligero 22	Genérico de alta calidad. Ideal para el hogar o negocio.	64588	582	15	B307	485	\N
995	Genérico Deluxe 88	Genérico de alta calidad. Ideal para el hogar o negocio.	76710	96	12	X412	281	\N
996	Vodka Plus 788	Vodka de alta calidad. Ideal para el hogar o negocio.	91727	368	4	P139	\N	7
997	Pastillas Clásico 219	Pastillas de alta calidad. Ideal para el hogar o negocio.	61603	160	1	J454	431	\N
998	Cloro Premium 560	Cloro de alta calidad. Ideal para el hogar o negocio.	18582	321	5	A063	\N	3
999	Aguardiente Selecto 540	Aguardiente de alta calidad. Ideal para el hogar o negocio.	63303	700	4	A247	\N	8
1000	Genérico Express 357	Genérico de alta calidad. Ideal para el hogar o negocio.	70095	240	11	Q986	267	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                             5017.dat                                                                                            0000600 0004000 0002000 00000056477 15015340177 0014274 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	2025-02-28	2025-03-16	\N	7015	paused	FIXED
2	2021-09-08	2021-09-16	\N	43201	paused	FIXED
3	2023-02-15	2023-02-22	\N	39180	active	FIXED
4	2021-11-12	2021-11-22	12	\N	paused	PERCENT
5	2023-06-14	2023-07-10	\N	33041	paused	FIXED
6	2023-01-02	2023-01-15	61	\N	inactive	PERCENT
7	2020-04-17	2020-04-24	49	\N	active	PERCENT
8	2023-02-05	2023-03-02	\N	13462	paused	FIXED
9	2020-08-21	2020-09-18	78	\N	inactive	PERCENT
10	2021-08-08	2021-08-28	88	\N	paused	PERCENT
11	2020-11-05	2020-12-03	\N	12958	active	FIXED
12	2021-06-03	2021-06-11	40	\N	paused	PERCENT
13	2022-08-03	2022-09-01	\N	37621	active	FIXED
14	2025-07-04	2025-08-01	82	\N	active	PERCENT
15	2021-03-09	2021-03-14	\N	6870	active	FIXED
16	2025-03-14	2025-04-05	\N	3860	paused	FIXED
17	2020-10-05	2020-10-21	92	\N	paused	PERCENT
18	2024-08-16	2024-08-25	64	\N	active	PERCENT
19	2020-07-25	2020-08-03	\N	31520	inactive	FIXED
20	2025-01-09	2025-02-02	17	\N	active	PERCENT
21	2021-09-15	2021-10-02	\N	41474	paused	FIXED
22	2020-03-25	2020-04-14	\N	5855	active	FIXED
23	2021-07-10	2021-08-02	\N	38180	paused	FIXED
24	2020-05-19	2020-06-06	\N	35301	paused	FIXED
25	2024-10-18	2024-10-23	\N	5652	paused	FIXED
26	2021-10-25	2021-11-21	\N	34824	inactive	FIXED
27	2023-08-09	2023-09-06	59	\N	active	PERCENT
28	2025-12-16	2025-12-28	9	\N	active	PERCENT
29	2020-10-19	2020-11-04	36	\N	active	PERCENT
30	2025-02-02	2025-02-22	\N	47104	paused	FIXED
31	2020-03-15	2020-04-02	54	\N	active	PERCENT
32	2023-02-17	2023-03-15	55	\N	active	PERCENT
33	2022-10-21	2022-11-13	89	\N	inactive	PERCENT
34	2021-05-14	2021-06-13	48	\N	inactive	PERCENT
35	2023-11-27	2023-12-06	77	\N	paused	PERCENT
36	2022-05-01	2022-05-27	18	\N	active	PERCENT
37	2023-05-18	2023-06-14	\N	49850	paused	FIXED
38	2021-04-15	2021-05-07	\N	2829	paused	FIXED
39	2024-01-07	2024-02-03	\N	6615	active	FIXED
40	2022-12-04	2022-12-09	\N	12235	paused	FIXED
41	2024-11-22	2024-12-03	50	\N	paused	PERCENT
42	2021-11-17	2021-12-17	\N	25075	active	FIXED
43	2021-09-08	2021-09-13	\N	42175	active	FIXED
44	2025-07-27	2025-08-13	15	\N	inactive	PERCENT
45	2024-08-12	2024-09-02	87	\N	paused	PERCENT
46	2024-11-21	2024-12-16	\N	48940	inactive	FIXED
47	2020-03-05	2020-03-26	96	\N	inactive	PERCENT
48	2023-09-27	2023-10-12	\N	5636	inactive	FIXED
49	2023-01-03	2023-01-21	18	\N	paused	PERCENT
50	2021-11-22	2021-12-07	9	\N	paused	PERCENT
51	2023-09-27	2023-10-18	\N	19939	active	FIXED
52	2023-04-28	2023-05-27	\N	21684	active	FIXED
53	2020-01-14	2020-02-03	83	\N	paused	PERCENT
54	2020-06-19	2020-07-05	\N	27822	paused	FIXED
55	2021-01-22	2021-02-03	\N	2961	inactive	FIXED
56	2022-10-14	2022-10-21	\N	8576	active	FIXED
57	2021-09-19	2021-10-19	\N	22486	inactive	FIXED
58	2022-01-16	2022-01-29	\N	49060	inactive	FIXED
59	2021-07-07	2021-08-05	47	\N	paused	PERCENT
60	2020-08-04	2020-08-14	\N	43887	active	FIXED
61	2020-08-26	2020-09-14	65	\N	paused	PERCENT
62	2022-04-11	2022-04-22	18	\N	active	PERCENT
63	2023-03-04	2023-03-15	77	\N	active	PERCENT
64	2021-01-08	2021-02-06	\N	19610	active	FIXED
65	2022-07-04	2022-07-30	\N	16872	inactive	FIXED
66	2020-11-26	2020-12-11	\N	7008	active	FIXED
67	2023-03-06	2023-03-18	\N	5097	paused	FIXED
68	2024-01-11	2024-02-09	\N	26555	active	FIXED
69	2021-10-03	2021-11-02	\N	4971	inactive	FIXED
70	2024-04-17	2024-05-02	8	\N	active	PERCENT
71	2025-04-22	2025-05-10	27	\N	inactive	PERCENT
72	2020-06-24	2020-07-03	7	\N	paused	PERCENT
73	2021-07-20	2021-08-07	18	\N	paused	PERCENT
74	2020-06-25	2020-06-30	\N	6223	inactive	FIXED
75	2020-09-01	2020-09-28	29	\N	paused	PERCENT
76	2021-07-05	2021-07-16	\N	26977	paused	FIXED
77	2021-03-06	2021-03-18	95	\N	active	PERCENT
78	2021-07-13	2021-07-20	85	\N	paused	PERCENT
79	2020-12-03	2020-12-30	81	\N	paused	PERCENT
80	2023-09-26	2023-10-19	\N	45808	paused	FIXED
81	2024-10-23	2024-11-07	\N	32725	inactive	FIXED
82	2025-05-25	2025-06-23	70	\N	paused	PERCENT
83	2024-05-19	2024-05-24	11	\N	active	PERCENT
84	2021-03-22	2021-04-05	\N	39249	paused	FIXED
85	2020-02-23	2020-03-12	78	\N	paused	PERCENT
86	2022-08-25	2022-09-19	52	\N	inactive	PERCENT
87	2022-12-26	2023-01-02	60	\N	paused	PERCENT
88	2024-08-24	2024-09-09	18	\N	paused	PERCENT
89	2023-03-05	2023-04-02	82	\N	inactive	PERCENT
90	2021-12-03	2021-12-23	82	\N	paused	PERCENT
91	2021-06-13	2021-07-05	1	\N	paused	PERCENT
92	2020-07-27	2020-08-11	2	\N	active	PERCENT
93	2023-09-20	2023-10-09	35	\N	inactive	PERCENT
94	2021-11-16	2021-12-07	93	\N	inactive	PERCENT
95	2025-08-02	2025-08-08	84	\N	inactive	PERCENT
96	2022-07-08	2022-07-29	\N	26786	active	FIXED
97	2021-05-03	2021-05-25	\N	14617	inactive	FIXED
98	2021-02-27	2021-03-16	41	\N	paused	PERCENT
99	2025-04-23	2025-05-21	\N	29146	paused	FIXED
100	2025-02-23	2025-03-08	\N	38206	inactive	FIXED
101	2022-06-11	2022-06-23	28	\N	inactive	PERCENT
102	2023-07-08	2023-07-14	\N	5911	active	FIXED
103	2021-09-14	2021-10-12	\N	32899	active	FIXED
104	2020-04-14	2020-05-09	17	\N	inactive	PERCENT
105	2020-10-27	2020-11-05	\N	35003	inactive	FIXED
106	2023-08-07	2023-08-28	\N	30376	paused	FIXED
107	2021-12-08	2021-12-21	\N	29207	active	FIXED
108	2023-04-05	2023-04-11	\N	1552	inactive	FIXED
109	2022-04-19	2022-05-02	74	\N	paused	PERCENT
110	2024-09-03	2024-09-18	65	\N	inactive	PERCENT
111	2024-01-02	2024-01-07	\N	20532	active	FIXED
112	2020-11-08	2020-11-21	\N	46969	inactive	FIXED
113	2021-12-13	2021-12-23	63	\N	active	PERCENT
114	2021-08-18	2021-08-29	\N	21508	paused	FIXED
115	2020-06-20	2020-07-07	97	\N	active	PERCENT
116	2022-04-16	2022-05-01	\N	44807	active	FIXED
117	2022-12-04	2022-12-10	54	\N	active	PERCENT
118	2020-07-20	2020-08-07	97	\N	active	PERCENT
119	2021-03-27	2021-04-23	39	\N	inactive	PERCENT
120	2020-09-11	2020-09-30	\N	1040	paused	FIXED
121	2023-05-18	2023-06-10	\N	44837	active	FIXED
122	2023-05-10	2023-06-08	\N	34337	paused	FIXED
123	2020-03-19	2020-04-08	43	\N	active	PERCENT
124	2023-11-14	2023-11-29	42	\N	active	PERCENT
125	2023-10-11	2023-10-16	82	\N	active	PERCENT
126	2025-05-17	2025-05-22	\N	16426	paused	FIXED
127	2021-05-18	2021-06-04	\N	35993	active	FIXED
128	2022-08-02	2022-08-12	12	\N	active	PERCENT
129	2020-12-16	2021-01-14	\N	17798	inactive	FIXED
130	2021-04-08	2021-05-08	65	\N	active	PERCENT
131	2020-12-16	2020-12-27	\N	25548	inactive	FIXED
132	2024-12-13	2025-01-12	33	\N	inactive	PERCENT
133	2024-07-01	2024-07-25	\N	20317	inactive	FIXED
134	2022-09-16	2022-10-16	\N	17915	paused	FIXED
135	2022-10-21	2022-11-17	38	\N	active	PERCENT
136	2020-06-05	2020-06-20	\N	23737	paused	FIXED
137	2020-09-08	2020-09-28	\N	33630	active	FIXED
138	2023-04-23	2023-05-09	\N	37944	inactive	FIXED
139	2022-08-12	2022-09-05	\N	43447	inactive	FIXED
140	2023-06-13	2023-07-13	\N	29536	paused	FIXED
141	2022-08-28	2022-09-10	\N	24049	active	FIXED
142	2024-11-23	2024-12-13	\N	8086	paused	FIXED
143	2025-07-08	2025-07-24	87	\N	paused	PERCENT
144	2021-06-06	2021-06-25	\N	23118	inactive	FIXED
145	2025-11-25	2025-12-22	\N	16286	paused	FIXED
146	2022-05-13	2022-05-22	38	\N	paused	PERCENT
147	2022-10-13	2022-11-02	\N	19731	inactive	FIXED
148	2024-02-09	2024-03-03	\N	48764	active	FIXED
149	2023-05-08	2023-05-25	39	\N	paused	PERCENT
150	2025-04-21	2025-05-20	\N	15497	active	FIXED
151	2023-11-01	2023-11-14	54	\N	paused	PERCENT
152	2022-11-12	2022-12-12	\N	10209	active	FIXED
153	2024-10-10	2024-10-19	\N	21590	inactive	FIXED
154	2024-07-01	2024-07-08	48	\N	active	PERCENT
155	2023-04-17	2023-05-12	\N	27783	inactive	FIXED
156	2022-02-26	2022-03-21	94	\N	paused	PERCENT
157	2021-10-27	2021-11-21	\N	9318	paused	FIXED
158	2025-08-16	2025-09-08	\N	31332	inactive	FIXED
159	2025-03-01	2025-03-06	39	\N	active	PERCENT
160	2020-06-20	2020-06-26	37	\N	paused	PERCENT
161	2022-12-09	2022-12-14	5	\N	active	PERCENT
162	2025-01-02	2025-01-08	\N	3079	inactive	FIXED
163	2020-01-12	2020-01-21	38	\N	inactive	PERCENT
164	2023-05-20	2023-06-13	52	\N	paused	PERCENT
165	2024-04-18	2024-05-13	\N	31956	inactive	FIXED
166	2024-07-24	2024-07-29	75	\N	paused	PERCENT
167	2022-04-28	2022-05-07	58	\N	paused	PERCENT
168	2022-09-28	2022-10-09	\N	15968	paused	FIXED
169	2023-09-17	2023-09-23	21	\N	active	PERCENT
170	2020-01-04	2020-01-31	54	\N	paused	PERCENT
171	2025-05-15	2025-06-01	74	\N	active	PERCENT
172	2024-07-24	2024-08-18	25	\N	active	PERCENT
173	2024-06-16	2024-07-07	60	\N	inactive	PERCENT
174	2022-08-24	2022-09-13	\N	30463	paused	FIXED
175	2022-02-01	2022-02-21	24	\N	active	PERCENT
176	2020-04-22	2020-05-21	19	\N	active	PERCENT
177	2022-05-08	2022-05-14	68	\N	active	PERCENT
178	2025-05-26	2025-06-10	48	\N	active	PERCENT
179	2025-06-22	2025-06-30	\N	32469	active	FIXED
180	2025-12-16	2025-12-28	69	\N	active	PERCENT
181	2025-08-12	2025-08-22	87	\N	paused	PERCENT
182	2024-08-21	2024-09-16	1	\N	inactive	PERCENT
183	2025-12-02	2025-12-21	27	\N	paused	PERCENT
184	2020-01-09	2020-01-24	12	\N	active	PERCENT
185	2021-10-14	2021-11-09	29	\N	inactive	PERCENT
186	2023-10-20	2023-10-28	\N	45562	inactive	FIXED
187	2021-05-14	2021-05-31	\N	31590	active	FIXED
188	2024-01-04	2024-01-16	51	\N	paused	PERCENT
189	2021-01-18	2021-01-31	40	\N	inactive	PERCENT
190	2020-09-22	2020-10-11	35	\N	paused	PERCENT
191	2022-02-17	2022-03-18	11	\N	inactive	PERCENT
192	2020-04-23	2020-04-28	\N	42811	active	FIXED
193	2022-03-22	2022-04-19	\N	46147	active	FIXED
194	2020-05-28	2020-06-10	22	\N	active	PERCENT
195	2024-02-11	2024-03-04	24	\N	paused	PERCENT
196	2020-08-04	2020-08-11	\N	9323	paused	FIXED
197	2020-08-21	2020-08-30	\N	5420	inactive	FIXED
198	2021-03-23	2021-04-16	\N	34596	active	FIXED
199	2025-05-06	2025-06-04	\N	13798	active	FIXED
200	2025-09-16	2025-09-22	4	\N	active	PERCENT
201	2021-05-14	2021-05-22	60	\N	active	PERCENT
202	2022-01-10	2022-02-01	70	\N	inactive	PERCENT
203	2021-06-11	2021-06-28	\N	2295	active	FIXED
204	2025-05-22	2025-06-17	\N	19766	inactive	FIXED
205	2024-11-01	2024-11-16	\N	34798	inactive	FIXED
206	2020-05-12	2020-06-07	\N	23277	paused	FIXED
207	2020-08-26	2020-09-17	54	\N	paused	PERCENT
208	2024-04-01	2024-04-12	\N	25825	paused	FIXED
209	2024-12-28	2025-01-27	8	\N	paused	PERCENT
210	2021-02-15	2021-03-01	\N	11258	paused	FIXED
211	2025-09-14	2025-10-11	\N	25786	active	FIXED
212	2025-12-26	2026-01-24	54	\N	paused	PERCENT
213	2022-03-09	2022-03-28	\N	28713	active	FIXED
214	2020-04-11	2020-04-20	\N	24769	paused	FIXED
215	2020-11-25	2020-12-14	\N	46790	paused	FIXED
216	2023-07-21	2023-08-13	53	\N	active	PERCENT
217	2024-09-09	2024-10-06	\N	29329	active	FIXED
218	2024-06-13	2024-06-24	20	\N	active	PERCENT
219	2023-08-06	2023-08-21	\N	12375	paused	FIXED
220	2024-05-23	2024-06-15	40	\N	active	PERCENT
221	2025-07-25	2025-08-14	70	\N	active	PERCENT
222	2021-12-24	2022-01-06	11	\N	inactive	PERCENT
223	2023-07-22	2023-07-31	\N	3069	active	FIXED
224	2022-11-16	2022-11-22	\N	31782	inactive	FIXED
225	2021-09-27	2021-10-11	\N	15031	inactive	FIXED
226	2020-03-28	2020-04-05	4	\N	active	PERCENT
227	2020-01-07	2020-01-31	\N	26438	active	FIXED
228	2021-01-13	2021-02-09	91	\N	inactive	PERCENT
229	2022-02-22	2022-03-23	62	\N	active	PERCENT
230	2022-11-03	2022-11-13	19	\N	active	PERCENT
231	2020-11-10	2020-11-27	40	\N	active	PERCENT
232	2024-01-18	2024-02-03	\N	10167	active	FIXED
233	2024-10-05	2024-10-11	\N	38196	paused	FIXED
234	2022-07-20	2022-08-06	31	\N	active	PERCENT
235	2021-11-15	2021-11-24	90	\N	paused	PERCENT
236	2023-08-09	2023-08-24	\N	24810	inactive	FIXED
237	2024-10-11	2024-10-30	12	\N	active	PERCENT
238	2021-10-21	2021-11-13	97	\N	inactive	PERCENT
239	2025-01-13	2025-01-22	26	\N	inactive	PERCENT
240	2024-09-12	2024-10-03	51	\N	active	PERCENT
241	2020-06-03	2020-06-21	\N	4519	inactive	FIXED
242	2023-10-24	2023-11-06	\N	33209	inactive	FIXED
243	2020-03-21	2020-04-11	\N	26569	paused	FIXED
244	2022-05-23	2022-06-03	57	\N	active	PERCENT
245	2021-07-15	2021-07-21	91	\N	inactive	PERCENT
246	2025-03-12	2025-03-30	60	\N	inactive	PERCENT
247	2021-10-12	2021-11-03	29	\N	active	PERCENT
248	2022-08-09	2022-08-27	\N	12380	inactive	FIXED
249	2020-05-10	2020-05-26	20	\N	active	PERCENT
250	2025-12-24	2025-12-30	\N	22839	active	FIXED
251	2025-08-10	2025-09-09	\N	15028	active	FIXED
252	2020-02-13	2020-02-25	\N	19715	inactive	FIXED
253	2022-01-14	2022-02-12	31	\N	paused	PERCENT
254	2021-01-12	2021-01-29	\N	44205	paused	FIXED
255	2021-12-05	2021-12-21	2	\N	paused	PERCENT
256	2020-10-13	2020-11-04	39	\N	inactive	PERCENT
257	2024-01-19	2024-02-05	38	\N	inactive	PERCENT
258	2025-02-04	2025-02-09	25	\N	active	PERCENT
259	2025-02-05	2025-02-25	\N	16490	paused	FIXED
260	2021-08-26	2021-09-19	46	\N	paused	PERCENT
261	2025-01-22	2025-02-02	\N	30109	paused	FIXED
262	2023-05-27	2023-06-03	49	\N	paused	PERCENT
263	2020-01-13	2020-01-18	\N	14825	active	FIXED
264	2022-08-27	2022-09-25	31	\N	inactive	PERCENT
265	2023-11-26	2023-12-19	53	\N	paused	PERCENT
266	2024-07-04	2024-07-29	\N	5068	inactive	FIXED
267	2023-11-06	2023-11-20	\N	23624	active	FIXED
268	2022-08-28	2022-09-14	72	\N	active	PERCENT
269	2020-10-26	2020-11-09	46	\N	paused	PERCENT
270	2022-11-23	2022-12-18	42	\N	inactive	PERCENT
271	2022-05-10	2022-06-05	\N	13003	paused	FIXED
272	2022-09-06	2022-09-27	\N	46581	paused	FIXED
273	2025-10-28	2025-11-08	\N	35887	paused	FIXED
274	2022-11-05	2022-11-28	\N	40339	active	FIXED
275	2022-05-19	2022-05-31	84	\N	active	PERCENT
276	2023-10-15	2023-10-20	90	\N	paused	PERCENT
277	2024-03-27	2024-04-02	18	\N	active	PERCENT
278	2023-05-09	2023-05-26	59	\N	paused	PERCENT
279	2021-06-26	2021-07-03	\N	1705	active	FIXED
280	2020-06-02	2020-06-22	66	\N	inactive	PERCENT
281	2025-06-08	2025-06-29	\N	25268	active	FIXED
282	2021-10-19	2021-11-17	\N	18719	active	FIXED
283	2023-12-25	2024-01-10	\N	49292	inactive	FIXED
284	2025-12-15	2026-01-11	38	\N	paused	PERCENT
285	2021-05-26	2021-06-07	\N	13693	inactive	FIXED
286	2024-08-06	2024-08-26	94	\N	paused	PERCENT
287	2024-01-12	2024-01-19	\N	1139	active	FIXED
288	2021-03-26	2021-04-18	83	\N	active	PERCENT
289	2025-02-28	2025-03-18	96	\N	inactive	PERCENT
290	2022-11-14	2022-12-12	2	\N	paused	PERCENT
291	2025-06-21	2025-07-18	20	\N	paused	PERCENT
292	2025-02-05	2025-02-11	70	\N	active	PERCENT
293	2022-02-24	2022-03-20	27	\N	active	PERCENT
294	2025-06-03	2025-06-27	77	\N	paused	PERCENT
295	2022-01-12	2022-01-21	68	\N	active	PERCENT
296	2022-01-22	2022-02-12	\N	36634	active	FIXED
297	2022-04-01	2022-04-25	21	\N	inactive	PERCENT
298	2022-03-01	2022-03-06	34	\N	inactive	PERCENT
299	2025-08-08	2025-08-31	\N	1067	active	FIXED
300	2022-11-13	2022-11-19	\N	20077	active	FIXED
301	2022-04-19	2022-05-12	\N	19255	active	FIXED
302	2020-09-22	2020-09-27	\N	35922	inactive	FIXED
303	2023-01-06	2023-01-30	63	\N	paused	PERCENT
304	2025-01-22	2025-01-27	\N	4616	active	FIXED
305	2020-10-13	2020-10-30	\N	42947	active	FIXED
306	2021-10-18	2021-10-28	91	\N	inactive	PERCENT
307	2021-06-12	2021-06-27	\N	10393	inactive	FIXED
308	2025-10-19	2025-10-28	81	\N	paused	PERCENT
309	2020-03-12	2020-04-03	\N	19561	active	FIXED
310	2020-01-14	2020-01-20	\N	7524	inactive	FIXED
311	2023-10-05	2023-10-30	\N	9409	active	FIXED
312	2020-01-24	2020-02-01	\N	45680	inactive	FIXED
313	2025-08-13	2025-09-03	53	\N	inactive	PERCENT
314	2024-08-26	2024-09-12	11	\N	inactive	PERCENT
315	2025-11-09	2025-11-30	\N	49815	paused	FIXED
316	2024-09-14	2024-09-20	\N	48815	inactive	FIXED
317	2024-05-08	2024-05-26	42	\N	active	PERCENT
318	2024-05-09	2024-05-19	\N	18500	inactive	FIXED
319	2024-01-23	2024-02-15	\N	49515	active	FIXED
320	2025-07-10	2025-07-20	13	\N	paused	PERCENT
321	2025-05-07	2025-05-31	45	\N	inactive	PERCENT
322	2022-09-23	2022-10-23	9	\N	inactive	PERCENT
323	2025-03-06	2025-03-23	60	\N	inactive	PERCENT
324	2024-01-09	2024-01-25	\N	14705	paused	FIXED
325	2025-09-07	2025-10-03	\N	2102	paused	FIXED
326	2021-12-01	2021-12-29	\N	30299	inactive	FIXED
327	2024-05-08	2024-06-03	\N	27942	active	FIXED
328	2020-07-02	2020-07-31	\N	34786	paused	FIXED
329	2023-06-09	2023-06-24	\N	25053	paused	FIXED
330	2021-01-12	2021-02-07	40	\N	active	PERCENT
331	2024-05-24	2024-06-03	62	\N	active	PERCENT
332	2025-12-01	2025-12-18	50	\N	active	PERCENT
333	2023-12-06	2023-12-28	62	\N	paused	PERCENT
334	2020-10-03	2020-10-31	81	\N	active	PERCENT
335	2025-03-12	2025-03-21	\N	31268	paused	FIXED
336	2023-04-17	2023-04-26	\N	5343	paused	FIXED
337	2025-05-08	2025-06-04	\N	39044	paused	FIXED
338	2020-04-25	2020-05-25	\N	3290	paused	FIXED
339	2022-07-11	2022-07-20	\N	16845	active	FIXED
340	2021-07-04	2021-07-12	73	\N	active	PERCENT
341	2021-10-27	2021-11-19	\N	38955	inactive	FIXED
342	2022-05-04	2022-05-14	\N	9594	active	FIXED
343	2025-08-11	2025-09-06	15	\N	inactive	PERCENT
344	2020-07-14	2020-08-04	65	\N	active	PERCENT
345	2025-01-19	2025-02-02	\N	16733	inactive	FIXED
346	2024-11-27	2024-12-24	50	\N	paused	PERCENT
347	2025-06-08	2025-06-19	4	\N	inactive	PERCENT
348	2025-03-28	2025-04-14	\N	14815	active	FIXED
349	2023-05-11	2023-05-20	\N	13078	inactive	FIXED
350	2023-12-25	2024-01-19	\N	25762	paused	FIXED
351	2025-10-07	2025-10-26	\N	6228	active	FIXED
352	2021-02-09	2021-02-26	\N	1023	inactive	FIXED
353	2023-09-16	2023-09-28	\N	14514	active	FIXED
354	2025-03-14	2025-04-03	92	\N	inactive	PERCENT
355	2024-02-23	2024-03-21	\N	30483	paused	FIXED
356	2021-09-09	2021-09-24	\N	31011	inactive	FIXED
357	2022-11-12	2022-11-22	9	\N	inactive	PERCENT
358	2020-01-22	2020-02-20	94	\N	inactive	PERCENT
359	2023-11-09	2023-11-22	\N	14713	paused	FIXED
360	2025-09-19	2025-10-05	\N	34882	inactive	FIXED
361	2024-12-28	2025-01-11	\N	21836	paused	FIXED
362	2024-11-21	2024-11-30	\N	46307	active	FIXED
363	2020-03-09	2020-04-07	\N	41746	inactive	FIXED
364	2023-08-14	2023-08-20	49	\N	inactive	PERCENT
365	2020-01-22	2020-02-18	\N	23786	paused	FIXED
366	2022-08-03	2022-09-01	81	\N	inactive	PERCENT
367	2023-07-13	2023-08-06	\N	5807	active	FIXED
368	2022-03-23	2022-03-28	43	\N	active	PERCENT
369	2023-07-16	2023-08-13	14	\N	inactive	PERCENT
370	2025-12-08	2025-12-31	\N	13153	paused	FIXED
371	2024-10-21	2024-11-06	\N	39849	active	FIXED
372	2025-12-02	2025-12-28	61	\N	active	PERCENT
373	2025-08-10	2025-08-26	\N	44431	active	FIXED
374	2022-06-19	2022-06-28	36	\N	active	PERCENT
375	2025-05-19	2025-05-26	\N	40554	active	FIXED
376	2025-06-25	2025-07-06	73	\N	paused	PERCENT
377	2022-08-10	2022-08-22	19	\N	active	PERCENT
378	2024-05-03	2024-05-12	11	\N	inactive	PERCENT
379	2024-06-07	2024-06-26	\N	14045	paused	FIXED
380	2021-02-05	2021-03-03	64	\N	inactive	PERCENT
381	2024-05-15	2024-06-13	\N	49889	active	FIXED
382	2023-01-26	2023-01-31	11	\N	paused	PERCENT
383	2023-07-11	2023-08-06	90	\N	paused	PERCENT
384	2025-12-14	2025-12-29	41	\N	active	PERCENT
385	2023-08-16	2023-09-13	53	\N	active	PERCENT
386	2023-05-12	2023-06-07	\N	2267	paused	FIXED
387	2025-07-11	2025-08-02	3	\N	active	PERCENT
388	2023-04-09	2023-04-24	9	\N	active	PERCENT
389	2022-10-26	2022-11-01	70	\N	inactive	PERCENT
390	2024-12-24	2025-01-19	11	\N	inactive	PERCENT
391	2022-05-20	2022-05-30	90	\N	inactive	PERCENT
392	2020-07-07	2020-07-24	93	\N	paused	PERCENT
393	2025-08-15	2025-09-13	55	\N	inactive	PERCENT
394	2023-02-13	2023-03-03	90	\N	paused	PERCENT
395	2024-11-02	2024-11-08	\N	28757	active	FIXED
396	2020-05-05	2020-05-12	27	\N	active	PERCENT
397	2024-11-07	2024-12-03	\N	47894	active	FIXED
398	2025-06-16	2025-07-12	82	\N	active	PERCENT
399	2023-04-18	2023-05-16	53	\N	inactive	PERCENT
400	2022-01-15	2022-01-25	\N	4736	paused	FIXED
401	2021-11-21	2021-12-06	71	\N	active	PERCENT
402	2021-10-12	2021-11-10	\N	37499	paused	FIXED
403	2023-09-25	2023-10-13	\N	31205	paused	FIXED
404	2023-08-11	2023-08-24	\N	26766	inactive	FIXED
405	2021-06-08	2021-06-27	\N	20258	paused	FIXED
406	2025-12-02	2025-12-23	\N	15967	active	FIXED
407	2023-01-22	2023-02-14	\N	25238	inactive	FIXED
408	2022-03-24	2022-04-08	\N	40059	paused	FIXED
409	2025-03-19	2025-03-26	87	\N	inactive	PERCENT
410	2021-12-18	2021-12-23	\N	32828	inactive	FIXED
411	2023-09-07	2023-09-29	\N	21456	active	FIXED
412	2024-03-14	2024-03-20	43	\N	inactive	PERCENT
413	2023-11-11	2023-11-28	\N	30350	inactive	FIXED
414	2023-09-02	2023-09-19	32	\N	paused	PERCENT
415	2023-06-03	2023-06-19	46	\N	inactive	PERCENT
416	2023-01-15	2023-02-14	2	\N	paused	PERCENT
417	2024-10-09	2024-11-04	60	\N	inactive	PERCENT
418	2023-10-25	2023-11-14	\N	968	active	FIXED
419	2020-03-25	2020-04-16	1	\N	inactive	PERCENT
420	2024-09-06	2024-09-11	\N	4429	active	FIXED
421	2022-12-23	2023-01-17	42	\N	inactive	PERCENT
422	2020-01-01	2020-01-27	\N	49475	active	FIXED
423	2020-02-26	2020-03-02	58	\N	active	PERCENT
424	2023-05-18	2023-05-29	\N	4660	active	FIXED
425	2023-02-08	2023-03-09	52	\N	paused	PERCENT
426	2023-10-28	2023-11-07	\N	15176	paused	FIXED
427	2021-02-23	2021-03-06	\N	10927	paused	FIXED
428	2025-12-20	2025-12-26	78	\N	active	PERCENT
429	2020-06-14	2020-06-23	\N	32615	paused	FIXED
430	2021-09-10	2021-10-10	98	\N	inactive	PERCENT
431	2021-06-07	2021-06-20	69	\N	inactive	PERCENT
432	2025-08-17	2025-09-05	\N	25586	active	FIXED
433	2024-05-16	2024-06-15	58	\N	inactive	PERCENT
434	2021-05-12	2021-05-26	55	\N	active	PERCENT
435	2024-04-15	2024-05-15	78	\N	paused	PERCENT
436	2025-10-19	2025-11-03	84	\N	active	PERCENT
437	2021-12-04	2021-12-28	7	\N	paused	PERCENT
438	2023-04-18	2023-05-09	\N	16587	inactive	FIXED
439	2023-03-11	2023-04-06	93	\N	inactive	PERCENT
440	2025-02-10	2025-03-12	75	\N	inactive	PERCENT
441	2023-06-27	2023-07-11	\N	23744	active	FIXED
442	2022-09-17	2022-10-04	\N	7938	active	FIXED
443	2022-10-21	2022-11-03	\N	48938	active	FIXED
444	2023-10-11	2023-10-24	98	\N	active	PERCENT
445	2025-05-05	2025-05-28	66	\N	inactive	PERCENT
446	2025-04-22	2025-05-04	14	\N	inactive	PERCENT
447	2024-01-24	2024-02-21	35	\N	paused	PERCENT
448	2020-02-27	2020-03-17	44	\N	paused	PERCENT
449	2022-02-04	2022-02-26	63	\N	inactive	PERCENT
450	2021-05-12	2021-06-09	15	\N	active	PERCENT
451	2023-04-13	2023-05-12	\N	25769	active	FIXED
452	2021-04-02	2021-04-30	29	\N	inactive	PERCENT
453	2020-08-22	2020-09-04	\N	40193	inactive	FIXED
454	2021-05-14	2021-05-19	\N	13678	active	FIXED
455	2020-08-27	2020-09-19	\N	30583	inactive	FIXED
456	2020-05-13	2020-05-22	55	\N	paused	PERCENT
457	2023-10-10	2023-10-30	\N	40445	active	FIXED
458	2022-04-18	2022-04-29	97	\N	active	PERCENT
459	2021-07-27	2021-08-06	22	\N	paused	PERCENT
460	2023-05-26	2023-06-06	\N	47564	paused	FIXED
461	2020-07-26	2020-08-22	\N	6076	paused	FIXED
462	2023-06-16	2023-06-29	\N	3225	active	FIXED
463	2020-02-27	2020-03-25	\N	24609	active	FIXED
464	2025-04-08	2025-05-02	\N	8186	inactive	FIXED
465	2021-07-09	2021-07-22	\N	12544	active	FIXED
466	2024-05-19	2024-05-27	69	\N	active	PERCENT
467	2023-07-02	2023-07-16	46	\N	paused	PERCENT
468	2021-11-08	2021-12-08	\N	43862	paused	FIXED
469	2020-12-18	2021-01-08	\N	39606	paused	FIXED
470	2023-02-03	2023-03-01	68	\N	inactive	PERCENT
471	2023-05-11	2023-05-31	\N	8802	active	FIXED
472	2025-08-21	2025-09-14	\N	27304	inactive	FIXED
473	2025-04-19	2025-05-12	4	\N	inactive	PERCENT
474	2024-09-04	2024-09-15	\N	23525	active	FIXED
475	2021-07-18	2021-08-05	60	\N	inactive	PERCENT
476	2025-10-28	2025-11-09	\N	45173	paused	FIXED
477	2020-09-07	2020-09-19	\N	21639	inactive	FIXED
478	2023-03-26	2023-04-05	\N	25976	active	FIXED
479	2021-11-07	2021-11-25	71	\N	active	PERCENT
480	2024-05-26	2024-06-15	51	\N	inactive	PERCENT
481	2020-11-18	2020-12-11	\N	14315	inactive	FIXED
482	2021-04-11	2021-05-01	\N	19346	active	FIXED
483	2020-12-01	2020-12-30	\N	32398	active	FIXED
484	2023-01-22	2023-02-07	75	\N	paused	PERCENT
485	2021-02-01	2021-02-22	65	\N	active	PERCENT
486	2022-04-23	2022-05-02	\N	546	active	FIXED
487	2022-08-14	2022-08-30	\N	36606	inactive	FIXED
488	2021-09-17	2021-10-17	\N	17530	paused	FIXED
489	2024-10-08	2024-10-30	\N	9762	paused	FIXED
490	2021-03-15	2021-03-21	\N	39916	paused	FIXED
491	2023-12-03	2023-12-30	75	\N	inactive	PERCENT
492	2022-09-25	2022-10-04	\N	38361	paused	FIXED
493	2021-03-20	2021-04-12	28	\N	inactive	PERCENT
494	2022-04-10	2022-05-02	84	\N	inactive	PERCENT
495	2022-11-13	2022-11-24	77	\N	paused	PERCENT
496	2024-10-12	2024-11-07	\N	17102	inactive	FIXED
497	2020-04-24	2020-05-17	\N	39089	inactive	FIXED
498	2024-12-07	2025-01-05	\N	29172	active	FIXED
499	2025-09-02	2025-09-24	\N	40681	active	FIXED
500	2021-09-20	2021-10-09	6	\N	active	PERCENT
\.


                                                                                                                                                                                                 5023.dat                                                                                            0000600 0004000 0002000 00000000005 15015340177 0014241 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           5019.dat                                                                                            0000600 0004000 0002000 00000000560 15015340177 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	HALLOWEEN	2024-10-31	2024-11-02
2	NAVIDAD	2024-12-01	2024-12-31
3	VERANO	2024-06-01	2024-08-31
4	DÍA DE LA MADRE	2025-05-01	2025-05-10
5	FIESTAS PATRIAS	2024-07-20	2024-07-28
6	SAN VALENTÍN	2025-02-10	2025-02-15
7	SEMANA SANTA	2025-04-13	2025-04-20
8	AÑO NUEVO	2024-12-31	2025-01-01
9	BLACK FRIDAY	2024-11-29	2024-11-29
10	CYBER MONDAY	2024-12-02	2024-12-02
\.


                                                                                                                                                5012.dat                                                                                            0000600 0004000 0002000 00000004346 15015340177 0014253 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        MG01	Fortunata	Amor	Ángel	Borrego	3217951718	Pasadizo de José Mari Garcés 422 Piso 4  Ávila, 84499	4605629	\N	MANAGER	5
MG02	Ágata	Clemente	Márquez	Perez	3137665873	Calle Eloísa Ribes 9 Valencia, 43442	4867304	\N	MANAGER	1
MG03	Fabiola	\N	Cepeda	Oller	3889965724	Pasaje de Joan Pagès 29 Puerta 4  Ourense, 67890	6391986	\N	MANAGER	4
MG04	Hilario	Gervasio	Cortes	Segovia	3224219836	Acceso de Leandra Abella 49 Puerta 8  Tarragona, 36398	2753499	\N	MANAGER	2
MG05	Marcos	Manuelita	Acedo	Cepeda	3274762074	Paseo de Leticia Royo 6 Málaga, 82730	4593857	\N	MANAGER	3
EP01	Aníbal	Heliodoro	Aliaga	Gibert	3593841973	Via Armida Luján 71 Barcelona, 41776	2552535	MG05	EMPLOYEE	\N
EP02	Jaime	Marisol	Urrutia	Exposito	3448036271	Cañada de Bruno Segura 62 Huelva, 36085	6366104	MG03	EMPLOYEE	\N
EP03	Duilio	Adela	Caro	Juan	3696619147	Avenida de Yésica Peñas 81 Cuenca, 05545	3709169	MG01	EMPLOYEE	\N
EP04	Teodosio	David	Garzón	Carranza	3703121919	Callejón Socorro Rivera 5 Apt. 57  Málaga, 39146	5442836	MG03	EMPLOYEE	\N
EP05	Violeta	Marino	Abril	Román	3292078499	C. Dorotea Diez 2 Valencia, 01352	4101765	MG05	EMPLOYEE	\N
EP06	Desiderio	\N	Villalonga	Olmedo	3458196923	Glorieta de María José Cañete 2 Cuenca, 52344	2826375	MG01	EMPLOYEE	\N
EP07	Emilia	\N	Amo	Matas	3895970655	Cañada de Florentina Espinosa 818 Lugo, 97940	7954782	MG02	EMPLOYEE	\N
EP08	Arcelia	Caridad	Alvarado	Osorio	3476369389	Callejón Domingo Cervera 93 Apt. 44  Lugo, 76889	4375894	MG05	EMPLOYEE	\N
EP09	Jacinta	\N	Pareja	Ariño	3454251502	Alameda de Atilio Raya 40 Puerta 9  Cáceres, 95301	4499121	MG04	EMPLOYEE	\N
EP10	Imelda	René	Ángel	Marín	3922836451	Vial Aureliano Jimenez 53 Sevilla, 02313	5389293	MG01	EMPLOYEE	\N
EP11	Elías	Jesusa	Manuel	Escobar	3802495350	Ronda Baudelio Carnero 19 Granada, 57005	6513062	MG01	EMPLOYEE	\N
EP12	Felipe	\N	Frías	Correa	3218645571	Acceso de Florinda García 67 Lleida, 06718	3656405	MG04	EMPLOYEE	\N
EP13	Marita	\N	Lasa	Chaves	3967818239	Vial Raimundo Casanovas 964 Cantabria, 31548	5008689	MG03	EMPLOYEE	\N
EP14	Etelvina	Cruz	Porcel	Benitez	3347903437	Cañada de Vidal Collado 520 Soria, 90505	5083373	MG01	EMPLOYEE	\N
EP15	Tomás	Gregorio	Portillo	Robles	3184028421	Ronda de Obdulia Palomar 95 Puerta 5  Huesca, 96247	7386971	MG03	EMPLOYEE	\N
\.


                                                                                                                                                                                                                                                                                          5011.dat                                                                                            0000600 0004000 0002000 00000141352 15015340177 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        928305435	Isidoro	Jaime	Portillo	3154465045	Avenida de Natalio Esteban 5 Girona, 30568	497	76	170
979228835	Leopoldo	Ana Belén	Urrutia	3190180948	Vial de Leire Folch 8 Burgos, 50090	889	97	170
943050644	Encarnacion	Patricia	Rivero	3141045765	Via de Esperanza Barbero 65 Almería, 52664	400	5	170
994565963	Sarita	Bartolomé	Márquez	3648144085	Pasaje de Elisabet Flor 7 Pontevedra, 43894	250	85	170
933815548	Maricela	Dalila	Parra	3792159021	Vial Joel Fuertes 71 Puerta 7  Valladolid, 45229	109	76	170
951373114	Diana	\N	Cervera	3757891958	Pasadizo de Eusebio Ripoll 314 Santa Cruz de Tenerife, 85042	580	23	170
972145590	Benjamín	\N	Porcel	3188597605	Calle Eutropio Vera 681 Ávila, 03723	473	70	170
919450329	Pastor	\N	Huerta	3308347242	Calle de José María Abella 77 Piso 7  Ourense, 01792	835	15	170
964565611	Gabriel	\N	Durán	3414870020	Calle Nicanor Núñez 16 Guipúzcoa, 65880	788	52	170
908499840	Olalla	\N	Bermúdez	3964579433	Calle Evangelina Leal 54 Puerta 7  Asturias, 49465	607	5	170
997036819	Asunción	\N	Bou	3325276927	Cuesta Marta Garay 143 Álava, 74653	823	25	170
959013389	Delfina	Primitiva	Pereira	3235434263	Pasaje de Cirino Sevillano 44 Puerta 5  Palencia, 53599	407	15	170
995166953	Consuela	\N	Boada	3472872053	Acceso de Isidora Lloret 85 Murcia, 56898	823	70	170
972603030	Gustavo	\N	Roura	3908469649	Plaza de Gala Escribano 302 Apt. 47  Vizcaya, 73098	720	54	170
944960247	María Manuela	Purificación	Yáñez	3434509506	C. Sarita Ayala 46 Puerta 6  Las Palmas, 82916	616	17	170
982246872	Sol	\N	Salmerón	3512637906	Pasaje de Francisco Álvaro 62 Valladolid, 10887	810	15	170
985872501	Agapito	\N	González	3930009034	Rambla Prudencia Pascual 68 Puerta 7  Álava, 97250	572	66	170
919753148	Jenaro	Juan	Ramírez	3648238686	Ronda Lucho Priego 69 Murcia, 52395	872	41	170
909657789	Martirio	Fortunata	Carmona	3203460150	Pasadizo Adolfo Cáceres 64 Piso 9  Tarragona, 42174	713	70	170
942995222	Godofredo	Ileana	Alcázar	3992150632	Pasaje de Vicenta Zaragoza 24 Apt. 26  La Rioja, 99038	42	17	170
982953194	Cruz	Emperatriz	Ayllón	3100772969	Cañada Paco García 16 Asturias, 66734	77	68	170
939042759	Gabino	Belén	Sánchez	3368232302	Paseo de Pedro Cerezo 87 Zamora, 33044	610	18	170
928234728	Benigno	Tristán	Peláez	3511904719	Urbanización Griselda Cortes 42 Apt. 55  Teruel, 29889	370	50	170
966097383	Mohamed	\N	Zurita	3816131706	Alameda Berto Planas 38 Apt. 21  La Rioja, 88408	835	15	170
972145798	Ani	Moisés	Gual	3711256946	Alameda Carmelo Malo 17 Piso 2  Soria, 06709	356	52	170
931218052	Isidora	\N	Viña	3348977058	Paseo Jose Manuel Sureda 16 Lleida, 47843	207	52	170
915029095	Teodora	Sandalio	Matas	3698825426	Camino Jeremías Escobar 62 Apt. 07  Soria, 75777	51	54	170
940886823	Ciriaco	\N	Agustí	3421259109	C. Carmelita Sans 44 Puerta 5  Huelva, 03942	154	25	170
933707549	Lope	Olimpia	Fuentes	3380711945	Via Elpidio Pinedo 42 Puerta 7  Pontevedra, 26392	245	54	170
907845496	Charo	\N	Vaquero	3518720992	Calle Gonzalo Peralta 39 Burgos, 35038	20	11	170
929608797	Gastón	Nilo	Tena	3980966081	Via Angelina Cortes 419 Puerta 7  Navarra, 85990	692	47	170
912767234	Nacio	Anna	Pelayo	3799017095	Pasaje de Teresa Guillén 70 Piso 1  Alicante, 11613	148	73	170
996770691	Lino	Prudencia	Guillén	3290480538	Acceso Hortensia Perea 90 Piso 5  Santa Cruz de Tenerife, 28395	622	19	170
956710698	Encarnación	\N	Lluch	3641154676	Ronda Rosaura Santamaria 76 Badajoz, 86711	807	19	170
993815780	Nazaret	Renato	Serna	3634118494	Via de José Solé 8 Piso 7  Burgos, 18291	1	50	170
902932073	Juan	\N	Barrio	3792812822	Callejón de Clara Vigil 584 Piso 7  Lugo, 55727	883	94	170
960035478	Manu	Febe	Priego	3157828762	Alameda de Celestina Ortiz 432 Las Palmas, 10295	570	47	170
977430883	Albano	\N	Luz	3857356761	Cañada Azeneth Girona 42 Apt. 73  Guadalajara, 79337	736	5	170
909457468	Diego	Chucho	Artigas	3108832789	Urbanización Marcio Segovia 35 Puerta 5  Jaén, 83372	161	97	170
958232533	Cruz	Visitación	Estrada	3994706545	Pasaje Anita Álamo 79 Piso 6  Burgos, 46131	555	23	170
913538049	Lucio	Nuria	Herrero	3287451544	Plaza de Nicolás Marin 383 Piso 9  Segovia, 60361	368	5	170
928574718	Carolina	Susana	Carballo	3851368079	Ronda de Pascual Jara 32 Apt. 45  Tarragona, 13500	11	20	170
956333991	Atilio	Julieta	Alberto	3799702845	Callejón Lorenza Campo 41 Piso 0  Málaga, 17501	500	15	170
953859634	Silvio	Emma	Vazquez	3893433111	Paseo Victor Manuel Sarabia 10 Piso 1  Zamora, 32802	790	5	170
930108605	Arsenio	Santiago	Arco	3168721404	Cuesta Tatiana Vicens 61 Toledo, 30553	344	54	170
956376214	Agustín	Miguel Ángel	Iñiguez	3686799087	Pasaje Haroldo Antón 1 Girona, 19396	885	41	170
990217511	Ciríaco	\N	Diego	3490217016	Acceso Dora Pareja 95 Piso 4  Toledo, 61542	847	5	170
986519059	Luis Miguel	Agustina	Cañizares	3627835740	C. Jose Miguel Casanova 75 Apt. 02  Segovia, 59609	279	85	170
962372083	Ariadna	Bruno	Galván	3356030828	Plaza de Angelino Bermúdez 88 Apt. 10  Cáceres, 86618	736	5	170
967318924	Clementina	Carolina	Montoya	3943305746	Cañada de Julia Acevedo 91 Las Palmas, 50636	483	41	170
965253647	Teófila	Luciana	Cáceres	3800824982	Calle de Alondra Llobet 255 Albacete, 34669	504	73	170
986119266	Mónica	\N	Vallejo	3305047970	Avenida Eliana Chaves 78 Apt. 26  Navarra, 95123	670	54	170
981788876	Jorge	Dalila	Belda	3415024098	Vial Clotilde Rueda 71 Piso 6  Huesca, 09513	444	17	170
956252108	Primitivo	Griselda	Tamayo	3948176161	C. Cesar Sarabia 71 Teruel, 42218	807	41	170
978781110	Melania	\N	Casado	3177763063	Paseo Abilio Tomás 5 Cádiz, 22395	367	15	170
959663318	Fátima	\N	Lucena	3538751871	Glorieta Virgilio Calzada 94 Piso 6  Ávila, 16634	820	70	170
950167769	Ana Belén	Julián	Amat	3660883185	Glorieta Xiomara Ríos 97 Castellón, 54956	91	5	170
982103979	Luciana	\N	Dominguez	3260917334	Via de Eusebio Tirado 69 Huesca, 27581	258	25	170
947749299	Nuria	\N	Viñas	3161384012	Acceso de Leopoldo Sáez 28 Piso 6  Ávila, 06163	580	23	170
905695911	Graciano	\N	Río	3787855407	Avenida de Rosario Palomo 8 Piso 9  Alicante, 42780	807	19	170
964063061	Cristóbal	Josefina	Conesa	3380549327	Pasaje Gala Peñalver 41 Apt. 83  Lugo, 14373	400	70	170
926856461	Serafina	Milagros	Ferrández	3846792057	Avenida de Rocío Segovia 37 Piso 1  Lleida, 19130	349	73	170
904202622	Gema	Soledad	Nicolás	3455928168	C. Ruperta Real 56 Apt. 18  Murcia, 27505	754	25	170
950892998	Guiomar	\N	Caro	3304458468	Acceso de Paca Bauzà 45 Vizcaya, 40760	682	66	170
975456008	Casemiro	\N	Diego	3335574920	Camino de Dionisio Feijoo 70 Puerta 5  Ciudad, 72348	899	25	170
950964791	Juan Francisco	Pánfilo	Barba	3730785027	Glorieta Loreto Lobato 223 Valencia, 53874	770	73	170
939715488	Emilia	Juan	Villalobos	3494516301	Paseo de Anita Torrens 3 Piso 5  La Rioja, 35037	122	76	170
905206411	Miguel	Carina	Alberto	3425233487	Pasaje Anunciación Peñalver 2 Apt. 85  Álava, 99855	320	52	170
976440882	Trinidad	Narcisa	Bru	3467256263	Acceso de María Belén Torrijos 9 Ciudad, 70752	535	25	170
936895631	Lorena	\N	Frutos	3604257184	Via de Chita Alcántara 940 Madrid, 69236	610	18	170
935869531	Florencio	Tadeo	Carbajo	3204630265	Via Anacleto Requena 20 Segovia, 33281	20	41	170
983755923	Che	Roberta	Vicente	3854989361	Callejón Calixta Hernandez 70 Puerta 8  Guipúzcoa, 67807	760	13	170
967193661	Renato	Vinicio	Vila	3699404665	Cañada Rocío Marquez 292 Lugo, 62791	693	19	170
960785086	Elvira	Palmira	Mariscal	3544395199	Acceso Elba Verdugo 352 Badajoz, 53679	764	15	170
900423294	Martín	\N	Villa	3915622937	Urbanización de Priscila Manjón 20 Córdoba, 14250	4	11	170
901750250	Edgardo	\N	Briones	3431086802	Avenida de José Baró 6 Salamanca, 71871	757	15	170
931684515	Leonel	Alba	Boada	3425059497	Rambla de Sancho Pomares 7 Melilla, 75537	647	13	170
925420116	Baltasar	Reynaldo	Huertas	3533822678	Cuesta de Fabricio Morera 48 Piso 2  Cáceres, 80134	461	73	170
933710576	Silvia	\N	Feijoo	3678023763	Rambla de Laura Fuentes 46 Piso 2  Cantabria, 26061	279	44	170
921827334	Tomás	Moreno	Ocaña	3950281739	Plaza Apolonia Rodrigo 4 Apt. 41  Salamanca, 42804	190	5	170
972033186	Itziar	Paz	Bermejo	3375409445	Pasadizo Heliodoro Bueno 28 Ourense, 55377	246	76	170
935915480	Cosme	Silvestre	Calvet	3416264587	Ronda Carlito Tejada 20 Piso 7  Granada, 72803	130	76	170
953040538	Dafne	\N	Almeida	3456102595	Pasaje de Natalio Aguado 908 Puerta 0  Almería, 36477	209	68	170
901320448	Tecla	\N	Duarte	3261660829	Pasadizo de Sofía Barros 32 Apt. 78  Jaén, 47869	226	50	170
963749255	Alberto	José Luis	Quesada	3937103121	Acceso de Valero Ribera 423 Piso 4  Almería, 97277	325	85	170
900643569	Loreto	\N	Ramirez	3394585887	Urbanización Atilio Calvet 94 Apt. 07  Las Palmas, 62243	223	15	170
917098910	Vicente	\N	Pulido	3410740816	Plaza de Yago Jordán 4 Apt. 98  Huelva, 19561	861	73	170
973346358	Conrado	\N	Saez	3901558566	Pasaje Sol Escribano 388 Alicante, 57343	418	68	170
980043785	Consuelo	Jose	Mercader	3647073744	Pasaje Dorotea Vallés 83 Cáceres, 48282	871	54	170
944888748	Macaria	Íñigo	Alemany	3681237262	Urbanización Armida Alsina 59 Piso 8  Guadalajara, 01779	450	50	170
970419719	Julio	\N	Barrio	3651003240	Acceso de Calista Farré 847 Apt. 42  Cáceres, 79447	30	5	170
923015577	Joan	Fito	Valls	3739324928	Urbanización Isabel Cuenca 7 Piso 4  Zamora, 31617	563	76	170
980110396	Anita	\N	Peláez	3272125640	Rambla Nélida Ramos 56 Puerta 1  Ceuta, 63204	522	68	170
945822498	Diana	\N	Marco	3128419136	Vial de Gerardo Garcés 1 Castellón, 44075	224	25	170
919120234	Ámbar	Hernán	Alba	3624087721	Pasadizo de Aureliano Salcedo 933 Granada, 31573	692	47	170
986142303	Cecilia	\N	Bauzà	3526937765	Cañada Horacio Cadenas 78 Vizcaya, 35820	873	73	170
944637933	Nilda	Itziar	Bravo	3106877892	Pasaje Maristela Zaragoza 9 Jaén, 93388	344	68	170
940517938	Gastón	Renato	Gallart	3783176676	Plaza de Pascual Castro 64 Puerta 5  Barcelona, 12138	436	8	170
941945188	León	Claudia	Briones	3168665715	C. de Simón Rius 17 Piso 8  Toledo, 19929	206	5	170
937831004	Beatriz	Ascensión	Riera	3429096107	Pasadizo Mauricio Barceló 70 Alicante, 79090	440	85	170
917534613	Eliseo	Narciso	Soriano	3515567298	Ronda de Florentino Cánovas 67 Lugo, 01276	361	27	170
910619583	Jenaro	\N	Olmedo	3547735175	Avenida de Rómulo Sales 51 Piso 8  La Rioja, 53521	40	5	170
995214416	Candelario	Remedios	Patiño	3493296832	Calle Eliana Alsina 31 Apt. 73  Palencia, 53754	101	68	170
987311639	Teresita	\N	Vélez	3935997236	C. de Bernarda Roca 85 Apt. 47  Málaga, 48636	300	81	170
943750082	Concha	\N	Aramburu	3206732507	Cañada de Gloria Mas 49 Soria, 49887	244	41	170
910020304	Elpidio	\N	Iglesias	3104521324	Paseo de Emilia Jover 93 Piso 1  León, 55135	162	15	170
996955749	Griselda	\N	Bastida	3103620396	Vial de Cayetano Peñas 16 Burgos, 31465	227	52	170
967708733	Candelas	Pilar	Seco	3767021243	Rambla Andrea Antón 3 Piso 9  Lugo, 40328	400	66	170
911613762	Juan Bautista	\N	Cabanillas	3563303771	Via Miguel Ángel Abellán 43 La Coruña, 30858	361	5	170
966637336	Benigna	\N	Bertrán	3810683765	Paseo de Feliciana Caro 663 Apt. 71  Pontevedra, 63203	657	13	170
963127111	Diana	\N	Sandoval	3663479795	Camino Eloísa Torrens 559 Madrid, 98058	6	50	170
922698657	Chema	\N	Toledo	3877144137	Paseo de Iris Oliver 27 Puerta 5  Zaragoza, 88997	2	11	170
994193991	Reyes	Mariano	Sanz	3859766150	Calle de Miriam Peñalver 1 Apt. 91  Santa Cruz de Tenerife, 19485	522	15	170
908028255	Lilia	\N	Mancebo	3862529412	Cuesta de Lupe Criado 49 Apt. 43  Badajoz, 74980	879	15	170
916036083	Anselmo	\N	Yáñez	3708375411	Avenida Flavia Urrutia 985 Córdoba, 03398	276	68	170
942836925	Sancho	Anna	Carbonell	3801721212	Glorieta de Clarisa Osorio 192 Puerta 3  Tarragona, 73649	839	15	170
937857992	Benito	\N	Amo	3847836863	Avenida Edmundo Canales 8 Santa Cruz de Tenerife, 48648	871	25	170
951876176	Chus	\N	Arregui	3303494664	Vial Encarnación Delgado 93 Piso 5  Santa Cruz de Tenerife, 03726	669	91	170
923222892	Francisco Javier	Juan Manuel	Aguilera	3119052206	Avenida Sofía Valdés 29 Apt. 29  Guipúzcoa, 02489	823	76	170
990342933	Emelina	Eugenia	Bernal	3516439631	Ronda Apolinar Echevarría 2 Navarra, 17706	553	54	170
960326839	Yaiza	Nidia	Peralta	3897367882	Pasadizo Mireia Sandoval 83 Apt. 74  Baleares, 71180	673	13	170
941951354	Marc	Cintia	Rivas	3510610146	Cuesta de Selena Cobos 31 Piso 4  Huelva, 76333	892	76	170
904720168	Toño	\N	Murcia	3414938025	Camino de Yésica Juárez 50 Apt. 61  Lugo, 71438	592	18	170
937847742	Régulo	Maricruz	Gelabert	3190141854	Camino de Haroldo Solsona 36 Apt. 33  Guadalajara, 53510	224	25	170
986605552	Sonia	\N	Taboada	3834525781	Acceso Hermenegildo Azcona 43 Piso 5  Las Palmas, 77567	549	13	170
930036154	Jenny	Humberto	Sosa	3496891507	Camino Ismael Cepeda 5 Albacete, 86073	45	20	170
996278458	Valerio	\N	Sanmartín	3414363809	Calle Maxi Nogués 33 Apt. 55  Palencia, 55738	870	73	170
962794570	Alex	\N	Gaya	3203352646	Rambla de Che Santiago 14 Puerta 1  Santa Cruz de Tenerife, 58191	92	15	170
975088483	Jacinta	Tiburcio	Guzmán	3353275368	Camino Roque Cornejo 991 Burgos, 61508	838	52	170
921654898	Casemiro	Itziar	Tejera	3432573371	C. de Timoteo Torrecilla 26 Castellón, 92351	675	8	170
970329879	Eric	\N	Tolosa	3663268428	Calle de Candelas Jódar 78 Piso 9  Segovia, 75186	209	5	170
936360693	Bernardino	\N	Montaña	3580789771	Plaza Nando Mena 17 Piso 6  Álava, 49641	400	66	170
984564516	Severiano	\N	Saura	3320945620	Pasaje de Hipólito Girón 67 Apt. 16  Ávila, 84859	284	5	170
903198159	Marcela	Gonzalo	Tur	3847155812	Via de Inocencio Batlle 75 Las Palmas, 70821	808	15	170
964073819	Atilio	Horacio	Ríos	3133318321	Via de Reinaldo Sanmiguel 64 Vizcaya, 64808	745	25	170
964929460	Juan José	Andrea	Román	3408652455	Callejón de Enrique Marcos 418 Piso 3  Navarra, 25127	226	15	170
980701033	Bonifacio	\N	Murillo	3312794867	Rambla Telmo Valle 901 Apt. 16  Toledo, 83930	541	5	170
984951188	Ruth	Cayetana	Canet	3931500033	Avenida Lilia Parra 65 La Rioja, 72270	669	91	170
959177027	Leticia	\N	Viana	3170705913	Paseo Lupe Orozco 22 Palencia, 54680	854	5	170
990214711	Albert	Anselmo	Pedrero	3940059632	Cuesta de Lalo Ros 963 Cádiz, 13710	430	13	170
905012595	José Antonio	Eusebia	Cabanillas	3291386359	Camino Nieves Santos 86 Ourense, 30179	470	63	170
900505451	Rubén	Alberto	Benavides	3442745352	Camino de Marcelino Ugarte 377 Soria, 75484	773	99	170
936996120	Ruperta	\N	Rubio	3468613144	Callejón de Cristóbal Maza 65 Piso 1  Zaragoza, 60021	616	76	170
947606063	Clímaco	Eustaquio	Mulet	3444601486	C. Heriberto Luz 11 Puerta 2  Teruel, 47346	30	47	170
966655599	Pascual	Lidia	Aliaga	3718374834	Avenida Haydée Mascaró 599 Zamora, 66514	197	5	170
969215341	Paulino	Primitivo	Lledó	3650447616	Vial Federico Uría 76 Piso 6  Ávila, 71024	347	54	170
902724169	Fabio	Gracia	Valbuena	3230378202	Rambla Graciana Rocha 423 Apt. 72  Valladolid, 90970	204	70	170
900513292	Hilda	Encarnita	Soler	3479584327	Rambla de Rosalina Clavero 73 Piso 3  Las Palmas, 56149	1	15	170
972644048	Ulises	Caridad	Arias	3144367552	Pasadizo de Salud Nicolau 96 Tarragona, 98766	162	85	170
990026243	Ezequiel	Nieves	Bustos	3678708365	Acceso de Domingo Vilar 25 Piso 9  Lleida, 58134	282	5	170
929849359	Gerardo	\N	Campoy	3372704007	Glorieta Mireia Llobet 41 Piso 0  Tarragona, 43441	520	76	170
924860695	Nerea	Santos	Balaguer	3647695649	Plaza Teresa Torralba 88 Piso 5  Murcia, 01615	757	15	170
958201314	Daniel	\N	Donoso	3929208705	Callejón Martina Ureña 62 Palencia, 38763	540	52	170
914222787	Azahara	\N	Sans	3702946667	Avenida Rodrigo Fortuny 938 Piso 7  Álava, 72896	420	44	170
968272979	Benito	Amparo	Cardona	3944920819	Camino de Nereida Zurita 3 Badajoz, 54020	362	15	170
947310382	Jenaro	\N	Calderón	3986103172	Calle Lisandro Duarte 31 La Coruña, 81299	281	25	170
982525411	Ciro	Gastón	Salmerón	3280877636	Avenida de Pastora Roura 6 Asturias, 44925	110	70	170
948717807	Clotilde	Ovidio	Álamo	3322424337	Paseo Ignacia Amores 414 Piso 2  Pontevedra, 94538	819	5	170
969156444	Reyes	Wilfredo	Palacios	3599353472	Acceso de Nacho Sastre 52 Puerta 4  Cantabria, 96340	687	66	170
943379110	Bernarda	Urbano	Lamas	3440483342	Via de Geraldo Campos 429 Badajoz, 67818	378	44	170
935131028	Ligia	\N	Nogueira	3568720492	Ronda de Rosendo Mulet 59 Apt. 79  Barcelona, 16583	785	18	170
902337693	Lorenzo	\N	Velasco	3594349121	Alameda Alma Cervantes 76 Palencia, 11113	350	23	170
924385656	Benjamín	Juliana	Jaén	3369750365	Avenida de Celestino Rosselló 9 Puerta 5  Lleida, 43386	110	52	170
938696444	Silvio	\N	Borrego	3958044631	Ronda Berto Marqués 68 Piso 6  Cáceres, 10992	318	76	170
963203037	Herminio	Régulo	Lobo	3657716864	Camino de Jenaro Tejedor 9 Melilla, 31434	449	73	170
952961053	Pilar	\N	Sobrino	3588927711	Acceso de Ruben Luís 18 Granada, 51689	250	54	170
933481145	Victoria	\N	Aller	3645585006	Cuesta de Cruz Romero 20 La Rioja, 54251	370	50	170
993726776	Manu	\N	Manuel	3421224322	Calle Albert Fernandez 765 Piso 7  Álava, 21119	397	68	170
947295627	Florencia	\N	Portillo	3640114895	Calle de Alejandro Borrás 587 Puerta 2  Álava, 55217	212	13	170
958167746	Adora	\N	Figueras	3729759676	Calle Damián Fonseca 29 Guipúzcoa, 90175	743	19	170
939699264	Gilberto	Fanny	Fonseca	3620761529	Alameda de Nicolás Sierra 5 Huelva, 03523	13	68	170
908978570	María Jesús	\N	Gomis	3280941852	Callejón Silvio Sanmartín 78 Lleida, 48998	750	20	170
941951465	Apolinar	Emilia	Cases	3290087265	Ronda Herberto Cantero 98 Piso 0  Málaga, 47393	230	85	170
906646819	Griselda	Cándido	Vázquez	3917550159	Cañada Visitación Carreño 4 Málaga, 52526	490	5	170
949692008	Saturnino	Delia	Cervera	3839196528	C. Joaquina Pastor 78 Lugo, 35626	224	25	170
930390301	Natividad	\N	Coello	3273050909	Vial Amparo Sarabia 37 Girona, 02262	430	13	170
904021001	Clara	Glauco	Vall	3420336895	Ronda de Bartolomé Mercader 51 Melilla, 44416	756	5	170
987035731	Vinicio	\N	Peñalver	3846800003	Paseo de Candelaria Manzano 43 Puerta 1  Girona, 19276	245	47	170
953180841	Iris	Amor	Hurtado	3203898147	Cuesta Íñigo Rodríguez 950 Piso 5  Lleida, 63061	841	25	170
979054057	Amor	Víctor	Prieto	3699790682	Vial Casemiro Carbonell 79 Burgos, 76365	682	66	170
963391429	Emiliana	\N	Cardona	3954506370	Rambla de Jordi Ariza 6 Ávila, 76590	678	52	170
913654133	Gertrudis	David	Báez	3313220741	Ronda de Leandra Carballo 28 Puerta 0  Madrid, 46289	835	52	170
905971985	Concha	Martín	Pineda	3327331211	Vial de Joan Gárate 42 Piso 8  Melilla, 69622	533	68	170
929294644	Matías	Haroldo	Valcárcel	3236265145	Avenida Lucio Olivares 4 Apt. 08  Ceuta, 86832	464	68	170
927857372	Adelaida	\N	Montero	3640819264	Glorieta Álvaro Carreras 557 Puerta 2  Castellón, 07063	430	27	170
985059117	Raúl	\N	Mulet	3933473168	Glorieta de Marciano Bayo 863 Asturias, 06796	7	11	170
979333621	Jose Carlos	\N	Borja	3927660056	Glorieta de Florencia Aguirre 24 Palencia, 42193	90	44	170
955486120	Alcides	\N	Caballero	3568452471	Acceso Vanesa Gimenez 2 León, 16165	845	19	170
966717579	Berta	\N	Isern	3376316013	Urbanización de Flor Alcolea 623 Sevilla, 69179	321	5	170
969542889	Lidia	Jose Manuel	Cózar	3977160307	Plaza de Fabricio Palomino 56 Soria, 85196	585	19	170
923104713	Fermín	\N	Sandoval	3475653057	C. Alberto Nadal 68 Puerta 1  Baleares, 50131	372	8	170
998169890	Fanny	María	Dalmau	3141327398	Calle de Zaida Montenegro 7 Piso 4  Álava, 42458	600	27	170
994832244	Gonzalo	\N	Jara	3647020751	Avenida Cándido Díez 15 Baleares, 54362	92	15	170
915548853	Nerea	\N	Barrios	3864556992	Pasaje Epifanio Morán 34 Cantabria, 45401	124	50	170
917902531	Andrés Felipe	\N	Zamorano	3467573451	Pasaje de Dolores Niño 74 Guadalajara, 82438	820	54	170
984448334	Hilario	Aránzazu	Lastra	3879968406	Avenida de Rufino Canals 76 Apt. 17  Palencia, 95735	535	25	170
967301377	Ciro	\N	Reguera	3999696012	Pasaje de Adelia Sánchez 75 Piso 9  Tarragona, 60718	288	25	170
937073955	Jovita	Esperanza	Gonzalo	3495511928	Via Wilfredo Osorio 69 Soria, 96830	660	41	170
999198554	Valentina	Lina	Farré	3861424491	Rambla Celso Chaparro 51 Piso 3  Barcelona, 39064	692	47	170
972997871	Ildefonso	\N	Viana	3853133453	Rambla de Quirino Beltrán 106 Puerta 7  Las Palmas, 32628	530	41	170
908265020	Paco	\N	Conesa	3403407715	C. Salvador Girón 16 La Coruña, 83038	284	5	170
978003241	Sandalio	\N	Echeverría	3962538956	Calle de Vito Mateu 88 La Coruña, 26471	270	50	170
900644966	Nilo	Jose Carlos	Aznar	3176698395	Camino Leonel Alarcón 7 Puerta 4  Zamora, 10234	356	52	170
995902042	Azahar	Rodolfo	Ojeda	3206540340	Cañada de Carina Mayo 642 Cáceres, 84485	542	15	170
980474616	Alexandra	\N	Escalona	3773955552	Rambla de Maura Ruano 78 Apt. 11  Pontevedra, 90071	410	18	170
919465469	Ale	María	Abella	3639018238	Avenida Pacífica Bonet 39 Ourense, 87405	760	86	170
929895646	Mirta	Edelmira	Paredes	3636669961	Paseo de Clara Villalba 94 Apt. 04  Álava, 53847	745	47	170
935997202	Isaac	Mauricio	Roca	3672943227	Camino Rufino Arregui 4 Apt. 12  Huesca, 47470	210	52	170
920846362	Eloy	Nando	Bru	3998599397	Cañada de Vicente Vendrell 43 Piso 7  Tarragona, 18461	755	15	170
962642645	Reyes	\N	Melero	3882061895	Ronda Tamara Castillo 8 Apt. 85  Teruel, 37443	322	15	170
902339304	Renato	Miriam	Mínguez	3195018989	Glorieta de Salvador Navarro 4 Apt. 41  Almería, 81672	531	15	170
937044408	Donato	Charo	Nebot	3370605643	Pasadizo de María Pilar Espada 49 Apt. 31  Ciudad, 04841	684	68	170
940515871	Federico	Macarena	Alegria	3969151670	Avenida de Lucio Falcón 311 Piso 2  León, 91154	1	23	170
984456845	Sarita	\N	Rivero	3496065241	Cuesta Albino Laguna 5 Piso 9  Zamora, 62489	306	76	170
935005522	Cirino	Sabas	Godoy	3273910686	Vial de Olimpia Sastre 7 Huesca, 89497	610	18	170
942372738	Beatriz	Diana	Ribes	3872150147	Pasaje de Samu Bonilla 815 Palencia, 48535	861	68	170
934364121	Cesar	\N	Montero	3902783756	Ronda de Sol Alarcón 94 Piso 7  Murcia, 95928	683	52	170
938644613	Graciana	\N	Duran	3151786925	Pasadizo Alondra Mendizábal 901 Apt. 17  Murcia, 04400	236	73	170
976934082	Elba	Rosaura	Barrera	3730408248	Acceso Agustina Quintana 69 Guadalajara, 43570	689	50	170
981636213	Duilio	\N	Guerrero	3971937508	Ronda de Olivia Galán 74 Piso 7  Zaragoza, 69435	154	25	170
959520720	Rosendo	\N	Malo	3960160543	Pasaje de Mar Falcón 89 Almería, 72091	708	70	170
918086145	José Antonio	Angelina	Castejón	3211735520	Cuesta Aurelio Artigas 86 Burgos, 04148	885	94	170
962756953	Heraclio	\N	Castell	3284288996	Acceso Vidal Gonzalo 99 Guadalajara, 78749	51	68	170
906040629	Gracia	\N	Ayuso	3921063700	Via Angelina Madrid 1 Piso 2  Ceuta, 28746	790	15	170
927284282	Coral	\N	Aguado	3459082082	Cuesta de Florentina Solsona 79 Huesca, 97086	111	63	170
907686292	Albert	Macaria	Martin	3579144201	Rambla Socorro Posada 1 Apt. 99  Ourense, 09933	560	8	170
999423667	Hugo	Yésica	Arias	3846519852	Avenida Florina Diaz 830 Puerta 8  Tarragona, 72844	523	70	170
908365796	Sara	Aníbal	Garcia	3251231444	Vial Anselmo Galan 97 Piso 8  Madrid, 25265	720	52	170
928928023	Vicenta	Trini	Gomez	3845911922	Avenida de Clímaco Alberdi 2 Madrid, 23195	774	15	170
936714701	Juan Luis	Eutropio	Carrasco	3609064697	Calle de Ofelia Aguilera 69 Piso 6  Lleida, 00962	553	54	170
917620321	Olga	\N	Llorente	3425145161	Cañada de Calisto Bou 7 Apt. 55  Navarra, 08279	279	85	170
931525358	Isidoro	\N	Feijoo	3762102444	Rambla de Corona Andrés 65 Zaragoza, 41723	479	18	170
968750894	Abigaíl	Lorenza	Conesa	3309183468	Plaza Reyes Enríquez 74 Apt. 19  Burgos, 49269	313	50	170
947004384	Leyre	\N	Salazar	3499283285	Cañada Teo Fabregat 56 Piso 8  Jaén, 13781	295	20	170
928881947	Ariel	\N	Pera	3953062439	Vial Evita Enríquez 97 Asturias, 04203	1	94	170
993161268	Inmaculada	Araceli	Ledesma	3316396792	Vial Pastora Fábregas 93 Las Palmas, 03954	272	63	170
960672024	Soraya	Petrona	Clemente	3929009893	Rambla Erasmo Zapata 76 Piso 8  Toledo, 58808	483	73	170
902801616	Omar	Mamen	Valero	3265648142	Cañada de Marcelo Montenegro 60 Piso 9  La Coruña, 82117	1	86	170
935689818	Amancio	\N	Garrido	3662335058	Alameda de Crescencia Ortuño 55 Palencia, 19300	664	15	170
960876416	Marina	Clara	Fajardo	3265609383	Pasaje Federico Tolosa 35 Melilla, 71200	385	68	170
960854777	Evita	Pablo	Patiño	3160889750	Pasadizo Crescencia Barco 686 Apt. 53  Toledo, 75312	517	19	170
999857613	Antonio	Yolanda	Montaña	3254101694	Pasaje de Bernardita Gallardo 98 Puerta 9  Zaragoza, 84834	1	11	170
915968982	Horacio	Gil	Criado	3847244518	Cañada Zoraida Bravo 827 Puerta 8  Baleares, 20656	244	15	170
991845776	Édgar	\N	Girón	3641367611	Plaza Dora Mulet 325 Lleida, 20393	815	25	170
936702553	Salomé	Verónica	Álvaro	3806255663	Alameda de Édgar Quiroga 8 Piso 9  Zamora, 10278	692	47	170
935183191	Maximiliano	\N	Vidal	3797372305	C. de Milagros Lladó 15 Teruel, 19357	370	68	170
900614697	Sancho	\N	Lozano	3482598981	Callejón de Edgardo Ribas 19 Lugo, 23241	500	68	170
980497266	Dionisio	Silvestre	Díaz	3919009801	Cañada Basilio Torres 91 Ceuta, 51883	810	13	170
941979585	Alonso	Alberto	Paniagua	3318418928	Pasadizo Matilde Guardia 766 Apt. 36  Huesca, 56076	6	11	170
992340977	Gertrudis	Dora	Mendizábal	3280246177	Vial de Albina Verdú 5 Almería, 70337	442	13	170
906229125	Néstor	Roxana	Cánovas	3492709240	C. de Julie Águila 621 Puerta 3  Segovia, 22168	800	54	170
931090808	Evangelina	\N	Ferrández	3728855152	Camino Iker Buendía 2 Alicante, 31383	250	5	170
965944028	Guiomar	Macario	Moya	3521892781	Plaza Fabio Meléndez 25 Tarragona, 06833	646	15	170
940233923	Leopoldo	\N	Álvarez	3847646007	Urbanización Delia Portillo 46 Soria, 19316	612	25	170
973490615	Yolanda	Vicente	Otero	3573313833	Alameda de Dulce Pacheco 98 Huesca, 18534	325	15	170
919746795	Haroldo	\N	Villena	3315265118	Paseo Florinda Blanch 53 Palencia, 69017	777	97	170
927966707	Jesús	Pedro	Torrijos	3108279841	Rambla Teodosio Iglesia 90 Granada, 18809	100	19	170
993861101	Cipriano	Adalberto	Morales	3238032878	Vial de Adrián Sáez 616 Puerta 1  Álava, 22426	513	17	170
978530395	Leopoldo	Milagros	Dueñas	3564897447	Urbanización de Nilo Fernandez 32 Apt. 24  La Rioja, 89429	763	15	170
993388700	Daniela	\N	Molina	3639947756	Plaza de Amílcar Morales 23 Alicante, 84189	206	41	170
939962893	Teodosio	Belen	Bermúdez	3343769198	Alameda Mónica Bueno 28 Piso 5  Cádiz, 34227	307	25	170
939551224	Edmundo	\N	Puente	3411875866	Plaza Anunciación Cordero 96 Apt. 21  Girona, 54307	51	52	170
934466870	Olalla	Flavio	Salmerón	3923538690	Glorieta de Natanael Gascón 77 La Rioja, 90786	45	5	170
921392548	Irma	\N	Fajardo	3335164000	Pasaje de Leoncio Santamaria 431 Apt. 93  Segovia, 07883	318	5	170
934158594	Raquel	Dalila	Ribera	3238810021	Ronda Amparo Barragán 588 Puerta 0  Pontevedra, 98888	755	68	170
972751550	Paz	\N	Boix	3926032618	Paseo Maura Sanchez 772 Granada, 17815	11	11	170
947556227	Nicolasa	\N	Tudela	3417471569	Alameda Loida Sánchez 29 Apt. 41  Toledo, 42130	660	47	170
907969920	Verónica	\N	Gisbert	3478871247	Rambla Valentín Águila 47 Apt. 11  Soria, 92734	501	5	170
948229554	Andrés	\N	Cueto	3250003311	Urbanización Georgina Gibert 666 Puerta 7  Cáceres, 75719	520	73	170
903737346	Hilario	\N	Almansa	3309550991	Acceso Candelas Conde 6 Apt. 69  Vizcaya, 35253	678	73	170
926949446	Agustina	Vilma	Nogueira	3881677098	Alameda de Ale Torralba 13 Apt. 53  Ávila, 48493	425	68	170
997241396	Valentín	\N	Puente	3601625394	Urbanización Calisto Ávila 12 Puerta 0  Baleares, 33981	94	18	170
938116476	Josefa	Rodolfo	Trujillo	3772167707	C. Custodia España 49 Apt. 89  Valencia, 26574	168	23	170
980665482	Maura	\N	Guerra	3341301803	Cuesta Marta Vidal 31 Valencia, 14745	600	13	170
967985232	Paulina	Gabriela	Calleja	3428454199	C. de Evelia Bartolomé 918 Apt. 03  Zamora, 25653	67	73	170
985292932	Antonia	Quique	Antúnez	3453305646	Plaza de Perlita Alsina 5 Ciudad, 08451	147	76	170
987789369	Berta	Odalys	Soto	3906969628	Via de Natividad Zorrilla 62 Piso 9  Almería, 07732	863	76	170
934494774	Luciana	\N	Duran	3195794977	Vial de Toño Carnero 6 Piso 6  Málaga, 74241	15	11	170
916643674	Azeneth	\N	Crespo	3420960282	Ronda Aurelio Fuente 838 Piso 7  Ávila, 43871	160	13	170
926562656	Raimundo	\N	Segarra	3206235412	Rambla de Casemiro Corbacho 1 Apt. 46  Cantabria, 25832	820	54	170
983017087	Margarita	\N	Mercader	3905501202	Plaza Camilo Pulido 2 Las Palmas, 74398	223	15	170
923829710	Luis Miguel	Emiliana	Pintor	3664476292	Via Inés Pou 94 Piso 6  Zamora, 68599	9	11	170
911446729	Catalina	\N	Bello	3845552068	Calle de Emiliano Gallo 808 Guadalajara, 82877	665	5	170
904257431	Natalio	\N	Salcedo	3660445486	Plaza de Álvaro Armengol 61 Puerta 4  Zamora, 22967	867	68	170
907080640	Sofía	\N	Abril	3793974813	Paseo de Juan Manuel Hervás 399 Almería, 66860	740	25	170
981591257	Oriana	Demetrio	Padilla	3707446739	Pasadizo Nacio Múgica 507 Cádiz, 70226	79	68	170
916184396	Armida	Silvio	Palmer	3211191766	Vial de Joel Ordóñez 43 Puerta 6  Melilla, 47499	476	15	170
949519868	Georgina	\N	Villalba	3289998893	Paseo de Estefanía Larrañaga 612 Jaén, 89524	653	25	170
917037622	Juanita	Dolores	Diego	3995045405	Urbanización de Che Escamilla 21 Piso 2  Toledo, 48154	817	25	170
928801443	Maristela	\N	Miró	3968587749	Glorieta Amarilis Quintanilla 5 Puerta 9  Ávila, 43029	479	18	170
934529850	Hector	Marianela	Pineda	3954667240	Glorieta de Julio César Cabo 56 Puerta 2  Castellón, 00539	347	5	170
958965635	Tadeo	Cruz	Quiroga	3738795349	Acceso Malena Arribas 66 Cádiz, 93079	548	19	170
917530568	Ani	Macarena	Amaya	3823796719	Urbanización de Leonardo Carrera 854 Badajoz, 38916	535	25	170
993870759	Moreno	Leire	Sotelo	3859258340	Plaza de Jafet Miró 26 Guipúzcoa, 36980	814	15	170
936400695	Merche	Leyre	Reguera	3673830799	Vial Tristán Rincón 8 Piso 5  Alicante, 45123	745	68	170
907333655	Sandalio	Cebrián	Carbó	3559892586	Paseo Leocadio Esteban 19 Piso 5  Ceuta, 72123	86	25	170
914126847	Viviana	Bautista	Frutos	3498288543	Vial Lorenzo Cerro 73 Barcelona, 58780	313	5	170
964690917	Plácido	Camilo	Fortuny	3307429046	Paseo de Marcio Alcalde 545 Guadalajara, 17437	288	47	170
985535217	Atilio	\N	Franco	3566664058	Pasadizo Magdalena Barón 5 Zaragoza, 45141	129	5	170
942777285	Enrique	\N	Coello	3973554412	Alameda Rosalva Marti 43 Apt. 93  Granada, 88529	686	50	170
932842013	Felipa	Manuela	Ramos	3922392547	Plaza Ildefonso Alcázar 9 Puerta 5  Alicante, 56780	573	19	170
900728176	Edu	Eustaquio	Maza	3660077479	Plaza Demetrio Parra 101 Teruel, 81432	141	8	170
912127067	Julieta	Selena	Peral	3934194348	Calle Melania Iglesias 70 Lugo, 47240	740	25	170
972261091	Ceferino	\N	Galan	3596881829	Cuesta de Jose Luis Pardo 55 Puerta 6  Álava, 13774	841	25	170
969236392	Matías	Julia	Goicoechea	3126222483	Plaza de Ainara Llorens 99 Ciudad, 11106	658	25	170
982793925	Roberto	Jose	Sosa	3155049041	Cañada de Eliana Montserrat 74 Apt. 40  Guipúzcoa, 64308	686	68	170
970660138	Heliodoro	Clímaco	Rovira	3565410899	Paseo de Fabiana Rozas 97 Teruel, 45817	495	17	170
998290061	Encarnacion	Gerardo	Llobet	3524824548	Urbanización de César Catalá 14 Puerta 1  Navarra, 55089	513	17	170
958026715	Lucio	Evelia	Amat	3390068302	Camino Piedad Ferrán 42 Apt. 37  Vizcaya, 33709	473	52	170
962087239	Jose Manuel	\N	Salvà	3582277598	Glorieta Anselma Toro 3 Vizcaya, 59183	217	73	170
970121374	Lisandro	Chema	Márquez	3747890703	Pasaje de Marc Izaguirre 269 Piso 9  Salamanca, 14280	307	25	170
984938276	Hipólito	\N	Zamorano	3295604817	Cañada Dafne Mercader 468 Piso 3  Valladolid, 04407	318	50	170
991193856	Azucena	\N	Rojas	3550690251	Camino Isidora Ureña 395 Apt. 22  Melilla, 96904	867	68	170
969935120	Sandalio	José Ángel	Ortiz	3174836093	Alameda Estela Cuadrado 69 Almería, 13202	68	23	170
939259390	Jenaro	\N	Torrens	3845529395	Vial de Anselmo Expósito 901 Piso 3  León, 40061	399	52	170
913766814	Carmen	Iker	Carretero	3506261329	Paseo Úrsula Serra 988 Lleida, 25047	245	47	170
918626192	Urbano	Etelvina	Garrido	3311259306	Ronda Pía Zamora 353 Castellón, 70687	300	85	170
927161285	Dionisio	\N	Sobrino	3159691150	C. de Ainara Roca 77 Ávila, 47718	780	19	170
929391363	Araceli	\N	Abascal	3278124614	Vial de Teodoro Navas 3 Ourense, 11978	755	68	170
968466014	Jose Francisco	Ariadna	Moles	3191145619	Glorieta Teobaldo Marco 97 Puerta 1  Asturias, 35189	646	15	170
991951975	Nazaret	Julián	Benito	3355010525	Via de Adelia Luís 58 Baleares, 43856	483	25	170
927142547	Ramón	\N	Zurita	3624660324	Cuesta Ambrosio Vives 89 Puerta 6  Vizcaya, 75772	41	76	170
910212559	Salomón	\N	Barrios	3508787031	Acceso de Manuel Correa 3 Ceuta, 46578	508	70	170
995891688	Duilio	Aurelia	Guzman	3645367218	Urbanización Cleto Plaza 36 Piso 9  Ceuta, 84657	400	76	170
976330722	Narcisa	Chus	Casanovas	3664529119	Pasadizo Candelario Mulet 10 Puerta 9  Zamora, 24802	660	41	170
949264025	Rosaura	Benito	Landa	3655675721	Glorieta de Pepita Aranda 633 Zamora, 47964	124	73	170
939609070	Ariel	\N	Comas	3812822216	Alameda Edelmira Parra 3 Apt. 74  Salamanca, 88414	606	8	170
990466736	Ainoa	Porfirio	Machado	3379644455	Plaza de Piedad Calderón 18 Badajoz, 63506	678	23	170
988046893	Gilberto	Elvira	Nuñez	3284387117	Plaza Germán Aragonés 32 Valencia, 25422	317	52	170
955994403	Herminia	\N	Zapata	3855822215	Via de Mauricio Arroyo 368 Piso 6  Guadalajara, 42550	354	52	170
900563862	Manola	\N	Sanz	3215589520	Ronda Silvestre Múñiz 66 Lugo, 34046	91	5	170
963941300	Teodora	Dionisia	Cabrera	3845405940	Callejón Clotilde Cañizares 7 Piso 6  Ciudad, 85654	568	86	170
915761700	Sebastian	\N	Muro	3829240650	Pasaje de Duilio Tamayo 22 Madrid, 71290	90	15	170
931586058	Juan Bautista	Amancio	Chaves	3339668790	Plaza Cornelio Delgado 575 Puerta 2  Segovia, 18086	500	68	170
924157888	Obdulia	Germán	Gual	3345623243	Acceso de Plinio Amo 26 La Coruña, 98315	759	15	170
902553445	Ignacia	\N	Sosa	3695881814	Pasaje Anita Asensio 2 Apt. 13  Pontevedra, 70583	436	8	170
940184878	Fidel	Alexandra	Benavent	3177705524	Alameda Anselmo Borrego 24 Guipúzcoa, 50720	660	54	170
944727444	Teobaldo	Perla	Patiño	3838113755	Avenida de Priscila Torrent 678 Huelva, 97904	388	17	170
960375764	Jose Ramón	Plácido	Galván	3624776948	Camino Camilo Gallo 86 Piso 2  Asturias, 29761	670	5	170
918584815	Ceferino	Mercedes	Azcona	3975467679	Urbanización Victor Valenzuela 1 Piso 5  Zamora, 20001	181	25	170
994718497	Fito	\N	Gomis	3247212997	Calle Olivia Alcolea 66 Cádiz, 01036	353	5	170
903693253	Hipólito	María Belén	Giralt	3199928046	Callejón Julie Jiménez 3 Apt. 48  Barcelona, 14034	594	63	170
959826784	Anabel	Paloma	Cabo	3842991713	Ronda de Florentina Grau 21 Apt. 71  Cuenca, 92925	686	5	170
989210522	Diego	\N	Murcia	3267241692	Vial Sebastian Baena 16 Huesca, 75693	206	5	170
916501846	Gracia	\N	Leal	3807331994	Ronda de Esther Lozano 73 Piso 7  Ceuta, 20189	385	54	170
957169455	Quique	Felix	Vallejo	3755994214	Camino Aureliano Bauzà 8 Tarragona, 74414	324	68	170
916544297	Vinicio	\N	Pinedo	3527099809	Paseo de Cecilio Castelló 60 Apt. 63  León, 03510	40	25	170
991598755	Gonzalo	Edmundo	Borrás	3911336495	Pasadizo Adora Téllez 31 Valencia, 12859	405	52	170
904452207	Fidela	\N	Álamo	3820764110	Cuesta Irma Belda 6 Piso 1  Álava, 45138	350	50	170
933929756	Eliana	\N	Arregui	3625796727	Plaza de Pablo Peiró 97 Puerta 6  La Rioja, 26914	320	52	170
923705454	Tamara	Javi	Ojeda	3984023986	Callejón Adelina Pablo 48 Puerta 0  Palencia, 59599	396	41	170
972932018	Benita	\N	Vargas	3936844350	Paseo Maricruz Niño 43 Cáceres, 05305	576	5	170
991422935	Soledad	Adelia	Roca	3116653888	Calle Sandra Losada 9 Jaén, 82782	558	8	170
935115286	Anna	Clarisa	Tomé	3727955714	Alameda de Marcela Pablo 87 Apt. 95  Zaragoza, 63636	178	20	170
935388688	Natanael	Adela	Garcia	3124590970	Glorieta de María Dolores Gálvez 48 Piso 9  Vizcaya, 54749	475	5	170
931358451	Valentina	Belen	Abella	3528021704	Rambla Juan Carlos Arana 86 Huesca, 72207	65	81	170
991981320	Santos	Zaira	Madrid	3661704917	Cañada de Remedios Querol 596 León, 82482	354	52	170
982192303	Rosaura	Eliseo	Pino	3969662612	Vial Victor Solera 5 Jaén, 39668	1	15	170
942989617	María Ángeles	Saturnina	Cid	3819210538	Pasaje Maximiliano Montaña 16 Málaga, 78006	380	5	170
986362733	Benito	Máximo	Pujol	3149439066	Alameda Lourdes Morera 5 Cáceres, 17585	683	52	170
928175879	Juan Antonio	Santos	Amigó	3339505979	Alameda Marita Pareja 57 Puerta 6  Palencia, 15132	809	19	170
946123979	Encarna	Marisol	Ripoll	3113100282	Camino de Aurelio Cabeza 12 Granada, 94819	518	25	170
917354828	Fabio	Judith	Jaén	3861063949	C. de Javier Merino 69 Murcia, 47631	600	27	170
900766760	Emiliano	\N	Catalán	3937958643	Cañada Joaquina Céspedes 872 Valladolid, 86725	646	15	170
941328782	Samu	Xavier	Clemente	3527485864	Pasaje de Chita Borrego 68 Vizcaya, 07950	254	52	170
902239713	Fabio	Guadalupe	Carrasco	3335707542	Glorieta de María Cristina Montes 96 Puerta 1  Vizcaya, 74571	47	15	170
918365303	Yolanda	Ester	Baquero	3880814334	Paseo de Eugenio Lastra 18 León, 58718	548	63	170
986441486	Mohamed	Nereida	Carballo	3435817077	Plaza Ruperto Sureda 816 Alicante, 45423	318	5	170
925773102	Carmelo	\N	Valenciano	3123030626	Paseo de Amado Alegre 4 Piso 3  Santa Cruz de Tenerife, 75328	114	15	170
971186911	Pancho	\N	Catalá	3684505932	Ronda de Dani Ocaña 5 Puerta 1  La Rioja, 92547	520	73	170
965112452	Wálter	\N	Alberola	3237695926	Plaza Xavier Castelló 6 Valencia, 90595	59	5	170
952353038	Chucho	Sandra	Pizarro	3794158718	Cañada Palmira Antón 590 Piso 4  Córdoba, 73773	349	73	170
953933579	Matías	\N	Girona	3344961508	Ronda de Azeneth Anglada 24 Álava, 46554	224	25	170
957109591	Angélica	Cruz	Vicens	3986080100	Calle Reynaldo Tolosa 33 Piso 9  Cádiz, 32513	692	47	170
968027409	Beatriz	\N	Solé	3587831435	Glorieta Azucena Laguna 4 La Coruña, 48712	839	25	170
971701932	Chelo	Jordán	Guillén	3807936083	Rambla de Chucho Murcia 11 Tarragona, 33002	417	23	170
936206354	Felix	Ema	Cárdenas	3139438639	C. Sergio Gimenez 23 Piso 3  Salamanca, 75006	2	11	170
931768866	Mariano	Marcos	Jódar	3397636896	Cañada Cayetana Zurita 62 Puerta 9  La Rioja, 79848	152	68	170
987764057	Bautista	\N	Alcalá	3522425507	Cañada Ester Miguel 4 La Coruña, 23586	513	19	170
979769442	Amando	\N	Ayuso	3300015002	Callejón de Nerea Rosell 77 Apt. 26  Cuenca, 80913	646	15	170
920165211	Carlos	\N	Quevedo	3806498930	Via de Ruth Gutierrez 33 Apt. 92  Asturias, 62311	755	68	170
996140074	Aurelio	Quirino	Alberdi	3609080733	Alameda Sabas Losada 20 Puerta 0  La Coruña, 77183	874	44	170
938374077	Alejo	\N	Franch	3560173604	Rambla Demetrio Baeza 75 León, 00872	822	15	170
930668323	Dorotea	Matilde	Amores	3288839373	Cañada Marina Solé 16 Puerta 4  Ciudad, 94206	419	23	170
990795516	Jose Carlos	\N	Esteve	3358298246	Acceso Teobaldo Andreu 4 Apt. 97  La Rioja, 17265	658	5	170
903510402	Coral	Miguela	Reyes	3703966487	Rambla Lázaro Jove 73 Huesca, 08230	570	47	170
963920453	Ileana	Amor	Pareja	3941419654	Vial de Gabriel Codina 17 Piso 9  Asturias, 52671	667	5	170
903348654	Lina	\N	Lobato	3435572455	Cuesta Gabriela Bejarano 33 Teruel, 94362	887	94	170
905926078	Octavia	\N	Ferrández	3445370743	Cañada de Esmeralda Peiró 6 Madrid, 10544	480	5	170
913024940	Nicanor	Montserrat	Bayón	3841391318	Via Josué Carreras 96 La Rioja, 00247	25	95	170
934675068	Miriam	Francisco	Zaragoza	3836241162	Cuesta Teófila Navas 98 Puerta 2  Alicante, 56729	250	52	170
957655613	Victor Manuel	Porfirio	Barriga	3853549127	Via Fanny Peralta 27 Apt. 80  Asturias, 54456	51	68	170
959758759	Francisco	Raúl	Vives	3279777944	Cuesta María Del Carmen Borja 6 Teruel, 18498	147	76	170
940258247	Dominga	\N	Morán	3657077913	Camino de Maricruz Pinto 24 León, 42853	410	18	170
991155642	Rosalinda	Amalia	Montesinos	3953400364	C. Violeta Terrón 84 Las Palmas, 77129	306	41	170
963159335	Angelino	\N	Gisbert	3981691509	Urbanización Eliana Luís 57 Pontevedra, 13587	132	41	170
936330219	Donato	Susanita	Mulet	3928792180	Cuesta de Mohamed Rubio 2 Baleares, 07621	308	5	170
950830080	Guiomar	\N	Ribes	3662070161	Cañada de Juanito Oliva 544 Apt. 02  Barcelona, 25719	287	50	170
944104963	Eustaquio	\N	Maza	3994359765	Acceso de Luciano Andrade 5 Apt. 42  Burgos, 71063	524	17	170
928827095	Francisco Jose	\N	Isern	3494520844	Camino Faustino Castillo 75 Ciudad, 95489	759	15	170
963309805	Amada	Américo	Mendizábal	3439696150	Cañada de Lucas Juliá 10 Puerta 4  Jaén, 19881	245	68	170
930068648	Estela	\N	León	3484886819	Paseo de Fermín Ferreras 3 Piso 3  Barcelona, 18450	425	15	170
989250746	Adrián	\N	Valenzuela	3229110289	Acceso Feliciana Sola 3 Soria, 08540	736	81	170
953290350	Reyes	\N	Cardona	3654434807	Camino de Vidal Adán 31 Piso 6  Cáceres, 77044	596	25	170
905545422	Rosaura	Marta	Bolaños	3252220845	Camino de Liliana Sales 94 Santa Cruz de Tenerife, 15861	283	73	170
911817746	Carmina	\N	Cepeda	3426360645	Via Ruy Alberdi 2 Piso 9  Lugo, 76861	550	15	170
958511705	Nazaret	\N	Abella	3920162873	Acceso de Irma Matas 90 Zaragoza, 13920	518	54	170
938852310	Álvaro	\N	Amador	3877036757	Callejón Nayara Torres 8 Teruel, 43791	15	11	170
956274071	Rogelio	Bartolomé	Estrada	3499743770	Paseo Samuel Rico 62 Valencia, 04323	275	76	170
982264346	Remedios	Miguel Ángel	Araujo	3309138518	Urbanización de Julieta Bolaños 89 Apt. 09  Salamanca, 72330	800	54	170
959696470	Amor	\N	Agudo	3534207367	Urbanización Sancho Uriarte 34 Apt. 61  Sevilla, 56741	777	25	170
915678834	Ciríaco	Rogelio	Vila	3905816393	Paseo Morena Adán 279 Piso 5  Ceuta, 13235	770	8	170
975438119	Benito	Salud	Arco	3252353573	Calle de Porfirio Marín 51 Puerta 5  Ciudad, 13649	122	76	170
999464622	Eutropio	Charo	Cerezo	3319752103	Alameda de Sarita Aroca 517 Cáceres, 72098	550	15	170
994398361	Lola	\N	Jimenez	3424128521	Pasaje de Feliciano Quintana 1 Vizcaya, 06770	680	54	170
982140570	Bruno	Enrique	Zamora	3538275558	Cañada de Morena Duarte 479 Las Palmas, 88970	491	27	170
984876790	Rosa	Primitiva	Melero	3540485714	Glorieta Edelmiro Frutos 69 Córdoba, 17902	466	15	170
995064798	Jose Miguel	José Ángel	Gallo	3188033252	Rambla de Emilio Castillo 587 Puerta 1  Soria, 66946	324	25	170
998402351	Hernando	América	Guillén	3906164353	Callejón de Domitila Valencia 933 Santa Cruz de Tenerife, 16961	430	27	170
943728057	José Luis	\N	Vaquero	3178717809	Pasaje Juan Manuel Lago 1 Piso 4  La Rioja, 79141	205	18	170
974431518	Cristian	\N	Falcó	3497368659	C. Salud Díez 396 Salamanca, 44435	530	41	170
966936386	Vinicio	Lucio	Piquer	3936919265	C. de Nélida Castejón 62 Álava, 95977	288	25	170
924412471	Mariana	\N	Blasco	3914791136	Cuesta Rocío Viña 444 Zamora, 24167	799	25	170
985290845	Leocadio	Loida	Rosado	3915964441	Ronda Regina Tomás 5 Pontevedra, 15955	87	15	170
902120071	Luis Ángel	Ignacio	Valero	3256702242	Cañada Manu Llanos 31 Las Palmas, 32273	287	52	170
971877209	Eleuterio	\N	Yuste	3390138021	Vial de Marcelo Céspedes 37 Apt. 79  Melilla, 60241	361	27	170
919273976	Edelmira	Amanda	Bejarano	3684569564	C. Reynaldo Pujadas 55 Puerta 5  Barcelona, 30030	572	68	170
975935778	Susana	\N	Riquelme	3624208750	Pasadizo Juan Francisco Alberola 170 Salamanca, 68992	86	5	170
935982874	Ágata	Nicolasa	Ferrero	3958831972	Pasaje Jose Manuel Peral 15 Soria, 56469	665	5	170
968908498	Carmen	\N	Villegas	3296199932	Calle Dorita Nebot 57 Puerta 0  Girona, 35624	268	47	170
922378905	Bernardita	Adalberto	Aramburu	3355528340	Alameda de Alicia Ugarte 29 Córdoba, 79543	832	15	170
975009513	Merche	\N	Torrent	3740994701	C. de Timoteo Rivero 98 Albacete, 67931	612	52	170
975300584	Gertrudis	\N	Pizarro	3495078273	Acceso de Lidia Luque 4 Ávila, 71205	150	18	170
983683515	Clímaco	Heriberto	Gutiérrez	3680032491	Cuesta Osvaldo Segarra 97 Murcia, 98117	223	15	170
910690647	Sebastian	Cosme	Roldan	3746020584	Camino de Guillermo Muñoz 62 Almería, 48518	893	5	170
917241552	Leonardo	\N	Villar	3200890396	Glorieta de Delia Azcona 6 Navarra, 93901	35	25	170
960744527	Pedro	\N	Guillen	3345322563	Calle Rodolfo Noguera 15 Granada, 19140	109	54	170
902077958	Feliciano	Anunciación	Lozano	3700700575	Alameda de Tere Agustí 76 Apt. 15  Guadalajara, 24812	400	20	170
973234138	Rafaela	Eufemia	Aguado	3303629819	Alameda de Encarnacion Barragán 5 Navarra, 70918	1	17	170
924699486	Alfredo	Cayetano	Millán	3325483345	Cuesta de Lina Moreno 28 Valencia, 13180	245	27	170
923477540	Noemí	Francisco Jose	Estevez	3375470190	Pasadizo Albino Montserrat 2 Granada, 01031	780	13	170
919485837	Borja	\N	Fabra	3183318668	Paseo Febe Carballo 102 Almería, 00211	773	99	170
958708255	Artemio	Cristina	Ros	3992607289	Urbanización de Epifanio Gomila 444 Apt. 37  Albacete, 52841	282	5	170
957591519	Xavier	Reyes	Olivé	3800279849	Glorieta América Marin 40 Apt. 16  Barcelona, 40563	432	68	170
955903170	Victor	\N	Morell	3142118972	Alameda de Roque Sanmiguel 876 Valladolid, 04822	530	25	170
978119331	Verónica	Eustaquio	Cuéllar	3462656166	Callejón Manuela Gascón 9 Pontevedra, 80469	355	19	170
966922224	Teófila	\N	Escamilla	3545415964	Paseo Jafet Adadia 20 Piso 1  Cuenca, 39062	313	54	170
910057604	Natalio	Nélida	Crespo	3455826273	Via de Casandra Valentín 48 Piso 4  Cuenca, 80389	135	27	170
916326030	Áurea	\N	Arnal	3700818977	Glorieta de Rubén Guzman 38 Valencia, 64517	616	17	170
936414648	Belén	Jaime	Redondo	3578265460	Urbanización Victoriano Izaguirre 815 Murcia, 04933	480	54	170
942379164	Rosenda	Isidro	Benavent	3973742707	Callejón de Joaquina Bernat 14 Apt. 90  Palencia, 39585	740	15	170
906526791	Modesta	Felipe	Bello	3822068906	Acceso de Fortunato Sanz 85 León, 43277	78	8	170
950664171	Julie	Gala	Lamas	3147664795	C. de Ciriaco Jordán 82 Ourense, 15145	548	41	170
977294179	Régulo	Bárbara	Riba	3308195747	Alameda Julio César Arcos 10 Apt. 74  Huelva, 83301	295	20	170
962984201	Benita	Malena	Requena	3350942403	Pasadizo Marino Albero 783 Huelva, 80435	161	47	170
978697781	Ana Belén	\N	Pinedo	3601777611	Acceso de Encarnación Egea 31 Córdoba, 70089	814	15	170
967741942	Luis Miguel	Toribio	Bautista	3297406999	Avenida de Natividad Vallejo 2 Apt. 45  Cuenca, 42116	785	25	170
949009403	Samu	\N	Casares	3789492187	Avenida de Cruz Franco 752 Granada, 63798	12	11	170
911735316	Eli	\N	Pedrosa	3452907785	Pasadizo Lina Montes 96 Puerta 0  Jaén, 44876	705	68	170
929492802	Luz	Heraclio	Castrillo	3129519377	Pasaje de Cecilia Catalán 2 Jaén, 32256	330	50	170
922681493	Paco	\N	Villalobos	3361555840	Urbanización Chita Gomis 95 Piso 6  Toledo, 82981	418	19	170
931272344	Ileana	\N	Pujadas	3290954441	Cuesta de Lupe Vidal 9 Puerta 8  Almería, 19599	761	15	170
974228742	Leonor	\N	Amaya	3726744809	Plaza Victoria Neira 98 Álava, 13857	244	41	170
914276972	Sol	\N	Lago	3122719243	Cuesta María Teresa Ripoll 80 Piso 7  Cuenca, 20276	461	73	170
990971135	Pelayo	\N	Madrigal	3336124552	Ronda Cintia Espejo 420 Almería, 46139	410	85	170
914776620	Mónica	Ramona	Nebot	3147312133	Pasaje Leonor Aguado 33 Ciudad, 32017	861	15	170
984272643	Maristela	Rolando	Bonilla	3468674405	Plaza Adelia Rivas 28 Girona, 71440	385	52	170
985384437	Pedro	\N	Casal	3139512931	Cañada Cintia Buendía 17 Apt. 65  Guipúzcoa, 26962	571	86	170
964211171	Crescencia	Ana Belén	Bertrán	3497762143	Urbanización Benigna Ortiz 22 Piso 5  Toledo, 64090	809	19	170
965916736	Maura	Sergio	Zurita	3291796589	Avenida de Paloma Doménech 82 Puerta 3  Ávila, 12624	533	15	170
902151417	Elisa	\N	Cerezo	3320791934	Pasadizo de Carlito Luque 51 Cantabria, 91600	865	86	170
913319978	Leyre	\N	Ibarra	3381195376	Camino de Dolores Arregui 50 Piso 0  Girona, 55484	675	73	170
977938238	Faustino	Román	Pintor	3960743381	Pasadizo de Valerio Mate 725 Puerta 5  Pontevedra, 73640	209	5	170
910048993	Ricarda	\N	Acedo	3984582988	Paseo de Melchor Ariza 20 Salamanca, 63622	606	50	170
992094031	Gloria	\N	Quintana	3116213446	Via Lucas Marco 12 Piso 9  Ciudad, 92602	672	23	170
967446689	Bruno	\N	Marí	3312354089	Acceso de Noé Ruiz 9 Guipúzcoa, 17699	755	15	170
942447858	Rocío	\N	Somoza	3612476969	Avenida de Clotilde Garay 79 Zamora, 03764	402	25	170
988181574	Arcelia	Luciano	Carnero	3445537750	Alameda de Paulino Bermúdez 83 Apt. 73  Almería, 37811	271	68	170
908711076	Itziar	\N	Aranda	3538471577	Cañada Juan Pablo Lobo 50 Segovia, 54591	520	76	170
911517507	Damián	\N	Segarra	3613229804	Acceso Mayte Llopis 41 Apt. 87  Guadalajara, 23069	51	68	170
966019594	Nieves	\N	Álamo	3448031956	Camino Eusebio Canals 37 Huelva, 30955	723	15	170
901838563	Luis Ángel	Yéssica	Quirós	3411204360	Camino Claudia Rebollo 88 Apt. 82  Burgos, 79720	785	18	170
983085468	Ariel	Eloy	Sobrino	3685268089	Callejón Jimena Calatayud 914 Piso 5  Cantabria, 39725	247	18	170
970743241	Clarisa	Eliana	Neira	3869138389	Rambla de Eugenia Murillo 8 Valladolid, 89500	318	5	170
939030294	Luciano	Reinaldo	Blanch	3693100842	Alameda de Seve Lopez 98 Albacete, 46525	290	19	170
916730085	Encarnacion	\N	Gallart	3336550204	Acceso de Victorino Zabaleta 119 Apt. 77  Tarragona, 76014	42	5	170
979851882	Rolando	\N	Campo	3414503890	Acceso de Carlos Gallardo 6 Apt. 27  Vizcaya, 17480	290	19	170
959293343	Jose Miguel	\N	Santamaría	3225612461	Calle Severiano Mercader 28 Salamanca, 16627	491	15	170
908457302	Débora	\N	Tirado	3329246815	Pasadizo de Etelvina Lobo 83 Córdoba, 64134	780	68	170
979575602	Merche	Mauricio	Luís	3641037148	Ronda de Ximena Coloma 1 Córdoba, 54624	1	88	170
948318504	Roldán	Itziar	Iñiguez	3596708687	Plaza María Ángeles Paredes 51 Apt. 33  Zaragoza, 24846	867	68	170
940402188	Jose Ignacio	\N	Berenguer	3776319439	Camino de Melisa Mulet 4 Apt. 67  Castellón, 08150	38	5	170
917275173	Jessica	\N	Larrea	3460594467	Ronda Ramona Ballesteros 486 Puerta 8  Burgos, 22028	685	8	170
973311354	Carlito	\N	Izquierdo	3594601633	Callejón Nerea Haro 11 Lugo, 51307	36	76	170
991467213	Inmaculada	\N	Tapia	3289727158	Pasaje de Juan Guillén 3 Piso 4  La Rioja, 74120	126	76	170
922697487	Nélida	\N	Machado	3622343991	Cañada de Adora Moliner 338 Puerta 2  Jaén, 38884	390	52	170
928046416	Vera	\N	López	3782164163	Alameda de Juan Luis Blázquez 144 Apt. 35  Lugo, 75209	250	85	170
901780514	Dani	\N	Mas	3415686702	Avenida de Silvia Balaguer 94 Piso 8  Soria, 05404	1	66	170
972136293	Ruben	\N	Sierra	3431813406	Acceso de Diego Company 31 Apt. 22  Melilla, 30056	214	25	170
971747674	Ezequiel	Amado	Gárate	3206694152	Cañada de Leonardo Lamas 93 Apt. 81  La Rioja, 57167	541	47	170
\.


                                                                                                                                                                                                                                                                                      restore.sql                                                                                         0000600 0004000 0002000 00000103000 15015340177 0015361 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
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
    CONSTRAINT ck_discount_logic CHECK (((((discount_type)::text = 'FIXED'::text) AND (discount_value > (0)::numeric) AND (disccount = (0)::numeric)) OR (((discount_type)::text = 'PERCENT'::text) AND (disccount > (0)::numeric) AND (discount_value = (0)::numeric)))),
    CONSTRAINT ck_discount_range CHECK (((disccount >= (0)::numeric) AND (disccount <= (100)::numeric))),
    CONSTRAINT ck_finish_date CHECK ((finish_date >= start_date)),
    CONSTRAINT ck_pmn_state CHECK (((state)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'paused'::character varying])::text[]))),
    CONSTRAINT ck_promotion_discount_logic CHECK (((((discount_type)::text = 'PERCENT'::text) AND (disccount IS NOT NULL) AND (discount_value IS NULL)) OR (((discount_type)::text = 'FIXED'::text) AND (discount_value IS NOT NULL) AND (disccount IS NULL)))),
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
    employee_number integer,
    CONSTRAINT ck_employee_number CHECK (((((type_worker)::text = 'MANAGER'::text) AND (employee_number IS NOT NULL)) OR (((type_worker)::text = 'EMPLOYEE'::text) AND (employee_number IS NULL)))),
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
COPY tienda.cities (cyy_id, name, dpt_id, cty_id) FROM '$$PATH$$/5010.dat';

--
-- Data for Name: countries; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.countries (cty_id, name) FROM stdin;
\.
COPY tienda.countries (cty_id, name) FROM '$$PATH$$/5008.dat';

--
-- Data for Name: customers; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.customers (document, first_name, middle_name, last_name, middle_last_name, phone_number, address) FROM stdin;
\.
COPY tienda.customers (document, first_name, middle_name, last_name, middle_last_name, phone_number, address) FROM '$$PATH$$/5007.dat';

--
-- Data for Name: departaments; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.departaments (dpt_id, name, cty_id) FROM stdin;
\.
COPY tienda.departaments (dpt_id, name, cty_id) FROM '$$PATH$$/5009.dat';

--
-- Data for Name: detail_orders; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.detail_orders (odr_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal, discount_value) FROM stdin;
\.
COPY tienda.detail_orders (odr_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal, discount_value) FROM '$$PATH$$/5027.dat';

--
-- Data for Name: detail_purchases; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.detail_purchases (prc_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal) FROM stdin;
\.
COPY tienda.detail_purchases (prc_id, line_item_id, ctg_pdt_id, pdt_id, quantity, unit_price, subtotal) FROM '$$PATH$$/5024.dat';

--
-- Data for Name: orders; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.orders (odr_id, order_date, total, document, stf_id, description, discount_value) FROM stdin;
\.
COPY tienda.orders (odr_id, order_date, total, document, stf_id, description, discount_value) FROM '$$PATH$$/5026.dat';

--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.product_categories (pdt_ctg_id, name, description) FROM stdin;
\.
COPY tienda.product_categories (pdt_ctg_id, name, description) FROM '$$PATH$$/5015.dat';

--
-- Data for Name: product_lot; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.product_lot (pdt_lot_id, expiration_date) FROM stdin;
\.
COPY tienda.product_lot (pdt_lot_id, expiration_date) FROM '$$PATH$$/5013.dat';

--
-- Data for Name: products; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.products (pdt_id, name, description, unit_price, stock, pdt_ctg_id, lot_pdt_id, pmn_id, ssn_id) FROM stdin;
\.
COPY tienda.products (pdt_id, name, description, unit_price, stock, pdt_ctg_id, lot_pdt_id, pmn_id, ssn_id) FROM '$$PATH$$/5021.dat';

--
-- Data for Name: promotions; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.promotions (pmn_id, start_date, finish_date, disccount, discount_value, state, discount_type) FROM stdin;
\.
COPY tienda.promotions (pmn_id, start_date, finish_date, disccount, discount_value, state, discount_type) FROM '$$PATH$$/5017.dat';

--
-- Data for Name: purchases; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.purchases (prc_id, purchase_date, total, nit, stf_id, description) FROM stdin;
\.
COPY tienda.purchases (prc_id, purchase_date, total, nit, stf_id, description) FROM '$$PATH$$/5023.dat';

--
-- Data for Name: seasons; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.seasons (ssn_id, name, start_date, finish_date) FROM stdin;
\.
COPY tienda.seasons (ssn_id, name, start_date, finish_date) FROM '$$PATH$$/5019.dat';

--
-- Data for Name: staff; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.staff (stf_id, first_name, middle_name, last_name, middle_last_name, phone_number, address, salary, mgr_id, type_worker, employee_number) FROM stdin;
\.
COPY tienda.staff (stf_id, first_name, middle_name, last_name, middle_last_name, phone_number, address, salary, mgr_id, type_worker, employee_number) FROM '$$PATH$$/5012.dat';

--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: tienda; Owner: postgres
--

COPY tienda.suppliers (nit, first_name, middle_name, last_name, phone_number, address, cyy_id, dpt_id, cty_id) FROM stdin;
\.
COPY tienda.suppliers (nit, first_name, middle_name, last_name, phone_number, address, cyy_id, dpt_id, cty_id) FROM '$$PATH$$/5011.dat';

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

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                