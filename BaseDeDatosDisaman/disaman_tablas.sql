-- TABLA CUSTOMERS (CTR)
CREATE TABLE TIENDA.CUSTOMERS (
    document VARCHAR(15),
    first_name VARCHAR(50),
    middle_name VARCHAR(50),
    last_name VARCHAR(50),
    middle_last_name VARCHAR(50),
    phone_number VARCHAR(15),
    address VARCHAR(100),
    
    -- Restricciones
    CONSTRAINT PK_CUSTOMERS PRIMARY KEY (document),
    CONSTRAINT UK_CUSTOMERS_PHONE UNIQUE (phone_number),
    
    -- Restricciones NOT NULL (NN) mediante CHECK
    CONSTRAINT NN_CUSTOMERS_ID CHECK (document IS NOT NULL),
    CONSTRAINT NN_CUSTOMERS_FIRST_NAME CHECK (First_name IS NOT NULL),
    CONSTRAINT NN_CUSTOMERS_LAST_NAME CHECK (last_name IS NOT NULL),
    CONSTRAINT NN_CUSTOMERS_MIDDLE_LAST_NAME CHECK (middle_last_name IS NOT NULL),
    CONSTRAINT NN_CUSTOMERS_PHONE CHECK (phone_number IS NOT NULL),
    CONSTRAINT NN_CUSTOMERS_ADDRESS CHECK (address IS NOT NULL)
);

-- TABLA SUPPLIERS (SPR)
CREATE TABLE TIENDA.SUPPLIERS (
    nit VARCHAR(15),
    First_name VARCHAR(50),
    middle_name VARCHAR(50),
    last_name VARCHAR(50),
    phone_number VARCHAR(15),
    address VARCHAR(100),
    cyy_id VARCHAR(3),
    dpt_id VARCHAR(3),
    cty_id VARCHAR(3),
    
    -- Restricciones
    CONSTRAINT PK_SUPPLIERS PRIMARY KEY (nit),
    CONSTRAINT UK_SUPPLIERS_PHONE UNIQUE (phone_number),
    
    -- Claves foráneas
    CONSTRAINT FK_SUPPLIERS_CITY 
        FOREIGN KEY (cyy_id,dpt_id,cty_id) REFERENCES TIENDA.CITIES(cyy_id,dpt_id,cty_id),
    CONSTRAINT FK_SUPPLIERS_DPT 
        FOREIGN KEY (dpt_id,cty_id) REFERENCES TIENDA.DEPARTAMENTS(dpt_id,cty_id),
    CONSTRAINT FK_SUPPLIERS_COUNTRY 
        FOREIGN KEY (cty_id) REFERENCES TIENDA.COUNTRIES(cty_id),
    
    -- Checks NOT NULL (NN)
    CONSTRAINT NN_SUPPLIERS_NIT CHECK (nit IS NOT NULL),
    CONSTRAINT NN_SUPPLIERS_FIRST_NAME CHECK (First_name IS NOT NULL),
    CONSTRAINT NN_SUPPLIERS_LAST_NAME CHECK (last_name IS NOT NULL),
    CONSTRAINT NN_SUPPLIERS_PHONE CHECK (phone_number IS NOT NULL),
    CONSTRAINT NN_SUPPLIERS_ADDRESS CHECK (address IS NOT NULL),
    CONSTRAINT NN_SUPPLIERS_CITY CHECK (cyy_id IS NOT NULL),
    CONSTRAINT NN_SUPPLIERS_DPT CHECK (dpt_id IS NOT NULL),
    CONSTRAINT NN_SUPPLIERS_COUNTRY CHECK (cty_id IS NOT NULL)
);

-- TABLA CITIES (CYY)
CREATE TABLE TIENDA.CITIES (
    cyy_id VARCHAR(3),
    name VARCHAR(60),
    dpt_id VARCHAR(3),
    cty_id VARCHAR(3),
    
    -- Restricciones
    CONSTRAINT PK_CITIES PRIMARY KEY (cyy_id, dpt_id, cty_id), -- Clave primaria compuesta
    CONSTRAINT FK_CITIES_DPT FOREIGN KEY (dpt_id,cty_id) REFERENCES TIENDA.DEPARTAMENTS(dpt_id,cty_id),
    CONSTRAINT FK_CITIES_CTY FOREIGN KEY (cty_id) REFERENCES TIENDA.COUNTRIES(cty_id),
    
    -- Checks NOT NULL (NN)
    CONSTRAINT NN_CITIES_ID CHECK (cyy_id IS NOT NULL),
    CONSTRAINT NN_CITIES_NAME CHECK (name IS NOT NULL),
    CONSTRAINT NN_CITIES_DPT CHECK (dpt_id IS NOT NULL),
    CONSTRAINT NN_CITIES_CTY CHECK (cty_id IS NOT NULL)
);

-- TABLA DEPARTAMENTS (DPT)
CREATE TABLE TIENDA.DEPARTAMENTS (
    dpt_id VARCHAR(3),
    name VARCHAR(60),
    cty_id VARCHAR(3),
    
    -- Restricciones
    CONSTRAINT PK_DEPARTAMENTS PRIMARY KEY (dpt_id, cty_id), -- Clave primaria compuesta
    CONSTRAINT FK_DEPARTAMENTS_COUNTRY FOREIGN KEY (cty_id) REFERENCES TIENDA.COUNTRIES(cty_id),
    
    -- Checks NOT NULL (NN)
    CONSTRAINT NN_DEPARTAMENTS_ID CHECK (dpt_id IS NOT NULL),
    CONSTRAINT NN_DEPARTAMENTS_NAME CHECK (name IS NOT NULL),
    CONSTRAINT NN_DEPARTAMENTS_CTY CHECK (cty_id IS NOT NULL)
);

-- TABLA COUNTRIES (CTY)
CREATE TABLE TIENDA.COUNTRIES (
    cty_id VARCHAR(3),
    name VARCHAR(60),
    
    -- Restricciones
    CONSTRAINT PK_COUNTRIES PRIMARY KEY (cty_id),
    
    -- Checks NOT NULL (NN)
    CONSTRAINT NN_COUNTRIES_CTY_ID CHECK (cty_id IS NOT NULL),
    CONSTRAINT NN_COUNTRIES_NAME CHECK (name IS NOT NULL)
);

CREATE TABLE TIENDA.STAFF (
    stf_id VARCHAR(4),                      
    first_name VARCHAR(50),                
    middle_name VARCHAR(50),               
    last_name VARCHAR(50),                 
    middle_last_name VARCHAR(50),          
    phone_number VARCHAR(15),              
    address VARCHAR(100),                  
    salary NUMERIC(10),                    
    mgr_id VARCHAR(4),                     
    type_worker VARCHAR(50),               
    sales INTEGER,                         
    bonification NUMERIC(10),              
    employee_number INTEGER,               
    
    -- Restricciones
    CONSTRAINT PK_STAFF PRIMARY KEY (stf_id),
    CONSTRAINT UK_STAFF_PHONE UNIQUE (phone_number),
    CONSTRAINT FK_STAFF_MGR 
        FOREIGN KEY (mgr_id) REFERENCES TIENDA.STAFF(stf_id),
    
    -- Checks NOT NULL para columnas obligatorias
    CONSTRAINT NN_STAFF_ID CHECK (stf_id IS NOT NULL),
    CONSTRAINT NN_STAFF_FIRST_NAME CHECK (first_name IS NOT NULL),
    CONSTRAINT NN_STAFF_LAST_NAME CHECK (last_name IS NOT NULL),
    CONSTRAINT NN_STAFF_MIDDLE_LAST_NAME CHECK (middle_last_name IS NOT NULL),
    CONSTRAINT NN_STAFF_PHONE CHECK (phone_number IS NOT NULL),
    CONSTRAINT NN_STAFF_ADDRESS CHECK (address IS NOT NULL),
    CONSTRAINT NN_STAFF_SALARY CHECK (salary IS NOT NULL),
    CONSTRAINT NN_STAFF_TYPE_WORKER CHECK (type_worker IS NOT NULL),
    
    -- Solo MANAGER tienen employee_number
    CONSTRAINT CK_EMPLOYEE_NUMBER 
        CHECK (
            (type_worker = 'MANAGER' AND employee_number IS NOT NULL) OR 
            (type_worker = 'EMPLOYEE' AND employee_number IS NULL)
        ),

    -- Solo EMPLOYEE pueden tener ventas y bonificación
    CONSTRAINT CK_EMPLOYEE_SALES_BONUS
        CHECK (
            (type_worker = 'MANAGER' AND sales IS NULL AND bonification IS NULL) OR
            (type_worker = 'EMPLOYEE')
        )
);

-- TABLA PRODUCT_LOT (PDT_LOT)
CREATE TABLE TIENDA.PRODUCT_LOT (
    pdt_lot_id VARCHAR(4),
    expiration_date DATE,
    
    -- Restricciones
    CONSTRAINT PK_PDT_LOT PRIMARY KEY (pdt_lot_id),
    CONSTRAINT NN_PDT_LOT_ID CHECK (pdt_lot_id IS NOT NULL),
    CONSTRAINT NN_PDT_LOT_EXPIRATION CHECK (expiration_date IS NOT NULL)
);


-- TABLA PRODUCT_CATEGORIES (PDT_CTG)
CREATE TABLE TIENDA.PRODUCT_CATEGORIES (
    pdt_ctg_id SERIAL,                        -- Clave primaria autoincremental (SERIAL)
    name VARCHAR(50),                 -- Nombre de la categoría
    description VARCHAR(200),         -- Descripción opcional
    
    -- Restricciones
    CONSTRAINT PK_PDT_CTG PRIMARY KEY (pdt_ctg_id),
    CONSTRAINT NN_PDT_CTG_NAME CHECK (name IS NOT NULL)   -- Obligatorio
);

-- TABLA PROMOTIONS (PMN)
CREATE TABLE TIENDA.PROMOTIONS (
    pmn_id SERIAL,                     -- Clave primaria autoincremental
    start_date DATE,                   
    finish_date DATE,                  
    disccount NUMERIC(2),              -- Porcentaje de descuento (0-99)
    discount_value NUMERIC(10),        -- Valor monetario del descuento en COP
    state VARCHAR(15),                 -- Estado: 'active', 'inactive', 'paused'
    
    -- Restricciones
    CONSTRAINT PK_PROMOTIONS PRIMARY KEY (pmn_id),
    
    -- Checks NOT NULL para columnas obligatorias
    CONSTRAINT NN_PMN_ID CHECK (pmn_id IS NOT NULL),
    CONSTRAINT NN_PMN_START_DATE CHECK (start_date IS NOT NULL),
    CONSTRAINT NN_PMN_FINISH_DATE CHECK (finish_date IS NOT NULL),
    CONSTRAINT NN_PMN_DISCOUNT CHECK (disccount IS NOT NULL),
    CONSTRAINT NN_PMN_DISCOUNT_VALUE CHECK (discount_value IS NOT NULL),
    CONSTRAINT NN_PMN_STATE CHECK (state IS NOT NULL),
    
    -- Validación de fechas y valores
    CONSTRAINT CK_FINISH_DATE CHECK (finish_date >= start_date),
    CONSTRAINT CK_DISCOUNT_RANGE CHECK (disccount BETWEEN 0 AND 100), -- 0% a 100%
    CONSTRAINT CK_DISCOUNT_VALUE CHECK (discount_value > 0),
    CONSTRAINT CK_PMN_STATE CHECK (state IN ('active', 'inactive', 'paused'))
);

-- TABLA SEASONS (SSN)
CREATE TABLE TIENDA.SEASONS (
    ssn_id SERIAL,                      -- Clave primaria autoincremental
    name VARCHAR(50),                   -- Nombre de la temporada
    start_date DATE,                    -- Fecha de inicio
    finish_date DATE,                   -- Fecha de finalización
    
    -- Restricciones
    CONSTRAINT PK_SSN PRIMARY KEY (ssn_id),
    
    -- Checks NOT NULL para columnas obligatorias
    CONSTRAINT NN_SSN_ID CHECK (ssn_id IS NOT NULL),
    CONSTRAINT NN_SSN_NAME CHECK (name IS NOT NULL),
    CONSTRAINT NN_SSN_START_DATE CHECK (start_date IS NOT NULL),
    CONSTRAINT NN_SSN_FINISH_DATE CHECK (finish_date IS NOT NULL),
    
    -- Validación de fechas
    CONSTRAINT CK_SSN_DATE CHECK (finish_date >= start_date)
);

-- TABLA PRODUCTS (PDT)
CREATE TABLE TIENDA.PRODUCTS (
    pdt_id SERIAL,                        -- ID autoincremental (parte de la PK)
    name VARCHAR(50),                      
    description VARCHAR(200),              
    unit_price NUMERIC(10),               
    stock INTEGER,                        
    pdt_ctg_id INTEGER,                   -- FK a categoría (parte de la PK)
    lot_pdt_id VARCHAR(4),                 -- FK a lote
    pmn_id INTEGER,                       -- FK a promoción (opcional)
    ssn_id INTEGER,                       -- FK a temporada (opcional)
    
    -- Restricciones
    CONSTRAINT PK_PRODUCTS PRIMARY KEY (pdt_id, pdt_ctg_id), -- Clave primaria compuesta
    CONSTRAINT NN_PRODUCTS_NAME CHECK (name IS NOT NULL),
    CONSTRAINT NN_PRODUCTS_UNIT_PRICE CHECK (unit_price IS NOT NULL),
    CONSTRAINT NN_PRODUCTS_STOCK CHECK (stock IS NOT NULL),
    CONSTRAINT NN_PRODUCTS_CTG_ID CHECK (pdt_ctg_id IS NOT NULL),
    CONSTRAINT NN_PRODUCTS_LOT_ID CHECK (lot_pdt_id IS NOT NULL),
    
    -- Claves foráneas
    CONSTRAINT FK_PRODUCTS_CTG 
        FOREIGN KEY (pdt_ctg_id) REFERENCES TIENDA.PRODUCT_CATEGORIES(pdt_ctg_id),
    CONSTRAINT FK_PRODUCTS_LOT 
        FOREIGN KEY (lot_pdt_id) REFERENCES TIENDA.PRODUCT_LOT(pdt_lot_id),
    CONSTRAINT FK_PRODUCTS_PMN 
        FOREIGN KEY (pmn_id) REFERENCES TIENDA.PROMOTIONS(pmn_id),
    CONSTRAINT FK_PRODUCTS_SSN 
        FOREIGN KEY (ssn_id) REFERENCES TIENDA.SEASONS(ssn_id),
    
    -- Validaciones adicionales
    CONSTRAINT CK_STOCK_RANGE CHECK (stock BETWEEN 0 AND 999), -- Stock máximo 999
    CONSTRAINT CK_UNIT_PRICE CHECK (unit_price > 0) -- Precio positivo
);

-- TABLA PURCHASES (PRC)
CREATE TABLE TIENDA.PURCHASES (
    prc_id SERIAL,                      -- ID único de compra
    purchase_date DATE,                 -- Fecha de compra
    total NUMERIC(10),                  -- Total en COP
    nit VARCHAR(15),                    -- NIT del proveedor
    stf_id VARCHAR(4),                  -- ID del empleado (solo 'MG__')
    description VARCHAR(200),           -- Descripción opcional
    
    -- Restricciones
    CONSTRAINT PK_PURCHASES PRIMARY KEY (prc_id),
    
    -- Claves foráneas
    CONSTRAINT FK_PURCHASES_SUPPLIER 
        FOREIGN KEY (nit) REFERENCES TIENDA.SUPPLIERS(nit),
    CONSTRAINT FK_PURCHASES_STAFF 
        FOREIGN KEY (stf_id) REFERENCES TIENDA.STAFF(stf_id),
    
    -- Checks NOT NULL
    CONSTRAINT NN_PURCHASES_ID CHECK (prc_id IS NOT NULL),
    CONSTRAINT NN_PURCHASES_DATE CHECK (purchase_date IS NOT NULL),
    CONSTRAINT NN_PURCHASES_TOTAL CHECK (total IS NOT NULL),
    CONSTRAINT NN_PURCHASES_NIT CHECK (nit IS NOT NULL),
    CONSTRAINT NN_PURCHASES_STF CHECK (stf_id IS NOT NULL),
    
    -- Validación: stf_id debe comenzar con 'MG' (solo managers)
    CONSTRAINT CK_PURCHASES_STF 
        CHECK (stf_id ~ '^MG'),  -- Expresión regular para 'MG' seguido de 2 dígitos
    
    -- Validación de total positivo
    CONSTRAINT CK_PURCHASES_TOTAL 
        CHECK (total > 0)
);

-- TABLA DETAIL_PURCHASES (DTL_PRC)
CREATE TABLE TIENDA.DETAIL_PURCHASES (
    prc_id INT,                      -- FK a PURCHASES (parte de la PK)
    line_item_id INT,                -- Secuencial por prc_id (ej: 1,2,3... para cada prc_id)
    ctg_pdt_id INT,                  -- FK a PRODUCT_CATEGORIES
    pdt_id INT,                      -- FK a PRODUCTS (parte de la PK compuesta de PRODUCTS)
    quantity NUMERIC(10, 2),         -- Cantidad comprada
    unit_price NUMERIC(10, 2),       -- Precio unitario en COP
    subtotal NUMERIC(10, 2),         -- Subtotal calculado (quantity * unit_price)
    
    -- Restricciones
    CONSTRAINT PK_DTL_PRC PRIMARY KEY (prc_id, line_item_id),
    CONSTRAINT FK_DTL_PRC_PURCHASES 
        FOREIGN KEY (prc_id) REFERENCES TIENDA.PURCHASES(prc_id),
    CONSTRAINT FK_DTL_PRC_PRODUCT_CATEGORIES 
        FOREIGN KEY (ctg_pdt_id) REFERENCES TIENDA.PRODUCT_CATEGORIES(pdt_ctg_id),
    CONSTRAINT FK_DTL_PRC_PRODUCTS 
        FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES TIENDA.PRODUCTS(pdt_id, pdt_ctg_id),
    
    -- Checks NOT NULL (NN) usando el mismo estilo de tus tablas anteriores
    CONSTRAINT NN_DTL_PRC_PRC_ID CHECK (prc_id IS NOT NULL),
    CONSTRAINT NN_DTL_PRC_LINE_ITEM CHECK (line_item_id IS NOT NULL),
    CONSTRAINT NN_DTL_PRC_CTG_PDT CHECK (ctg_pdt_id IS NOT NULL),
    CONSTRAINT NN_DTL_PRC_PDT_ID CHECK (pdt_id IS NOT NULL),
    CONSTRAINT NN_DTL_PRC_QUANTITY CHECK (quantity IS NOT NULL),
    CONSTRAINT NN_DTL_PRC_UNIT_PRICE CHECK (unit_price IS NOT NULL),
    CONSTRAINT NN_DTL_PRC_SUBTOTAL CHECK (subtotal IS NOT NULL),
    
    -- Validaciones lógicas
    CONSTRAINT CK_DTL_PRC_QUANTITY CHECK (quantity > 0),
    CONSTRAINT CK_DTL_PRC_UNIT_PRICE CHECK (unit_price > 0),
    CONSTRAINT CK_DTL_PRC_SUBTOTAL CHECK (subtotal = quantity * unit_price)
);

-- TABLA ORDERS (ODR)
CREATE TABLE TIENDA.ORDERS (
    odr_id SERIAL,                       -- Clave primaria autoincremental
    order_date DATE,
    total NUMERIC(10, 2),
    document VARCHAR(15),
    stf_id VARCHAR(4),
    description VARCHAR(200),
    
    -- Restricciones
    CONSTRAINT PK_ODR PRIMARY KEY (odr_id),
    
    -- Claves foráneas
    CONSTRAINT FK_ODR_CUSTOMER 
        FOREIGN KEY (document) REFERENCES TIENDA.CUSTOMERS(document),
    CONSTRAINT FK_ODR_STAFF 
        FOREIGN KEY (stf_id) REFERENCES TIENDA.STAFF(stf_id),
    
    -- NOT NULL obligatorios
    CONSTRAINT NN_ODR_ORDER_DATE CHECK (order_date IS NOT NULL),
    CONSTRAINT NN_ODR_TOTAL CHECK (total IS NOT NULL),
    CONSTRAINT NN_ODR_DOCUMENT CHECK (document IS NOT NULL),
    CONSTRAINT NN_ODR_STF_ID CHECK (stf_id IS NOT NULL),
    
    -- Validación: Total positivo
    CONSTRAINT CK_ODR_TOTAL CHECK (total > 0),
    
    -- Validación: solo empleados pueden hacer ventas (ID debe comenzar con 'EP')
    CONSTRAINT CK_ODR_STAFF_EMPLOYEE CHECK (stf_id LIKE 'EP%')
);

-- TABLA DETAIL_ORDERS (DTL_ODR)
CREATE TABLE TIENDA.DETAIL_ORDERS (
    odr_id INT,                        -- FK a ORDERS (parte de la PK)
    line_item_id INT,                  -- Secuencial por odr_id (auto-generado)
    ctg_pdt_id INT,                    -- FK a PRODUCT_CATEGORIES (parte de la PK compuesta de PRODUCTS)
    pdt_id INT,                        -- FK a PRODUCTS
    quantity NUMERIC(10, 2),           -- Cantidad vendida
    unit_price NUMERIC(10, 2),         -- Precio unitario en COP
    subtotal NUMERIC(10, 2),            -- Subtotal (quantity * unit_price)
    
    -- Restricciones
    CONSTRAINT PK_DTL_ODR PRIMARY KEY (odr_id, line_item_id),
    CONSTRAINT FK_DTL_ODR_ORDERS 
        FOREIGN KEY (odr_id) REFERENCES TIENDA.ORDERS(odr_id),
    CONSTRAINT FK_DTL_ODR_PRODUCTS 
        FOREIGN KEY (pdt_id, ctg_pdt_id) REFERENCES TIENDA.PRODUCTS(pdt_id, pdt_ctg_id),
    
    -- Checks NOT NULL (definidos como constraints nombradas)
    CONSTRAINT NN_DTL_ODR_ODR_ID CHECK (odr_id IS NOT NULL),
    CONSTRAINT NN_DTL_ODR_LINE_ITEM CHECK (line_item_id IS NOT NULL),
    CONSTRAINT NN_DTL_ODR_CTG_PDT CHECK (ctg_pdt_id IS NOT NULL),
    CONSTRAINT NN_DTL_ODR_PDT_ID CHECK (pdt_id IS NOT NULL),
    CONSTRAINT NN_DTL_ODR_QUANTITY CHECK (quantity IS NOT NULL),
    CONSTRAINT NN_DTL_ODR_UNIT_PRICE CHECK (unit_price IS NOT NULL),
    CONSTRAINT NN_DTL_ODR_SUBTOTAL CHECK (subtotal IS NOT NULL),
    
    -- Validaciones lógicas
    CONSTRAINT CK_DTL_ODR_QUANTITY CHECK (quantity > 0),
    CONSTRAINT CK_DTL_ODR_UNIT_PRICE CHECK (unit_price > 0)
);


