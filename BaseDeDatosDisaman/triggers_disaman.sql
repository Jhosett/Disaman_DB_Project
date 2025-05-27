--DETAIL_ORDERS TRIGGER
CREATE OR REPLACE FUNCTION TIENDA.fn_calcular_subtotal()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

--Aplicación deL Trigger
CREATE OR REPLACE TRIGGER trg_calcular_subtotal
BEFORE INSERT OR UPDATE ON TIENDA.DETAIL_ORDERS
FOR EACH ROW
EXECUTE FUNCTION TIENDA.fn_calcular_subtotal();


--ORDERS TRIGGER
CREATE OR REPLACE FUNCTION TIENDA.fn_actualizar_total_orden()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

--Aplicación de Trigger
CREATE TRIGGER trg_actualizar_total_orden
AFTER INSERT OR UPDATE ON TIENDA.DETAIL_ORDERS
FOR EACH ROW
EXECUTE FUNCTION TIENDA.fn_actualizar_total_orden();

