defmodule TripPlannerIa.AiPreferencesTest do
  use TripPlannerIa.DataCase

  alias TripPlannerIa.Accounts
  alias TripPlannerIa.Accounts.User

  import TripPlannerIa.AccountsFixtures

  describe "get_user_ai_preferences/1" do
    test "returns nil for new user without preferences" do
      user = user_fixture()
      assert Accounts.get_user_ai_preferences(user.id) == nil
    end

    test "returns nil when user does not exist" do
      assert Accounts.get_user_ai_preferences(-1) == nil
    end
  end

  describe "update_user_ai_preferences/2" do
    test "saves and reads provider preference" do
      user = user_fixture()

      assert {:ok, %User{}} =
               Accounts.update_user_ai_preferences(user.id, %{provider_id: "nvidia-nim"})

      assert Accounts.get_user_ai_preferences(user.id) == %{
               provider_id: "nvidia-nim",
               model: nil
             }
    end

    test "saves provider and model together" do
      user = user_fixture()

      assert {:ok, %User{}} =
               Accounts.update_user_ai_preferences(user.id, %{
                 provider_id: "gemini",
                 model: "gemini-custom"
               })

      assert Accounts.get_user_ai_preferences(user.id) == %{
               provider_id: "gemini",
               model: "gemini-custom"
             }
    end

    test "trims whitespace from model and stores nil when blank" do
      user = user_fixture()

      assert {:ok, %User{}} =
               Accounts.update_user_ai_preferences(user.id, %{
                 provider_id: "gemini",
                 model: "  "
               })

      assert Accounts.get_user_ai_preferences(user.id) == %{
               provider_id: "gemini",
               model: nil
             }
    end

    test "overwrites previous preference" do
      user = user_fixture()

      Accounts.update_user_ai_preferences(user.id, %{provider_id: "gemini", model: "a"})
      Accounts.update_user_ai_preferences(user.id, %{provider_id: "nvidia-nim"})

      updated = Repo.get!(User, user.id)
      assert updated.ai_provider_id == "nvidia-nim"
      assert updated.ai_model == nil

      assert Accounts.get_user_ai_preferences(user.id) == %{
               provider_id: "nvidia-nim",
               model: nil
             }
    end
  end
end
