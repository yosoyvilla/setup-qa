import pytest
from selenium import webdriver
from pages import LoginPage, ProductsPage


@pytest.fixture
def driver():
    d = webdriver.Chrome()
    yield d
    d.quit()


def do_login(driver, password="Passw0rd!"):
    page = LoginPage(driver)
    page.open()
    page.login("alice@example.com", password)
    return page


def test_login_shows_user_name(driver):
    do_login(driver)
    assert "/products" in driver.current_url
    assert ProductsPage(driver).user_name() == "Alice Reyes"


def test_wrong_password_shows_error(driver):
    page = do_login(driver, "nope")
    assert "/login" in driver.current_url
    assert page.error_text() == "Invalid credentials"


def test_search_narrows_results(driver):
    do_login(driver)
    products = ProductsPage(driver)
    products.search("backpack")
    assert products.result_count(2) == 2


def test_add_to_cart_updates_count(driver):
    do_login(driver)
    products = ProductsPage(driver)
    products.add(3)
    assert products.cart_count("1") == "1"
