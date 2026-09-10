defmodule Slax.Helpers.Markdown do
  @moduledoc """
  Converts GitHub-flavored Markdown into Slack `mrkdwn`.

  Slack doesn't render standard Markdown. It uses its own `mrkdwn` syntax,
  which differs in several ways:

  * Bold is `*text*`, not `**text**`.
  * Italic is `_text_`, not `*text*`.
  * Strikethrough is `~text~`, not `~~text~~`.
  * Links are `<url|text>`, not `[text](url)`.
  * Headings, tables, and horizontal rules aren't supported.
  * `&`, `<`, and `>` must be escaped as HTML entities.

  `to_slack/1` handles those differences so text copied from a GitHub issue
  reads well when posted to Slack.
  """

  # Private-use characters that won't appear in real issue text. They mark
  # stashed segments (code, tables, links) that must not be reformatted or
  # escaped again, and the bold marker that must survive italic conversion.
  @stash_open "\uE000"
  @stash_close "\uE001"
  @bold "\uE002"

  @fenced_code ~r/```[^\n]*\n(.*?)\n?```/s
  @table ~r/(?:^[ \t]*\|[^\n]*(?:\n|\z)){2,}/m
  @table_separator ~r/^[ \t]*\|?[ \t]*:?-+:?[ \t]*(?:\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$/
  @inline_code ~r/`[^`\n]+`/
  @image ~r/!\[([^\]]*)\]\(([^)\s]+)(?:[ \t]+"[^"]*")?\)/
  @link ~r/\[([^\]]+)\]\(([^)\s]+)(?:[ \t]+"[^"]*")?\)/
  @img_tag ~r/<img\b[^>]*\bsrc="([^"]+)"[^>]*>/i
  @anchor_tag ~r/<a\b[^>]*\bhref="([^"]+)"[^>]*>(.*?)<\/a>/is
  @autolink ~r/<(https?:\/\/[^\s>]+)>/
  # `[#]` instead of `#` keeps the sigil from reading `#{` as interpolation.
  @heading ~r/^[ \t]{0,3}[#]{1,6}[ \t]+(.+?)[ \t]*[#]*[ \t]*$/m

  @doc """
  Converts a GitHub-flavored Markdown string into Slack `mrkdwn`.

  Returns an empty string for `nil`, which is what the GitHub API returns for
  an issue with no body.

  ## Examples

      iex> to_slack("# Title\\n\\nSome **bold** and *italic* text.")
      "*Title*\\n\\nSome *bold* and _italic_ text."

      iex> to_slack("- [x] done\\n- [ ] todo\\n- plain")
      "☑ done\\n☐ todo\\n• plain"

      iex> to_slack("See [the docs](https://example.com/a_b) & `x < y`.")
      "See <https://example.com/a_b|the docs> &amp; `x &lt; y`."

      iex> to_slack("```elixir\\nIO.puts(\\"hi\\")\\n```")
      "```\\nIO.puts(\\"hi\\")\\n```"

      iex> to_slack(nil)
      ""

  """
  @spec to_slack(String.t() | nil) :: String.t()
  def to_slack(nil), do: ""

  def to_slack(markdown) when is_binary(markdown) do
    {text, stash} =
      markdown
      |> String.replace("\r\n", "\n")
      |> strip_html_comments()
      |> convert_html_tags()
      |> stash(@fenced_code, fn [_, code] -> "```\n#{escape(code)}\n```" end)
      |> stash(@table, fn [table] -> format_table(table) end)
      |> stash(@inline_code, fn [code] -> escape(code) end)
      |> stash(@image, fn [_, alt, url] -> slack_link(url, alt) end)
      |> stash(@link, fn [_, text, url] -> slack_link(url, text) end)
      |> stash(@img_tag, fn [_, url] -> slack_link(url, "image") end)
      |> stash(@anchor_tag, fn [_, url, text] -> slack_link(url, String.trim(text)) end)
      |> stash(@autolink, fn [_, url] -> slack_link(url, "") end)

    text
    |> escape()
    |> convert_rules()
    |> convert_headings()
    |> convert_emphasis()
    |> convert_strikethrough()
    |> convert_lists()
    |> convert_blockquotes()
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> restore(stash)
    |> String.trim()
  end

  @doc """
  Escapes the three characters Slack requires as HTML entities.

  ## Examples

      iex> escape("a < b && c > d")
      "a &lt; b &amp;&amp; c &gt; d"

  """
  @spec escape(String.t()) :: String.t()
  def escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  # Pulls every match of `regex` out of the text and replaces it with a
  # placeholder. `fun` receives the match (whole match first, then captures)
  # and returns the finished Slack text to put back at the end. Later stashes
  # may contain earlier placeholders, so `restore/2` unwinds them in reverse.
  defp stash(text, regex, fun) when is_binary(text), do: stash({text, []}, regex, fun)

  defp stash({text, stash}, regex, fun) do
    regex
    |> Regex.split(text, include_captures: true)
    |> Enum.with_index()
    |> Enum.map_reduce(stash, fn
      {part, index}, acc when rem(index, 2) == 1 ->
        placeholder = "#{@stash_open}#{length(acc)}#{@stash_close}"
        replacement = fun.(Regex.run(regex, part))
        {placeholder, [{placeholder, replacement} | acc]}

      {part, _index}, acc ->
        {part, acc}
    end)
    |> then(fn {parts, acc} -> {Enum.join(parts), acc} end)
  end

  defp restore(text, stash) do
    Enum.reduce(stash, text, fn {placeholder, replacement}, acc ->
      String.replace(acc, placeholder, replacement)
    end)
  end

  defp strip_html_comments(text), do: String.replace(text, ~r/<!--.*?-->/s, "")

  # GitHub issues often mix a little HTML into Markdown. Map the common tags to
  # their Markdown equivalents so the rest of the pipeline can handle them, and
  # drop layout-only wrappers that Slack can't show.
  defp convert_html_tags(text) do
    text
    |> String.replace(~r/<br[ \t]*\/?>/i, "\n")
    |> String.replace(~r/<\/?(?:b|strong)>/i, "**")
    |> String.replace(~r/<\/?(?:i|em)>/i, "*")
    |> String.replace(~r/<\/?(?:code|kbd)>/i, "`")
    |> String.replace(~r/<\/?(?:details|summary|p|div|center|sub|sup)\b[^>]*>/i, "")
  end

  defp slack_link(url, ""), do: "<#{escape_url(url)}>"
  defp slack_link(url, text), do: "<#{escape_url(url)}|#{escape(text)}>"

  defp escape_url(url), do: String.replace(url, "&", "&amp;")

  # Slack has no tables, so render one as a monospaced block with the columns
  # padded to line up.
  defp format_table(table) do
    rows =
      table
      |> String.split("\n", trim: true)
      |> Enum.reject(&Regex.match?(@table_separator, &1))
      |> Enum.map(fn row ->
        row
        |> String.trim()
        |> String.trim("|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)
      end)

    case rows do
      [] -> ""
      rows -> "```\n#{rows |> pad_columns() |> escape()}\n```\n"
    end
  end

  defp pad_columns(rows) do
    column_count = rows |> Enum.map(&length/1) |> Enum.max()
    rows = Enum.map(rows, &(&1 ++ List.duplicate("", column_count - length(&1))))

    widths =
      Enum.zip_with(rows, fn column -> column |> Enum.map(&String.length/1) |> Enum.max() end)

    Enum.map_join(rows, "\n", fn row ->
      row
      |> Enum.zip(widths)
      |> Enum.map_join(" | ", fn {cell, width} -> String.pad_trailing(cell, width) end)
      |> String.replace(~r/(\s*\|)*\s*$/, "")
    end)
  end

  defp convert_rules(text) do
    String.replace(text, ~r/^[ \t]*([-*_])(?:[ \t]*\1){2,}[ \t]*$/m, "---")
  end

  defp convert_headings(text) do
    Regex.replace(@heading, text, fn _, title ->
      "#{@bold}#{String.trim(title, "*")}#{@bold}"
    end)
  end

  # Bold is converted to a marker first so the italic pass can't mistake the
  # single `*` Slack uses for bold as Markdown italic.
  defp convert_emphasis(text) do
    text
    |> String.replace(~r/\*\*\*(?=\S)(.+?)(?<=\S)\*\*\*/, "#{@bold}_\\1_#{@bold}")
    |> String.replace(~r/\*\*(?=\S)(.+?)(?<=\S)\*\*/, "#{@bold}\\1#{@bold}")
    |> String.replace(~r/(?<!\w)__(?=\S)(.+?)(?<=\S)__(?!\w)/, "#{@bold}\\1#{@bold}")
    |> String.replace(~r/(?<![\w*])\*(?=[^\s*])(.+?)(?<=[^\s*])\*(?![\w*])/, "_\\1_")
    |> String.replace(@bold, "*")
  end

  defp convert_strikethrough(text) do
    String.replace(text, ~r/~~(?=\S)(.+?)(?<=\S)~~/, "~\\1~")
  end

  defp convert_lists(text) do
    text
    |> String.replace(~r/^([ \t]*)[-*+][ \t]+\[[xX]\][ \t]+/m, "\\1☑ ")
    |> String.replace(~r/^([ \t]*)[-*+][ \t]+\[ \][ \t]+/m, "\\1☐ ")
    |> String.replace(~r/^([ \t]*)[-*+][ \t]+/m, "\\1• ")
  end

  # `>` was escaped above, so a quote marker now reads `&gt;`. Put the real
  # character back at the start of the line, where Slack treats it as a quote.
  defp convert_blockquotes(text) do
    String.replace(text, ~r/^([ \t]*)&gt;[ \t]?/m, "\\1> ")
  end
end
