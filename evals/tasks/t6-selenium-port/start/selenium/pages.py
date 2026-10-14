from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

BASE = "http://localhost:3000"


class LoginPage:
    def __init__(self, driver):
        self.driver = driver

    def open(self):
        self.driver.get(f"{BASE}/login")

    def login(self, email, password):
        self.driver.find_element(By.CSS_SELECTOR, "[data-testid=login-email]").send_keys(email)
        self.driver.find_element(By.CSS_SELECTOR, "[data-testid=login-password]").send_keys(password)
        self.driver.find_element(By.CSS_SELECTOR, "[data-testid=login-submit]").click()

    def error_text(self):
        el = WebDriverWait(self.driver, 5).until(
            EC.visibility_of_element_located((By.CSS_SELECTOR, "[data-testid=login-error]"))
        )
        return el.text


class ProductsPage:
    def __init__(self, driver):
        self.driver = driver

    def user_name(self):
        return WebDriverWait(self.driver, 5).until(
            lambda d: d.find_element(By.CSS_SELECTOR, "[data-testid=user-name]").text or False
        )

    def search(self, text):
        self.driver.find_element(By.CSS_SELECTOR, "[data-testid=search]").send_keys(text)

    def result_count(self, expected):
        WebDriverWait(self.driver, 5).until(
            lambda d: len(d.find_elements(By.CSS_SELECTOR, "[data-testid^=product-]")) == expected
        )
        return expected

    def add(self, product_id):
        WebDriverWait(self.driver, 5).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, f"[data-testid=add-{product_id}]"))
        ).click()

    def cart_count(self, expected):
        WebDriverWait(self.driver, 5).until(
            lambda d: d.find_element(By.CSS_SELECTOR, "[data-testid=cart-count]").text == expected
        )
        return expected
