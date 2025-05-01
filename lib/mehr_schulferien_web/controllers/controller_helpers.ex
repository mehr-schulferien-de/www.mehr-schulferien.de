defmodule MehrSchulferienWeb.ControllerHelpers do
  @moduledoc """
  Helper functions for use with controllers.

  Note: This module is kept for backward compatibility.
  New code should use modules in MehrSchulferienWeb.Controllers.Helpers namespace instead.
  """

  alias MehrSchulferienWeb.Controllers.Helpers.PeriodHelpers

  @doc """
  Returns period data for a location, including school and public periods.

  @deprecated Use MehrSchulferienWeb.Controllers.Helpers.PeriodHelpers.list_period_data/2 instead.
  """
  defdelegate list_period_data(location_ids, today), to: PeriodHelpers

  @doc """
  Returns FAQ-related period data including information about holidays.

  @deprecated Use MehrSchulferienWeb.Controllers.Helpers.PeriodHelpers.list_faq_data/2 instead.
  """
  defdelegate list_faq_data(location_ids, today), to: PeriodHelpers
end
