defmodule Slax.Helpers.Markdown.Test do
  use ExUnit.Case, async: true

  import Slax.Helpers.Markdown

  doctest Slax.Helpers.Markdown

  describe "to_slack/1" do
    test "converts headings to bold" do
      assert to_slack("# One\n## Two ##\n### **Three**") == "*One*\n*Two*\n*Three*"
    end

    test "converts bold, italic, and bold italic" do
      assert to_slack("**a** __b__ *c* ***d***") == "*a* *b* _c_ *_d_*"
    end

    test "keeps bold that wraps italic" do
      assert to_slack("**bold *and* italic**") == "*bold _and_ italic*"
    end

    test "leaves underscores and asterisks inside words alone" do
      assert to_slack("snake_case_name and 2*3*4") == "snake_case_name and 2*3*4"
    end

    test "converts strikethrough" do
      assert to_slack("~~gone~~") == "~gone~"
    end

    test "converts links and images" do
      markdown =
        ~s|[docs](https://a.io/x?y=1&z=2 "Docs") ![shot](https://a.io/s.png) ![](https://a.io/t.png)|

      assert to_slack(markdown) ==
               "<https://a.io/x?y=1&amp;z=2|docs> <https://a.io/s.png|shot> <https://a.io/t.png>"
    end

    test "converts html links, images, and autolinks" do
      markdown =
        ~s|<a href="https://a.io">Site</a> <img width="10" src="https://a.io/i.png"> <https://a.io/b>|

      assert to_slack(markdown) ==
               "<https://a.io|Site> <https://a.io/i.png|image> <https://a.io/b>"
    end

    test "escapes link text but not formatting inside urls" do
      assert to_slack("[a < b](https://a.io/some_path_here)") ==
               "<https://a.io/some_path_here|a &lt; b>"
    end

    test "converts bullet and task lists and keeps numbered lists" do
      markdown = "- one\n* two\n+ three\n  - nested\n- [ ] todo\n- [X] done\n1. first\n2. second"

      assert to_slack(markdown) ==
               "• one\n• two\n• three\n  • nested\n☐ todo\n☑ done\n1. first\n2. second"
    end

    test "keeps blockquotes and escapes other angle brackets" do
      assert to_slack("> quoted\n>also quoted\na > b") == "> quoted\n> also quoted\na &gt; b"
    end

    test "renders tables as an aligned code block" do
      markdown =
        "Before\n\n| Name | Value |\n|:-----|------:|\n| a | 1 |\n| longer | 22 |\n\nAfter"

      assert to_slack(markdown) ==
               "Before\n\n```\nName   | Value\na      | 1\nlonger | 22\n```\n\nAfter"
    end

    test "pads ragged table rows" do
      assert to_slack("| a | b |\n|---|---|\n| c |") == "```\na | b\nc\n```"
    end

    test "strips the language from fenced code and escapes inside it" do
      markdown = "```elixir\nif a < b && c, do: **x**\n```"

      assert to_slack(markdown) == "```\nif a &lt; b &amp;&amp; c, do: **x**\n```"
    end

    test "does not reformat inline code" do
      assert to_slack("Use `**not bold**` and `[x](y)`") == "Use `**not bold**` and `[x](y)`"
    end

    test "strips html comments and converts simple html tags" do
      markdown =
        "<!-- template\nnote -->\n<details><summary>More</summary>\n<b>bold</b> <i>it</i> <code>c</code><br>next\n</details>"

      assert to_slack(markdown) == "More\n*bold* _it_ `c`\nnext"
    end

    test "converts horizontal rules" do
      assert to_slack("a\n***\nb\n___\nc\n- - -\nd") == "a\n---\nb\n---\nc\n---\nd"
    end

    test "normalizes windows newlines and collapses blank lines" do
      assert to_slack("a\r\n\r\n\r\n\r\nb\r\n") == "a\n\nb"
    end

    test "escapes ampersands" do
      assert to_slack("Tom & Jerry") == "Tom &amp; Jerry"
    end

    test "handles a realistic issue body" do
      markdown = """
      ## Summary

      When a user clicks **Save** on the `/settings` page the request fails.

      ### Steps to reproduce

      1. Log in as an admin
      2. Go to [Settings](https://example.com/settings)
      3. Click *Save*

      ### Checklist

      - [x] Reproduced locally
      - [ ] Fix written
      - [ ] Tests added

      > Note: only happens when `flag_enabled == true`

      ```
      ** (RuntimeError) boom
      ```
      """

      expected = """
      *Summary*

      When a user clicks *Save* on the `/settings` page the request fails.

      *Steps to reproduce*

      1. Log in as an admin
      2. Go to <https://example.com/settings|Settings>
      3. Click _Save_

      *Checklist*

      ☑ Reproduced locally
      ☐ Fix written
      ☐ Tests added

      > Note: only happens when `flag_enabled == true`

      ```
      ** (RuntimeError) boom
      ```
      """

      assert to_slack(markdown) == String.trim(expected)
    end
  end

  describe "escape/1" do
    test "escapes the three characters Slack requires" do
      assert escape("<a> & <b>") == "&lt;a&gt; &amp; &lt;b&gt;"
    end
  end
end
