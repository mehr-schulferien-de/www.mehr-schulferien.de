defmodule MehrSchulferienWeb.Shared.CodeBlockComponent do
  @moduledoc """
  Shared code block for the developer documentation pages.

  The code is passed via the `content` attribute (usually a `~s|...|` sigil)
  instead of an inner block so the HEEx formatter cannot alter the
  significant whitespace inside the rendered `<pre>` block.

  The copy button calls the `copyToClipboard/1` JavaScript function that the
  developer pages define inline (see `developers.html.heex` and
  `developers_mcp.html.heex`).
  """
  use Phoenix.Component

  # Default style for plain documentation code blocks.
  @plain_class "bg-gray-100 dark:bg-gray-800 p-4 mb-6 rounded overflow-x-auto text-sm"
  # Default style for terminal-like blocks with a copy button.
  @copy_class "bg-gray-900 text-gray-100 p-3 pr-20 rounded-lg overflow-x-auto text-sm"

  attr :content, :string, required: true, doc: "code to display (rendered HTML-escaped)"

  attr :copy, :string,
    default: nil,
    doc: "clipboard text; when set, a copy button is rendered above the block"

  attr :label, :string, default: nil, doc: "optional language label shown above the block"

  attr :class, :string,
    default: nil,
    doc: "classes for the <pre> tag; defaults depend on whether copy is set"

  attr :tabindex, :string, default: nil

  def code_block(assigns) do
    assigns =
      assign(
        assigns,
        :pre_class,
        assigns.class || if(assigns.copy, do: @copy_class, else: @plain_class)
      )

    ~H"""
    <div :if={@label} class="text-xs text-gray-500 dark:text-gray-400 mb-1">{@label}</div>
    <div :if={@copy} class="relative">
      <button
        onclick="copyToClipboard(this)"
        data-content={@copy}
        class="absolute top-2 right-2 px-3 py-1 text-xs bg-gray-700 hover:bg-gray-600 text-white rounded transition-colors"
        title="In Zwischenablage kopieren"
      >
        Kopieren
      </button>
      <pre class={@pre_class} tabindex={@tabindex}><code>{@content}</code></pre>
    </div>
    <pre :if={is_nil(@copy)} class={@pre_class} tabindex={@tabindex}>{@content}</pre>
    """
  end
end
