defmodule TripPlannerIa.Fixtures do
  @moduledoc false

  def sample_trip_plan(overrides \\ %{}) do
    base = %{
      id: "trip_test",
      destination: "Lisboa, Portugal",
      duration_days: 3,
      tagline: "Azulejos e pastéis",
      summary: "Roteiro cultural",
      budget_estimate: %{
        total_cost_estimate: "R$ 3000",
        hotel_average_night: "R$ 200",
        food_average_day: "R$ 100",
        transport_average_day: "R$ 40"
      },
      packing_essentials: ["Casaco leve"],
      weather_expected: "Ameno",
      days: [
        %{
          day_number: 1,
          theme: "Centro histórico",
          morning: %{
            title: "Alfama",
            description: "Bairro antigo",
            cost: "Grátis",
            duration: "3h"
          },
          afternoon: %{
            title: "Castelo",
            description: "Vista panorâmica",
            cost: "R$ 30",
            duration: "2h"
          },
          evening: %{
            title: "Fado",
            description: "Música tradicional",
            cost: "R$ 80",
            duration: "2h"
          },
          dining_spot: %{
            name: "Tasca",
            type: "Portuguesa",
            price_level: "R$ Moderado",
            description: "Bacalhau"
          }
        }
      ],
      tips: [%{category: "Transporte", text: "Use o metro"}],
      created_at: "2026-01-15T10:00:00.000Z"
    }

    Map.merge(base, overrides)
  end

  def map_trip_plan(overrides \\ %{}) do
    sample_trip_plan(%{
      id: "map_test",
      destination: "Kyoto, Japão",
      duration_days: 2,
      tagline: "Templos",
      summary: "Cultura",
      days: [
        %{
          day_number: 1,
          theme: "Templos",
          morning: %{
            title: "Fushimi Inari",
            description: "Torii gates",
            cost: "Grátis",
            duration: "3h"
          },
          afternoon: %{
            title: "Arashiyama",
            description: "Bamboo grove",
            cost: "R$ 20",
            duration: "4h"
          },
          evening: %{
            title: "Gion",
            description: "Geisha district",
            cost: "Grátis",
            duration: "2h"
          },
          dining_spot: %{
            name: "Ramen Ya",
            type: "Japonesa",
            price_level: "R$ Barato",
            description: "Tonkotsu"
          }
        },
        %{
          day_number: 2,
          theme: "Cidade",
          morning: %{title: "Nijo Castle", description: "Castelo", cost: "R$ 40", duration: "2h"},
          afternoon: %{
            title: "Nishiki Market",
            description: "Mercado",
            cost: "R$ 30",
            duration: "3h"
          },
          evening: %{title: "Pontocho", description: "Ruelas", cost: "R$ 60", duration: "2h"},
          dining_spot: %{
            name: "Izakaya",
            type: "Japonesa",
            price_level: "R$ Moderado",
            description: "Sake"
          }
        }
      ],
      tips: []
    })
    |> Map.merge(overrides)
  end

  def budget_trip_plan do
    sample_trip_plan(%{
      id: "trip_1",
      destination: "Paris",
      duration_days: 4,
      budget_estimate: %{
        total_cost_estimate: "R$ 5000",
        hotel_average_night: "R$ 300",
        food_average_day: "R$ 150",
        transport_average_day: "R$ 50"
      },
      days: [],
      tips: []
    })
  end
end
