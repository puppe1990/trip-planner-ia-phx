defmodule TripPlannerIa.PlannerJsonInstructions do
  @moduledoc false

  @activity_fields ~s({ "title": "string", "description": "string", "cost": "string", "duration": "string" })
  @dining_fields ~s({ "name": "string", "type": "string", "priceLevel": "string", "description": "string" })

  def build_planner_json_schema_instruction do
    """
    Return ONLY one raw JSON object (no markdown fences, no commentary) with EXACTLY these keys:
    {
      "destination": "string",
      "durationDays": number,
      "tagline": "string",
      "summary": "string",
      "budgetEstimate": {
        "totalCostEstimate": "string",
        "hotelAverageNight": "string",
        "foodAverageDay": "string",
        "transportAverageDay": "string"
      },
      "packingEssentials": ["string"],
      "weatherExpected": "string",
      "days": [
        {
          "dayNumber": number,
          "theme": "string",
          "morning": #{@activity_fields},
          "afternoon": #{@activity_fields},
          "evening": #{@activity_fields},
          "diningSpot": #{@dining_fields}
        }
      ],
      "tips": [{ "category": "string", "text": "string" }]
    }
    All fields are required. Use the requested destination and durationDays values exactly.
    """
    |> String.trim()
  end

  def build_planner_outline_schema_instruction do
    """
    Return ONLY one raw JSON object (no markdown fences, no commentary) with EXACTLY these keys:
    {
      "destination": "string",
      "durationDays": number,
      "tagline": "string",
      "summary": "string",
      "budgetEstimate": {
        "totalCostEstimate": "string",
        "hotelAverageNight": "string",
        "foodAverageDay": "string",
        "transportAverageDay": "string"
      },
      "packingEssentials": ["string"],
      "weatherExpected": "string"
    }
    All fields are required. Use the requested destination and durationDays values exactly.
    """
    |> String.trim()
  end

  def build_planner_day_schema_instruction do
    """
    Return ONLY one raw JSON object (no markdown fences, no commentary) with EXACTLY these keys:
    {
      "dayNumber": number,
      "theme": "string",
      "morning": #{@activity_fields},
      "afternoon": #{@activity_fields},
      "evening": #{@activity_fields},
      "diningSpot": #{@dining_fields}
    }
    All fields are required. Use the requested dayNumber exactly.
    """
    |> String.trim()
  end

  def build_planner_tips_schema_instruction do
    """
    Return ONLY one raw JSON object (no markdown fences, no commentary) with EXACTLY this key:
    {
      "tips": [{ "category": "string", "text": "string" }]
    }
    Provide at least 4 practical tips.
    """
    |> String.trim()
  end
end