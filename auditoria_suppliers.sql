CREATE TABLE tienda.audi_suppliers (
    consecutivo SERIAL PRIMARY KEY,
    nit VARCHAR(15),
    first_name VARCHAR(50),
    middle_name VARCHAR(50),
    last_name VARCHAR(50),
    phone_number VARCHAR(15),
    address VARCHAR(100),
    cyy_id VARCHAR(3),
    dpt_id VARCHAR(3),
    cty_id VARCHAR(3),
    fecha_registro TIMESTAMP,
    usuario VARCHAR(50),
    accion CHAR(1) -- 'U' para update, 'D' para delete
);

CREATE OR REPLACE FUNCTION tienda.audi_suppliers_func() 
RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO tienda.audi_suppliers(
            nit, first_name, middle_name, last_name,
            phone_number, address, cyy_id, dpt_id, cty_id,
            fecha_registro, usuario, accion
        )
        VALUES (
            OLD.nit, OLD.first_name, OLD.middle_name, OLD.last_name,
            OLD.phone_number, OLD.address, OLD.cyy_id, OLD.dpt_id, OLD.cty_id,
            current_timestamp, current_user, 'U'
        );
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO tienda.audi_suppliers(
            nit, first_name, middle_name, last_name,
            phone_number, address, cyy_id, dpt_id, cty_id,
            fecha_registro, usuario, accion
        )
        VALUES (
            OLD.nit, OLD.first_name, OLD.middle_name, OLD.last_name,
            OLD.phone_number, OLD.address, OLD.cyy_id, OLD.dpt_id, OLD.cty_id,
            current_timestamp, current_user, 'D'
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audi_suppliers
BEFORE UPDATE OR DELETE ON tienda.suppliers
FOR EACH ROW
EXECUTE FUNCTION tienda.audi_suppliers_func();

