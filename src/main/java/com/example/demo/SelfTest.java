package com.example.demo;

import com.example.demo.model.Product;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;

import java.util.List;

@Configuration
public class SelfTest {

    private static final Logger logger = LoggerFactory.getLogger(SelfTest.class);
    private static final String BASE_URL = "http://localhost:8080/api/products";

    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder.build();
    }

    @Bean
    public CommandLineRunner testProductApi(RestTemplate restTemplate) {
        return args -> {
            try {
                logger.info("Starting Product API Self Test");

                // 1. Create new products
                logger.info("Creating new products...");
                Product laptop = new Product("Laptop", "High performance laptop", 999.99, 10);
                Product phone = new Product("Smartphone", "Latest model smartphone", 599.99, 20);

                Product savedLaptop = restTemplate.postForObject(BASE_URL, laptop, Product.class);
                logger.info("Created product: {}", savedLaptop);

                Product savedPhone = restTemplate.postForObject(BASE_URL, phone, Product.class);
                logger.info("Created product: {}", savedPhone);

                // 2. Get all products
                logger.info("Retrieving all products...");
                ResponseEntity<List<Product>> response = restTemplate.exchange(
                    BASE_URL,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Product>>() {}
                );
                List<Product> products = response.getBody();
                logger.info("Found {} products", products != null ? products.size() : 0);
                if (products != null) {
                    products.forEach(p -> logger.info(p.toString()));
                }

                // 3. Get product by ID
                if (savedLaptop != null) {
                    logger.info("Retrieving product with ID: {}", savedLaptop.getId());
                    Product retrievedProduct = restTemplate.getForObject(BASE_URL + "/{id}", Product.class, savedLaptop.getId());
                    logger.info("Retrieved product: {}", retrievedProduct);
                }

                // 4. Update product
                if (savedPhone != null) {
                    logger.info("Updating product with ID: {}", savedPhone.getId());
                    savedPhone.setPrice(499.99);
                    savedPhone.setQuantity(25);
                    restTemplate.put(BASE_URL + "/{id}", savedPhone, savedPhone.getId());
                    Product updatedProduct = restTemplate.getForObject(BASE_URL + "/{id}", Product.class, savedPhone.getId());
                    logger.info("Updated product: {}", updatedProduct);
                }

                // 5. Delete product
                if (savedLaptop != null) {
                    logger.info("Deleting product with ID: {}", savedLaptop.getId());
                    restTemplate.delete(BASE_URL + "/{id}", savedLaptop.getId());
                    logger.info("Product deleted successfully");

                    // Verify deletion
                    response = restTemplate.exchange(
                        BASE_URL,
                        HttpMethod.GET,
                        null,
                        new ParameterizedTypeReference<List<Product>>() {}
                    );
                    products = response.getBody();
                    logger.info("Remaining products after deletion: {}", products != null ? products.size() : 0);
                    if (products != null) {
                        products.forEach(p -> logger.info(p.toString()));
                    }
                }

                logger.info("Product API Self Test completed successfully");
            } catch (Exception e) {
                logger.error("Error during Product API Self Test", e);
            }
        };
    }
}
