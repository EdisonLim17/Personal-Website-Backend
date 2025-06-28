import re, pytest, json
from typing import Generator
from playwright.sync_api import Playwright, APIRequestContext, Page, expect

BASE_URL = "https://5ak2nip9i9.execute-api.us-east-1.amazonaws.com/"

# def test_has_title(page: Page):
#     page.goto("https://edisonlim.ca")

#     expect(page).to_have_title("Edison Lim - Portfolio")

@pytest.fixture(scope="session")
def api_request_context(playwright: Playwright) -> Generator[APIRequestContext, None, None]:
    headers = {}
    request_context = playwright.request.new_context(
        base_url=BASE_URL, extra_http_headers=headers
    )
    yield request_context
    request_context.dispose()

def test_updates_database(api_request_context: APIRequestContext) -> None:
    #check num_views in database before post call
    get_before_response = api_request_context.get("/prod/websitecounterlambdaendpoint", data=json.dumps({}))
    assert get_before_response.status == 200
    assert get_before_response.ok
    get_before_json_body = get_before_response.json()
    assert "num_views" in get_before_json_body, "Get_Before Response JSON missing 'num_views'"
    before_count = get_before_json_body["num_views"]
    assert isinstance(before_count, int)

    #check post call
    post_response = api_request_context.post("/prod/websitecounterlambdaendpoint", data=json.dumps({}))
    assert post_response.status == 200
    assert post_response.ok
    post_json_body = post_response.json()
    assert "num_views" in post_json_body, "Post Response JSON missing 'num_views'"
    assert isinstance(post_json_body["num_views"], int)
    post_count = post_json_body["num_views"]
    assert isinstance(post_count, int)

    #check num_views in database after post call
    get_after_response = api_request_context.get("/prod/websitecounterlambdaendpoint", data=json.dumps({}))
    assert get_after_response.status == 200
    assert get_after_response.ok
    get_after_json_body = get_after_response.json()
    assert "num_views" in get_after_json_body, "Get_After Response JSON missing 'num_views'"
    after_count = get_after_json_body["num_views"]
    assert isinstance(after_count, int)

    #make sure num_views in database after post call is one more than before post call
    assert before_count == after_count - 1, "Visitor count not updated in database"
    assert post_count == after_count