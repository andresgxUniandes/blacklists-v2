class TestRootEndpoint:
    def test_returns_hello_world(self, client):
        response = client.get("/")

        assert response.status_code == 200
        assert response.get_json() == {"Hello": "World Version 2026-05-06 00:56"}


class TestHealthEndpoint:
    def test_returns_pong(self, client):
        response = client.get("/health")

        assert response.status_code == 200
        assert response.get_json() == "pong!"
