defmodule Fluminus.AuthorizationTest do
  use ExUnit.Case, async: true

  @idsrv "Ywnb0vX7NMtrerdyfJsdSQmn5b0U44QTOxaQTazUU2plr9z3mZr_tXbxKQqwzHUEv14qZCkOu349j8JsTi8A7ePLpBi2l7CiVBvoV5lB6ufTBgamnp9_1dqxxZwg30VPC2sGvmlndzXo9Iz-LQK3FQi2sKNnW_MnokhKfmRI5rQszRIyxJl0fzr-sT9vTTH5FE8GK7mJ5oFTYpcsukHkEuZlfCmzA8SQ1wwOMzg3gr_KOpakzDgUsQrjubhedDWbkdIm0LpCSp4nWJdwO270mSZjrdf3MNSscIpCRRVvqb4MnaMvcBSgZTOjgm4YfDSgCyPVh4AKFaofuPYSwab2qq-ZqkbS7dRiGiCHBA62PiYoR8xm-QJor7XkqkQM_nxiGLBpvQeqF0J3z77H2Sgiwg"
  @id_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwMzQ4ODQsIm5iZiI6MTU1MjAzNDU4NCwibm9uY2UiOiJlYjA0Y2ZmN2U4YTg0YTM0YTlhOWE0YWI3NGU3NzE2NiIsImlhdCI6MTU1MjAzNDU4NCwiYXRfaGFzaCI6Im9RYmFrbkxxeUVPYWtWQV8tMjA2Q1EiLCJjX2hhc2giOiJfMi02T29UYjJJOUpFU2lDZEI2ZGVBIiwic2lkIjoiNTYyZGYxYWYyODRhMDA4MTY1MGE0MDQ4N2NhODAzOTgiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWViMGYiLCJhdXRoX3RpbWUiOjE1NTIwMzQ1ODQsImlkcCI6Imlkc3J2IiwiYWRkcmVzcyI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.R54fwml4-KmwaD_pNSJxmf3XXoQdf3coik7-c-Lt7dconpJHLlorsiymQaiGLTlUdvMGHYvN_1JzCi42azkCxF2kjAJiosdCigR3b4okM1sovXoJsbE7tIycx2jpZwCmusL6nMffzE0ly_Q28x55jdQmJ9PIyGe7XD4mfKqDweht4fhCAtoeJtNPeDKX2dG6p4ll0lJxgVBOZsdi8PYF6z_rTt7zmMgd9CSc6WH2sOl8f9FKpVxoGtLBmjEBcNbwODokTu-cgW20vLFc05a7UZa3uKzPZI3DONnUDptLGgatcYGmNDTooQrJdh5xDKrK1tmkgVgBTmvPb44WYIiqHw"
  @renew_id_token "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSIsImtpZCI6ImEzck1VZ01Gdjl0UGNsTGE2eUYzekFrZnF1RSJ9.eyJpc3MiOiJodHRwczovL2x1bWludXMubnVzLmVkdS5zZy92Mi9hdXRoIiwiYXVkIjoidmVyc28iLCJleHAiOjE1NTIwMzQ4ODQsIm5iZiI6MTU1MjA5NDU4NCwibm9uY5UiOiJlYjA0Y2ZmN2U4YTg0YTM0YTlhOWE0YWI3NGU3NzE2NiIsImlhdCI6MTU1MjAzNDU4NCwiYXRfaGFzaCI6Im9RYmFrbkxxeUVPYW5WQV8tMjA2Q1EiLC5jX2hhc2giOiJfMi02T29UYjJJOUpFU2lDZEI2ZGVBIiwic2lkIjoiNTYyZGYxYWYyODRhMDA4MTY1MGE0MDQ4N2NhODAzOTgiLCJzdWIiOiIwMzA4OTI1Mi0wYzk2LTRmYWItYjA4MC1mMmFlYjA3ZWViMGYiLCJhdXRoX3RpbWUiOjE1NTIwMzQ1ODQsImlkcCI6Imlkc3J2IiwiYWRkcmVzcyI6IlJlcXVlc3QgYWxsIGNsYWltcyIsImFtciI6WyJwYXNzd29yZCJdfQ.R54fwml4-KmwaD_pNSJxmf3XXoQdf3coik7-c-Lt7dconpJHLlorsiymQaiGLTlUdvMGHYvN_1JzCi42azkCxF2kjAJiosdCigR3b4okM1sovXoJsbE7tIycx2jpZwCmusL6nMffzE0ly_Q28x55jdQmJ9PIyGe7XD4mfKqDweht4fhCAtoeJtNPeDKX2dG6p4ll0lJxgVBOZsdi8PYF6z_rTt7zmMgd9CSc6WH2sOl8f9FKpVxoGtLBmjEBcNbwODokTu-cgW20vLFc05a7UZa3uKzPZI3DONnUDptLGgatcYGmNDTooQrJdh5xDKrK1tmkgVgBTmvPb44WYIiqHw"

  alias Fluminus.{Authorization, HTTPClient}

  test "jwt happy path" do
    {:ok, auth} = Authorization.jwt("e0123456", "hunter2")

    assert auth.jwt == @id_token
    assert(auth.client.cookies["idsrv"] == @idsrv)
  end

  test "jwt invalid credential" do
    {:error, :invalid_credentials} = Authorization.jwt("e1234567", "wrongpassword")
  end

  test "renew_jwt happy path" do
    auth = %Authorization{jwt: @id_token, client: %HTTPClient{cookies: %{"idsrv" => @idsrv}}}
    {:ok, auth} = Authorization.renew_jwt(auth)

    assert auth.jwt == @renew_id_token
  end

  test "new" do
    auth = Authorization.new(@id_token, @idsrv)
    assert auth.jwt == @id_token
    assert auth.client.cookies["idsrv"] == @idsrv
  end

  test "get_jwt" do
    auth = Authorization.new(@id_token, @idsrv)
    assert Authorization.get_jwt(auth) == @id_token
  end

  test "get_refresh_token" do
    auth = Authorization.new(@id_token, @idsrv)
    assert Authorization.get_refresh_token(auth) == @idsrv
  end
end
