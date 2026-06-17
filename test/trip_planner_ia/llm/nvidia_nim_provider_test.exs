defmodule TripPlannerIa.Llm.NvidiaNimProviderTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Llm.NvidiaNimProvider

  @stub TripPlannerIa.Llm.NvidiaNimProvider
  @model "meta/llama-3.3-70b-instruct"

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "create/2" do
    test "calls NVIDIA NIM chat completions with bearer auth" do
      Req.Test.stub(@stub, fn conn ->
        body = Jason.decode!(Req.Test.raw_body(conn))
        [auth] = Plug.Conn.get_req_header(conn, "authorization")

        assert auth == "Bearer nvapi-test-key"
        assert body["model"] == @model
        assert body["temperature"] == 0.5

        assert body["messages"] == [
                 %{"role" => "system", "content" => "You are helpful"},
                 %{"role" => "user", "content" => "Transit tips for Paris"}
               ]

        Req.Test.json(conn, %{
          "choices" => [%{"message" => %{"content" => "Hello transit"}}]
        })
      end)

      provider =
        NvidiaNimProvider.create("nvapi-test-key", @model, req_options: [plug: {Req.Test, @stub}])

      text =
        provider.generate_text.(%{
          system: "You are helpful",
          prompt: "Transit tips for Paris",
          temperature: 0.5
        })

      assert text == "Hello transit"
    end

    test "requests json_object format for generate_json" do
      Req.Test.stub(@stub, fn conn ->
        body = Jason.decode!(Req.Test.raw_body(conn))

        assert body["response_format"] == %{"type" => "json_object"}
        assert body["max_tokens"] == 4096
        assert body["temperature"] == 0.8

        Req.Test.json(conn, %{
          "choices" => [%{"message" => %{"content" => ~s({"destination":"Paris"})}}]
        })
      end)

      provider =
        NvidiaNimProvider.create("nvapi-test-key", @model, req_options: [plug: {Req.Test, @stub}])

      json =
        provider.generate_json.(%{
          system: "Return JSON only",
          prompt: "Plan a trip",
          temperature: 0.8
        })

      assert json == ~s({"destination":"Paris"})
    end

    test "rejects unhosted models before calling the API" do
      provider = NvidiaNimProvider.create("nvapi-test-key", "qwen/qwen2.5-72b-instruct")

      assert_raise RuntimeError, ~r/not available on the hosted NVIDIA NIM API/, fn ->
        provider.generate_text.(%{system: "sys", prompt: "prompt"})
      end
    end

    test "throws a helpful error when the API fails" do
      Req.Test.stub(@stub, fn conn ->
        Plug.Conn.send_resp(conn, 401, "Unauthorized")
      end)

      provider =
        NvidiaNimProvider.create("bad-key", @model, req_options: [plug: {Req.Test, @stub}])

      assert_raise RuntimeError, ~r/NVIDIA NIM request failed \(401\): Unauthorized/, fn ->
        provider.generate_text.(%{system: "sys", prompt: "prompt"})
      end
    end

    test "throws a model-specific message for hosted-model 404 responses" do
      Req.Test.stub(@stub, fn conn ->
        Plug.Conn.send_resp(conn, 404, "404 page not found")
      end)

      provider =
        NvidiaNimProvider.create("nvapi-test-key", @model, req_options: [plug: {Req.Test, @stub}])

      assert_raise RuntimeError,
                   ~r/Model "#{@model}" is not available on the hosted API/,
                   fn ->
                     provider.generate_text.(%{system: "sys", prompt: "prompt"})
                   end
    end
  end
end
