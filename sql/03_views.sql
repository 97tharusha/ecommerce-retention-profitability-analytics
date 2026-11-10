CREATE VIEW completed_orders_view AS
SELECT * FROM orders WHERE order_status = 'Completed';