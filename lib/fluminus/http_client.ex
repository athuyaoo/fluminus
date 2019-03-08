defmodule Fluminus.HTTPClient do
  @moduledoc """
  A HTTP client backed by HTTPoison that manages cookies.

  Struct fields:
  * `:cookies` - cookies stored by this HTTP client.
  """

  @supported_methods ~w(get post)a
  @type methods() :: :get | :post

  @type flattened_headers() :: %{required(String.t()) => String.t()}
  @type headers() :: [{String.t(), String.t()}]

  @type t :: %__MODULE__{cookies: %{required(String.t()) => String.t()}}
  defstruct cookies: %{}

  @doc """
  Performs a GET request.

  This is a convenience method that will call `request/5`
  """
  @spec get(__MODULE__.t(), String.t(), headers()) ::
          {:ok, __MODULE__.t(), flattened_headers(), HTTPoison.Response.t()}
          | {:error, %HTTPoison.Error{}}
  def get(client = %__MODULE__{}, url, headers \\ []) when is_binary(url) do
    request(client, :get, url, "", headers)
  end

  @doc """
  Performs a POST request.

  This is a convenience method that will call `request/5`
  """
  @spec post(__MODULE__.t(), String.t(), String.t(), headers()) ::
          {:ok, __MODULE__.t(), flattened_headers(), HTTPoison.Response.t()}
          | {:error, %HTTPoison.Error{}}
  def post(client = %__MODULE__{}, url, body, headers \\ [{"Content-Type", "application/x-www-form-urlencoded"}])
      when is_binary(url) and is_binary(body) do
    request(client, :post, url, body, headers)
  end

  @doc """
  Performs a HTTP request.

  Note that for flattened headers, in case there are some headers with the same key, the value will contain the value
  of the last header with that key as returned by `HTTPoison`.
  """
  @spec request(__MODULE__.t(), methods(), String.t(), String.t()) ::
          {:ok, __MODULE__.t(), flattened_headers(), HTTPoison.Response.t()}
          | {:error, %HTTPoison.Error{}}
  def request(client = %__MODULE__{}, method, url, body \\ "", headers \\ [])
      when method in @supported_methods and is_binary(url) and is_binary(body) do
    headers = generate_headers(client, headers)

    case HTTPoison.request(method, url, body, headers, recv_timeout: 10_000) do
      {:ok, response = %HTTPoison.Response{headers: headers}} ->
        updated_client = update_cookies(client, response)
        flattened_headers = Map.new(headers)
        {:ok, updated_client, flattened_headers, response}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Downloads from the `url` to the `destination`.

  If `overwrite` is `false`, this function will return `{:error, :exists}` if destination alread exists.
  """
  @spec download(__MODULE__.t(), String.t(), Path.t(), bool(), headers()) :: :ok | {:error, :exists | any()}
  def download(client = %__MODULE__{}, url, destination, overwrite \\ false, headers \\ [])
      when is_binary(url) and is_binary(destination) and is_boolean(overwrite) and is_list(headers) do
    headers = generate_headers(client, headers)

    with {:overwrite?, true} <- {:overwrite?, overwrite or not File.exists?(destination)},
         {:ok, file} <- File.open(destination, [:write]),
         {:ok, response} = HTTPoison.get(url, headers, stream_to: self(), async: :once),
         :ok <- download_loop(response, file),
         :ok <- File.close(file) do
      :ok
    else
      {:overwrite?, true} -> {:error, :exists}
      {:error, reason} -> {:error, reason}
    end
  end

  defp download_loop(response = %HTTPoison.AsyncResponse{id: id}, file) do
    receive do
      %HTTPoison.AsyncStatus{code: 200, id: ^id} ->
        HTTPoison.stream_next(response)
        download_loop(response, file)

      %HTTPoison.AsyncHeaders{id: ^id} ->
        HTTPoison.stream_next(response)
        download_loop(response, file)

      %HTTPoison.AsyncChunk{chunk: chunk, id: ^id} ->
        IO.binwrite(file, chunk)
        HTTPoison.stream_next(response)
        download_loop(response, file)

      %HTTPoison.AsyncEnd{id: ^id} ->
        :ok
    end
  end

  @spec generate_headers(__MODULE__.t(), headers()) :: headers()
  defp generate_headers(%__MODULE__{cookies: cookies}, headers) do
    cookies_string = Cookie.serialize(cookies)

    headers ++
      if(cookies_string != "", do: [{"Cookie", cookies_string}], else: [])
  end

  @spec update_cookies(__MODULE__.t(), HTTPoison.Response.t()) :: __MODULE__.t()
  defp update_cookies(client = %__MODULE__{cookies: cookies}, %HTTPoison.Response{headers: headers}) do
    updated_cookies =
      headers
      |> Enum.filter(fn {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i) end)
      |> Enum.map(fn {_, value} -> value |> SetCookie.parse() |> Map.take([:key, :value]) end)
      |> Enum.reduce(cookies, fn %{key: key, value: value}, acc -> Map.put(acc, key, value) end)

    %__MODULE__{client | cookies: updated_cookies}
  end
end