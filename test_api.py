import re
from playwright.sync_api import Page, expect

def test_has_title1(page: Page):
    page.goto("https://edisonlim.ca")

    expect(page).to_have_title("Edison Lim - Portfolio")