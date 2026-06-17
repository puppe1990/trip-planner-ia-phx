defmodule TripPlannerIa.Llm.GeminiProviderTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.Llm.GeminiProvider

  @stub TripPlannerIa.Llm.GeminiProvider

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "create/2" do
    test "calls generateContent with json mime type for generate_json" do
      Req.Test.stub(@stub, fn conn ->
        body = Jason.decode!(Req.Test.raw_body(conn))

        assert conn.request_path =~ "generateContent"
        assert get_in(body, ["generationConfig", "responseMimeType"]) == "application/json"
        assert get_in(body, ["generationConfig", "temperature"]) == 0.8
        assert get_in(body, ["systemInstruction", "parts", Access.at(0), "text"]) == "Return JSON"

        Req.Test.json(conn, %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [%{"text" => ~s({"destination":"Paris"})}]
              }
            }
          ]
        })
      end)

      provider =
        GeminiProvider.create("gemini-test-key", "gemini-3.5-flash",
          req_options: [plug: {Req.Test, @stub}]
        )

      json =
        provider.generate_json.(%{
          system: "Return JSON",
          prompt: "Plan a trip to Paris",
          temperature: 0.8
        })

      assert json == ~s({"destination":"Paris"})
    end

    test "returns grounded text and sources for generate_grounded_text" do
      Req.Test.stub(@stub, fn conn ->
        body = Jason.decode!(Req.Test.raw_body(conn))

        assert get_in(body, ["tools"]) == [%{"googleSearch" => %{}}]
        assert get_in(body, ["generationConfig", "temperature"]) == 0.5

        Req.Test.json(conn, %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [%{"text" => "### Metro\nLine 1 is available"}]
              },
              "groundingMetadata" => %{
                "groundingChunks" => [
                  %{"web" => %{"uri" => "https://example.com/metro", "title" => "Metro Guide"}},
                  %{"web" => %{"uri" => "https://example.com/metro", "title" => "Duplicate"}}
                ]
              }
            }
          ]
        })
      end)

      provider =
        GeminiProvider.create("gemini-test-key", "gemini-3.5-flash",
          req_options: [plug: {Req.Test, @stub}]
        )

      result =
        provider.generate_grounded_text.(%{
          prompt: "Transit in Tokyo",
          temperature: 0.5
        })

      assert result.text == "### Metro\nLine 1 is available"

      assert result.sources == [
               %{title: "Metro Guide", url: "https://example.com/metro"}
             ]
    end

    test "raises when Gemini returns no content" do
      Req.Test.stub(@stub, fn conn ->
        Req.Test.json(conn, %{"candidates" => []})
      end)

      provider =
        GeminiProvider.create("gemini-test-key", "gemini-3.5-flash",
          req_options: [plug: {Req.Test, @stub}]
        )

      assert_raise RuntimeError, ~r/No content returned by Gemini model/, fn ->
        provider.generate_text.(%{system: "sys", prompt: "prompt"})
      end
    end
  end
end
