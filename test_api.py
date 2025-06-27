import re, pytest
from typing import Generator
from playwright.sync_api import Playwright, APIRequestContext, Page, expect

BASE_URL = "https://5ak2nip9i9.execute-api.us-east-1.amazonaws.com/"

# def test_has_title(page: Page):
#     page.goto("https://edisonlim.ca")

#     expect(page).to_have_title("Edison Lim - Portfolio")

@pytest.fixture(scope="session")
def api_request_context(playwright: Playwright) -> Generator[APIRequestContext, None, None]:
    headers = {
        "method": "POST"
    }
    request_context = playwright.request.new_context(
        base_url=BASE_URL, extra_http_headers=headers
    )
    yield request_context
    request_context.dispose()

def test_updates_database(api_request_context: APIRequestContext) -> None:
    data = {}

    response = api_request_context.post("/prod/websitecounterlambdaendpoint", data=data)

    assert response.status == 200
    assert response.ok
    assert response.json()["num_views"] == 141