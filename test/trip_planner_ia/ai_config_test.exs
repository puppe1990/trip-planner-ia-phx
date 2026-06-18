defmodule TripPlannerIa.AiConfigTest do
  use ExUnit.Case, async: true

  alias TripPlannerIa.AiConfig
  alias TripPlannerIa.AiConfig.InvalidAiProviderError

  setup do
    on_exit(fn ->
      System.delete_env("AI_PROVIDER")
      System.delete_env("AI_MODEL")
      System.delete_env("GEMINI_API_KEY")
      System.delete_env("NVIDIA_API_KEY")
    end)

    :ok
  end

  describe "get_provider_id/0" do
    test "defaults to gemini when AI_PROVIDER is unset" do
      System.put_env("AI_PROVIDER", "")
      assert AiConfig.get_provider_id() == "gemini"
    end

    test "returns nvidia-nim when configured" do
      System.put_env("AI_PROVIDER", "nvidia-nim")
      System.put_env("NVIDIA_API_KEY", "key")
      assert AiConfig.get_provider_id() == "nvidia-nim"
    end

    test "falls back to nvidia-nim when gemini env is set but not configured" do
      System.put_env("AI_PROVIDER", "gemini")
      System.put_env("GEMINI_API_KEY", "")
      System.put_env("NVIDIA_API_KEY", "key")
      assert AiConfig.get_provider_id() == "nvidia-nim"
    end

    test "throws for invalid provider id" do
      System.put_env("AI_PROVIDER", "openai")

      assert_raise InvalidAiProviderError, fn ->
        AiConfig.get_provider_id()
      end
    end
  end

  describe "get_ai_config/0" do
    test "returns gemini defaults when AI_PROVIDER is gemini" do
      System.put_env("AI_PROVIDER", "gemini")

      assert AiConfig.get_ai_config() == %{
               provider_id: "gemini",
               provider: "Google Gemini",
               model: "gemini-2.5-flash",
               capabilities: %{structured_json: true, web_grounding: true}
             }
    end

    test "returns nvidia-nim defaults when AI_PROVIDER is nvidia-nim" do
      System.put_env("AI_PROVIDER", "nvidia-nim")
      System.put_env("GEMINI_API_KEY", "")
      System.put_env("NVIDIA_API_KEY", "key")

      assert AiConfig.get_ai_config() == %{
               provider_id: "nvidia-nim",
               provider: "NVIDIA NIM",
               model: "nvidia/nvidia-nemotron-nano-9b-v2",
               capabilities: %{structured_json: true, web_grounding: false}
             }
    end

    test "allows AI_MODEL override for any provider" do
      System.put_env("AI_PROVIDER", "nvidia-nim")
      System.put_env("GEMINI_API_KEY", "")
      System.put_env("NVIDIA_API_KEY", "key")
      System.put_env("AI_MODEL", "nvidia/nemotron-3-nano-30b-a3b")

      assert AiConfig.get_ai_config().model == "nvidia/nemotron-3-nano-30b-a3b"
    end
  end

  describe "resolve_ai_config/1" do
    test "falls back when saved provider is not configured" do
      System.put_env("AI_PROVIDER", "gemini")
      System.put_env("GEMINI_API_KEY", "")
      System.put_env("NVIDIA_API_KEY", "key")

      assert AiConfig.resolve_ai_config(%{provider_id: "gemini", model: nil}).provider_id ==
               "nvidia-nim"
    end

    test "uses user provider preference over env default" do
      System.put_env("AI_PROVIDER", "gemini")
      System.put_env("GEMINI_API_KEY", "key")
      System.put_env("NVIDIA_API_KEY", "key")

      assert AiConfig.resolve_ai_config(%{provider_id: "nvidia-nim", model: nil}) == %{
               provider_id: "nvidia-nim",
               provider: "NVIDIA NIM",
               model: "nvidia/nvidia-nemotron-nano-9b-v2",
               capabilities: %{structured_json: true, web_grounding: false}
             }
    end

    test "uses user model preference when provider is set" do
      System.put_env("AI_PROVIDER", "gemini")
      System.put_env("GEMINI_API_KEY", "key")
      System.put_env("NVIDIA_API_KEY", "key")

      assert AiConfig.resolve_ai_config(%{
               provider_id: "nvidia-nim",
               model: "meta/llama-3.1-8b-instruct"
             }).model ==
               "meta/llama-3.1-8b-instruct"
    end

    test "falls back to env when user has no preferences" do
      System.put_env("AI_PROVIDER", "nvidia-nim")
      System.put_env("GEMINI_API_KEY", "")
      System.put_env("NVIDIA_API_KEY", "key")
      System.put_env("AI_MODEL", "env-model")

      assert AiConfig.resolve_ai_config(nil) == %{
               provider_id: "nvidia-nim",
               provider: "NVIDIA NIM",
               model: "env-model",
               capabilities: %{structured_json: true, web_grounding: false}
             }
    end
  end

  describe "provider_models/0" do
    test "exposes only hosted nvidia nim model options" do
      models = AiConfig.provider_models()["nvidia-nim"]

      assert length(models) == 6
      refute Enum.any?(models, &(&1.id == "qwen/qwen2.5-72b-instruct"))
      assert hd(models).id == "nvidia/nvidia-nemotron-nano-9b-v2"
    end

    test "falls back to hosted default when saved nvidia model is unavailable" do
      System.put_env("AI_PROVIDER", "gemini")
      System.put_env("GEMINI_API_KEY", "key")
      System.put_env("NVIDIA_API_KEY", "key")

      assert AiConfig.resolve_ai_config(%{
               provider_id: "nvidia-nim",
               model: "qwen/qwen2.5-72b-instruct"
             }).model == "nvidia/nvidia-nemotron-nano-9b-v2"
    end

    test "does not surface unavailable nvidia models in the picker" do
      models = AiConfig.get_models_for_provider("nvidia-nim", "qwen/qwen2.5-72b-instruct")

      refute Enum.any?(models, &(&1.id == "qwen/qwen2.5-72b-instruct"))
    end
  end

  describe "list_provider_options/0" do
    test "marks providers as configured when api keys exist" do
      System.put_env("GEMINI_API_KEY", "key")
      System.put_env("NVIDIA_API_KEY", "")

      options = AiConfig.list_provider_options()

      assert length(options) == 2
      assert Enum.find(options, &(&1.id == "gemini")).configured == true
      assert Enum.find(options, &(&1.id == "nvidia-nim")).configured == false
    end

    test "includes model catalogs per provider" do
      options = AiConfig.list_provider_options()

      assert length(Enum.find(options, &(&1.id == "gemini")).models) > 1
      assert length(Enum.find(options, &(&1.id == "nvidia-nim")).models) == 6
    end
  end

  describe "parse_provider_id/1" do
    test "accepts valid provider ids" do
      assert AiConfig.parse_provider_id("gemini") == "gemini"
      assert AiConfig.parse_provider_id("nvidia-nim") == "nvidia-nim"
    end

    test "raises for invalid provider ids" do
      assert_raise InvalidAiProviderError, fn ->
        AiConfig.parse_provider_id("openai")
      end
    end
  end

  describe "provider_configured?/1" do
    test "returns true when gemini api key is set" do
      System.put_env("GEMINI_API_KEY", "key")
      assert AiConfig.provider_configured?("gemini") == true
    end

    test "returns true when nvidia api key is set" do
      System.put_env("NVIDIA_API_KEY", "key")
      assert AiConfig.provider_configured?("nvidia-nim") == true
    end

    test "returns false when api key is missing" do
      System.put_env("GEMINI_API_KEY", "")
      assert AiConfig.provider_configured?("gemini") == false
    end
  end
end
