package com.example;

import java.sql.*;
import java.util.Properties;
import java.io.InputStream;
import java.io.IOException;
import org.flywaydb.core.Flyway;

public class App {
    private static String url;
    private static String username;
    private static String password;

    public static void main(String[] args) {
        System.out.println("*** Приложение по мониторингу/оформлению заказов Order Management ***");
        
        Connection connection = null;
        try {
            // Загрузка конфигурации
            loadConfiguration();
            
            // Подключение к БД с транзакциями
            connection = DriverManager.getConnection(url, username, password);
            connection.setAutoCommit(false);
            
            // Выполнение миграций Flyway
            performMigrations();
            
            // Демонстрация CRUD операций
            demonstrateCRUDOperations(connection);
            
            connection.commit();
            
        } catch (Exception e) {
            System.err.println("Ошибка: " + e.getMessage());
            //e.printStackTrace();
            if (connection != null) {
                try {
                    connection.rollback();
                    System.out.println("Транзакция откатана");
                } catch (SQLException ex) {
                    System.err.println("Ошибка при откате: " + ex.getMessage());
                }
            }
        } finally {
            if (connection != null) {
                try {
                    connection.close();
                } catch (SQLException e) {
                    System.err.println("Ошибка при закрытии соединения: " + e.getMessage());
                }
            }
        }
    }
    
    private static void loadConfiguration() throws IOException {
        Properties props = new Properties();
        try (InputStream input = App.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (input == null) {
                throw new IOException("ОШИБКА: Файл application.properties не найден.");
            }
            props.load(input);
        }
        url = props.getProperty("db.url");
        username = props.getProperty("db.username");
        password = props.getProperty("db.password");
    }
    
    private static void performMigrations() {
        try {
            
            // Настройка Flyway
            Flyway flyway = Flyway.configure()
                    .dataSource(url, username, password)
                    .locations("db/migration")
                    .load();
            
            // Запуск миграций
            flyway.migrate();
            
        } catch (Exception e) {
            System.err.println("Ошибка миграций: " + e.getMessage());
            throw new RuntimeException("ОШИБКА: Миграции не выполнены", e);
        }
    }
    
    private static void demonstrateCRUDOperations(Connection connection) throws SQLException {
        System.out.println("\n*** ДЕМОНСТРАЦИЯ CRUD ОПЕРАЦИЙ **");
        
        // 1. CREATE - Вставка нового товара
        System.out.println("\n1. CREATE - Добавление нового товара:");
        int newProductId = insertNewProduct(connection);
        
        // 2. CREATE - Вставка нового клиента
        System.out.println("\n2. CREATE - Добавление нового клиента:");
        int newCustomerId = insertNewCustomer(connection);
        
        // 3. CREATE - Создание заказа
        System.out.println("\n3. CREATE - Создание заказа:");
        createNewOrder(connection, newProductId, newCustomerId);
        
        // 4. READ - Чтение последних заказов
        System.out.println("\n4. READ - Последние 5 заказов:");
        readLastOrders(connection);
        
        // 5. UPDATE - Обновление цены товара
        System.out.println("\n5. UPDATE - Обновление цены товара:");
        updateProductPrice(connection, newProductId);
        
        // 6. UPDATE - Обновление количества товара
        System.out.println("\n6. UPDATE - Обновление количества товара:");
        updateProductQuantity(connection, newProductId);
        
        // 7. DELETE - Удаление тестовых данных
        System.out.println("\n7. DELETE - Удаление тестовых данных:");
        deleteTestData(connection, newProductId, newCustomerId);
    }
    
    // Вставка нового товара (PreparedStatement)
    private static int insertNewProduct(Connection connection) throws SQLException {
        String sql = "INSERT INTO product (description, price, quantity, category) VALUES (?, ?, ?, ?)";
        try (PreparedStatement stmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, "Самокат для малышей 1+");
            stmt.setDouble(2, 1800.00);
            stmt.setInt(3, 2);
            stmt.setString(4, "Транспорт");
            stmt.executeUpdate();
            
            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int newId = generatedKeys.getInt(1);
                    System.out.println("Добавлен товар с ID: " + newId);
                    return newId;
                }
            }
        }
        return -1;
    }
    
    // Вставка нового покупателя (PreparedStatement)
    private static int insertNewCustomer(Connection connection) throws SQLException {
        String sql = "INSERT INTO customer (first_name, last_name, phone, email) VALUES (?, ?, ?, ?)";
        try (PreparedStatement stmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, "Екатерина");
            stmt.setString(2, "Бондарева");
            stmt.setString(3, "+79067381123");
            stmt.setString(4, "bondareva@mail.ru");
            stmt.executeUpdate();
            
            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int newId = generatedKeys.getInt(1);
                    System.out.println("Добавлен клиент с ID: " + newId);
                    return newId;
                }
            }
        }
        return -1;
    }
    
    // Создание заказа для покупателя
    private static void createNewOrder(Connection connection, int productId, int customerId) throws SQLException {
        String sql = "INSERT INTO orders (product_id, customer_id, order_date, quantity, status_id) VALUES (?, ?, CURRENT_DATE, ?, ?)";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, productId);
            stmt.setInt(2, customerId);
            stmt.setInt(3, 1);
            stmt.setInt(4, 1); // статус "Новый", т.к. новый заказ
            stmt.executeUpdate();
            System.out.println("Создан новый заказ");
        }
    }
    
    // Чтение и вывод последних 5 заказов с JOIN на товары и покупателей
    private static void readLastOrders(Connection connection) throws SQLException {
        String sql = """
            SELECT o.id, o.order_date, 
                   c.first_name || ' ' || c.last_name as customer,
                   p.description as product, 
                   o.quantity, 
                   os.status_name,
                   (p.price * o.quantity) as total
            FROM orders o
            JOIN customer c ON o.customer_id = c.id
            JOIN product p ON o.product_id = p.id
            JOIN order_status os ON o.status_id = os.id
            ORDER BY o.order_date DESC
            LIMIT 5
            """;
            
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            
            System.out.println("   ┌─────┬────────────┬──────────────────┬──────────────────────┬──────────┬──────────────┬─────────┐");
            System.out.println("   │ ID  │    Дата    │     Клиент       │       Товар          │ Кол-во   │   Статус     │  Сумма  │");
            System.out.println("   ├─────┼────────────┼──────────────────┼──────────────────────┼──────────┼──────────────┼─────────┤");
            
            while (rs.next()) {
                int orderId = rs.getInt("id");
                String orderDate = rs.getDate("order_date").toString();
                String customer = rs.getString("customer");
                String product = rs.getString("product");
                int quantity = rs.getInt("quantity");
                String status = rs.getString("status_name");
                double total = rs.getDouble("total");
                
                System.out.printf("   │ %-3d │ %-10s │ %-16s │ %-20s │ %-8d │ %-12s │ %-7.0f │\n",
                    orderId, orderDate, customer, 
                    product.length() > 20 ? product.substring(0, 17) + "..." : product,
                    quantity, status, total);
            }
            System.out.println("   └─────┴────────────┴──────────────────┴──────────────────────┴──────────┴──────────────┴─────────┘");
        }
    }
    
    // Обновление цены товара
    private static void updateProductPrice(Connection connection, int productId) throws SQLException {
        String sql = "UPDATE product SET price = ? WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setDouble(1, 3500.00);
            stmt.setInt(2, productId);
            int rows = stmt.executeUpdate();
            System.out.println("Обновлена цена товара. Затронуто строк: " + rows);
        }
    }
    
    // Обновление количества на складе
    private static void updateProductQuantity(Connection connection, int productId) throws SQLException {
        String sql = "UPDATE product SET quantity = ? WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, 12);
            stmt.setInt(2, productId);
            int rows = stmt.executeUpdate();
            System.out.println("Обновлено количество товара. Затронуто строк: " + rows);
        }
    }
    
    private static void deleteTestData(Connection connection, int productId, int customerId) throws SQLException {
        // Удаление заказов
        String deleteOrders = "DELETE FROM orders WHERE product_id = ? OR customer_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(deleteOrders)) {
            stmt.setInt(1, productId);
            stmt.setInt(2, customerId);
            int ordersDeleted = stmt.executeUpdate();
            System.out.println("Тестовый заказ удален из БД: " + ordersDeleted);
        }
        
        // Удаление товара
        String deleteProduct = "DELETE FROM product WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(deleteProduct)) {
            stmt.setInt(1, productId);
            int productsDeleted = stmt.executeUpdate();
            System.out.println("Тестовый товар удален из БД: " + productsDeleted);
        }
        
        // Удаление клиента
        String deleteCustomer = "DELETE FROM customer WHERE id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(deleteCustomer)) {
            stmt.setInt(1, customerId);
            int customersDeleted = stmt.executeUpdate();
            System.out.println("Тестовый клиент удален из БД: " + customersDeleted);
        }
    }
}